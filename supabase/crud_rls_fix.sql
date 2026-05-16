-- ============================================================
-- MASTER CRUD & ADMIN PERMISSIONS FIX
-- Run this in your Supabase SQL Editor to fix broken dashboard actions
-- ============================================================

-- 1. UNIFIED ADMIN CHECK (Improved)
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean 
LANGUAGE sql SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
    AND (role IN ('admin', 'account_manager') OR team_role IS NOT NULL)
  );
$$;

-- 2. FIX ADMIN LOGS (Allow AMs to log their actions)
ALTER TABLE admin_logs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "admin_logs_admin_only" ON admin_logs;
CREATE POLICY "admin_logs_write_access" ON admin_logs 
FOR INSERT WITH CHECK (is_admin());

CREATE POLICY "admin_logs_read_access" ON admin_logs 
FOR SELECT USING (is_admin());

-- 3. FIX PROFILES (Allow admins to manage all profiles)
DROP POLICY IF EXISTS "Admins manage profiles" ON profiles;
CREATE POLICY "Admins manage profiles" ON profiles 
FOR ALL USING (is_admin()) WITH CHECK (is_admin());

-- 4. FIX PROJECTS (Explicit Update for AMs/Admins)
DROP POLICY IF EXISTS "am_updates_own_projects" ON projects;
CREATE POLICY "am_updates_own_projects" ON projects 
FOR UPDATE USING (is_admin()) WITH CHECK (is_admin());

-- 5. FIX TASKS (Team management)
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admins manage tasks" ON tasks;
CREATE POLICY "Admins manage tasks" ON tasks 
FOR ALL USING (is_admin()) WITH CHECK (is_admin());

-- 6. FIX APPROVALS (Team management)
ALTER TABLE approvals ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admins manage approvals" ON approvals;
CREATE POLICY "Admins manage approvals" ON approvals 
FOR ALL USING (is_admin()) WITH CHECK (is_admin());

-- 7. FIX REPORTS (Team management)
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admins manage reports" ON reports;
CREATE POLICY "Admins manage reports" ON reports 
FOR ALL USING (is_admin()) WITH CHECK (is_admin());

-- 8. FIX NOTIFICATIONS (Allow system triggers and admins to insert)
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admins manage notifications" ON notifications;
CREATE POLICY "Admins manage notifications" ON notifications 
FOR ALL USING (is_admin()) WITH CHECK (is_admin());

-- System insert for triggers (Internal)
CREATE POLICY "System insert notifications" ON notifications 
FOR INSERT WITH CHECK (true); 

-- 9. FIX INVITATIONS
DROP POLICY IF EXISTS "invitations_admin_only" ON invitations;
CREATE POLICY "invitations_admin_only" ON invitations 
FOR ALL USING (is_admin()) WITH CHECK (is_admin());

-- 10. REFRESH SCHEMA CACHE POKE
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS _schema_refresh boolean;
ALTER TABLE profiles DROP COLUMN IF EXISTS _schema_refresh;
