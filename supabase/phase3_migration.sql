-- ============================================================
-- MOHAREK GROWTH HUB — PHASE 3 DATABASE MIGRATION
-- Run this script in the Supabase SQL Editor.
-- This script safely adds new columns and tables without 
-- dropping existing data.
-- ============================================================

-- ------------------------------------------------------------
-- 1. MODIFYING EXISTING TABLES
-- ------------------------------------------------------------

-- PROFILES
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS team_role text CHECK (team_role IN ('admin','account_manager','seo_team','content_team','ads_team','tech_team','design_team'));
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_client boolean DEFAULT false;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS preferred_locale text DEFAULT 'ar';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS notification_preferences jsonb DEFAULT '{"results": true, "tasks": true, "reports": true, "invoices": true, "milestones": true, "calls": true, "approvals": true, "ai_updates": true}';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS last_seen_at timestamptz;

-- PROJECTS
ALTER TABLE projects ADD COLUMN IF NOT EXISTS project_goal text;
ALTER TABLE projects ADD COLUMN IF NOT EXISTS target_market text;
ALTER TABLE projects ADD COLUMN IF NOT EXISTS target_audience text;
ALTER TABLE projects ADD COLUMN IF NOT EXISTS main_services text[];
ALTER TABLE projects ADD COLUMN IF NOT EXISTS competitors text[];
ALTER TABLE projects ADD COLUMN IF NOT EXISTS priorities text[];
ALTER TABLE projects ADD COLUMN IF NOT EXISTS channels text[];
ALTER TABLE projects ADD COLUMN IF NOT EXISTS health_score numeric DEFAULT 0;
ALTER TABLE projects ADD COLUMN IF NOT EXISTS health_label text DEFAULT 'steady';

-- JOURNEY STAGES
ALTER TABLE journey_stages ADD COLUMN IF NOT EXISTS stage_description text;

-- TASKS
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS progress_percent int DEFAULT 0 CHECK (progress_percent BETWEEN 0 AND 100);
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS notes text;
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS is_client_request boolean DEFAULT false;
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS request_type text;
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS client_proposed_deadline date;
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS source_message_id uuid;
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES profiles(id);

-- RESULTS
ALTER TABLE results ADD COLUMN IF NOT EXISTS metric_label text;
ALTER TABLE results ADD COLUMN IF NOT EXISTS change_from_last numeric;

-- REPORTS
ALTER TABLE reports ADD COLUMN IF NOT EXISTS title_ar text;
ALTER TABLE reports ADD COLUMN IF NOT EXISTS highlight_stat text;
ALTER TABLE reports ADD COLUMN IF NOT EXISTS highlight_context text;
ALTER TABLE reports ADD COLUMN IF NOT EXISTS manager_note text;
ALTER TABLE reports ADD COLUMN IF NOT EXISTS next_month_priorities text[];
ALTER TABLE reports ADD COLUMN IF NOT EXISTS ai_summary text;
ALTER TABLE reports ADD COLUMN IF NOT EXISTS ai_summary_generated_at timestamptz;

-- APPROVALS
ALTER TABLE approvals ADD COLUMN IF NOT EXISTS preview_url text;

-- CHAT CHANNELS
ALTER TABLE chat_channels ADD COLUMN IF NOT EXISTS name_ar text;
ALTER TABLE chat_channels ADD COLUMN IF NOT EXISTS is_active boolean DEFAULT true;

-- MESSAGES
ALTER TABLE messages ADD COLUMN IF NOT EXISTS linked_task_id uuid REFERENCES tasks(id);
ALTER TABLE messages ADD COLUMN IF NOT EXISTS converted_to_task boolean DEFAULT false;

-- MEETINGS
ALTER TABLE meetings ADD COLUMN IF NOT EXISTS title_ar text;
ALTER TABLE meetings ADD COLUMN IF NOT EXISTS livekit_room_name text;
ALTER TABLE meetings ADD COLUMN IF NOT EXISTS external_link text;
ALTER TABLE meetings ADD COLUMN IF NOT EXISTS agenda text[];
ALTER TABLE meetings ADD COLUMN IF NOT EXISTS decisions text[];
ALTER TABLE meetings ADD COLUMN IF NOT EXISTS initiated_by uuid REFERENCES profiles(id);

-- FILES
ALTER TABLE files ADD COLUMN IF NOT EXISTS mime_type text;
ALTER TABLE files ADD COLUMN IF NOT EXISTS version int DEFAULT 1;

-- INVOICES
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS invoice_number text;
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS description text;
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS paymob_order_id text;
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS receipt_url text;

-- ------------------------------------------------------------
-- 2. CREATING NEW TABLES
-- ------------------------------------------------------------

