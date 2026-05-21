-- ============================================================
-- FIX: RealtimeSubscribeStatus.channelError on messages table
--
-- Root causes:
--   1. messages / chat_channels tables not in supabase_realtime publication
--   2. RLS USING clause not valid for Realtime filter (needs WITH CHECK too)
--   3. Rabhan client with no channel gets a dead-end UI instead of auto-create
-- ============================================================

-- ── 1. Enable Realtime on the relevant tables ──────────────
DO $$
BEGIN
  -- messages
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'messages'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
  END IF;

  -- chat_channels
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'chat_channels'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_channels;
  END IF;

  -- notifications
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'notifications'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
  END IF;
END $$;

-- ── 2. Fix RLS on messages so Realtime can authenticate the subscription ──
-- Realtime uses the same RLS — the policy must allow SELECT for the connecting user.

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Drop old policies
DROP POLICY IF EXISTS "clients can view messages"           ON public.messages;
DROP POLICY IF EXISTS "clients and team can view messages"  ON public.messages;
DROP POLICY IF EXISTS "Users can view messages"             ON public.messages;
DROP POLICY IF EXISTS "Team can view messages"              ON public.messages;
DROP POLICY IF EXISTS "Allow message reads"                 ON public.messages;
DROP POLICY IF EXISTS "messages_select_policy"              ON public.messages;

-- Allow SELECT: client (via their project channels) OR any team member
CREATE POLICY "messages_select" ON public.messages
  FOR SELECT USING (
    channel_id IN (
      SELECT cc.id FROM public.chat_channels cc
      WHERE cc.project_id IN (SELECT my_project_ids())   -- client path
    )
    OR
    (SELECT role FROM public.profiles WHERE id = auth.uid())
    IN ('admin', 'account_manager', 'ads_team', 'seo_team',
        'content_team', 'design_team', 'tech_team')        -- team path
  );

-- Drop old insert policies
DROP POLICY IF EXISTS "clients can insert messages"         ON public.messages;
DROP POLICY IF EXISTS "Team can insert messages"            ON public.messages;
DROP POLICY IF EXISTS "Allow message inserts"               ON public.messages;
DROP POLICY IF EXISTS "messages_insert_policy"              ON public.messages;
DROP POLICY IF EXISTS "Clients and team can send messages"  ON public.messages;

-- Allow INSERT: client (via their project channels) OR any team member
CREATE POLICY "messages_insert" ON public.messages
  FOR INSERT WITH CHECK (
    channel_id IN (
      SELECT cc.id FROM public.chat_channels cc
      WHERE cc.project_id IN (SELECT my_project_ids())
    )
    OR
    (SELECT role FROM public.profiles WHERE id = auth.uid())
    IN ('admin', 'account_manager', 'ads_team', 'seo_team',
        'content_team', 'design_team', 'tech_team')
  );

-- ── 3. Fix RLS on chat_channels ────────────────────────────
ALTER TABLE public.chat_channels ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "clients can view channels"           ON public.chat_channels;
DROP POLICY IF EXISTS "Team can view channels"              ON public.chat_channels;
DROP POLICY IF EXISTS "Allow channel reads"                 ON public.chat_channels;
DROP POLICY IF EXISTS "chat_channels_select_policy"         ON public.chat_channels;

CREATE POLICY "chat_channels_select" ON public.chat_channels
  FOR SELECT USING (
    project_id IN (SELECT my_project_ids())
    OR
    (SELECT role FROM public.profiles WHERE id = auth.uid())
    IN ('admin', 'account_manager', 'ads_team', 'seo_team',
        'content_team', 'design_team', 'tech_team')
  );

DROP POLICY IF EXISTS "Team can manage channels"            ON public.chat_channels;
DROP POLICY IF EXISTS "Allow channel inserts"               ON public.chat_channels;

CREATE POLICY "chat_channels_all" ON public.chat_channels
  FOR ALL USING (
    (SELECT role FROM public.profiles WHERE id = auth.uid())
    IN ('admin', 'account_manager', 'ads_team', 'seo_team',
        'content_team', 'design_team', 'tech_team')
  );

-- ── 4. Ensure get_or_create_chat_channel RPC exists ────────
-- Called by both Moharek and Rabhan chatChannelProvider
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

  -- Create if not found
  IF v_channel_id IS NULL THEN
    INSERT INTO public.chat_channels (project_id, name)
    VALUES (p_project_id, 'general')
    RETURNING id INTO v_channel_id;
  END IF;

  RETURN v_channel_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_or_create_chat_channel(uuid) TO authenticated;
