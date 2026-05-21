-- ============================================================
-- RABHAN FLAVOR MASTER SETUP SQL SCRIPT
-- Run this entire script in your Supabase SQL Editor (one-shot)
-- This creates ALL tables, columns, constraints, functions, 
-- triggers, and RLS policies for both Moharek base and Rabhan.
-- ============================================================

-- ------------------------------------------------------------
-- 1. BASE AND EXTENDED TABLES
-- ------------------------------------------------------------

-- PROFILES (extends auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  full_name text,
  company_name text,
  role text DEFAULT 'client' CHECK (role IN ('client','account_manager','seo_team','ads_team','content_team','design_team','tech_team','admin')),
  avatar_url text,
  phone text,
  created_at timestamptz DEFAULT now(),
  onboarding_completed boolean DEFAULT false,
  client_goal text,
  created_by uuid REFERENCES public.profiles(id),
  is_active boolean DEFAULT true,
  notes text,
  team_role text CHECK (team_role IN ('admin', 'account_manager', 'seo_team', 'ads_team', 'content_team', 'design_team', 'tech_team')),
  preferred_language text DEFAULT 'en' CHECK (preferred_language IN ('en', 'ar')),
  notification_preferences jsonb DEFAULT '{"reports":true,"tasks":true,"messages":true,"milestones":true,"meetings":true}'::jsonb
);

-- PROJECTS
CREATE TABLE IF NOT EXISTS public.projects (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  account_manager_id uuid REFERENCES public.profiles(id),
  name text NOT NULL,
  status text DEFAULT 'active',
  start_date date DEFAULT CURRENT_DATE,
  current_stage text DEFAULT 'audit',
  created_at timestamptz DEFAULT now(),
  previous_am_ids uuid[] DEFAULT '{}',
  am_assigned_at timestamptz
);

-- JOURNEY STAGES
CREATE TABLE IF NOT EXISTS public.journey_stages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES public.projects(id) ON DELETE CASCADE,
  stage_name text,
  status text DEFAULT 'not_started' CHECK (status IN ('not_started','in_progress','completed')),
  order_index int DEFAULT 0,
  is_completed boolean DEFAULT false,
  assigned_to uuid REFERENCES public.profiles(id),
  deadline date,
  notes text,
  completed_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- TASKS
CREATE TABLE IF NOT EXISTS public.tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES public.projects(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  status text DEFAULT 'todo' CHECK (status IN ('todo','in_progress','waiting_client','in_review','completed','delayed')),
  assigned_to uuid REFERENCES public.profiles(id),
  deadline date,
  priority text DEFAULT 'normal' CHECK (priority IN ('low','normal','high','urgent')),
  category text CHECK (category IN ('seo','ads','content','design','tech','ai_visibility')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- RESULTS
CREATE TABLE IF NOT EXISTS public.results (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES public.projects(id) ON DELETE CASCADE,
  result_type text CHECK (result_type IN ('seo','ads','ai_visibility','trust_engine')),
  metric_name text,
  metric_value numeric,
  metric_unit text,
  recorded_at date DEFAULT CURRENT_DATE,
  created_at timestamptz DEFAULT now()
);

-- REPORTS
CREATE TABLE IF NOT EXISTS public.reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES public.projects(id) ON DELETE CASCADE,
  title text,
  report_type text DEFAULT 'monthly' CHECK (report_type IN ('weekly','monthly','campaign','seo','ads','competitor')),
  summary text,
  status text DEFAULT 'draft' CHECK (status IN ('draft','ready','archived')),
  file_url text,
  period_start date,
  period_end date,
  created_at timestamptz DEFAULT now()
);

-- APPROVALS
CREATE TABLE IF NOT EXISTS public.approvals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES public.projects(id) ON DELETE CASCADE,
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

-- CHAT CHANNELS
CREATE TABLE IF NOT EXISTS public.chat_channels (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES public.projects(id) ON DELETE CASCADE,
  name text NOT NULL,
  channel_type text DEFAULT 'client_manager' CHECK (channel_type IN ('client_manager','team_only','support')),
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

-- MESSAGES
CREATE TABLE IF NOT EXISTS public.messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_id uuid REFERENCES public.chat_channels(id) ON DELETE CASCADE,
  sender_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  message_type text DEFAULT 'text' CHECK (message_type IN ('text','file','voice','system')),
  content text,
  file_url text,
  file_name text,
  file_size int,
  duration_seconds int,
  waveform_data jsonb,
  created_at timestamptz DEFAULT now()
);

-- MEETINGS
CREATE TABLE IF NOT EXISTS public.meetings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES public.projects(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  scheduled_at timestamptz NOT NULL,
  duration_minutes int DEFAULT 30,
  meeting_link text,
  status text DEFAULT 'scheduled' CHECK (status IN ('scheduled','completed','cancelled')),
  created_at timestamptz DEFAULT now()
);

-- CONTRACTS
CREATE TABLE IF NOT EXISTS public.contracts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES public.projects(id) ON DELETE CASCADE,
  title text NOT NULL,
  file_url text NOT NULL,
  status text DEFAULT 'pending' CHECK (status IN ('pending','signed','expired')),
  signed_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- INVOICES
CREATE TABLE IF NOT EXISTS public.invoices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES public.projects(id) ON DELETE CASCADE,
  invoice_number text NOT NULL,
  amount numeric(12,2) NOT NULL,
  currency text DEFAULT 'SAR',
  status text DEFAULT 'unpaid' CHECK (status IN ('unpaid','paid','overdue','void')),
  due_date date NOT NULL,
  paid_at timestamptz,
  stripe_invoice_id text,
  created_at timestamptz DEFAULT now()
);

