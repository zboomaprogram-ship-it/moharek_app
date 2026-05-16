-- ============================================================
-- MOHAREK CLIENT PORTAL — COMPLETE DATABASE SETUP
-- Run this entire script in Supabase SQL Editor (one-shot)
-- ============================================================

-- 1. PROFILES (extends auth.users)
CREATE TABLE IF NOT EXISTS profiles (
  id uuid REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  full_name text,
  company_name text,
  role text DEFAULT 'client' CHECK (role IN ('client','account_manager','seo_team','ads_team','content_team','design_team','tech_team','admin')),
  avatar_url text,
  phone text,
  created_at timestamptz DEFAULT now()
);

-- 2. PROJECTS
CREATE TABLE IF NOT EXISTS projects (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  account_manager_id uuid REFERENCES profiles(id),
  name text NOT NULL,
  status text DEFAULT 'active',
  start_date date DEFAULT CURRENT_DATE,
  current_stage text DEFAULT 'audit',
  created_at timestamptz DEFAULT now()
);

-- 3. JOURNEY STAGES
CREATE TABLE IF NOT EXISTS journey_stages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES projects(id) ON DELETE CASCADE,
  stage_name text,
  status text DEFAULT 'not_started' CHECK (status IN ('not_started','in_progress','completed')),
  order_index int DEFAULT 0,
  is_completed boolean DEFAULT false,
  assigned_to uuid REFERENCES profiles(id),
  deadline date,
  notes text,
  completed_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- 4. TASKS
CREATE TABLE IF NOT EXISTS tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES projects(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  status text DEFAULT 'todo' CHECK (status IN ('todo','in_progress','waiting_client','in_review','completed','delayed')),
  assigned_to uuid REFERENCES profiles(id),
  deadline date,
  priority text DEFAULT 'normal' CHECK (priority IN ('low','normal','high','urgent')),
  category text CHECK (category IN ('seo','ads','content','design','tech','ai_visibility')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 5. RESULTS
CREATE TABLE IF NOT EXISTS results (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES projects(id) ON DELETE CASCADE,
  result_type text CHECK (result_type IN ('seo','ads','ai_visibility','trust_engine')),
  metric_name text,
  metric_value numeric,
  metric_unit text,
  recorded_at date DEFAULT CURRENT_DATE,
  created_at timestamptz DEFAULT now()
);

-- 6. REPORTS
CREATE TABLE IF NOT EXISTS reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES projects(id) ON DELETE CASCADE,
  title text,
  report_type text DEFAULT 'monthly' CHECK (report_type IN ('weekly','monthly','campaign','seo','ads','competitor')),
  summary text,
  status text DEFAULT 'draft' CHECK (status IN ('draft','ready','archived')),
  file_url text,
  period_start date,
  period_end date,
  created_at timestamptz DEFAULT now()
);

-- 7. APPROVALS
CREATE TABLE IF NOT EXISTS approvals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES projects(id) ON DELETE CASCADE,
  title text,
  description text,
  approval_type text CHECK (approval_type IN ('content_calendar','design','ad_copy','landing_page','budget','campaign','monthly_strategy')),
  status text DEFAULT 'pending' CHECK (status IN ('pending','approved','changes_requested')),
  file_url text,
  team_notes text,
  client_notes text,
  created_at timestamptz DEFAULT now(),
  responded_at timestamptz
);

-- 8. CHAT CHANNELS
CREATE TABLE IF NOT EXISTS chat_channels (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES projects(id) ON DELETE CASCADE,
  name text,
  channel_type text DEFAULT 'client_manager'
);

-- 9. MESSAGES
CREATE TABLE IF NOT EXISTS messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_id uuid REFERENCES chat_channels(id) ON DELETE CASCADE,
  sender_id uuid REFERENCES profiles(id),
  content text,
  message_type text DEFAULT 'text' CHECK (message_type IN ('text','image','file','voice')),
  file_url text,
  is_read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- 10. MEETINGS
CREATE TABLE IF NOT EXISTS meetings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES projects(id) ON DELETE CASCADE,
  title text,
  scheduled_at timestamptz,
  duration_minutes int DEFAULT 30,
  meeting_type text DEFAULT 'scheduled' CHECK (meeting_type IN ('scheduled','instant')),
  jitsi_room_id text,
  summary text,
  action_items text[],
  status text DEFAULT 'upcoming' CHECK (status IN ('upcoming','ongoing','completed','cancelled')),
  created_at timestamptz DEFAULT now()
);

-- 11. CONTRACTS
CREATE TABLE IF NOT EXISTS contracts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES projects(id) ON DELETE CASCADE,
  title text,
  file_url text,
  status text DEFAULT 'pending' CHECK (status IN ('pending','signed','expired')),
  signed_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- 12. INVOICES
CREATE TABLE IF NOT EXISTS invoices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES projects(id) ON DELETE CASCADE,
  amount numeric,
  currency text DEFAULT 'AED',
  status text DEFAULT 'pending' CHECK (status IN ('pending','paid','overdue','cancelled')),
  due_date date,
  payment_link text,
  stripe_payment_intent_id text,
  paid_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- 13. ACTIVITY FEED
