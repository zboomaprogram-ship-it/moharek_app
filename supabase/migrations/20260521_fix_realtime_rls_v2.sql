-- ============================================================
-- FIX: Drop existing policies before recreating them
-- Idempotent version of 20260521_fix_realtime_and_rls.sql
-- Run this INSTEAD of the previous version if it errored.
-- ============================================================

-- ── 1. Enable Realtime on the relevant tables ──────────────
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'messages'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'chat_channels'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_channels;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'notifications'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
  END IF;
END $$;

-- ── 2. messages table RLS ──────────────────────────────────
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Drop ALL known policy names (belt and suspenders)
DO $$ DECLARE pol text;
BEGIN
  FOR pol IN
    SELECT policyname FROM pg_policies
    WHERE tablename = 'messages' AND schemaname = 'public'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.messages', pol);
  END LOOP;
END $$;

CREATE POLICY "messages_select" ON public.messages
  FOR SELECT USING (
    channel_id IN (
      SELECT cc.id FROM public.chat_channels cc
      WHERE cc.project_id IN (SELECT my_project_ids())
    )
    OR (SELECT role FROM public.profiles WHERE id = auth.uid())
      IN ('admin','account_manager','ads_team','seo_team',
          'content_team','design_team','tech_team')
  );

CREATE POLICY "messages_insert" ON public.messages
  FOR INSERT WITH CHECK (
    channel_id IN (
      SELECT cc.id FROM public.chat_channels cc
      WHERE cc.project_id IN (SELECT my_project_ids())
    )
    OR (SELECT role FROM public.profiles WHERE id = auth.uid())
      IN ('admin','account_manager','ads_team','seo_team',
          'content_team','design_team','tech_team')
  );

-- ── 3. chat_channels table RLS ─────────────────────────────
ALTER TABLE public.chat_channels ENABLE ROW LEVEL SECURITY;

DO $$ DECLARE pol text;
BEGIN
  FOR pol IN
    SELECT policyname FROM pg_policies
    WHERE tablename = 'chat_channels' AND schemaname = 'public'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.chat_channels', pol);
  END LOOP;
END $$;

CREATE POLICY "chat_channels_select" ON public.chat_channels
  FOR SELECT USING (
    project_id IN (SELECT my_project_ids())
    OR (SELECT role FROM public.profiles WHERE id = auth.uid())
      IN ('admin','account_manager','ads_team','seo_team',
          'content_team','design_team','tech_team')
  );

CREATE POLICY "chat_channels_all" ON public.chat_channels
  FOR ALL USING (
    (SELECT role FROM public.profiles WHERE id = auth.uid())
      IN ('admin','account_manager','ads_team','seo_team',
          'content_team','design_team','tech_team')
  );

-- ── 4. get_or_create_chat_channel RPC ─────────────────────
CREATE OR REPLACE FUNCTION public.get_or_create_chat_channel(p_project_id uuid)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_channel_id uuid;
BEGIN
  SELECT id INTO v_channel_id FROM public.chat_channels
  WHERE project_id = p_project_id LIMIT 1;
  IF v_channel_id IS NULL THEN
    INSERT INTO public.chat_channels (project_id, name)
    VALUES (p_project_id, 'general') RETURNING id INTO v_channel_id;
  END IF;
  RETURN v_channel_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_or_create_chat_channel(uuid) TO authenticated;