-- ACTIVITY FEED
CREATE TABLE IF NOT EXISTS public.activity_feed (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES public.projects(id) ON DELETE CASCADE,
  actor_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  action text NOT NULL,
  entity_type text NOT NULL,
  entity_id uuid,
  created_at timestamptz DEFAULT now()
);

-- FILES (Project Documents Repository)
CREATE TABLE IF NOT EXISTS public.files (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES public.projects(id) ON DELETE CASCADE,
  uploaded_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  name text NOT NULL,
  file_url text NOT NULL,
  file_size int,
  category text DEFAULT 'other' CHECK (category IN ('design','contract','invoice','report','other')),
  created_at timestamptz DEFAULT now()
);

-- ENGINE PROGRESS
CREATE TABLE IF NOT EXISTS public.engine_progress (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES public.projects(id) ON DELETE CASCADE,
  engine_type text NOT NULL,
  progress numeric DEFAULT 0 CHECK (progress >= 0 AND progress <= 100),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(project_id, engine_type)
);

-- MILESTONES
CREATE TABLE IF NOT EXISTS public.milestones (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES public.projects(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  target_date date,
  is_completed boolean DEFAULT false,
  completed_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- CAMPAIGNS
CREATE TABLE IF NOT EXISTS public.campaigns (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES public.projects(id) ON DELETE CASCADE,
  name text NOT NULL,
  platform text,
  status text,
  budget numeric,
  spend numeric,
  clicks int,
  impressions int,
  conversions int,
  ctr numeric,
  cpc numeric,
  roas numeric,
  start_date date,
  end_date date,
  created_at timestamptz DEFAULT now()
);

-- CALL SIGNALS
CREATE TABLE IF NOT EXISTS public.call_signals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_id uuid REFERENCES public.chat_channels(id) ON DELETE CASCADE,
  sender_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  receiver_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  signal_type text NOT NULL, -- 'offer', 'answer', 'candidate', 'hangup', 'ringing'
  sdp text,
  candidate jsonb,
  created_at timestamptz DEFAULT now()
);

-- SATISFACTION SURVEYS (NPS)
CREATE TABLE IF NOT EXISTS public.satisfaction_surveys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  score INT NOT NULL CHECK (score >= 1 AND score <= 10),
  comment TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- NOTIFICATIONS (Notification Center)
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title_ar TEXT NOT NULL,
    title_en TEXT NOT NULL,
    body_ar TEXT NOT NULL,
    body_en TEXT NOT NULL,
    type TEXT NOT NULL,
    link_path TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ------------------------------------------------------------
-- 2. RABHAN SPECIFIC TABLES
-- ------------------------------------------------------------

-- PACKAGES (Rabhan Subscription Tiers)
CREATE TABLE IF NOT EXISTS public.packages (
  id                uuid default gen_random_uuid() primary key,
  project_id        uuid references public.projects(id) on delete cascade not null,
  package_name      text not null,
  package_tier      text not null default 'starter',
  status            text not null default 'active',
  renews_at         timestamptz,
  trial_ends_at     timestamptz,
  requests_used     int default 0,
  requests_limit    int default 200,
  services          jsonb default '[]'::jsonb,
  notes             text,
  created_at        timestamptz default now(),
  updated_at        timestamptz default now()
);

-- ECOM_METRICS (Rabhan Dashboard Sales KPIs)
CREATE TABLE IF NOT EXISTS public.ecom_metrics (
  id                   uuid default gen_random_uuid() primary key,
  project_id           uuid references public.projects(id) on delete cascade not null,
  period_start         date not null,
  period_end           date not null,
  period_type          text default 'monthly',
  total_sales          numeric(14,2) default 0,
  prev_sales           numeric(14,2) default 0,
  orders_count         int default 0,
  prev_orders          int default 0,
  roas                 numeric(6,2) default 0,
  prev_roas            numeric(6,2) default 0,
  conversion_rate      numeric(6,4) default 0,
  prev_conversion_rate numeric(6,4) default 0,
  net_profit           numeric(14,2) default 0,
  ad_spend             numeric(14,2) default 0,
  impressions          bigint default 0,
  clicks               bigint default 0,
  add_to_cart          int default 0,
  currency             text default 'SAR',
  published_by         uuid references public.profiles(id),
  published_at         timestamptz,
  is_published         boolean default false,
  created_at           timestamptz default now(),
  updated_at           timestamptz default now()
);

-- GROWTH ENGINES (Rabhan System Integration Progress)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'engine_type') THEN
    CREATE TYPE public.engine_type AS ENUM (
      'store', 'product', 'ads', 'sales_page', 'operations', 'analytics'
    );
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS public.growth_engines (
  id             uuid default gen_random_uuid() primary key,
  project_id     uuid references public.projects(id) on delete cascade not null,
  engine_type    public.engine_type not null,
  status         text default 'pending',
  health_score   int default 0 check (health_score between 0 and 100),
  current_tasks  jsonb default '[]'::jsonb,
  notes          text,
  last_updated_by uuid references public.profiles(id),
  created_at     timestamptz default now(),
  updated_at     timestamptz default now(),
  UNIQUE(project_id, engine_type)
);

