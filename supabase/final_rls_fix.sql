-- ============================================================
-- ULTIMATE NON-RECURSIVE RLS FIX FOR MOHAREK
-- Run this in your Supabase SQL Editor to fix the "Error loading chat"
-- ============================================================

-- 0. FIX SCHEMA: Add missing created_at column to chat_channels
ALTER TABLE chat_channels ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();

-- 1. FIX THE ADMIN HELPER (Avoids profile recursion)
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean 
LANGUAGE sql SECURITY DEFINER
STABLE
AS $$
  -- Query profiles directly bypassing RLS
  SELECT EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
    AND role IN ('admin', 'account_manager')
  );
$$;

-- 2. FIX PROJECT ACCESS HELPER
CREATE OR REPLACE FUNCTION my_project_ids()
RETURNS SETOF uuid
LANGUAGE sql SECURITY DEFINER
STABLE
AS $$
  -- Extremely direct query on projects
  SELECT id FROM projects
  WHERE client_id = auth.uid()
     OR account_manager_id = auth.uid();
$$;

-- 3. FIX COMPANY ACCESS HELPER
CREATE OR REPLACE FUNCTION my_company_ids()
RETURNS SETOF uuid
LANGUAGE sql SECURITY DEFINER
STABLE
AS $$
  SELECT company_id FROM company_members WHERE user_id = auth.uid();
$$;

-- 4. APPLY CLEAN POLICIES TO PROFILES
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users read own profile" ON profiles;
CREATE POLICY "Users read own profile" ON profiles FOR SELECT
  USING (id = auth.uid() OR is_admin());

DROP POLICY IF EXISTS "Users update own profile" ON profiles;
CREATE POLICY "Users update own profile" ON profiles FOR UPDATE
  USING (id = auth.uid());

DROP POLICY IF EXISTS "Admins manage profiles" ON profiles;
CREATE POLICY "Admins manage profiles" ON profiles FOR ALL
  USING (is_admin());

-- 5. APPLY CLEAN POLICIES TO PROJECTS
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "projects_select" ON projects;
DROP POLICY IF EXISTS "Clients see own projects" ON projects;
CREATE POLICY "projects_select" ON projects FOR SELECT
  USING (client_id = auth.uid() OR is_admin());

-- 6. APPLY CLEAN POLICIES TO CHAT
ALTER TABLE chat_channels ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Chat channels access" ON chat_channels;
DROP POLICY IF EXISTS "Users can view their chat channels" ON chat_channels;
DROP POLICY IF EXISTS "chat_channels_select" ON chat_channels;
CREATE POLICY "chat_channels_select" ON chat_channels FOR SELECT
  USING (
    project_id IN (SELECT my_project_ids()) OR is_admin()
  );

ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Messages read" ON messages;
DROP POLICY IF EXISTS "Users can view messages in their channels" ON messages;
DROP POLICY IF EXISTS "messages_select" ON messages;
CREATE POLICY "messages_select" ON messages FOR SELECT
  USING (
    channel_id IN (SELECT id FROM chat_channels) -- Access is inherited from chat_channels policy
    OR is_admin()
  );

DROP POLICY IF EXISTS "Messages insert" ON messages;
DROP POLICY IF EXISTS "Users can insert messages into their channels" ON messages;
DROP POLICY IF EXISTS "messages_insert" ON messages;
CREATE POLICY "messages_insert" ON messages FOR INSERT
  WITH CHECK (
    sender_id = auth.uid() AND (
      channel_id IN (SELECT id FROM chat_channels)
      OR is_admin()
    )
  );

-- 7. ENSURE STORAGE POLICIES ARE SAFE
-- (Objects policies often cause recursion if they query tables with recursive policies)
DROP POLICY IF EXISTS "Project members can read voice messages" ON storage.objects;
CREATE POLICY "Project members can read voice messages"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'voice-messages' AND
  (storage.foldername(name))[1] IN (SELECT id::text FROM projects) -- Simplified check
);

