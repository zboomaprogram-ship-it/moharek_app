-- ============================================================
-- PHASE 4: DUAL WEB DASHBOARDS (ADMIN + AM)
-- Run this in your Supabase SQL Editor
-- ============================================================

-- 1. AM PERFORMANCE TRACKING
CREATE TABLE IF NOT EXISTS am_performance (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  am_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  period_month date,  -- first day of the month: 2026-05-01
  total_clients int DEFAULT 0,
  active_clients int DEFAULT 0,
  avg_client_health_score numeric DEFAULT 0,
  tasks_created int DEFAULT 0,
  tasks_completed int DEFAULT 0,
  reports_uploaded int DEFAULT 0,
  approvals_created int DEFAULT 0,
  avg_response_time_hours numeric DEFAULT 0,
  client_satisfaction_avg numeric DEFAULT 0,
  updated_at timestamptz DEFAULT now(),
  UNIQUE(am_id, period_month)
);

-- 2. INVITATION SYSTEM
CREATE TABLE IF NOT EXISTS invitations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text NOT NULL,
  invited_role text CHECK (invited_role IN ('account_manager','client')),
  invited_by uuid REFERENCES profiles(id),
  project_id uuid REFERENCES projects(id),     
  assigned_am_id uuid REFERENCES profiles(id), 
  status text DEFAULT 'pending' CHECK (status IN ('pending','accepted','expired')),
  token text UNIQUE DEFAULT gen_random_uuid()::text,
  expires_at timestamptz DEFAULT now() + INTERVAL '7 days',
  accepted_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- 3. ADMIN AUDIT LOG
CREATE TABLE IF NOT EXISTS admin_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id uuid REFERENCES profiles(id),
  action text,  -- 'created_am', 'assigned_client', 'deleted_report', etc.
  target_type text,
  target_id uuid,
  metadata jsonb,
  created_at timestamptz DEFAULT now()
);

-- 4. NEW COLUMNS ON EXISTING TABLES
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES profiles(id);
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_active boolean DEFAULT true;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS notes text;
-- Add team_role if it doesn't exist (Phase 4 uses team_role for dashboard switching)
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS team_role text CHECK (team_role IN ('admin', 'account_manager', 'seo_team', 'ads_team', 'content_team', 'design_team', 'tech_team'));

ALTER TABLE projects ADD COLUMN IF NOT EXISTS previous_am_ids uuid[] DEFAULT '{}';
ALTER TABLE projects ADD COLUMN IF NOT EXISTS am_assigned_at timestamptz;

-- 5. RLS UPDATES
ALTER TABLE am_performance ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE invitations ENABLE ROW LEVEL SECURITY;

-- AM/Admin can see performance
DROP POLICY IF EXISTS "am_performance_select" ON am_performance;
CREATE POLICY "am_performance_select" ON am_performance FOR SELECT USING (
  am_id = auth.uid() OR
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Admin logs: admin only
DROP POLICY IF EXISTS "admin_logs_admin_only" ON admin_logs;
CREATE POLICY "admin_logs_admin_only" ON admin_logs FOR ALL USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Invitations: admin only
DROP POLICY IF EXISTS "invitations_admin_only" ON invitations;
CREATE POLICY "invitations_admin_only" ON invitations FOR ALL USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- AM can see/update their assigned projects
DROP POLICY IF EXISTS "am_sees_own_projects" ON projects;
CREATE POLICY "am_sees_own_projects" ON projects FOR SELECT USING (
  account_manager_id = auth.uid() OR
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

DROP POLICY IF EXISTS "am_updates_own_projects" ON projects;
CREATE POLICY "am_updates_own_projects" ON projects FOR UPDATE USING (
  account_manager_id = auth.uid() OR
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

-- 6. AM PERFORMANCE CRON JOB (requires pg_cron)
-- Run this if pg_cron is enabled in your Supabase project
/*
SELECT cron.schedule('update-am-performance', '0 1 * * *', $$
  INSERT INTO am_performance (am_id, period_month, total_clients, active_clients, avg_client_health_score, tasks_created, tasks_completed, reports_uploaded, approvals_created)
  SELECT
    p.account_manager_id,
    date_trunc('month', current_date)::date,
    count(*),
    count(*) filter (where p.status = 'active'),
    coalesce(avg(p.health_score), 0),
    (SELECT count(*) FROM tasks t WHERE t.project_id = any(array_agg(p.id)) AND date_trunc('month', t.created_at) = date_trunc('month', current_date)),
    (SELECT count(*) FROM tasks t WHERE t.project_id = any(array_agg(p.id)) AND t.status = 'completed' AND date_trunc('month', t.updated_at) = date_trunc('month', current_date)),
    (SELECT count(*) FROM reports r WHERE r.project_id = any(array_agg(p.id)) AND date_trunc('month', r.created_at) = date_trunc('month', current_date)),
    (SELECT count(*) FROM approvals a WHERE a.project_id = any(array_agg(p.id)) AND date_trunc('month', a.created_at) = date_trunc('month', current_date))
  FROM projects p
  WHERE p.account_manager_id IS NOT NULL
  GROUP BY p.account_manager_id
  ON CONFLICT (am_id, period_month) DO UPDATE SET
    total_clients = excluded.total_clients,
    active_clients = excluded.active_clients,
    avg_client_health_score = excluded.avg_client_health_score,
    tasks_created = excluded.tasks_created,
    tasks_completed = excluded.tasks_completed,
    reports_uploaded = excluded.reports_uploaded,
    approvals_created = excluded.approvals_created,
    updated_at = now();
$$);
*/