-- AD CAMPAIGNS (Meta/Google integration)
CREATE TABLE IF NOT EXISTS public.ad_campaigns (
  id                   uuid default gen_random_uuid() primary key,
  project_id           uuid references public.projects(id) on delete cascade not null,
  campaign_name        text not null,
  platform             text not null,
  status               text default 'active',
  budget               numeric(12,2) default 0,
  spend                numeric(12,2) default 0,
  roas                 numeric(6,2) default 0,
  clicks               bigint default 0,
  impressions          bigint default 0,
  conversions          int default 0,
  platform_campaign_id text,
  start_date           date,
  end_date             date,
  currency             text default 'SAR',
  created_at           timestamptz default now(),
  updated_at           timestamptz default now()
);

-- AM PERFORMANCE TRACKING
CREATE TABLE IF NOT EXISTS public.am_performance (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  am_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  period_month date,
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

-- INVITATION SYSTEM
CREATE TABLE IF NOT EXISTS public.invitations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text NOT NULL,
  invited_role text CHECK (invited_role IN ('account_manager','client')),
  invited_by uuid REFERENCES public.profiles(id),
  project_id uuid REFERENCES public.projects(id),     
  assigned_am_id uuid REFERENCES public.profiles(id), 
  status text DEFAULT 'pending' CHECK (status IN ('pending','accepted','expired')),
  token text UNIQUE DEFAULT gen_random_uuid()::text,
  expires_at timestamptz DEFAULT now() + INTERVAL '7 days',
  accepted_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- ADMIN AUDIT LOG
CREATE TABLE IF NOT EXISTS public.admin_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id uuid REFERENCES public.profiles(id),
  action text,
  target_type text,
  target_id uuid,
  metadata jsonb,
  created_at timestamptz DEFAULT now()
);

-- ------------------------------------------------------------
-- 3. STORAGE BUCKET INITS
-- ------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public) 
VALUES ('voice-messages', 'voice-messages', false)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public) 
VALUES ('files', 'files', false)
ON CONFLICT (id) DO NOTHING;