CREATE TABLE IF NOT EXISTS activity_feed (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES projects(id) ON DELETE CASCADE,
  actor_id uuid REFERENCES profiles(id),
  action text,
  entity_type text,
  entity_id uuid,
  created_at timestamptz DEFAULT now()
);

-- 14. FILES
CREATE TABLE IF NOT EXISTS files (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES projects(id) ON DELETE CASCADE,
  name text,
  file_url text,
  file_type text CHECK (file_type IN ('brand_guidelines','logo','report','content_plan','campaign_asset','contract','proposal','strategy')),
  uploaded_by uuid REFERENCES profiles(id),
  size_bytes bigint,
  created_at timestamptz DEFAULT now()
);

-- ============================================================
-- ROW-LEVEL SECURITY POLICIES
-- ============================================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE journey_stages ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE results ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE approvals ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_channels ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE meetings ENABLE ROW LEVEL SECURITY;
ALTER TABLE contracts ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_feed ENABLE ROW LEVEL SECURITY;
ALTER TABLE files ENABLE ROW LEVEL SECURITY;

-- Helper function: check if current user is admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean AS $$
  SELECT EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
    AND role IN ('admin','account_manager')
  );
$$ LANGUAGE sql SECURITY DEFINER;

-- Helper function: get current user's project IDs
CREATE OR REPLACE FUNCTION my_project_ids()
RETURNS SETOF uuid AS $$
  SELECT id FROM projects WHERE client_id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER;

-- ── PROFILES ──
DROP POLICY IF EXISTS "Users read own profile" ON profiles;
CREATE POLICY "Users read own profile" ON profiles FOR SELECT
  USING (id = auth.uid() OR is_admin());

DROP POLICY IF EXISTS "Users update own profile" ON profiles;
CREATE POLICY "Users update own profile" ON profiles FOR UPDATE
  USING (id = auth.uid());

DROP POLICY IF EXISTS "Admins manage profiles" ON profiles;
CREATE POLICY "Admins manage profiles" ON profiles FOR ALL
  USING (is_admin());

-- ── PROJECTS ──
DROP POLICY IF EXISTS "Clients see own projects" ON projects;
CREATE POLICY "Clients see own projects" ON projects FOR SELECT
  USING (client_id = auth.uid() OR is_admin());

DROP POLICY IF EXISTS "Admins manage projects" ON projects;
CREATE POLICY "Admins manage projects" ON projects FOR ALL
  USING (is_admin());

-- ── JOURNEY STAGES ──
DROP POLICY IF EXISTS "Journey access" ON journey_stages;
CREATE POLICY "Journey access" ON journey_stages FOR SELECT
  USING (project_id IN (SELECT my_project_ids()) OR is_admin());

DROP POLICY IF EXISTS "Admins manage journey" ON journey_stages;
CREATE POLICY "Admins manage journey" ON journey_stages FOR ALL
  USING (is_admin());

-- ── TASKS ──
DROP POLICY IF EXISTS "Tasks access" ON tasks;
CREATE POLICY "Tasks access" ON tasks FOR SELECT
  USING (project_id IN (SELECT my_project_ids()) OR is_admin());

DROP POLICY IF EXISTS "Admins manage tasks" ON tasks;
CREATE POLICY "Admins manage tasks" ON tasks FOR ALL
  USING (is_admin());

-- ── RESULTS ──
DROP POLICY IF EXISTS "Results access" ON results;
CREATE POLICY "Results access" ON results FOR SELECT
  USING (project_id IN (SELECT my_project_ids()) OR is_admin());

DROP POLICY IF EXISTS "Admins manage results" ON results;
CREATE POLICY "Admins manage results" ON results FOR ALL
  USING (is_admin());

-- ── REPORTS ──
DROP POLICY IF EXISTS "Reports access" ON reports;
CREATE POLICY "Reports access" ON reports FOR SELECT
  USING (project_id IN (SELECT my_project_ids()) OR is_admin());

DROP POLICY IF EXISTS "Admins manage reports" ON reports;
CREATE POLICY "Admins manage reports" ON reports FOR ALL
  USING (is_admin());

-- ── APPROVALS ──
DROP POLICY IF EXISTS "Approvals read" ON approvals;
CREATE POLICY "Approvals read" ON approvals FOR SELECT
  USING (project_id IN (SELECT my_project_ids()) OR is_admin());

DROP POLICY IF EXISTS "Clients update approvals" ON approvals;
CREATE POLICY "Clients update approvals" ON approvals FOR UPDATE
  USING (project_id IN (SELECT my_project_ids()));

DROP POLICY IF EXISTS "Admins manage approvals" ON approvals;
CREATE POLICY "Admins manage approvals" ON approvals FOR ALL
  USING (is_admin());

-- ── CHAT CHANNELS ──
DROP POLICY IF EXISTS "Chat channels access" ON chat_channels;
CREATE POLICY "Chat channels access" ON chat_channels FOR SELECT
  USING (project_id IN (SELECT my_project_ids()) OR is_admin());

