-- ============================================================
-- COMPREHENSIVE CHAT FIX
-- Fixes all causes of "cannot insert into messages":
--   1. RLS INSERT policy (admin/client)
--   2. RLS UPDATE policy (mark as read)
--   3. Ensures every project has a chat_channel row
--   4. Adds a helper to auto-create channels on demand
-- ============================================================

-- ── 1. MESSAGES INSERT POLICY ─────────────────────────────
DROP POLICY IF EXISTS "Messages insert" ON public.messages;

CREATE POLICY "Messages insert" ON public.messages
  FOR INSERT
  WITH CHECK (
    sender_id = auth.uid()
    AND (
      -- Client: channel belongs to one of their projects
      channel_id IN (
        SELECT id FROM public.chat_channels
        WHERE project_id IN (SELECT id FROM public.projects WHERE client_id = auth.uid())
      )
      -- Admin / account_manager: unrestricted
      OR EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid()
          AND role IN ('admin', 'account_manager')
      )
    )
  );

-- ── 2. MESSAGES UPDATE POLICY ─────────────────────────────
DROP POLICY IF EXISTS "Messages update" ON public.messages;

CREATE POLICY "Messages update" ON public.messages
  FOR UPDATE
  USING (
    channel_id IN (
      SELECT id FROM public.chat_channels
      WHERE project_id IN (SELECT id FROM public.projects WHERE client_id = auth.uid())
    )
    OR EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
        AND role IN ('admin', 'account_manager')
    )
  );

-- ── 3. ENSURE EVERY PROJECT HAS A CHAT CHANNEL ────────────
-- Creates a channel for any project that is missing one.
INSERT INTO public.chat_channels (project_id, name, channel_type)
SELECT
  p.id,
  'Project Chat',
  'client_manager'
FROM public.projects p
WHERE NOT EXISTS (
  SELECT 1 FROM public.chat_channels c WHERE c.project_id = p.id
)
ON CONFLICT DO NOTHING;

-- ── 4. RPC: get_or_create_chat_channel ────────────────────
-- Used by the app to reliably get a channel_id.
CREATE OR REPLACE FUNCTION public.get_or_create_chat_channel(p_project_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_channel_id uuid;
BEGIN
  -- Try to find existing channel
  SELECT id INTO v_channel_id
  FROM public.chat_channels
  WHERE project_id = p_project_id
  LIMIT 1;

  -- Create if missing
  IF v_channel_id IS NULL THEN
    INSERT INTO public.chat_channels (project_id, name, channel_type)
    VALUES (p_project_id, 'Project Chat', 'client_manager')
    RETURNING id INTO v_channel_id;
  END IF;

  RETURN v_channel_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_or_create_chat_channel(uuid) TO authenticated;

-- ── 5. Realtime (idempotent) ───────────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'messages'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE messages;
  END IF;
END$$;