-- ------------------------------------------------------------
-- 4. ROW LEVEL SECURITY (RLS) POLICIES & HELPER FUNCTIONS
-- ------------------------------------------------------------

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journey_stages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.results ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.approvals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_channels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meetings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contracts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_feed ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.files ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.engine_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.milestones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.call_signals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.satisfaction_surveys ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ecom_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.growth_engines ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ad_campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.am_performance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_logs ENABLE ROW LEVEL SECURITY;

-- RLS Helper Functions
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
    AND role IN ('admin','account_manager')
  );
$$ LANGUAGE sql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.my_project_ids()
RETURNS SETOF uuid AS $$
  SELECT id FROM public.projects WHERE client_id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER;

-- Profiles Policies
DROP POLICY IF EXISTS "Users read own profile" ON public.profiles;
CREATE POLICY "Users read own profile" ON public.profiles FOR SELECT USING (id = auth.uid() OR is_admin());
DROP POLICY IF EXISTS "Users update own profile" ON public.profiles;
CREATE POLICY "Users update own profile" ON public.profiles FOR UPDATE USING (id = auth.uid());
DROP POLICY IF EXISTS "Admins manage profiles" ON public.profiles;
CREATE POLICY "Admins manage profiles" ON public.profiles FOR ALL USING (is_admin());

-- Projects Policies
DROP POLICY IF EXISTS "Clients see own projects" ON public.projects;
CREATE POLICY "Clients see own projects" ON public.projects FOR SELECT USING (client_id = auth.uid() OR is_admin());
DROP POLICY IF EXISTS "Admins manage projects" ON public.projects;
CREATE POLICY "Admins manage projects" ON public.projects FOR ALL USING (is_admin());

-- Journey Stages Policies
DROP POLICY IF EXISTS "Journey access" ON public.journey_stages;
CREATE POLICY "Journey access" ON public.journey_stages FOR SELECT USING (project_id IN (SELECT my_project_ids()) OR is_admin());
DROP POLICY IF EXISTS "Admins manage journey" ON public.journey_stages;
CREATE POLICY "Admins manage journey" ON public.journey_stages FOR ALL USING (is_admin());

-- Tasks Policies
DROP POLICY IF EXISTS "Tasks access" ON public.tasks;
CREATE POLICY "Tasks access" ON public.tasks FOR SELECT USING (project_id IN (SELECT my_project_ids()) OR is_admin());
DROP POLICY IF EXISTS "Admins manage tasks" ON public.tasks;
CREATE POLICY "Admins manage tasks" ON public.tasks FOR ALL USING (is_admin());

-- Results Policies
DROP POLICY IF EXISTS "Results access" ON public.results;
CREATE POLICY "Results access" ON public.results FOR SELECT USING (project_id IN (SELECT my_project_ids()) OR is_admin());
DROP POLICY IF EXISTS "Admins manage results" ON public.results;
CREATE POLICY "Admins manage results" ON public.results FOR ALL USING (is_admin());

-- Reports Policies
DROP POLICY IF EXISTS "Reports access" ON public.reports;
CREATE POLICY "Reports access" ON public.reports FOR SELECT USING (project_id IN (SELECT my_project_ids()) OR is_admin());
DROP POLICY IF EXISTS "Admins manage reports" ON public.reports;
CREATE POLICY "Admins manage reports" ON public.reports FOR ALL USING (is_admin());

-- Approvals Policies
DROP POLICY IF EXISTS "Approvals access" ON public.approvals;
CREATE POLICY "Approvals access" ON public.approvals FOR SELECT USING (project_id IN (SELECT my_project_ids()) OR is_admin());
DROP POLICY IF EXISTS "Clients update approvals" ON public.approvals;
CREATE POLICY "Clients update approvals" ON public.approvals FOR UPDATE USING (project_id IN (SELECT my_project_ids()));
DROP POLICY IF EXISTS "Admins manage approvals" ON public.approvals;
CREATE POLICY "Admins manage approvals" ON public.approvals FOR ALL USING (is_admin());

-- Chat Channels Policies
DROP POLICY IF EXISTS "Channels access" ON public.chat_channels;
CREATE POLICY "Channels access" ON public.chat_channels FOR SELECT USING (project_id IN (SELECT my_project_ids()) OR is_admin());
DROP POLICY IF EXISTS "Admins manage channels" ON public.chat_channels;
CREATE POLICY "Admins manage channels" ON public.chat_channels FOR ALL USING (is_admin());

