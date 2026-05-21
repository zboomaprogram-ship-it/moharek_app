-- ================================================================
-- COMPREHENSIVE FIX: Realtime, RLS, Push Notifications, Profile
-- Run this in Supabase SQL Editor (project: pyzheqwypoaazpmpgiuq)
-- ================================================================

-- ── PART 1: Enable Realtime on ALL tables the app streams from ──
-- This fixes: RealtimeSubscribeStatus.channelError on ALL providers
DO $$
DECLARE
  tbl TEXT;
  tables TEXT[] := ARRAY[
    'messages', 'chat_channels', 'notifications', 'tasks',
    'approvals', 'contracts', 'results', 'engine_progress',
    'growth_engines', 'journey_stages', 'reports', 'invoices',
    'files', 'meetings', 'support_tickets', 'activity_feed',
    'support_ticket_messages', 'milestones', 'campaigns',
    'campaign_results', 'call_signals', 'profiles', 'projects'
  ];
BEGIN
  FOREACH tbl IN ARRAY tables LOOP
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = tbl) THEN
      IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime' AND tablename = tbl
      ) THEN
        EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', tbl);
        RAISE NOTICE 'Added % to supabase_realtime', tbl;
      END IF;
    END IF;
  END LOOP;
END $$;

-- ── PART 2: Fix ALL RLS policies for stream tables ──────────────
-- Pattern: clients read their own project data; team reads all

-- Helper: ensure every client has a profile (prevents PGRST116)
-- If profiles.id doesn't have a row for auth.uid(), insert a stub
CREATE OR REPLACE FUNCTION public.ensure_profile_exists()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_email text;
  v_name text;
BEGIN
  IF v_user_id IS NULL THEN RETURN; END IF;
  IF EXISTS (SELECT 1 FROM public.profiles WHERE id = v_user_id) THEN RETURN; END IF;
  -- Get email from auth.users
  SELECT email INTO v_email FROM auth.users WHERE id = v_user_id;
  INSERT INTO public.profiles (id, email, full_name, role, created_at)
  VALUES (v_user_id, v_email, split_part(v_email, '@', 1), 'client', now())
  ON CONFLICT (id) DO NOTHING;
END;
$$;

GRANT EXECUTE ON FUNCTION public.ensure_profile_exists() TO authenticated;

-- Auto-create profile on first sign-in via trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role, created_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    'client',
    now()
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ── tasks RLS ──
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
DO $$ DECLARE pol text; BEGIN
  FOR pol IN SELECT policyname FROM pg_policies WHERE tablename='tasks' AND schemaname='public'
  LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.tasks', pol); END LOOP;
END $$;
CREATE POLICY "tasks_select" ON public.tasks FOR SELECT USING (
  project_id IN (SELECT my_project_ids()) OR
  (SELECT role FROM public.profiles WHERE id = auth.uid())
    IN ('admin','account_manager','ads_team','seo_team','content_team','design_team','tech_team')
);
CREATE POLICY "tasks_team_all" ON public.tasks FOR ALL USING (
  (SELECT role FROM public.profiles WHERE id = auth.uid())
    IN ('admin','account_manager','ads_team','seo_team','content_team','design_team','tech_team')
);

-- ── approvals RLS ──
ALTER TABLE public.approvals ENABLE ROW LEVEL SECURITY;
DO $$ DECLARE pol text; BEGIN
  FOR pol IN SELECT policyname FROM pg_policies WHERE tablename='approvals' AND schemaname='public'
  LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.approvals', pol); END LOOP;
END $$;
CREATE POLICY "approvals_select" ON public.approvals FOR SELECT USING (
  project_id IN (SELECT my_project_ids()) OR
  (SELECT role FROM public.profiles WHERE id = auth.uid())
    IN ('admin','account_manager','ads_team','seo_team','content_team','design_team','tech_team')
);
CREATE POLICY "approvals_team_all" ON public.approvals FOR ALL USING (
  (SELECT role FROM public.profiles WHERE id = auth.uid())
    IN ('admin','account_manager','ads_team','seo_team','content_team','design_team','tech_team')
);

-- ── contracts RLS ──
ALTER TABLE public.contracts ENABLE ROW LEVEL SECURITY;
DO $$ DECLARE pol text; BEGIN
  FOR pol IN SELECT policyname FROM pg_policies WHERE tablename='contracts' AND schemaname='public'
  LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.contracts', pol); END LOOP;
END $$;
CREATE POLICY "contracts_select" ON public.contracts FOR SELECT USING (
  project_id IN (SELECT my_project_ids()) OR
  (SELECT role FROM public.profiles WHERE id = auth.uid())
    IN ('admin','account_manager','ads_team','seo_team','content_team','design_team','tech_team')
);
CREATE POLICY "contracts_team_all" ON public.contracts FOR ALL USING (
  (SELECT role FROM public.profiles WHERE id = auth.uid())
    IN ('admin','account_manager','ads_team','seo_team','content_team','design_team','tech_team')
);

-- ── notifications RLS ──
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
DO $$ DECLARE pol text; BEGIN
  FOR pol IN SELECT policyname FROM pg_policies WHERE tablename='notifications' AND schemaname='public'
  LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.notifications', pol); END LOOP;
END $$;
CREATE POLICY "notifications_select" ON public.notifications FOR SELECT USING (
  user_id = auth.uid() OR
  (SELECT role FROM public.profiles WHERE id = auth.uid())
    IN ('admin','account_manager','ads_team','seo_team','content_team','design_team','tech_team')
);
CREATE POLICY "notifications_update" ON public.notifications FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "notifications_team_insert" ON public.notifications FOR INSERT WITH CHECK (true); -- service role inserts