DROP POLICY IF EXISTS "Admins manage channels" ON chat_channels;
CREATE POLICY "Admins manage channels" ON chat_channels FOR ALL
  USING (is_admin());

-- ── MESSAGES ──
DROP POLICY IF EXISTS "Messages read" ON messages;
CREATE POLICY "Messages read" ON messages FOR SELECT
  USING (
    channel_id IN (
      SELECT id FROM chat_channels
      WHERE project_id IN (SELECT my_project_ids())
    ) OR is_admin()
  );

DROP POLICY IF EXISTS "Messages insert" ON messages;
CREATE POLICY "Messages insert" ON messages FOR INSERT
  WITH CHECK (
    sender_id = auth.uid() AND (
      channel_id IN (
        SELECT id FROM chat_channels
        WHERE project_id IN (SELECT my_project_ids())
      ) OR is_admin()
    )
  );

DROP POLICY IF EXISTS "Admins manage messages" ON messages;
CREATE POLICY "Admins manage messages" ON messages FOR ALL
  USING (is_admin());

-- ── MEETINGS ──
DROP POLICY IF EXISTS "Meetings access" ON meetings;
CREATE POLICY "Meetings access" ON meetings FOR SELECT
  USING (project_id IN (SELECT my_project_ids()) OR is_admin());

DROP POLICY IF EXISTS "Admins manage meetings" ON meetings;
CREATE POLICY "Admins manage meetings" ON meetings FOR ALL
  USING (is_admin());

-- ── CONTRACTS ──
DROP POLICY IF EXISTS "Contracts access" ON contracts;
CREATE POLICY "Contracts access" ON contracts FOR SELECT
  USING (project_id IN (SELECT my_project_ids()) OR is_admin());

DROP POLICY IF EXISTS "Clients update contracts" ON contracts;
CREATE POLICY "Clients update contracts" ON contracts FOR UPDATE
  USING (project_id IN (SELECT my_project_ids()));

DROP POLICY IF EXISTS "Admins manage contracts" ON contracts;
CREATE POLICY "Admins manage contracts" ON contracts FOR ALL
  USING (is_admin());

-- ── INVOICES ──
DROP POLICY IF EXISTS "Invoices access" ON invoices;
CREATE POLICY "Invoices access" ON invoices FOR SELECT
  USING (project_id IN (SELECT my_project_ids()) OR is_admin());

DROP POLICY IF EXISTS "Admins manage invoices" ON invoices;
CREATE POLICY "Admins manage invoices" ON invoices FOR ALL
  USING (is_admin());

-- ── ACTIVITY FEED ──
DROP POLICY IF EXISTS "Activity access" ON activity_feed;
CREATE POLICY "Activity access" ON activity_feed FOR SELECT
  USING (project_id IN (SELECT my_project_ids()) OR is_admin());

DROP POLICY IF EXISTS "Admins manage activity" ON activity_feed;
CREATE POLICY "Admins manage activity" ON activity_feed FOR ALL
  USING (is_admin());

-- ── FILES ──
DROP POLICY IF EXISTS "Files access" ON files;
CREATE POLICY "Files access" ON files FOR SELECT
  USING (project_id IN (SELECT my_project_ids()) OR is_admin());

DROP POLICY IF EXISTS "Admins manage files" ON files;
CREATE POLICY "Admins manage files" ON files FOR ALL
  USING (is_admin());

-- ============================================================
-- AUTO-SETUP TRIGGERS
-- When a new project is created, automatically:
-- 1. Create a chat channel
-- 2. Create journey stages
-- 3. Add a welcome activity item
-- ============================================================

CREATE OR REPLACE FUNCTION on_project_created()
RETURNS TRIGGER AS $$
BEGIN
  -- Create chat channel
  INSERT INTO chat_channels (project_id, name, channel_type)
  VALUES (NEW.id, NEW.name || ' Chat', 'client_manager');

  -- Create journey stages
  INSERT INTO journey_stages (project_id, stage_name, order_index, status)
  VALUES
    (NEW.id, 'audit',        0, 'in_progress'),
    (NEW.id, 'strategy',     1, 'not_started'),
    (NEW.id, 'setup',        2, 'not_started'),
    (NEW.id, 'execution',    3, 'not_started'),
    (NEW.id, 'optimization', 4, 'not_started'),
    (NEW.id, 'results',      5, 'not_started');

  -- Welcome activity
  INSERT INTO activity_feed (project_id, actor_id, action, entity_type, entity_id)
  VALUES (NEW.id, NEW.client_id, 'Welcome to Moharek', 'project', NEW.id);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_project_created ON projects;
CREATE TRIGGER trigger_project_created
  AFTER INSERT ON projects
  FOR EACH ROW
  EXECUTE FUNCTION on_project_created();

-- ============================================================
-- STORAGE BUCKETS (run separately if needed)
-- ============================================================
-- Go to Supabase Dashboard > Storage and create these buckets:
-- 1. "reports" (public)
-- 2. "files" (public)
-- 3. "avatars" (public)
-- 4. "contracts" (public)

-- ============================================================
-- DONE! Your database is ready.
-- ============================================================