-- Messages Policies
DROP POLICY IF EXISTS "Messages select" ON public.messages;
CREATE POLICY "Messages select" ON public.messages FOR SELECT USING (
  channel_id IN (
    SELECT id FROM public.chat_channels
    WHERE project_id IN (SELECT my_project_ids()) OR is_admin()
  )
);
DROP POLICY IF EXISTS "Messages insert" ON public.messages;
CREATE POLICY "Messages insert" ON public.messages FOR INSERT WITH CHECK (
  sender_id = auth.uid() AND
  channel_id IN (
    SELECT id FROM public.chat_channels
    WHERE project_id IN (SELECT my_project_ids()) OR is_admin()
  )
);

-- Meetings Policies
DROP POLICY IF EXISTS "Meetings access" ON public.meetings;
CREATE POLICY "Meetings access" ON public.meetings FOR SELECT USING (project_id IN (SELECT my_project_ids()) OR is_admin());
DROP POLICY IF EXISTS "Admins manage meetings" ON public.meetings;
CREATE POLICY "Admins manage meetings" ON public.meetings FOR ALL USING (is_admin());

-- Contracts Policies
DROP POLICY IF EXISTS "Contracts access" ON public.contracts;
CREATE POLICY "Contracts access" ON public.contracts FOR SELECT USING (project_id IN (SELECT my_project_ids()) OR is_admin());
DROP POLICY IF EXISTS "Clients sign contracts" ON public.contracts;
CREATE POLICY "Clients sign contracts" ON public.contracts FOR UPDATE USING (project_id IN (SELECT my_project_ids()));
DROP POLICY IF EXISTS "Admins manage contracts" ON public.contracts;
CREATE POLICY "Admins manage contracts" ON public.contracts FOR ALL USING (is_admin());

-- Invoices Policies
DROP POLICY IF EXISTS "Invoices access" ON public.invoices;
CREATE POLICY "Invoices access" ON public.invoices FOR SELECT USING (project_id IN (SELECT my_project_ids()) OR is_admin());
DROP POLICY IF EXISTS "Admins manage invoices" ON public.invoices;
CREATE POLICY "Admins manage invoices" ON public.invoices FOR ALL USING (is_admin());

-- Activity Feed Policies
DROP POLICY IF EXISTS "Activity access" ON public.activity_feed;
CREATE POLICY "Activity access" ON public.activity_feed FOR SELECT USING (project_id IN (SELECT my_project_ids()) OR is_admin());
DROP POLICY IF EXISTS "Admins manage activity" ON public.activity_feed;
CREATE POLICY "Admins manage activity" ON public.activity_feed FOR ALL USING (is_admin());

-- Files Policies
DROP POLICY IF EXISTS "Files access" ON public.files;
CREATE POLICY "Files access" ON public.files FOR SELECT USING (project_id IN (SELECT my_project_ids()) OR is_admin());
DROP POLICY IF EXISTS "Admins manage files" ON public.files;
CREATE POLICY "Admins manage files" ON public.files FOR ALL USING (is_admin());

-- Engine Progress Policies
DROP POLICY IF EXISTS "Access engine_progress" ON public.engine_progress;
CREATE POLICY "Access engine_progress" ON public.engine_progress FOR ALL USING (project_id IN (SELECT my_project_ids()) OR is_admin());

-- Milestones Policies
DROP POLICY IF EXISTS "Milestones access" ON public.milestones;
CREATE POLICY "Milestones access" ON public.milestones FOR SELECT USING (project_id IN (SELECT my_project_ids()) OR is_admin());
DROP POLICY IF EXISTS "Admins manage milestones" ON public.milestones;
CREATE POLICY "Admins manage milestones" ON public.milestones FOR ALL USING (is_admin());

-- Campaigns Policies
DROP POLICY IF EXISTS "Campaigns access" ON public.campaigns;
CREATE POLICY "Campaigns access" ON public.campaigns FOR SELECT USING (project_id IN (SELECT my_project_ids()) OR is_admin());
DROP POLICY IF EXISTS "Admins manage campaigns" ON public.campaigns;
CREATE POLICY "Admins manage campaigns" ON public.campaigns FOR ALL USING (is_admin());

