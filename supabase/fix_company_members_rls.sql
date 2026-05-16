-- ============================================================
-- FIX: Infinite Recursion in company_members RLS Policy
-- ============================================================
-- The "Access company_members" policy had a subquery that
-- queried company_members INSIDE a policy ON company_members,
-- causing PostgreSQL to detect infinite recursion (code 42P17).
--
-- Fix: Use the SECURITY DEFINER helper function my_company_ids()
-- which bypasses RLS when called, breaking the recursion loop.
-- ============================================================

-- Drop the recursive policy
DROP POLICY IF EXISTS "Access company_members" ON company_members;

-- Recreate using the SECURITY DEFINER helper (no recursion)
CREATE POLICY "Access company_members" ON company_members
FOR ALL USING (
  company_id IN (SELECT my_company_ids()) OR is_admin()
);

-- Also fix the companies policy to use the helper function
DROP POLICY IF EXISTS "Access companies" ON companies;
CREATE POLICY "Access companies" ON companies
FOR ALL USING (
  id IN (SELECT my_company_ids()) OR is_admin()
);

-- Also fix the projects policy which has the same direct subquery issue
DROP POLICY IF EXISTS "projects_select" ON projects;
CREATE POLICY "projects_select" ON projects FOR SELECT USING (
  is_admin() OR
  client_id = auth.uid() OR
  account_manager_id = auth.uid() OR
  company_id IN (SELECT my_company_ids()) OR
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND team_role IS NOT NULL)
);

-- Also ensure chat_channels policy doesn't have similar recursion issues
DROP POLICY IF EXISTS "Users can view their chat channels" ON chat_channels;
CREATE POLICY "Users can view their chat channels"
ON chat_channels FOR SELECT
USING (
  project_id IN (SELECT my_project_ids()) OR is_admin()
);

-- Ensure messages policy is also non-recursive and supports multi-user
DROP POLICY IF EXISTS "Users can view messages in their channels" ON messages;
CREATE POLICY "Users can view messages in their channels"
ON messages FOR SELECT
USING (
  channel_id IN (
    SELECT id FROM chat_channels 
    WHERE project_id IN (SELECT my_project_ids())
  ) OR is_admin()
);

DROP POLICY IF EXISTS "Users can insert messages into their channels" ON messages;
CREATE POLICY "Users can insert messages into their channels"
ON messages FOR INSERT
WITH CHECK (
  auth.uid() = sender_id AND
  channel_id IN (
    SELECT id FROM chat_channels 
    WHERE project_id IN (SELECT my_project_ids())
  ) OR is_admin()
);

-- Ensure the helper function exists with correct definition
CREATE OR REPLACE FUNCTION my_company_ids()
RETURNS SETOF uuid
LANGUAGE sql SECURITY DEFINER
STABLE
AS $$
  SELECT company_id FROM company_members WHERE user_id = auth.uid();
$$;

-- Also ensure chat_channels policy doesn't have similar recursion issues
-- (chat_channels likely uses my_project_ids() which is fine)
-- Verify my_project_ids() is correct
CREATE OR REPLACE FUNCTION my_project_ids()
RETURNS SETOF uuid
LANGUAGE sql SECURITY DEFINER
STABLE
AS $$
  SELECT id FROM projects
  WHERE client_id = auth.uid()
     OR account_manager_id = auth.uid()
     OR company_id IN (SELECT my_company_ids());
$$;