-- ENGINE PROGRESS
CREATE TABLE IF NOT EXISTS engine_progress (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES projects(id) ON DELETE CASCADE,
  engine text CHECK (engine IN ('content','ai_visibility','seo','trust','conversion')),
  progress_percent int CHECK (progress_percent BETWEEN 0 AND 100) DEFAULT 0,
  status_notes text,
  updated_by uuid REFERENCES profiles(id),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(project_id, engine)
);

-- ONBOARDING DATA
CREATE TABLE IF NOT EXISTS onboarding_data (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES projects(id) ON DELETE CASCADE,
  website_url text,
  website_access_notes text,
  google_business_url text,
  social_links jsonb,
  brand_notes text,
  target_services text[],
  submitted_at timestamptz DEFAULT now()
);

-- TASK ATTACHMENTS
CREATE TABLE IF NOT EXISTS task_attachments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id uuid REFERENCES tasks(id) ON DELETE CASCADE,
  file_url text,
  file_name text,
  uploaded_by uuid REFERENCES profiles(id),
  created_at timestamptz DEFAULT now()
);

-- TASK COMMENTS
CREATE TABLE IF NOT EXISTS task_comments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id uuid REFERENCES tasks(id) ON DELETE CASCADE,
  author_id uuid REFERENCES profiles(id),
  content text,
  created_at timestamptz DEFAULT now()
);

-- KEYWORDS
CREATE TABLE IF NOT EXISTS keywords (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES projects(id) ON DELETE CASCADE,
  keyword text NOT NULL,
  current_position int,
  previous_position int,
  search_volume int,
  target_position int DEFAULT 10,
  url text,
  recorded_at date,
  created_at timestamptz DEFAULT now()
);

-- AI VISIBILITY
CREATE TABLE IF NOT EXISTS ai_visibility (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES projects(id) ON DELETE CASCADE,
  platform text CHECK (platform IN ('chatgpt','gemini','perplexity','copilot')),
  appears boolean DEFAULT false,
  visibility_score int DEFAULT 0,
  sample_questions text[],
  competitor_brands text[],
  notes text,
  recorded_at date,
  created_at timestamptz DEFAULT now()
);

-- CAMPAIGNS
CREATE TABLE IF NOT EXISTS campaigns (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES projects(id) ON DELETE CASCADE,
  name text NOT NULL,
  name_ar text,
  goal text,
  goal_ar text,
  channel text CHECK (channel IN ('seo','content','google_ads','ai_visibility','google_business','social')),
  budget numeric,
  currency text DEFAULT 'AED',
  status text DEFAULT 'planned' CHECK (status IN ('planned','active','paused','completed')),
  start_date date,
  end_date date,
  created_at timestamptz DEFAULT now()
);

-- CAMPAIGN RESULTS
CREATE TABLE IF NOT EXISTS campaign_results (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id uuid REFERENCES campaigns(id) ON DELETE CASCADE,
  metric_label text,
  metric_value numeric,
  metric_unit text,
  recorded_at date,
  created_at timestamptz DEFAULT now()
);

-- VOICE UPDATES
CREATE TABLE IF NOT EXISTS voice_updates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES projects(id) ON DELETE CASCADE,
  recorded_by uuid REFERENCES profiles(id),
  audio_url text,
  duration_seconds int,
  transcript text,
  is_heard boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- SUBSCRIPTION PLANS
CREATE TABLE IF NOT EXISTS subscription_plans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES projects(id) ON DELETE CASCADE,
  plan_name text,
  plan_name_ar text,
  services text[],
  monthly_amount numeric,
  currency text DEFAULT 'AED',
  renewal_date date,
  status text DEFAULT 'active' CHECK (status IN ('active','paused','cancelled')),
  created_at timestamptz DEFAULT now()
);

-- SUPPORT TICKETS
CREATE TABLE IF NOT EXISTS support_tickets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES projects(id) ON DELETE CASCADE,
  submitted_by uuid REFERENCES profiles(id),
  title text,
  description text,
  ticket_type text CHECK (ticket_type IN ('bug','question','feature_request','urgent_call','training','other')),
  priority text DEFAULT 'normal' CHECK (priority IN ('normal','important','urgent')),
  status text DEFAULT 'open' CHECK (status IN ('open','in_progress','waiting_client','resolved','closed')),
  assigned_to uuid REFERENCES profiles(id),
  resolved_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- TICKET REPLIES
CREATE TABLE IF NOT EXISTS ticket_replies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id uuid REFERENCES support_tickets(id) ON DELETE CASCADE,
  author_id uuid REFERENCES profiles(id),
  content text,
  created_at timestamptz DEFAULT now()
);