-- Call Signals Policies
DROP POLICY IF EXISTS "Call signals access" ON public.call_signals;
CREATE POLICY "Call signals access" ON public.call_signals FOR ALL USING (
  sender_id = auth.uid() OR receiver_id = auth.uid() OR is_admin()
);

-- Satisfaction Surveys (NPS) Policies
DROP POLICY IF EXISTS "Clients can view their own surveys" ON public.satisfaction_surveys;
CREATE POLICY "Clients can view their own surveys" ON public.satisfaction_surveys FOR SELECT USING (client_id = auth.uid());
DROP POLICY IF EXISTS "Clients can insert their own surveys" ON public.satisfaction_surveys;
CREATE POLICY "Clients can insert their own surveys" ON public.satisfaction_surveys FOR INSERT WITH CHECK (client_id = auth.uid());

-- Notifications Policies
DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
CREATE POLICY "Users can view own notifications" ON public.notifications FOR SELECT USING (user_id = auth.uid());
DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
CREATE POLICY "Users can update own notifications" ON public.notifications FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Packages Policies
DROP POLICY IF EXISTS "client_read_own_package" ON public.packages;
CREATE POLICY "client_read_own_package" ON public.packages FOR SELECT USING (project_id IN (SELECT my_project_ids()));
DROP POLICY IF EXISTS "am_manage_packages" ON public.packages;
CREATE POLICY "am_manage_packages" ON public.packages FOR ALL USING (project_id IN (SELECT id FROM public.projects WHERE account_manager_id = auth.uid()));
DROP POLICY IF EXISTS "admin_full_packages" ON public.packages;
CREATE POLICY "admin_full_packages" ON public.packages FOR ALL USING ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin');

-- Ecom Metrics Policies
DROP POLICY IF EXISTS "client_read_own_metrics" ON public.ecom_metrics;
CREATE POLICY "client_read_own_metrics" ON public.ecom_metrics FOR SELECT USING (is_published = true AND project_id IN (SELECT my_project_ids()));
DROP POLICY IF EXISTS "am_manage_metrics" ON public.ecom_metrics;
CREATE POLICY "am_manage_metrics" ON public.ecom_metrics FOR ALL USING (project_id IN (SELECT id FROM public.projects WHERE account_manager_id = auth.uid()));
DROP POLICY IF EXISTS "admin_full_metrics" ON public.ecom_metrics;
CREATE POLICY "admin_full_metrics" ON public.ecom_metrics FOR ALL USING ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin');

-- Growth Engines Policies
DROP POLICY IF EXISTS "client_read_engines" ON public.growth_engines;
CREATE POLICY "client_read_engines" ON public.growth_engines FOR SELECT USING (project_id IN (SELECT my_project_ids()));
DROP POLICY IF EXISTS "team_manage_engines" ON public.growth_engines;
CREATE POLICY "team_manage_engines" ON public.growth_engines FOR ALL USING ((SELECT role FROM public.profiles WHERE id = auth.uid()) IN ('admin', 'account_manager', 'ads_team', 'seo_team', 'content_team', 'design_team', 'tech_team'));

-- Ad Campaigns Policies
DROP POLICY IF EXISTS "client_read_campaigns" ON public.ad_campaigns;
CREATE POLICY "client_read_campaigns" ON public.ad_campaigns FOR SELECT USING (project_id IN (SELECT my_project_ids()));
DROP POLICY IF EXISTS "ads_team_manage" ON public.ad_campaigns;
CREATE POLICY "ads_team_manage" ON public.ad_campaigns FOR ALL USING ((SELECT role FROM public.profiles WHERE id = auth.uid()) IN ('admin', 'account_manager', 'ads_team'));

-- AM Performance Policies
DROP POLICY IF EXISTS "am_performance_select" ON public.am_performance;
CREATE POLICY "am_performance_select" ON public.am_performance FOR SELECT USING (
  am_id = auth.uid() OR is_admin()
);

-- Invitations Policies
DROP POLICY IF EXISTS "invitations_admin_only" ON public.invitations;
CREATE POLICY "invitations_admin_only" ON public.invitations FOR ALL USING (is_admin());