-- ── profiles RLS (allow user to read their own + team reads all) ──
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
DO $$ DECLARE pol text; BEGIN
  FOR pol IN SELECT policyname FROM pg_policies WHERE tablename='profiles' AND schemaname='public'
  LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.profiles', pol); END LOOP;
END $$;
CREATE POLICY "profiles_select_own" ON public.profiles FOR SELECT USING (
  id = auth.uid() OR
  (SELECT role FROM public.profiles WHERE id = auth.uid())
    IN ('admin','account_manager','ads_team','seo_team','content_team','design_team','tech_team')
);
CREATE POLICY "profiles_update_own" ON public.profiles FOR UPDATE USING (id = auth.uid());
CREATE POLICY "profiles_insert_own" ON public.profiles FOR INSERT WITH CHECK (id = auth.uid());

-- ── PART 3: Fix chat message notification trigger ───────────────
-- The trigger directly calls the Edge Function with service_role key
-- to avoid auth issues.

CREATE OR REPLACE FUNCTION public.on_message_inserted()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  target_user_id    UUID;
  project_client_id UUID;
  project_am_id     UUID;
  service_key TEXT := current_setting('app.supabase_service_key', true);
  fn_url TEXT;
  sender_name TEXT;
BEGIN
  -- Get the service key and URL from app settings (set via Supabase secrets)
  -- Fallback: hardcode project URL (safe, it's public)
  fn_url := 'https://pyzheqwypoaazpmpgiuq.supabase.co/functions/v1/send-notification';

  -- Skip system/automated messages
  IF NEW.message_type = 'system' THEN RETURN NEW; END IF;

  -- Get the project for this channel
  SELECT p.client_id, p.account_manager_id
  INTO project_client_id, project_am_id
  FROM public.chat_channels c
  JOIN public.projects p ON c.project_id = p.id
  WHERE c.id = NEW.channel_id;

  -- Determine recipient: notify the OTHER party
  IF NEW.sender_id = project_client_id THEN
    target_user_id := project_am_id;
  ELSE
    target_user_id := project_client_id;
  END IF;

  IF target_user_id IS NULL THEN RETURN NEW; END IF;

  -- Get sender name for the notification body
  SELECT COALESCE(full_name, 'فريق ربحان') INTO sender_name
  FROM public.profiles WHERE id = NEW.sender_id;

  -- Insert an in-app notification row (picked up by the app's notification stream)
  INSERT INTO public.notifications (
    user_id, type, title_ar, title_en, body_ar, body_en,
    is_read, data, created_at
  ) VALUES (
    target_user_id,
    'chat_message',
    '💬 رسالة جديدة',
    '💬 New Message',
    COALESCE(sender_name, 'فريقك') || ': ' || LEFT(NEW.content, 80),
    COALESCE(sender_name, 'Your team') || ': ' || LEFT(NEW.content, 80),
    false,
    jsonb_build_object(
      'sender_id', NEW.sender_id,
      'channel_id', NEW.channel_id,
      'message_id', NEW.id
    ),
    now()
  );

  -- Also call Edge Function directly for immediate push (if pg_net is available)
  BEGIN
    IF service_key IS NOT NULL AND service_key != '' THEN
      PERFORM net.http_post(
        url     := fn_url,
        headers := jsonb_build_object(
          'Content-Type',  'application/json',
          'Authorization', 'Bearer ' || service_key
        ),
        body := jsonb_build_object(
          'table',          'messages',
          'record',         row_to_json(NEW),
          'target_user_id', target_user_id,
          'sender_name',    sender_name
        )
      );
    END IF;
  EXCEPTION WHEN OTHERS THEN
    -- pg_net not available or call failed — the notification row above is the fallback
    NULL;
  END;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_on_message_inserted ON public.messages;
CREATE TRIGGER trigger_on_message_inserted
  AFTER INSERT ON public.messages
  FOR EACH ROW EXECUTE FUNCTION public.on_message_inserted();

-- ── PART 4: Fix on_notification_inserted to use service_role ───
-- The old trigger used anon key — insufficient to call Edge Functions.
-- The new approach: read service key from pg_settings (set once below).

CREATE OR REPLACE FUNCTION public.on_notification_inserted()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  service_key TEXT := current_setting('app.supabase_service_key', true);
  fn_url TEXT := 'https://pyzheqwypoaazpmpgiuq.supabase.co/functions/v1/send-notification';
BEGIN
  -- Only call if pg_net is available and key is set
  BEGIN
    IF service_key IS NOT NULL AND service_key != '' THEN
      PERFORM net.http_post(
        url     := fn_url,
        headers := jsonb_build_object(
          'Content-Type',  'application/json',
          'Authorization', 'Bearer ' || service_key
        ),
        body := jsonb_build_object(
          'table',          'notifications',
          'record',         row_to_json(NEW),
          'target_user_id', NEW.user_id
        )
      );
    END IF;
  EXCEPTION WHEN OTHERS THEN NULL;
  END;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_notification_inserted ON public.notifications;
CREATE TRIGGER trigger_notification_inserted
  AFTER INSERT ON public.notifications
  FOR EACH ROW EXECUTE FUNCTION public.on_notification_inserted();

-- ── PART 5: Set the service key as a DB setting ─────────────────
-- ⚠️  REPLACE the value below with your actual Supabase service_role JWT
-- Get it from: Supabase Dashboard → Settings → API → service_role key
-- Run this separately AFTER pasting your key:
--
-- ALTER DATABASE postgres SET app.supabase_service_key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...your_service_role_key...';
--
-- Then run: SELECT pg_reload_conf();
--
-- NOTE: This is safe — the key is never exposed to clients (SECURITY DEFINER functions
-- run as the function owner, not the calling user).
