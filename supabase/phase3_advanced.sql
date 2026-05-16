-- ============================================================
-- MOHAREK GROWTH HUB — PHASE 3+ ADVANCED MIGRATION
-- Multi-User Client Companies
-- ============================================================

-- 1. Create Companies Table
CREATE TABLE IF NOT EXISTS companies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  industry text,
  created_at timestamptz DEFAULT now()
);

-- 2. Create Company Members Table
CREATE TABLE IF NOT EXISTS company_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE,
  user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  role text CHECK (role IN ('owner','manager','marketing','finance','viewer')) DEFAULT 'viewer',
  created_at timestamptz DEFAULT now(),
  UNIQUE(company_id, user_id)
);

-- 3. Update Projects Table
ALTER TABLE projects ADD COLUMN IF NOT EXISTS company_id uuid REFERENCES companies(id);

-- 4. Data Migration: Create companies for existing projects
DO $$
DECLARE
  p RECORD;
  c_id uuid;
BEGIN
  FOR p IN SELECT * FROM projects WHERE client_id IS NOT NULL AND company_id IS NULL LOOP
    -- Create a company for this project
    INSERT INTO companies (name) VALUES ('Company of ' || p.client_id) RETURNING id INTO c_id;
    
    -- Add the client as owner
    INSERT INTO company_members (company_id, user_id, role) VALUES (c_id, p.client_id, 'owner') ON CONFLICT DO NOTHING;
    
    -- Update the project
    UPDATE projects SET company_id = c_id WHERE id = p.id;
  END LOOP;
END $$;

-- 5. Helper Functions for RLS
CREATE OR REPLACE FUNCTION my_company_ids()
RETURNS SETOF uuid
LANGUAGE sql SECURITY DEFINER
AS $$
  SELECT company_id FROM company_members WHERE user_id = auth.uid();
$$;

-- Modify my_project_ids() to include projects owned by any of the user's companies
CREATE OR REPLACE FUNCTION my_project_ids()
RETURNS SETOF uuid
LANGUAGE sql SECURITY DEFINER
AS $$
  SELECT id FROM projects 
  WHERE client_id = auth.uid() 
     OR account_manager_id = auth.uid()
     OR company_id IN (SELECT company_id FROM company_members WHERE user_id = auth.uid());
$$;

-- Enable RLS on new tables
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE company_members ENABLE ROW LEVEL SECURITY;

-- Companies Policy
CREATE POLICY "Access companies" ON companies FOR ALL USING (
  id IN (SELECT company_id FROM company_members WHERE user_id = auth.uid()) OR is_admin()
);

-- Company Members Policy
CREATE POLICY "Access company_members" ON company_members FOR ALL USING (
  company_id IN (SELECT company_id FROM company_members WHERE user_id = auth.uid()) OR is_admin()
);

-- 6. Update Projects Policy
DROP POLICY IF EXISTS "projects_select" ON projects;
CREATE POLICY "projects_select" ON projects FOR SELECT USING (
  is_admin() OR
  client_id = auth.uid() OR
  account_manager_id = auth.uid() OR
  company_id IN (SELECT company_id FROM company_members WHERE user_id = auth.uid()) OR
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND team_role IS NOT NULL)
);

-- Note: Because `my_project_ids()` is used in almost ALL other policies (tasks, results, reports, etc.) 
-- updating `my_project_ids()` effectively updates RLS for the entire system without rewriting every policy!

-- 7. Trigger to auto-create companies for new projects
CREATE OR REPLACE FUNCTION auto_create_company_for_project()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  c_id uuid;
BEGIN
  IF NEW.client_id IS NOT NULL AND NEW.company_id IS NULL THEN
    INSERT INTO companies (name) VALUES ('Company of ' || NEW.client_id) RETURNING id INTO c_id;
    INSERT INTO company_members (company_id, user_id, role) VALUES (c_id, NEW.client_id, 'owner') ON CONFLICT DO NOTHING;
    NEW.company_id := c_id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_auto_create_company ON projects;
CREATE TRIGGER trigger_auto_create_company
BEFORE INSERT ON projects
FOR EACH ROW
EXECUTE FUNCTION auto_create_company_for_project();
