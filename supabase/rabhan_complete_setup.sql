-- ============================================================
-- RABHAN COMPLETE DATABASE SETUP (ONE-SHOT RUN)
-- Run this entire script in your new Rabhan Supabase SQL Editor.
-- ============================================================

-- ------------------------------------------------------------
-- PART 1: BASE SYSTEM TABLES
-- ------------------------------------------------------------

-- 1. PROFILES (extends auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  full_name text,
  company_name text,
  role text DEFAULT 'client' CHECK (role IN ('client','account_manager','seo_team','ads_team','content_team','design_team','tech_team','admin')),
  avatar_url text,
  phone text,
  created_at timestamptz DEFAULT now()
);

-- 2. PROJECTS
CREATE TABLE IF NOT EXISTS public.projects (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  account_manager_id uuid REFERENCES public.profiles(id),
  name text NOT NULL,
  status text DEFAULT 'active',
  start_date date DEFAULT CURRENT_DATE,
  current_stage text DEFAULT 'audit',
  created_at timestamptz DEFAULT now()
);

-- 3. JOURNEY STAGES
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

-- 4. TASKS
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
  updated_at timestamptz DEFAULT now(),
  stage_type text,                                      -- Rabhan stage type reference
  is_client_pending boolean default false,              -- Rabhan stage tracking flag
  journey_order int default 0                           -- Rabhan ordering index
);

-- 5. RESULTS
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

-- 6. REPORTS
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

-- 7. APPROVALS
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

-- 8. CHAT CHANNELS
CREATE TABLE IF NOT EXISTS public.chat_channels (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES public.projects(id) ON DELETE CASCADE,
  name text,
  channel_type text DEFAULT 'client_manager'
);

-- 9. MESSAGES
CREATE TABLE IF NOT EXISTS public.messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_id uuid REFERENCES public.chat_channels(id) ON DELETE CASCADE,
  sender_id uuid REFERENCES public.profiles(id),
  content text,
  message_type text DEFAULT 'text' CHECK (message_type IN ('text','image','file','voice')),
  file_url text,
  is_read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- 10. MEETINGS
CREATE TABLE IF NOT EXISTS public.meetings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES public.projects(id) ON DELETE CASCADE,
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
CREATE TABLE IF NOT EXISTS public.contracts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES public.projects(id) ON DELETE CASCADE,
  title text,
  file_url text,
  status text DEFAULT 'pending' CHECK (status IN ('pending','signed','expired')),
  signed_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- 12. INVOICES
CREATE TABLE IF NOT EXISTS public.invoices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES public.projects(id) ON DELETE CASCADE,
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
CREATE TABLE IF NOT EXISTS public.activity_feed (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES public.projects(id) ON DELETE CASCADE,
  actor_id uuid REFERENCES public.profiles(id),
  action text,
  entity_type text,
  entity_id uuid,
  created_at timestamptz DEFAULT now()
);

-- 14. FILES
CREATE TABLE IF NOT EXISTS public.files (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES public.projects(id) ON DELETE CASCADE,
  name text,
  file_url text,
  file_type text CHECK (file_type IN ('brand_guidelines','logo','report','content_plan','campaign_asset','contract','proposal','strategy')),
  uploaded_by uuid REFERENCES public.profiles(id),
  size_bytes bigint,
  created_at timestamptz DEFAULT now()
);

-- ------------------------------------------------------------
-- PART 2: RABHAN SPECIFIC TABLES
-- ------------------------------------------------------------

-- 15. PACKAGES (Rabhan Subscription Tiers)
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

-- 16. ECOM_METRICS (Rabhan Dashboard Sales KPIs)
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

-- 17. GROWTH ENGINES (Rabhan System Integration Progress)
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

-- 18. AD CAMPAIGNS (Meta/Google integration)
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

-- ------------------------------------------------------------
-- PART 3: ROW LEVEL SECURITY POLICIES & HELPER FUNCTIONS
-- ------------------------------------------------------------

-- Enable Row-Level Security
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
ALTER TABLE public.packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ecom_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.growth_engines ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ad_campaigns ENABLE ROW LEVEL SECURITY;

-- Helper functions
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
DROP POLICY IF EXISTS "Approvals read" ON public.approvals;
CREATE POLICY "Approvals read" ON public.approvals FOR SELECT USING (project_id IN (SELECT my_project_ids()) OR is_admin());
DROP POLICY IF EXISTS "Clients update approvals" ON public.approvals;
CREATE POLICY "Clients update approvals" ON public.approvals FOR UPDATE USING (project_id IN (SELECT my_project_ids()));
DROP POLICY IF EXISTS "Admins manage approvals" ON public.approvals;
CREATE POLICY "Admins manage approvals" ON public.approvals FOR ALL USING (is_admin());

-- Chat Channels Policies
DROP POLICY IF EXISTS "Chat channels access" ON public.chat_channels;
CREATE POLICY "Chat channels access" ON public.chat_channels FOR SELECT USING (project_id IN (SELECT my_project_ids()) OR is_admin());
DROP POLICY IF EXISTS "Admins manage channels" ON public.chat_channels;
CREATE POLICY "Admins manage channels" ON public.chat_channels FOR ALL USING (is_admin());

-- Messages Policies
DROP POLICY IF EXISTS "Messages read" ON public.messages;
CREATE POLICY "Messages read" ON public.messages FOR SELECT USING (channel_id IN (SELECT id FROM public.chat_channels WHERE project_id IN (SELECT my_project_ids())) OR is_admin());
DROP POLICY IF EXISTS "Messages insert" ON public.messages;
CREATE POLICY "Messages insert" ON public.messages FOR INSERT WITH CHECK (sender_id = auth.uid() AND (channel_id IN (SELECT id FROM public.chat_channels WHERE project_id IN (SELECT my_project_ids())) OR is_admin()));
DROP POLICY IF EXISTS "Admins manage messages" ON public.messages;
CREATE POLICY "Admins manage messages" ON public.messages FOR ALL USING (is_admin());

-- Meetings Policies
DROP POLICY IF EXISTS "Meetings access" ON public.meetings;
CREATE POLICY "Meetings access" ON public.meetings FOR SELECT USING (project_id IN (SELECT my_project_ids()) OR is_admin());
DROP POLICY IF EXISTS "Admins manage meetings" ON public.meetings;
CREATE POLICY "Admins manage meetings" ON public.meetings FOR ALL USING (is_admin());

-- Contracts Policies
DROP POLICY IF EXISTS "Contracts access" ON public.contracts;
CREATE POLICY "Contracts access" ON public.contracts FOR SELECT USING (project_id IN (SELECT my_project_ids()) OR is_admin());
DROP POLICY IF EXISTS "Clients update contracts" ON public.contracts;
CREATE POLICY "Clients update contracts" ON public.contracts FOR UPDATE USING (project_id IN (SELECT my_project_ids()));
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

-- ------------------------------------------------------------
-- PART 4: AUTO-SETUP TRIGGERS & PROCEDURES
-- ------------------------------------------------------------

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

-- ------------------------------------------------------------
-- PART 5: HELPER VIEWS/FUNCTIONS FOR METRICS
-- ------------------------------------------------------------

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