-- Admin Logs Policies
DROP POLICY IF EXISTS "admin_logs_admin_only" ON public.admin_logs;
CREATE POLICY "admin_logs_admin_only" ON public.admin_logs FOR ALL USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Storage bucket policies (voice-messages)
DROP POLICY IF EXISTS "Project members can read voice messages" ON storage.objects;
CREATE POLICY "Project members can read voice messages" ON storage.objects FOR SELECT USING (
  bucket_id = 'voice-messages' AND
  (storage.foldername(name))[1] IN (
    SELECT project_id::text FROM public.chat_channels
    WHERE id::text = (storage.foldername(name))[2]
  )
);
DROP POLICY IF EXISTS "Authenticated users can upload voice messages" ON storage.objects;
CREATE POLICY "Authenticated users can upload voice messages" ON storage.objects FOR INSERT WITH CHECK (
  bucket_id = 'voice-messages' AND auth.role() = 'authenticated'
);

-- ------------------------------------------------------------
-- 5. STORAGE BUCKET RLS (general files bucket)
-- ------------------------------------------------------------
DROP POLICY IF EXISTS "Project members can access project files" ON storage.objects;
CREATE POLICY "Project members can access project files" ON storage.objects FOR ALL USING (
  bucket_id = 'files' AND
  (storage.foldername(name))[1] IN (
    SELECT id::text FROM public.projects 
    WHERE client_id = auth.uid() OR account_manager_id = auth.uid() OR EXISTS (
      SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
    )
  )
);

-- Index for notifications performance
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON public.notifications(user_id, is_read);

-- ------------------------------------------------------------
-- 6. TRIGGERS, PROCEDURES & HELPER FUNCTIONS
-- ------------------------------------------------------------

-- Auto update updated_at helper
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$;

DROP TRIGGER IF EXISTS packages_updated_at ON public.packages;
CREATE TRIGGER packages_updated_at BEFORE UPDATE ON public.packages
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS ecom_metrics_updated_at ON public.ecom_metrics;
CREATE TRIGGER ecom_metrics_updated_at BEFORE UPDATE ON public.ecom_metrics
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS growth_engines_updated_at ON public.growth_engines;
CREATE TRIGGER growth_engines_updated_at BEFORE UPDATE ON public.growth_engines
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS ad_campaigns_updated_at ON public.ad_campaigns;
CREATE TRIGGER ad_campaigns_updated_at BEFORE UPDATE ON public.ad_campaigns
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- Auto-setup triggers & procedures on project creation
CREATE OR REPLACE FUNCTION public.on_project_created()
RETURNS TRIGGER AS $$
BEGIN
  -- Create chat channel
  INSERT INTO public.chat_channels (project_id, name, channel_type)
  VALUES (NEW.id, NEW.name || ' Chat', 'client_manager');

  -- Create journey stages
  INSERT INTO public.journey_stages (project_id, stage_name, order_index, status)
  VALUES
    (NEW.id, 'audit',        0, 'in_progress'),
    (NEW.id, 'strategy',     1, 'not_started'),
    (NEW.id, 'setup',        2, 'not_started'),
    (NEW.id, 'execution',    3, 'not_started'),
    (NEW.id, 'optimization', 4, 'not_started'),
    (NEW.id, 'results',      5, 'not_started');

  -- Welcome activity
  INSERT INTO public.activity_feed (project_id, actor_id, action, entity_type, entity_id)
  VALUES (NEW.id, NEW.client_id, 'Welcome to Rabhan', 'project', NEW.id);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_project_created ON public.projects;
CREATE TRIGGER trigger_project_created
  AFTER INSERT ON public.projects
  FOR EACH ROW
  EXECUTE FUNCTION public.on_project_created();

-- Helper views/functions for metrics
CREATE OR REPLACE FUNCTION public.get_latest_metrics(p_project_id uuid)
RETURNS TABLE (
  total_sales numeric, prev_sales numeric,
  orders_count int, prev_orders int,
  roas numeric, prev_roas numeric,
  conversion_rate numeric, net_profit numeric,
  period_start date, period_end date
)
LANGUAGE sql SECURITY DEFINER AS $$
  SELECT total_sales, prev_sales, orders_count, prev_orders,
         roas, prev_roas, conversion_rate, net_profit,
         period_start, period_end
  FROM public.ecom_metrics
  WHERE project_id = p_project_id AND is_published = true
  ORDER BY period_end DESC LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.get_engine_health(p_project_id uuid)
RETURNS TABLE (engine_type text, status text, health_score int)
LANGUAGE sql SECURITY DEFINER AS $$
  SELECT engine_type::text, status, health_score
  from public.growth_engines
  WHERE project_id = p_project_id
  ORDER BY engine_type;
