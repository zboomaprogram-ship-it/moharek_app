-- Users & Roles
create table profiles (
  id uuid references auth.users primary key,
  full_name text,
  company_name text,
  role text check (role in ('client', 'account_manager', 'seo_team', 'ads_team', 'content_team', 'design_team', 'tech_team', 'admin')),
  avatar_url text,
  phone text,
  created_at timestamptz default now()
);

-- Projects
create table projects (
  id uuid primary key default gen_random_uuid(),
  client_id uuid references profiles(id),
  account_manager_id uuid references profiles(id),
  name text not null,
  status text default 'active',
  start_date date,
  current_stage text default 'audit',
  created_at timestamptz default now()
);

-- Journey Stages
create table journey_stages (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id),
  stage_name text, -- audit, strategy, setup, execution, optimization, results
  status text default 'not_started', -- not_started, in_progress, completed
  assigned_to uuid references profiles(id),
  deadline date,
  notes text,
  completed_at timestamptz
);

-- Tasks
create table tasks (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id),
  title text,
  description text,
  status text default 'todo', -- todo, in_progress, waiting_client, in_review, completed, delayed
  assigned_to uuid references profiles(id),
  deadline date,
  priority text default 'normal',
  category text, -- seo, ads, content, design, tech, ai_visibility
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Results
create table results (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id),
  result_type text, -- seo, ads, ai_visibility, trust_engine
  metric_name text,
  metric_value numeric,
  metric_unit text,
  recorded_at date,
  created_at timestamptz default now()
);

-- Reports
create table reports (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id),
  title text,
  report_type text, -- weekly, monthly, campaign, seo, ads, competitor
  summary text,
  status text default 'draft', -- draft, ready, archived
  file_url text,
  period_start date,
  period_end date,
  created_at timestamptz default now()
);

-- Approvals
create table approvals (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id),
  title text,
  description text,
  approval_type text, -- content_calendar, design, ad_copy, landing_page, budget, campaign, monthly_strategy
  status text default 'pending', -- pending, approved, changes_requested
  file_url text,
  team_notes text,
  client_notes text,
  created_at timestamptz default now(),
  responded_at timestamptz
);

-- Messages (Chat)
create table chat_channels (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id),
  name text,
  channel_type text default 'client_manager'
);

create table messages (
  id uuid primary key default gen_random_uuid(),
  channel_id uuid references chat_channels(id),
  sender_id uuid references profiles(id),
  content text,
  message_type text default 'text', -- text, image, file, voice
  file_url text,
  is_read boolean default false,
  payload jsonb,
  created_at timestamptz default now()
);

-- Meetings
create table meetings (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id),
  title text,
  scheduled_at timestamptz,
  duration_minutes int,
  meeting_type text, -- scheduled, instant
  jitsi_room_id text,
  summary text,
  action_items text[],
  status text default 'upcoming', -- upcoming, ongoing, completed, cancelled
  created_at timestamptz default now()
);

-- Contracts
create table contracts (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id),
  title text,
  file_url text,
  status text default 'pending', -- pending, signed, expired
  signed_at timestamptz,
  created_at timestamptz default now()
);

-- Invoices & Payments
create table invoices (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id),
  amount numeric,
  currency text default 'USD',
  status text default 'pending', -- pending, paid, overdue, cancelled
  due_date date,
  payment_link text,
  stripe_payment_intent_id text,
  paid_at timestamptz,
  created_at timestamptz default now()
);

-- Activity Feed
create table activity_feed (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id),
  actor_id uuid references profiles(id),
  action text,
  entity_type text,
  entity_id uuid,
  created_at timestamptz default now()
);

-- Files
create table files (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id),
  name text,
  file_url text,
  file_type text, -- brand_guidelines, logo, report, content_plan, campaign_asset, contract, proposal, strategy
  uploaded_by uuid references profiles(id),
  size_bytes bigint,
  created_at timestamptz default now()
);

-- FCM Tokens
create table fcm_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id),
  token text unique,
  platform text, -- ios, android
  created_at timestamptz default now()
);

-- Enable RLS
alter table profiles enable row level security;
alter table projects enable row level security;
alter table tasks enable row level security;
alter table results enable row level security;
alter table reports enable row level security;
alter table approvals enable row level security;
alter table chat_channels enable row level security;
alter table messages enable row level security;
alter table meetings enable row level security;
alter table contracts enable row level security;
alter table invoices enable row level security;
alter table files enable row level security;

-- Basic RLS Policies (example - need refinement based on exact requirements)
-- Clients read their own profile
create policy "Users can view own profile" on profiles for select using (auth.uid() = id);
create policy "Users can update own profile" on profiles for update using (auth.uid() = id);

-- Admins can do everything (requires a function to check admin role)
-- ... 
