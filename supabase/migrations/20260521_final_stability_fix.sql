-- ================================================================
-- FINAL STABILITY FIX: RLS Recursion (42P17) & Missing Profiles Sync
-- Run this in the Supabase SQL Editor
-- ================================================================

-- ── 1. Create SECURITY DEFINER role helper (bypasses RLS recursion) ──
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS TEXT LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid() LIMIT 1;
$$;

GRANT EXECUTE ON FUNCTION public.get_my_role() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_role() TO anon;

-- ── 2. Re-create Profiles RLS Policies without self-references ──
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DO $$ DECLARE pol text;
BEGIN
  FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'profiles' AND schemaname = 'public'
  LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.profiles', pol); END LOOP;
END $$;

CREATE POLICY "profiles_select_own" ON public.profiles 
  FOR SELECT USING (id = auth.uid());

CREATE POLICY "profiles_select_team" ON public.profiles 
  FOR SELECT USING (
    public.get_my_role() IN ('admin','account_manager','ads_team','seo_team','content_team','design_team','tech_team')
  );

CREATE POLICY "profiles_update_own" ON public.profiles 
  FOR UPDATE USING (id = auth.uid());

CREATE POLICY "profiles_insert_own" ON public.profiles 
  FOR INSERT WITH CHECK (id = auth.uid());


-- ── 3. Re-create other table policies using get_my_role() ──

-- tasks
DO $$ DECLARE pol text; BEGIN
  FOR pol IN SELECT policyname FROM pg_policies WHERE tablename='tasks' AND schemaname='public'
  LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.tasks', pol); END LOOP;
END $$;
CREATE POLICY "tasks_select" ON public.tasks FOR SELECT USING (
  project_id IN (SELECT my_project_ids()) OR
  public.get_my_role() IN ('admin','account_manager','ads_team','seo_team','content_team','design_team','tech_team')
);
CREATE POLICY "tasks_team_all" ON public.tasks FOR ALL USING (
  public.get_my_role() IN ('admin','account_manager','ads_team','seo_team','content_team','design_team','tech_team')
);

-- approvals
DO $$ DECLARE pol text; BEGIN
  FOR pol IN SELECT policyname FROM pg_policies WHERE tablename='approvals' AND schemaname='public'
  LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.approvals', pol); END LOOP;
END $$;
CREATE POLICY "approvals_select" ON public.approvals FOR SELECT USING (
  project_id IN (SELECT my_project_ids()) OR
  public.get_my_role() IN ('admin','account_manager','ads_team','seo_team','content_team','design_team','tech_team')
);
CREATE POLICY "approvals_team_all" ON public.approvals FOR ALL USING (
  public.get_my_role() IN ('admin','account_manager','ads_team','seo_team','content_team','design_team','tech_team')
);

-- contracts
DO $$ DECLARE pol text; BEGIN
  FOR pol IN SELECT policyname FROM pg_policies WHERE tablename='contracts' AND schemaname='public'
  LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.contracts', pol); END LOOP;
END $$;
CREATE POLICY "contracts_select" ON public.contracts FOR SELECT USING (
  project_id IN (SELECT my_project_ids()) OR
  public.get_my_role() IN ('admin','account_manager','ads_team','seo_team','content_team','design_team','tech_team')
);
CREATE POLICY "contracts_team_all" ON public.contracts FOR ALL USING (
  public.get_my_role() IN ('admin','account_manager','ads_team','seo_team','content_team','design_team','tech_team')
);

-- notifications
DO $$ DECLARE pol text; BEGIN
  FOR pol IN SELECT policyname FROM pg_policies WHERE tablename='notifications' AND schemaname='public'
  LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.notifications', pol); END LOOP;
END $$;
CREATE POLICY "notifications_select" ON public.notifications FOR SELECT USING (
  user_id = auth.uid() OR
  public.get_my_role() IN ('admin','account_manager','ads_team','seo_team','content_team','design_team','tech_team')
);
CREATE POLICY "notifications_update" ON public.notifications FOR UPDATE USING (user_id = auth.uid());

-- messages
DO $$ DECLARE pol text; BEGIN
  FOR pol IN SELECT policyname FROM pg_policies WHERE tablename='messages' AND schemaname='public'
  LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.messages', pol); END LOOP;
END $$;
CREATE POLICY "messages_select" ON public.messages FOR SELECT USING (
  channel_id IN (SELECT cc.id FROM public.chat_channels cc WHERE cc.project_id IN (SELECT my_project_ids())) OR
  public.get_my_role() IN ('admin','account_manager','ads_team','seo_team','content_team','design_team','tech_team')
);
CREATE POLICY "messages_insert" ON public.messages FOR INSERT WITH CHECK (
  channel_id IN (SELECT cc.id FROM public.chat_channels cc WHERE cc.project_id IN (SELECT my_project_ids())) OR
  public.get_my_role() IN ('admin','account_manager','ads_team','seo_team','content_team','design_team','tech_team')
);

-- chat_channels
DO $$ DECLARE pol text; BEGIN
  FOR pol IN SELECT policyname FROM pg_policies WHERE tablename='chat_channels' AND schemaname='public'
  LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.chat_channels', pol); END LOOP;
END $$;
CREATE POLICY "chat_channels_select" ON public.chat_channels FOR SELECT USING (
  project_id IN (SELECT my_project_ids()) OR
  public.get_my_role() IN ('admin','account_manager','ads_team','seo_team','content_team','design_team','tech_team')
);
CREATE POLICY "chat_channels_team_all" ON public.chat_channels FOR ALL USING (
  public.get_my_role() IN ('admin','account_manager','ads_team','seo_team','content_team','design_team','tech_team')
);


-- ── 4. Sync missing profile rows for any existing auth users ──
INSERT INTO public.profiles (id, email, full_name, role, created_at)
SELECT 
  id, 
  email, 
  COALESCE(raw_user_meta_data->>'full_name', raw_user_meta_data->>'name', split_part(email, '@', 1)),
  'client',
  created_at
FROM auth.users
ON CONFLICT (id) DO NOTHING;