$$;

-- NPS due helper function
CREATE OR REPLACE FUNCTION public.is_nps_due(p_client_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    last_survey_at TIMESTAMPTZ;
BEGIN
    SELECT created_at INTO last_survey_at
    FROM public.satisfaction_surveys
    WHERE client_id = p_client_id
    ORDER BY created_at DESC
    LIMIT 1;

    IF last_survey_at IS NULL OR last_survey_at < NOW() - INTERVAL '30 days' THEN
        RETURN TRUE;
    END IF;

    RETURN FALSE;
END;
$$;

-- E-commerce metrics update trigger for automated notifications
CREATE OR REPLACE FUNCTION public.on_metrics_published()
RETURNS TRIGGER AS $$
DECLARE
  v_client_id UUID;
  v_company_name TEXT;
BEGIN
  IF (TG_OP = 'INSERT' AND NEW.is_published = true) OR 
     (TG_OP = 'UPDATE' AND NEW.is_published = true AND (OLD.is_published = false OR OLD.is_published IS NULL)) THEN
     
    SELECT client_id, name INTO v_client_id, v_company_name
    FROM public.projects
    WHERE id = NEW.project_id;
    
    IF v_client_id IS NOT NULL THEN
      INSERT INTO public.notifications (
        user_id,
        title_ar,
        title_en,
        body_ar,
        body_en,
        type,
        link_path
      ) VALUES (
        v_client_id,
        '📈 تحديث أداء المتجر جديد لـ ' || COALESCE(v_company_name, 'متجرك'),
        '📈 New E-commerce Performance Update',
        'تم نشر تقرير مبيعات وأداء جديد لمتجرك للفترة من ' || NEW.period_start || ' إلى ' || NEW.period_end || '. تفقد النتائج الآن.',
        'A new sales and performance report has been published for your store from ' || NEW.period_start || ' to ' || NEW.period_end || '.',
        'metrics',
        '/dashboard/analytics'
      );
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_metrics_published ON public.ecom_metrics;
CREATE TRIGGER trigger_metrics_published
  AFTER INSERT OR UPDATE ON public.ecom_metrics
  FOR EACH ROW
  EXECUTE FUNCTION public.on_metrics_published();

-- Package expiry alert check (Cron or scheduled call)
CREATE OR REPLACE FUNCTION public.check_expiring_packages()
RETURNS TABLE (notified_count INT) AS $$
DECLARE
  v_pkg RECORD;
  v_client_id UUID;
  v_company_name TEXT;
  v_inserted_count INT := 0;
BEGIN
  FOR v_pkg IN 
    SELECT p.id, p.project_id, p.package_name, p.renews_at
    FROM public.packages p
    WHERE p.status = 'active'
      AND p.renews_at >= (now() + interval '2 days')
      AND p.renews_at <= (now() + interval '3 days')
  LOOP
    SELECT client_id, name INTO v_client_id, v_company_name
    FROM public.projects
    WHERE id = v_pkg.project_id;
    
    IF v_client_id IS NOT NULL THEN
      IF NOT EXISTS (
        SELECT 1 FROM public.notifications 
        WHERE user_id = v_client_id 
          AND type = 'package_alert'
          AND created_at >= (now() - interval '3 days')
      ) THEN
        INSERT INTO public.notifications (
          user_id,
          title_ar,
          title_en,
          body_ar,
          body_en,
          type,
          link_path
        ) VALUES (
          v_client_id,
          '⚠️ تنبيه: قُرب انتهاء باقة ' || COALESCE(v_pkg.package_name, 'النمو'),
          '⚠️ Alert: Package Expiring Soon',
          'باقة ' || COALESCE(v_pkg.package_name, 'النمو') || ' لـ ' || COALESCE(v_company_name, 'متجرك') || ' ستنتهي خلال 3 أيام بتاريخ ' || v_pkg.renews_at::date || '.',
          'Your ' || COALESCE(v_pkg.package_name, 'Growth') || ' subscription is set to expire in 3 days on ' || v_pkg.renews_at::date || '.',
          'package_alert',
          '/dashboard/growth'
        );
        v_inserted_count := v_inserted_count + 1;
      END IF;
    END IF;
  END LOOP;
  
  RETURN QUERY SELECT v_inserted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