-- MILESTONES
CREATE TABLE IF NOT EXISTS milestones (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES projects(id) ON DELETE CASCADE,
  milestone_type text CHECK (milestone_type IN ('page1_keyword','traffic_doubled','leads_100','first_invoice_paid','stage_completed','90_days','partner_6_months','ai_visibility_first')),
  title_ar text,
  title_en text,
  description_ar text,
  description_en text,
  achieved_at timestamptz DEFAULT now(),
  seen_by_client boolean DEFAULT false
);

-- SATISFACTION SURVEYS
CREATE TABLE IF NOT EXISTS satisfaction_surveys (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES projects(id) ON DELETE CASCADE,
  trigger_event text,
  score int CHECK (score BETWEEN 1 AND 5),
  comment text,
  created_at timestamptz DEFAULT now()
);

-- AI QUERY USAGE
CREATE TABLE IF NOT EXISTS ai_query_usage (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES projects(id) ON DELETE CASCADE,
  query_text text,
  response_text text,
  tokens_used int,
  created_at timestamptz DEFAULT now()
);

-- FCM TOKENS
CREATE TABLE IF NOT EXISTS fcm_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  token text UNIQUE NOT NULL,
  platform text CHECK (platform IN ('ios','android')),
  created_at timestamptz DEFAULT now()
);


-- ------------------------------------------------------------
-- 3. APPLY ROW-LEVEL SECURITY TO NEW TABLES
-- ------------------------------------------------------------

-- Enable RLS
ALTER TABLE engine_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE onboarding_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE keywords ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_visibility ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaign_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE voice_updates ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE ticket_replies ENABLE ROW LEVEL SECURITY;
ALTER TABLE milestones ENABLE ROW LEVEL SECURITY;
ALTER TABLE satisfaction_surveys ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_query_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE fcm_tokens ENABLE ROW LEVEL SECURITY;

-- Apply standard generic access policy
-- Clients can see their own project's data. Admins see all.

CREATE POLICY "Access engine_progress" ON engine_progress FOR ALL USING (project_id IN (SELECT my_project_ids()) OR is_admin());
CREATE POLICY "Access onboarding_data" ON onboarding_data FOR ALL USING (project_id IN (SELECT my_project_ids()) OR is_admin());
CREATE POLICY "Access task_attachments" ON task_attachments FOR ALL USING (task_id IN (SELECT id FROM tasks WHERE project_id IN (SELECT my_project_ids())) OR is_admin());
CREATE POLICY "Access task_comments" ON task_comments FOR ALL USING (task_id IN (SELECT id FROM tasks WHERE project_id IN (SELECT my_project_ids())) OR is_admin());
CREATE POLICY "Access keywords" ON keywords FOR ALL USING (project_id IN (SELECT my_project_ids()) OR is_admin());
CREATE POLICY "Access ai_visibility" ON ai_visibility FOR ALL USING (project_id IN (SELECT my_project_ids()) OR is_admin());
CREATE POLICY "Access campaigns" ON campaigns FOR ALL USING (project_id IN (SELECT my_project_ids()) OR is_admin());
CREATE POLICY "Access campaign_results" ON campaign_results FOR ALL USING (campaign_id IN (SELECT id FROM campaigns WHERE project_id IN (SELECT my_project_ids())) OR is_admin());
CREATE POLICY "Access voice_updates" ON voice_updates FOR ALL USING (project_id IN (SELECT my_project_ids()) OR is_admin());
CREATE POLICY "Access subscription_plans" ON subscription_plans FOR ALL USING (project_id IN (SELECT my_project_ids()) OR is_admin());
CREATE POLICY "Access support_tickets" ON support_tickets FOR ALL USING (project_id IN (SELECT my_project_ids()) OR is_admin());
CREATE POLICY "Access ticket_replies" ON ticket_replies FOR ALL USING (ticket_id IN (SELECT id FROM support_tickets WHERE project_id IN (SELECT my_project_ids())) OR is_admin());
CREATE POLICY "Access milestones" ON milestones FOR ALL USING (project_id IN (SELECT my_project_ids()) OR is_admin());
CREATE POLICY "Access satisfaction_surveys" ON satisfaction_surveys FOR ALL USING (project_id IN (SELECT my_project_ids()) OR is_admin());
CREATE POLICY "Access ai_query_usage" ON ai_query_usage FOR ALL USING (project_id IN (SELECT my_project_ids()) OR is_admin());

-- FCM tokens (Users can access their own tokens, admins can see all)
CREATE POLICY "Access fcm_tokens" ON fcm_tokens FOR ALL USING (user_id = auth.uid() OR is_admin());

-- ============================================================
-- MIGRATION COMPLETE
-- ============================================================
