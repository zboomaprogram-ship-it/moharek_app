# Moharek Growth Hub — Master Engineering & Product Plan v3.0

**Consolidates: v1.6.0 (base) + v2.1 (improvements) + New Product Spec**
**Date: May 2026 | Status: Ready for AI Agent Implementation**

> **App Name Change:** "Moharek Client App" → **"Moharek Growth Hub"**
> This is not just a rename. The Growth Hub positions the product as a complete operating system, not a reporting tool.

---

## ⚠️ MUST READ FIRST — Critical Decisions & Warnings

Read this entire section before building anything. These are the decisions that will cost you the most time and money if you get them wrong.

---

### WARNING 1 — The AI Assistant will cost money. Plan for it.

The AI Assistant feature (client asks "ما الذي حدث هذا الشهر؟" and gets a smart answer) requires calling the Anthropic Claude API per query. This is NOT free.

**Cost estimate:**

- Every AI query = ~2,000 tokens input + ~500 tokens output
- Claude Sonnet 4: ~$0.003 per query
- If 50 clients each ask 10 questions/month = 500 queries = **$1.50/month** (very manageable)
- If you scale to 500 clients = **$15/month** — still fine

**What to do:**

- Implement a rate limit: max 20 AI queries per client per month
- Show a "Queries remaining this month: 17/20" counter
- Cache AI answers: if the same client asks the same question twice in 24 hours, return the cached answer
- Never call the AI API on every page load — only on explicit button press

**Rate limiting table:**

```sql
create table ai_query_usage (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id),
  query_text text,
  response_text text,
  tokens_used int,
  created_at timestamptz default now()
);
-- Index for monthly count check
create index on ai_query_usage(project_id, created_at);
```

---

### WARNING 2 — Multiple chat channels will destroy Supabase free tier fast.

The new spec calls for 6 chat channels per client (Account Manager, SEO, Content, Tech, Reports, Support). With 20 clients that's 120 realtime subscriptions running simultaneously.

**Supabase free tier Realtime limit:** 200 concurrent connections total across the entire project.

**What to do — phased approach:**

- **MVP (Phase 1):** ONE channel per client only. Client talks to Account Manager. Account Manager routes internally. This is also better UX — client doesn't want to manage 6 threads.
- **Phase 2 (after 30+ clients):** Upgrade Supabase to Pro ($25/mo) and enable team channels
- **Phase 3:** Add team-specific channels one at a time based on actual client demand

**This is a product decision, not just a technical one.** Start with 1 channel. It's cleaner.

---

### WARNING 3 — Multi-user per client company requires a completely different auth model.

The new spec has: Owner, Manager, Marketing Team, Finance, Viewer — all from the same client company.

This is NOT the same as the Moharek team roles (admin, account_manager, seo_team etc.). These are the **client's own internal users** sharing access to their project.

**You need a new concept:** `company_members` — people who belong to a client company and can access that company's project with different permission levels.

**New tables needed:**

```sql
-- A client company (separate from a single profile)
create table companies (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  owner_id uuid references profiles(id), -- the main client
  created_at timestamptz default now()
);

-- Members of a client company
create table company_members (
  id uuid primary key default gen_random_uuid(),
  company_id uuid references companies(id),
  user_id uuid references profiles(id),
  company_role text check (company_role in ('owner','manager','marketing','finance','viewer')),
  invited_by uuid references profiles(id),
  joined_at timestamptz default now()
);

-- Project now belongs to a company, not just one client
alter table projects add column company_id uuid references companies(id);
```

**Impact:** RLS policies must be rewritten. A client's project is now accessible to ALL members of their company, filtered by their `company_role`.

**Start MVP without multi-user.** Add it in Phase 3 only when a real client asks for it. Building it too early is the #1 waste of time in SaaS apps.

---

### WARNING 4 — Google Search Console / Analytics integration is 3-5 days of work alone.

The spec mentions integrating GSC, GA, GBP, Looker Studio. Each one requires:

- OAuth 2.0 flow (client grants your app access to their account)
- Storing refresh tokens securely (never in the client-side app)
- Supabase Edge Functions that call Google APIs server-side
- Handling token expiry and re-auth flows
- Rate limits from Google's API

**Decision: Do NOT build this in the first 3 months.** Instead:

- The admin team manually enters results into the `results` table via the admin panel
- This gives you 100% of the UX benefit with 0% of the integration complexity
- Add real API integrations in Phase 4 only after the core app is stable and generating revenue

---

### WARNING 5 — "Convert message to Task" sounds simple. It is not.

When an account manager reads a client message and taps "Convert to Task", you need to:

- Show a mini task-creation form pre-filled from the message content
- Link the created task back to the source message
- Notify the client that their message became a task
- Update the message UI to show the linked task card

This is 2-3 days of work. Put it in Phase 3. Phase 1 gets a "Create Task" button in the chat screen header that opens a blank task form.

---

### WARNING 6 — The 5 Engines progress bars need an owner. Who updates them?

The Strategy page shows SEO Engine: 70%, Content Engine: 80%, etc. These percentages don't calculate themselves. Someone has to update them.

**Decision:** Admin panel only. The account manager updates engine progress manually each week/month via a simple slider in the admin panel. No auto-calculation in MVP.

**Future (Phase 4):** Calculate automatically from completed tasks per category.

---

### WARNING 7 — Apple Developer Account ($99/year) and Google Play ($25 one-time) are required BEFORE you can test on real devices through the store.

For TestFlight (iOS beta testing), you need the Apple Developer account. Without it you can only test on simulators. Buy it early — Apple approval takes 1-2 days.

---

### WARNING 8 — Voice updates from Account Manager ≠ Voice messages in chat.

The spec describes two different features:

- **Voice messages in chat** (Section 12 of v2.1) — real-time chat voice notes. Already planned. ✅
- **Voice Updates** — the account manager records a broadcast voice update to the client that appears on the home dashboard as a "message from your manager". This is a separate feature.

The Voice Update is simpler: it's just an audio file uploaded to Storage, linked to the `activity_feed` table with `type = 'voice_update'`. The home screen shows it as a playable card in the Latest Updates feed. Build this in Phase 2.

---

## Table of Contents

**Part A — Product Definition**

1. [App Identity & Navigation](#1-app-identity)
2. [Complete Screen Map](#2-screen-map)
3. [User Roles — Two Systems](#3-user-roles)

**Part B — Database (Complete Schema)** 4. [Full Database Schema v3.0](#4-database-schema)

**Part C — All Features (Detailed)** 5. [Home Dashboard — Living & Personalized](#5-home-dashboard) 6. [Strategy Page — 5 Engines](#6-strategy-page) 7. [Tasks + Client Requests](#7-tasks) 8. [Reports + Growth Story + AI Summary](#8-reports) 9. [Approvals](#9-approvals) 10. [Campaigns](#10-campaigns) 11. [Chat — Realtime + Voice + Message→Task](#11-chat) 12. [Files Center](#12-files) 13. [Meetings + In-App Calls (LiveKit)](#13-meetings--calls) 14. [Billing & Subscription](#14-billing) 15. [Support / Help Center](#15-support) 16. [AI Assistant](#16-ai-assistant) 17. [Milestones & Celebrations](#17-milestones) 18. [Client Health Score](#18-health-score) 19. [NPS & Satisfaction](#19-nps) 20. [Smart Notifications](#20-notifications) 21. [Full Arabic Support — Default Language](#21-arabic) 22. [Voice Messages in Chat](#22-voice-messages) 23. [Onboarding — First Day Experience](#23-onboarding) 24. [UX System — Design Tokens & Patterns](#24-ux-system)

**Part D — Admin Web Panel** 25. [Admin Panel — Complete Feature Set](#25-admin-panel)

**Part E — Build Plan** 26. [Implementation Phases — 12 Weeks](#26-phases) 27. [Complete Package List](#27-packages) 28. [Cost Breakdown](#28-cost) 29. [What to Build vs What to Skip in MVP](#29-mvp-scope)

---

## Part A — Product Definition

---

## 1. App Identity

**Name:** Moharek Growth Hub | محرك Growth Hub
**Tagline (AR):** نظام نموك الكامل في مكان واحد
**Tagline (EN):** Your complete growth system, in one place
**Default Language:** Arabic (RTL)
**Platforms:** iOS + Android (Flutter) | Admin: Flutter Web

**Bottom navigation (5 tabs — client app):**

1. الرئيسية (Home)
2. المهام (Tasks)
3. النتائج (Results)
4. التقارير (Reports)
5. المحادثة (Chat)

**Side drawer / hamburger (remaining screens):**

- الاستراتيجية (Strategy)
- الموافقات (Approvals)
- الحملات (Campaigns)
- الملفات (Files)
- الاجتماعات (Meetings)
- الفواتير (Billing)
- الدعم (Support)
- الإعدادات (Settings)

---

## 2. Screen Map

```
Moharek Growth Hub
├── Auth
│   ├── Login
│   ├── Forgot Password
│   └── First-Time Setup (onboarding, 5 steps)
│
├── Bottom Nav
│   ├── Home Dashboard
│   ├── Tasks
│   │   ├── All Tasks (Kanban / List toggle)
│   │   ├── Task Detail
│   │   └── New Client Request Form
│   ├── Results
│   │   ├── SEO Results
│   │   ├── Google Ads Results
│   │   ├── AI Visibility Results
│   │   └── Trust Engine Results
│   ├── Reports
│   │   ├── Report List
│   │   ├── Report Viewer (swipeable Growth Story)
│   │   └── AI Summary Sheet
│   └── Chat
│       ├── Channel List (MVP: 1 channel)
│       ├── Chat Screen (text + voice + image)
│       └── Active Call Screen (LiveKit video/voice)
│
└── Drawer
    ├── Strategy
    │   ├── Growth Strategy Summary
    │   ├── 5 Engines Tracker
    │   └── 90-Day Roadmap
    ├── Approvals
    │   ├── Pending List
    │   └── Approval Detail
    ├── Campaigns
    │   ├── Campaign List
    │   └── Campaign Detail
    ├── Files
    │   ├── Categories
    │   └── File Viewer
    ├── Meetings
    │   ├── Upcoming / Past
    │   └── Meeting Detail + Action Items
    ├── Billing
    │   ├── Current Plan
    │   ├── Invoice List
    │   └── Payment Screen
    ├── Support
    │   ├── Open Ticket
    │   ├── My Tickets
    │   └── FAQ
    └── Settings
        ├── Profile
        ├── Language (AR / EN)
        ├── Notification Preferences
        └── Logout
```

---

## 3. User Roles — Two Systems

There are TWO completely separate role systems that must not be confused.

### System A — Moharek Team Roles (who operates the app)

These are Moharek's internal employees.

| Role              | Access                                             |
| ----------------- | -------------------------------------------------- |
| `admin`           | Full access to all clients, all data, admin panel  |
| `account_manager` | Assigned clients only — all data for those clients |
| `seo_team`        | Assigned clients — SEO tasks only                  |
| `content_team`    | Assigned clients — content tasks only              |
| `ads_team`        | Assigned clients — ads tasks only                  |
| `tech_team`       | Assigned clients — technical tasks only            |
| `design_team`     | Assigned clients — design tasks only               |

### System B — Client Company Roles (who is the client's team)

These are the client's own staff accessing their project.

| Role        | What they see                                                                       |
| ----------- | ----------------------------------------------------------------------------------- |
| `owner`     | Everything — strategy, tasks, results, reports, approvals, billing, files, meetings |
| `manager`   | Tasks, results, reports, approvals, files, meetings (no billing)                    |
| `marketing` | Tasks (content/SEO only), results, reports, approvals, files                        |
| `finance`   | Billing only                                                                        |
| `viewer`    | Results and reports (read-only, no actions)                                         |

**MVP Decision:** Build only `owner` role for now. Add other client roles in Phase 3.

---

## Part B — Database (Complete Schema)

---

## 4. Database Schema v3.0

Complete Supabase PostgreSQL schema. Run in order.

```sql
-- =============================================
-- SECTION 1: IDENTITY & AUTH
-- =============================================

create table profiles (
  id uuid references auth.users primary key,
  full_name text not null,
  company_name text,
  -- Moharek team role (null for clients)
  team_role text check (team_role in (
    'admin','account_manager','seo_team','content_team',
    'ads_team','tech_team','design_team'
  )),
  -- Client flag
  is_client boolean default false,
  avatar_url text,
  phone text,
  preferred_locale text default 'ar',
  onboarding_completed boolean default false,
  client_goal text,
  last_seen_at timestamptz,
  notification_preferences jsonb default '{
    "results": true, "tasks": true, "reports": true,
    "invoices": true, "milestones": true, "calls": true,
    "approvals": true, "ai_updates": true
  }',
  created_at timestamptz default now()
);

-- Client companies (for multi-user client access — Phase 3)
create table companies (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  owner_id uuid references profiles(id),
  created_at timestamptz default now()
);

-- Company members (Phase 3 only — skip in MVP)
create table company_members (
  id uuid primary key default gen_random_uuid(),
  company_id uuid references companies(id),
  user_id uuid references profiles(id),
  company_role text check (company_role in ('owner','manager','marketing','finance','viewer')),
  invited_by uuid references profiles(id),
  is_active boolean default true,
  joined_at timestamptz default now(),
  unique(company_id, user_id)
);

-- FCM tokens for push notifications
create table fcm_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id),
  token text unique not null,
  platform text check (platform in ('ios','android')),
  created_at timestamptz default now()
);

-- =============================================
-- SECTION 2: PROJECT CORE
-- =============================================

create table projects (
  id uuid primary key default gen_random_uuid(),
  client_id uuid references profiles(id),
  company_id uuid references companies(id), -- Phase 3
  account_manager_id uuid references profiles(id),
  name text not null,
  status text default 'active' check (status in ('active','paused','completed')),
  current_stage text default 'audit',
  start_date date,
  -- Strategy fields
  project_goal text,
  target_market text,
  target_audience text,
  main_services text[], -- ['زراعة أسنان', 'تقويم']
  competitors text[],
  priorities text[],
  channels text[], -- ['seo','content','ai_visibility','trust','conversion']
  -- Health
  health_score numeric default 0,
  health_label text default 'steady',
  created_at timestamptz default now()
);

-- =============================================
-- SECTION 3: JOURNEY & STRATEGY
-- =============================================

create table journey_stages (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id),
  stage_name text check (stage_name in (
    'audit','strategy','setup','execution','optimization','results'
  )),
  order_index int not null,
  status text default 'not_started' check (status in (
    'not_started','in_progress','completed'
  )),
  assigned_to uuid references profiles(id),
  deadline date,
  notes text,
  stage_description text,  -- Arabic description written by account manager
  completed_at timestamptz
);

-- 5 Engines tracker (updated manually by account manager)
create table engine_progress (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id),
  engine text check (engine in (
    'content','ai_visibility','seo','trust','conversion'
  )),
  progress_percent int check (progress_percent between 0 and 100) default 0,
  status_notes text, -- Arabic note about this engine's current status
  updated_by uuid references profiles(id),
  updated_at timestamptz default now(),
  unique(project_id, engine)
);

-- Client onboarding data (collected on first login)
create table onboarding_data (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id),
  website_url text,
  website_access_notes text,
  google_business_url text,
  social_links jsonb, -- {'instagram': '...', 'facebook': '...'}
  brand_notes text,
  target_services text[],
  submitted_at timestamptz default now()
);

-- =============================================
-- SECTION 4: TASKS & REQUESTS
-- =============================================

create table tasks (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id),
  title text not null,
  description text,
  category text check (category in (
    'technical_seo','content','google_business','backlinks',
    'ai_search','reports','client_request','design','tracking','ads'
  )),
  priority text default 'normal' check (priority in ('normal','important','urgent')),
  status text default 'new' check (status in (
    'new','in_progress','waiting_client','under_review','done','delayed'
  )),
  progress_percent int default 0 check (progress_percent between 0 and 100),
  assigned_to uuid references profiles(id),
  deadline date,
  notes text,
  -- Client request fields
  is_client_request boolean default false,
  request_type text, -- 'content_edit','report','new_page','seo_campaign', etc.
  client_proposed_deadline date,
  -- Message linkage (Phase 3)
  source_message_id uuid, -- references messages(id) if converted from chat
  created_by uuid references profiles(id),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table task_attachments (
  id uuid primary key default gen_random_uuid(),
  task_id uuid references tasks(id),
  file_url text,
  file_name text,
  uploaded_by uuid references profiles(id),
  created_at timestamptz default now()
);

create table task_comments (
  id uuid primary key default gen_random_uuid(),
  task_id uuid references tasks(id),
  author_id uuid references profiles(id),
  content text,
  created_at timestamptz default now()
);

-- =============================================
-- SECTION 5: RESULTS & METRICS
-- =============================================

create table results (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id),
  result_type text check (result_type in (
    'seo','ads','ai_visibility','trust_engine','conversion','leads'
  )),
  metric_label text not null,
  metric_value numeric,
  metric_unit text, -- '%', 'K', 'SAR', 'EGP', '#'
  change_from_last numeric, -- for trend indicator: +12.5 means +12.5%
  recorded_at date not null,
  created_at timestamptz default now()
);

-- Keyword tracking (separate from generic results)
create table keywords (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id),
  keyword text not null,
  current_position int,
  previous_position int,
  search_volume int,
  target_position int default 10,
  url text, -- which page is ranking
  recorded_at date,
  created_at timestamptz default now()
);

-- AI Visibility tracking
create table ai_visibility (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id),
  platform text check (platform in ('chatgpt','gemini','perplexity','copilot')),
  appears boolean default false,
  visibility_score int default 0, -- 0-100
  sample_questions text[],
  competitor_brands text[],
  notes text,
  recorded_at date,
  created_at timestamptz default now()
);

-- =============================================
-- SECTION 6: REPORTS
-- =============================================

create table reports (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id),
  title text,
  title_ar text, -- Arabic title
  report_type text check (report_type in (
    'monthly','weekly','seo','ads','content','google_business',
    'ai_visibility','leads','competitor'
  )),
  status text default 'draft' check (status in ('draft','ready','archived')),
  -- Growth Story fields
  highlight_stat text,          -- "زادت الزيارات 47%"
  highlight_context text,       -- "أفضل شهر منذ بداية التعاون"
  manager_note text,            -- Arabic personal note from account manager
  next_month_priorities text[], -- ["تحسين 3 صفحات خدمات", "حملة Backlinks"]
  -- File
  file_url text,
  period_start date,
  period_end date,
  -- AI Summary cache
  ai_summary text,
  ai_summary_generated_at timestamptz,
  created_at timestamptz default now()
);

-- =============================================
-- SECTION 7: APPROVALS
-- =============================================

create table approvals (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id),
  title text,
  approval_type text check (approval_type in (
    'article','service_page','landing_page','ad_copy',
    'website_change','monthly_plan','final_report',
    'google_business_content','case_study','design','budget'
  )),
  description text,
  file_url text,
  preview_url text,
  team_notes text,
  client_notes text,
  status text default 'pending' check (status in (
    'pending','approved','needs_edit','rejected'
  )),
  created_at timestamptz default now(),
  responded_at timestamptz
);

-- =============================================
-- SECTION 8: CAMPAIGNS
-- =============================================

create table campaigns (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id),
  name text not null,
  name_ar text,
  goal text,
  goal_ar text,
  channel text check (channel in (
    'seo','content','google_ads','ai_visibility','google_business','social'
  )),
  budget numeric,
  currency text default 'EGP',
  status text default 'planned' check (status in (
    'planned','active','paused','completed'
  )),
  start_date date,
  end_date date,
  created_at timestamptz default now()
);

create table campaign_results (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid references campaigns(id),
  metric_label text,
  metric_value numeric,
  metric_unit text,
  recorded_at date,
  created_at timestamptz default now()
);

-- =============================================
-- SECTION 9: CHAT & COMMUNICATION
-- =============================================

create table chat_channels (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id),
  name text,
  name_ar text,
  channel_type text default 'account_manager' check (channel_type in (
    'account_manager','seo_team','content_team',
    'tech_team','reports','support'
  )),
  is_active boolean default true,
  created_at timestamptz default now()
);

create table messages (
  id uuid primary key default gen_random_uuid(),
  channel_id uuid references chat_channels(id),
  sender_id uuid references profiles(id),
  content text,
  message_type text default 'text' check (message_type in (
    'text','image','file','voice','call','system'
  )),
  file_url text,
  duration_seconds int,      -- for voice messages
  waveform_data jsonb,        -- amplitude array for voice playback
  is_read boolean default false,
  -- Task linkage (Phase 3)
  linked_task_id uuid references tasks(id),
  converted_to_task boolean default false,
  created_at timestamptz default now()
);

-- Voice updates from account manager (shown on home dashboard)
create table voice_updates (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id),
  recorded_by uuid references profiles(id),
  audio_url text,
  duration_seconds int,
  transcript text,        -- optional: AI transcription
  is_heard boolean default false,
  created_at timestamptz default now()
);

-- =============================================
-- SECTION 10: MEETINGS & CALLS
-- =============================================

create table meetings (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id),
  title text,
  title_ar text,
  scheduled_at timestamptz,
  duration_minutes int default 60,
  meeting_type text default 'video' check (meeting_type in ('video','voice','external')),
  -- LiveKit fields
  livekit_room_name text,
  -- External meeting (Zoom/Meet) — for reference only
  external_link text,
  -- Agenda & outcomes
  agenda text[],
  summary text,
  action_items text[],
  decisions text[],
  status text default 'upcoming' check (status in (
    'upcoming','ongoing','completed','cancelled'
  )),
  initiated_by uuid references profiles(id),
  created_at timestamptz default now()
);

-- =============================================
-- SECTION 11: FILES
-- =============================================

create table files (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id),
  name text,
  file_url text,
  file_type text check (file_type in (
    'contract','report','strategy','keyword_research',
    'content_draft','design','website_access','brand_asset',
    'competitor_analysis','meeting_record','other'
  )),
  file_size_bytes bigint,
  mime_type text,
  version int default 1,
  uploaded_by uuid references profiles(id),
  created_at timestamptz default now()
);

-- =============================================
-- SECTION 12: BILLING & CONTRACTS
-- =============================================

create table contracts (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id),
  title text,
  file_url text,
  status text default 'pending' check (status in ('pending','signed','expired')),
  signed_at timestamptz,
  created_at timestamptz default now()
);

create table subscription_plans (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id),
  plan_name text,           -- "Growth Plan", "Starter", "Enterprise"
  plan_name_ar text,
  services text[],          -- ['SEO', 'Content', 'Google Business']
  monthly_amount numeric,
  currency text default 'EGP',
  renewal_date date,
  status text default 'active' check (status in ('active','paused','cancelled')),
  created_at timestamptz default now()
);

create table invoices (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id),
  invoice_number text,
  amount numeric,
  currency text default 'EGP',
  description text,
  status text default 'pending' check (status in (
    'pending','paid','overdue','cancelled'
  )),
  due_date date,
  paid_at timestamptz,
  -- Payment gateway fields
  stripe_payment_intent_id text,
  paymob_order_id text,
  payment_link text,
  receipt_url text,
  created_at timestamptz default now()
);

-- =============================================
-- SECTION 13: SUPPORT
-- =============================================

create table support_tickets (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id),
  submitted_by uuid references profiles(id),
  title text,
  description text,
  ticket_type text check (ticket_type in (
    'bug','question','feature_request','urgent_call','training','other'
  )),
  priority text default 'normal' check (priority in ('normal','important','urgent')),
  status text default 'open' check (status in (
    'open','in_progress','waiting_client','resolved','closed'
  )),
  assigned_to uuid references profiles(id),
  resolved_at timestamptz,
  created_at timestamptz default now()
);

create table ticket_replies (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid references support_tickets(id),
  author_id uuid references profiles(id),
  content text,
  created_at timestamptz default now()
);

-- =============================================
-- SECTION 14: GAMIFICATION & ENGAGEMENT
-- =============================================

create table milestones (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id),
  milestone_type text check (milestone_type in (
    'page1_keyword','traffic_doubled','leads_100','first_invoice_paid',
    'stage_completed','90_days','partner_6_months','ai_visibility_first'
  )),
  title_ar text,
  title_en text,
  description_ar text,
  description_en text,
  achieved_at timestamptz default now(),
  seen_by_client boolean default false
);

create table satisfaction_surveys (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id),
  trigger_event text,
  score int check (score between 1 and 5),
  comment text,
  created_at timestamptz default now()
);

-- =============================================
-- SECTION 15: ACTIVITY & AI
-- =============================================

create table activity_feed (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id),
  actor_id uuid references profiles(id),
  action_ar text,  -- Arabic: "أكمل فريق SEO تحليل الكلمات المفتاحية"
  action_en text,
  entity_type text,
  entity_id uuid,
  created_at timestamptz default now()
);

create table ai_query_usage (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id),
  query_text text,
  response_text text,
  tokens_used int,
  created_at timestamptz default now()
);

-- =============================================
-- SECTION 16: ROW-LEVEL SECURITY
-- =============================================

-- Enable RLS on all tables
alter table profiles enable row level security;
alter table projects enable row level security;
alter table tasks enable row level security;
alter table results enable row level security;
alter table reports enable row level security;
alter table approvals enable row level security;
alter table messages enable row level security;
alter table campaigns enable row level security;
alter table invoices enable row level security;
alter table support_tickets enable row level security;
alter table milestones enable row level security;

-- Helper function: is this user an admin?
create or replace function is_admin()
returns boolean language sql security definer as $$
  select exists (
    select 1 from profiles where id = auth.uid() and team_role = 'admin'
  );
$$;

-- Helper function: is this user an account manager for this project?
create or replace function is_project_manager(p_project_id uuid)
returns boolean language sql security definer as $$
  select exists (
    select 1 from projects
    where id = p_project_id
      and account_manager_id = auth.uid()
  );
$$;

-- Helper function: is this user the client of this project?
create or replace function is_project_client(p_project_id uuid)
returns boolean language sql security definer as $$
  select exists (
    select 1 from projects
    where id = p_project_id
      and client_id = auth.uid()
  );
$$;

-- Projects policy
create policy "projects_select" on projects for select using (
  is_admin() or
  client_id = auth.uid() or
  account_manager_id = auth.uid() or
  exists (select 1 from profiles where id = auth.uid() and team_role is not null)
);

-- Tasks: clients see all tasks for their project, team sees assigned tasks
create policy "tasks_select" on tasks for select using (
  is_admin() or
  is_project_client(project_id) or
  is_project_manager(project_id) or
  assigned_to = auth.uid()
);

-- Only Moharek team can insert/update tasks (clients can insert requests only)
create policy "tasks_insert_team" on tasks for insert with check (
  is_admin() or
  is_project_manager(project_id) or
  -- Client can insert their own requests
  (is_project_client(project_id) and is_client_request = true)
);

-- Messages: only participants of the project's channel can read
create policy "messages_select" on messages for select using (
  exists (
    select 1 from chat_channels cc
    join projects p on p.id = cc.project_id
    where cc.id = channel_id
      and (p.client_id = auth.uid() or p.account_manager_id = auth.uid() or is_admin())
  )
);

-- Invoices: only the client and admin can see their invoices
create policy "invoices_select" on invoices for select using (
  is_admin() or is_project_client(project_id) or is_project_manager(project_id)
);
```

---

## Part C — All Features (Detailed)

---

## 5. Home Dashboard — Living & Personalized

### Layout (top to bottom)

**1. Welcome Card**

```dart
String greeting(String name, String goal, String locale) {
  final hour = DateTime.now().hour;
  if (locale == 'ar') {
    final timeAr = hour < 12 ? 'صباح الخير' : hour < 17 ? 'مساء الخير' : 'مساء النور';
    return '$timeAr، $name 👋\nهدفك: $goal';
  }
  final timeEn = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
  return '$timeEn, $name 👋\nYour goal: $goal';
}
```

**2. Growth Status Card (prominent)**

```
حالة المشروع الحالية
🟢 سير العمل منتظم      or      🟡 بانتظار موافقتك      or      🔴 متأخر
```

Status is derived from: if `tasks.status = 'waiting_client'` count > 0 → yellow. If any task is `delayed` → red. Otherwise → green.

**3. "New since your last visit" banner**
Appears only if there is new activity since `profiles.last_seen_at`:

- "تم إنجاز 3 مهام منذ آخر زيارة"
- "يوجد تقرير جديد جاهز"
- "عنصران ينتظران موافقتك"

**4. Quick Numbers (animated counters, Arabic digits in AR mode)**

- الزيارات العضوية + trend chip (↑ 34%)
- الكلمات المتصدرة
- العملاء المحتملون
- المهام المنجزة (done / total this month)
- نتيجة الصحة (Health Score gauge)

**5. 5 Engines Progress Section**

```
نظام النمو من البحث

محرك المحتوى        ████████░░  80%
محرك SEO            ███████░░░  70%
محرك الظهور AI      ████░░░░░░  40%
محرك الثقة          ██████░░░░  60%
محرك التحويل        █████░░░░░  50%
```

Data from `engine_progress` table. Tap any engine → goes to Strategy page, scrolled to that engine.

**6. Voice Update Card (if exists)**
If `voice_updates` has an unheard entry for today:

```
🎙️ رسالة صوتية من سارة — مديرة حسابك
[▶ استمع — 0:47]   [×]
```

On listen → mark `is_heard = true`.

**7. Latest Activity Feed**
Last 5 entries from `activity_feed`, realtime subscription:

```
اليوم
✅  فريق SEO أكمل تحليل الكلمات المفتاحية
📄  تم رفع تقرير مايو — اضغط لقراءته
⚠️  مطلوب موافقتك على مقال "زراعة الأسنان"
📞  تم جدولة اجتماع المراجعة — 30 مايو
```

**8. Quick Actions Row**

- عرض المهام
- المحادثة
- الموافقات (with badge count)
- طلب اجتماع

---

## 6. Strategy Page — 5 Engines

### A. Growth Strategy Summary

Display fields from the `projects` table in a clean card layout:

- **هدف المشروع** → `project_goal`
- **السوق المستهدف** → `target_market`
- **الجمهور المستهدف** → `target_audience`
- **الكلمات المفتاحية الأساسية** → from `keywords` table, top 10
- **المنافسون** → `competitors[]`
- **القنوات المستخدمة** → `channels[]` displayed as colored chips
- **الأولويات** → `priorities[]` as numbered list

### B. 5 Engines — Detailed View

Each engine is an expandable card:

```dart
class EngineCard extends StatelessWidget {
  final String engineName;
  final String engineNameAr;
  final IconData icon;
  final Color color;
  final int progressPercent;
  final String statusNotes;
  final List<String> subItems; // what's included in this engine

  // On tap: expand to show sub-items + status notes
}
```

**Engine sub-items (hardcoded, always shown):**

| Engine         | Sub-items (AR)                                                |
| -------------- | ------------------------------------------------------------- |
| محرك المحتوى   | مقالات · صفحات الخدمات · فيديوهات قصيرة · محتوى يدعم البحث    |
| محرك الظهور AI | الظهور في ChatGPT · Gemini · Perplexity · تحسين إجابات الذكاء |
| محرك SEO       | SEO التقني · SEO داخل الصفحة · الكلمات المفتاحية · المدونة    |
| محرك الثقة     | التقييمات · Google Business · السمعة · الدلائل                |
| محرك التحويل   | تحسين صفحات الهبوط · CTA · تتبع WhatsApp · نماذج الليدز       |

### C. 90-Day Roadmap

Animated milestone timeline pulled from `journey_stages`. Same widget as Journey screen but presented horizontally here.

---

## 7. Tasks + Client Requests

### Task List Screen

**Toggle:** List view / Kanban view (3 columns: قيد التنفيذ / بانتظار العميل / مكتمل)

**Filter chips:** الكل · SEO · محتوى · تقني · طلبات العميل · عاجل

**Task Card:**

```
[Category Chip] [Priority Badge]
عنوان المهمة
المسؤول: اسم الشخص      الموعد: ١٥ مايو ↑
[████████░░ 80%]
Status: قيد التنفيذ
```

**Task Detail Sheet:**

- Full description
- Progress bar (admin updates)
- Comments thread (team + client can comment)
- Attachments (view/download)
- Status history timeline
- Linked approval (if any)

### Client Request Form

Accessed via FAB "+" button on Tasks screen.

```dart
// Form fields:
// 1. نوع الطلب (dropdown):
//    تعديل محتوى / تقرير / صفحة جديدة / حملة SEO /
//    مشكلة في الموقع / طلب اجتماع / تحليل منافس / محتوى جديد
// 2. العنوان (text)
// 3. الوصف (multiline text)
// 4. درجة الأهمية (3 buttons: عادي / مهم / عاجل)
// 5. رفع ملفات (optional)
// 6. الموعد المقترح (date picker, optional)
```

On submit:

- Insert into `tasks` with `is_client_request = true`, `status = 'new'`
- Insert into `activity_feed`
- Send FCM to account manager: "طلب جديد من [client_name]: [title]"
- Show confirmation: "تم استلام طلبك وسيتم مراجعته من فريق محرك ✅"

---

## 8. Reports + Growth Story + AI Summary

### Report List

Cards showing: title_ar, report_type chip, period, status badge, highlight_stat.

### Growth Story Viewer (swipeable)

`PageView.builder` with 6 pages:

**Page 1 — Cover**

- Month + year in large Arabic text
- `highlight_stat` displayed huge: "زادت الزيارات ٤٧٪"
- `highlight_context`: "أفضل شهر منذ بداية التعاون"
- Animated confetti if > 30% improvement

**Page 2 — The Numbers**

- Key metrics as large cards with trend arrows
- All values from `results` for the report period

**Page 3 — Keywords Story**

- Table: keyword · الترتيب السابق · الترتيب الحالي · التغيير
- Top 5 movers highlighted in green
- Bottom 3 flagged in amber

**Page 4 — What We Built**

- Completed tasks this month: category chips + task titles
- Total: "X مهمة مكتملة هذا الشهر"

**Page 5 — From Your Manager**

- Account manager's avatar + name
- `manager_note` in a styled quote block
- Feel: personal, human, not automated

**Page 6 — What's Coming**

- `next_month_priorities[]` as a numbered list
- CTA: "وافق على خطة الشهر القادم →"

### AI Report Summary

Button on report list card: "🤖 ملخص ذكي"

```dart
Future<void> generateAISummary(String reportId) async {
  // 1. Check monthly quota
  final usageCount = await supabase
      .from('ai_query_usage')
      .select('id', const FetchOptions(count: CountOption.exact))
      .eq('project_id', projectId)
      .gte('created_at', firstDayOfMonth);

  if (usageCount >= 20) {
    showQuotaExceededSheet(); return;
  }

  // 2. Check cache (if summary generated today, return it)
  final report = await supabase.from('reports').select().eq('id', reportId).single();
  if (report['ai_summary'] != null &&
      report['ai_summary_generated_at'] != null &&
      DateTime.parse(report['ai_summary_generated_at']).isAfter(
        DateTime.now().subtract(const Duration(hours: 24)))) {
    showSummarySheet(report['ai_summary']); return;
  }

  // 3. Call Supabase Edge Function (which calls Anthropic API)
  final res = await supabase.functions.invoke('ai-report-summary', body: {
    'report_id': reportId,
    'project_id': projectId,
    'locale': userLocale,
  });

  // 4. Cache and display
  showSummarySheet(res.data['summary']);
}
```

**Supabase Edge Function — `ai-report-summary`:**

```typescript
import Anthropic from "@anthropic-ai/sdk";

Deno.serve(async (req) => {
  const { report_id, project_id, locale } = await req.json();
  const supabase = createClient(/* ... */);

  // Fetch report + results data
  const { data: report } = await supabase
    .from("reports")
    .select("*")
    .eq("id", report_id)
    .single();
  const { data: results } = await supabase
    .from("results")
    .select("*")
    .eq("project_id", project_id)
    .gte("recorded_at", report.period_start)
    .lte("recorded_at", report.period_end);

  const systemPrompt =
    locale === "ar"
      ? "أنت مساعد تحليلي لوكالة محرك. اعطِ ملخصاً موجزاً باللغة العربية يشمل: أهم نتيجة، أكبر تحدٍّ، أهم فرصة، المطلوب من العميل، خطة الشهر القادم. كن مباشراً وودوداً."
      : "You are an analytics assistant for Moharek agency. Provide a brief summary in English covering: top result, biggest challenge, best opportunity, what the client needs to do, next month plan. Be direct and friendly.";

  const client = new Anthropic();
  const message = await client.messages.create({
    model: "claude-sonnet-4-20250514",
    max_tokens: 500,
    system: systemPrompt,
    messages: [
      {
        role: "user",
        content: `Report: ${JSON.stringify(report)}\nResults: ${JSON.stringify(results)}`,
      },
    ],
  });

  const summary = message.content[0].text;

  // Cache in database
  await supabase
    .from("reports")
    .update({
      ai_summary: summary,
      ai_summary_generated_at: new Date().toISOString(),
    })
    .eq("id", report_id);

  // Log usage
  await supabase.from("ai_query_usage").insert({
    project_id,
    query_text: "report_summary",
    tokens_used: message.usage.input_tokens + message.usage.output_tokens,
  });

  return Response.json({ summary });
});
```

The AI summary displays in a bottom sheet with these labeled sections:

- 🏆 أهم نتيجة
- ⚠️ أكبر تحدٍّ
- 💡 أهم فرصة
- ✅ المطلوب منك
- 🗓️ خطة الشهر القادم

---

## 9. Approvals

**Status filters:** الكل · بانتظار موافقتك · تمت الموافقة · يحتاج تعديل

**Approval Card:**

- File thumbnail (image preview or PDF icon)
- Title + type chip + date
- Orange border if pending

**Approval Detail:**

- Full description
- File viewer (image full-screen or PDF using `syncfusion_flutter_pdfviewer`)
- Team notes in a styled block
- Four action buttons:
  - ✅ **موافقة** → status = 'approved', green
  - ✏️ **طلب تعديل** → shows text field for notes, status = 'needs_edit'
  - 💬 **تعليق** → adds to task_comments
  - ❌ **رفض** → status = 'rejected', shows reason field

On any action:

- Update `approvals` table
- Insert `activity_feed` entry
- Send FCM to account manager with action taken

---

## 10. Campaigns

**Campaign List:** Cards with channel chip (SEO / Ads / Content / AI), status badge, name, goal summary.

**Campaign Detail:**

- Goal + channel + dates + budget
- Status bar
- Results: metric cards for this campaign from `campaign_results`
- Quick chart: results over time

---

## 11. Chat — Realtime + Voice + Message→Task

### Architecture (MVP = 1 channel)

```
client project
  └── chat_channels (1 row: type='account_manager')
        └── messages (all messages)
```

### Chat Screen Features

- Realtime via `supabase.from('messages').stream()` with channel filter
- Message bubbles: text / image / voice / call-started card / system message
- Typing indicator via Supabase Realtime Broadcast
- Read receipts: update `is_read = true` on message load
- Unread count badge on bottom nav
- "Online" indicator via Supabase Presence

### Input Bar States

1. **Idle:** text field + mic button
2. **Typing:** text field + send button (mic hidden)
3. **Recording:** RecordingBar replaces entire input (live waveform + timer + slide-to-cancel)

### Convert Message to Task (Phase 3)

Long-press on a message → context menu → "حوّل إلى مهمة"
→ Opens task creation bottom sheet pre-filled with message content
→ On save: task created, `messages.converted_to_task = true`, message shows a task link card

### Call Initiation (from chat)

- Top-right of chat screen: phone icon + video icon
- Tap video → `CallService.startCall(callType: 'video')`
- Tap voice → `CallService.startCall(callType: 'voice')`
- System message auto-posted in chat: "📹 جلسة فيديو بدأت — الرابط: [join button]"
- Other party receives FCM incoming call notification → native call screen (CallKit / callkeep)

---

## 12. Files Center

**Category tabs:** العقود · التقارير · الاستراتيجية · الكلمات المفتاحية · المحتوى · التصاميم · البراند · التحليل · اجتماعات

**File card:** icon by mime type + name + uploader name + date + size

**Actions:**

- Tap → open (PDF viewer or full-screen image or `url_launcher` for other types)
- Long-press → download option
- Client can upload files (to `brand_asset` or `other` category)

---

## 13. Meetings + In-App Calls (LiveKit)

See full LiveKit implementation in original v2.1 plan — fully preserved here.

### Meeting Detail Screen

- Agenda items list
- Join button (if `status = 'upcoming'` and `scheduled_at` is within 15 minutes): launches LiveKit
- Post-meeting: summary + action items + "Tasks created from this meeting" section

### Request Meeting Form

- Preferred date/time (date + time pickers)
- Topic (text)
- Notes (optional)
  → Inserts into `meetings` with `status = 'upcoming'`
  → FCM to account manager

---

## 14. Billing & Subscription

### Current Plan Card

```
خطة النمو
خدمات: SEO · المحتوى · Google Business
تاريخ التجديد: ١ يونيو ٢٠٢٦
الحالة: ✅ فعّال
```

### Invoices List

Status chips: مدفوع (green) / معلق (amber) / متأخر (red)

### Payment Flow

1. Tap "ادفع الآن" on pending invoice
2. Call Supabase Edge Function `create-payment` → returns payment link (Paymob for Egypt) or Stripe PaymentIntent
3. For Paymob: `url_launcher` opens Paymob hosted checkout → webhook updates `invoices.status = 'paid'`
4. For Stripe: `flutter_stripe` native payment sheet
5. On success: show receipt screen, update invoice, send FCM confirmation, add to activity feed

---

## 15. Support / Help Center

### My Tickets List

Status filter: مفتوحة · قيد المعالجة · محلولة

### Open New Ticket Form

- النوع: bug / question / طلب ميزة / مكالمة عاجلة / تدريب
- العنوان + الوصف
- الأولوية: عادي / مهم / عاجل
  → Inserts into `support_tickets`
  → FCM to admin

### Ticket Detail

- Thread of replies between client and Moharek team
- Status updates shown as system messages

### FAQ Section

Hardcoded for MVP (no database needed):

- كيف أقرأ تقرير SEO؟
- متى تظهر النتائج؟
- كيف أوافق على محتوى؟
- كيف أطلب اجتماعاً؟
- ما الفرق بين المهام وطلبات العميل؟

---

## 16. AI Assistant

Floating action button on Home Dashboard (bottom right, secondary FAB): 🤖

**Chat interface:**

- Appears as a bottom sheet with a mini chat UI
- Shows last 3 exchanges in session
- Input field + send button

**What it can answer:**

- "ما الذي حدث هذا الشهر؟" → queries activity_feed + results + tasks
- "ما أفضل الكلمات المفتاحية لديّ؟" → queries keywords table
- "ما الذي يحتاج موافقتي؟" → queries approvals
- "متى موعد اجتماعنا القادم؟" → queries meetings
- "كيف أداء الإعلانات؟" → queries results where type='ads'

**Supabase Edge Function — `ai-assistant`:**

```typescript
Deno.serve(async (req) => {
  const { question, project_id, locale, conversation_history } =
    await req.json();

  // Gather context from database
  const [tasks, results, approvals, meetings, keywords] = await Promise.all([
    supabase
      .from("tasks")
      .select("title,status,category,deadline")
      .eq("project_id", project_id)
      .limit(20),
    supabase
      .from("results")
      .select("metric_label,metric_value,result_type,recorded_at")
      .eq("project_id", project_id)
      .order("recorded_at", { ascending: false })
      .limit(30),
    supabase
      .from("approvals")
      .select("title,status")
      .eq("project_id", project_id)
      .eq("status", "pending"),
    supabase
      .from("meetings")
      .select("title,scheduled_at,status")
      .eq("project_id", project_id)
      .eq("status", "upcoming")
      .limit(3),
    supabase
      .from("keywords")
      .select("keyword,current_position,previous_position")
      .eq("project_id", project_id)
      .order("current_position")
      .limit(10),
  ]);

  const context = `
    Project data:
    Tasks: ${JSON.stringify(tasks.data)}
    Results: ${JSON.stringify(results.data)}
    Pending Approvals: ${JSON.stringify(approvals.data)}
    Upcoming Meetings: ${JSON.stringify(meetings.data)}
    Top Keywords: ${JSON.stringify(keywords.data)}
  `;

  const systemPrompt =
    locale === "ar"
      ? `أنت مساعد ذكي لعميل وكالة محرك للنمو الرقمي. تجيب بالعربية فقط. 
       استخدم البيانات المتاحة للإجابة بدقة. كن ودوداً ومباشراً. 
       لا تختلق معلومات غير موجودة في البيانات.
       حافظ على ردود قصيرة (2-4 جمل).`
      : `You are an AI assistant for a Moharek Growth client. Answer in English only. 
       Use the provided data accurately. Be friendly and direct. 
       Never invent data not present. Keep responses short (2-4 sentences).`;

  const client = new Anthropic();
  const response = await client.messages.create({
    model: "claude-sonnet-4-20250514",
    max_tokens: 300,
    system: systemPrompt,
    messages: [
      ...conversation_history,
      {
        role: "user",
        content: `Context:\n${context}\n\nQuestion: ${question}`,
      },
    ],
  });

  // Log usage
  await supabase.from("ai_query_usage").insert({
    project_id,
    query_text: question,
    tokens_used: response.usage.input_tokens + response.usage.output_tokens,
  });

  return Response.json({ answer: response.content[0].text });
});
```

**Rate limiting display:**
Small text under input field: "الاستفسارات المتبقية هذا الشهر: ١٧/٢٠"

---

## 17. Milestones & Celebrations

See full implementation in v2.1 — fully preserved.

**Milestone types (updated with new spec):**

- `page1_keyword` — كلمة مفتاحية في الصفحة الأولى
- `traffic_doubled` — تضاعفت الزيارات
- `leads_100` — ١٠٠ عميل محتمل
- `first_invoice_paid` — أول دفعة
- `stage_completed` — مرحلة مكتملة
- `90_days` — ٩٠ يوماً معاً
- `partner_6_months` — ٦ أشهر شراكة
- `ai_visibility_first` — أول ظهور في ChatGPT

---

## 18. Client Health Score

See full formula in v2.1 — fully preserved. Score saved to `projects.health_score` and `projects.health_label` daily via `pg_cron`.

---

## 19. NPS & Satisfaction

See full implementation in v2.1 — fully preserved.

---

## 20. Smart Notifications

See bilingual template system in v2.1 — fully preserved, updated with new event types:

| Event                         | FCM trigger          |
| ----------------------------- | -------------------- |
| Client request received       | → to account manager |
| Approval responded            | → to account manager |
| New support ticket            | → to admin           |
| Ticket reply                  | → to client          |
| Invoice paid                  | → to admin + client  |
| AI quota running low (5 left) | → to client          |
| Voice update posted           | → to client          |
| New campaign result           | → to client          |

---

## 21. Full Arabic Support — Default Language

See complete implementation in v2.1 — fully preserved including:

- Cairo font setup
- Full ARB files (app_ar.arb + app_en.arb)
- RTL layout rules
- ArabicFormatter (numbers, dates, currency)
- Language switcher
- Admin panel Arabic fields
- Notification Arabic copy
- RTL testing checklist

---

## 22. Voice Messages in Chat

See complete implementation in v2.1 — fully preserved including:

- `VoiceRecorderService` (using `record` package)
- `VoiceUploadService` (Supabase Storage)
- `VoiceRecordButton` (hold to record, slide to cancel — RTL-aware)
- `RecordingBar` (live waveform + timer)
- `VoiceMessageBubble` (playback with waveform)
- iOS/Android permissions
- Supabase Storage bucket + RLS

---

## 23. Onboarding — First Day Experience

### Updated flow (now includes data collection)

**Screen 1 — Welcome Moment** (unchanged from v2.1)

**Screen 2 — Meet Your Team** (unchanged from v2.1)

**Screen 3 — Your Goal**
"ما هو هدفك الأول لهذا العام؟"

- زيادة العملاء المحتملين
- تقوية الحضور الرقمي
- زيادة المبيعات
- تحسين ترتيب الموقع
  → saves to `profiles.client_goal`

**Screen 4 — Share Your Basics (new — from spec)**
"نحتاج منك بعض المعلومات للبدء"

```
رابط موقعك:          [text field]
رابط Google Business: [text field]
أهم خدماتك:          [multi-select chips]
روابط التواصل:        [Instagram / Facebook / TikTok fields]
ملاحظات إضافية:       [optional text area]
```

→ Saves to `onboarding_data` table
→ FCM to account manager: "العميل [name] أكمل الإعداد — راجع البيانات"

**Screen 5 — Your 90-Day Roadmap** (unchanged from v2.1)

**Screen 6 — You're Ready**
"أنت جاهز 🚀"
"فريقك يعمل الآن على خطتك. ستبدأ أول تحديثات خلال 48 ساعة."
[ابدأ رحلتك]

---

## 24. UX System — Design Tokens & Patterns

### Colors

```dart
class AppColors {
  static const background   = Color(0xFF0F172A);  // Deep midnight
  static const card         = Color(0xFF1E293B);  // Card surface
  static const primaryGreen = Color(0xFF4CAF50);  // Success, CTAs
  static const primaryBlue  = Color(0xFF2196F3);  // Info, links
  static const amber        = Color(0xFFFFC107);  // Waiting / caution
  static const red          = Color(0xFFF44336);  // Error / delayed
  static const textPrimary  = Color(0xFFFFFFFF);
  static const textSecondary= Color(0xFF94A3B8);
  static const divider      = Color(0xFF334155);

  // Engine colors
  static const engineContent    = Color(0xFF8B5CF6); // Purple
  static const engineAI         = Color(0xFF06B6D4); // Cyan
  static const engineSEO        = Color(0xFF4CAF50); // Green
  static const engineTrust      = Color(0xFFF59E0B); // Amber
  static const engineConversion = Color(0xFFEF4444); // Red
}
```

### Typography (Cairo)

```dart
// Line height 1.8 for all Arabic text
// Letter spacing: 0 (Arabic doesn't use letter spacing)
// Font weights used: 400 (body), 600 (label), 700 (headline)
```

### Status badge colors

| Status         | Color  | Arabic label     |
| -------------- | ------ | ---------------- |
| new            | Blue   | جديد             |
| in_progress    | Blue   | قيد التنفيذ      |
| waiting_client | Amber  | بانتظار العميل   |
| under_review   | Purple | قيد المراجعة     |
| done           | Green  | مكتمل            |
| delayed        | Red    | متأخر            |
| pending        | Amber  | بانتظار الموافقة |
| approved       | Green  | تمت الموافقة     |
| needs_edit     | Orange | يحتاج تعديل      |
| rejected       | Red    | مرفوض            |

### Loading states

Every screen that fetches data MUST show Shimmer skeleton. Never blank screen, never spinner alone.

### Empty states

Each list has a custom empty state widget with illustration + Arabic message:

```dart
class EmptyStateWidget extends StatelessWidget {
  final String messageAr;
  final String messageEn;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabelAr;
}
```

### Haptic feedback map

| Action                     | Haptic             |
| -------------------------- | ------------------ |
| Approve item               | `mediumImpact()`   |
| Send message               | `lightImpact()`    |
| Milestone celebration      | `heavyImpact()`    |
| End call                   | `heavyImpact()`    |
| Pull-to-refresh complete   | `lightImpact()`    |
| Task status changed        | `selectionClick()` |
| Long-press to record voice | `mediumImpact()`   |

---

## Part D — Admin Web Panel

---

## 25. Admin Panel — Complete Feature Set

Built as Flutter Web, same codebase (separate flavor/route), deployed free on Vercel.

### Navigation (sidebar)

- 👥 العملاء (Clients)
- 📊 لوحة التحكم (Overview)
- 📋 المهام (All Tasks)
- 📈 النتائج (Results Input)
- 📄 التقارير (Reports Manager)
- ✅ الموافقات (Approvals Manager)
- 📁 الملفات (Files)
- 📅 الاجتماعات (Meetings)
- 💰 الفواتير (Financials)
- 🎧 الدعم (Support Tickets)
- 🔔 الإشعارات (Notifications)

### Client Hub (إدارة عميل)

When an admin/account_manager selects a client, they see a 10-tab interface:

| Tab                   | What the admin does here                                                                                                       |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| **النظرة العامة**     | Client health score, recent activity, quick stats                                                                              |
| **الاستراتيجية**      | Edit project goal, target market, competitors, priorities. Update 5 Engines progress sliders. Write stage descriptions.        |
| **المهام**            | Kanban board (appflowy_board). Create tasks, assign to team members, update status, add comments.                              |
| **النتائج**           | Form to log metrics: select type (SEO/Ads/AI/Trust/Conversion), metric label, value, date. These feed the client's charts.     |
| **التقارير**          | Upload PDF → Supabase Storage. Write Arabic title, highlight stat, manager note, next month priorities. Set status to 'ready'. |
| **الموافقات**         | Create new approval: type, description, upload file, team notes. Client sees it immediately.                                   |
| **الحملات**           | Create/edit campaigns with goals, channel, dates, budget. Log campaign results.                                                |
| **الملفات**           | Upload files to any category. Client can view/download immediately.                                                            |
| **الفواتير**          | Create invoice (amount, due date, description). Generate payment link. Mark as paid manually if needed.                        |
| **التحديثات الصوتية** | Record a voice update (web audio recording) for the client. Appears on client's home dashboard.                                |

### Global Notifications Center

- Select client(s) or "All Clients"
- Write notification title + body (Arabic)
- Schedule or send now
- View notification history + open rates

### Results Input (Critical — client charts depend on this)

```dart
// The admin sees a form for each project:
// Select result_type → select metric_label (dropdown with suggestions) → enter value → date

// Metric suggestions by type:
// SEO: Organic Traffic, Clicks, Impressions, CTR, Indexed Pages, Technical Score
// Ads: Spend, Leads, Cost Per Lead, ROAS, Conversion Rate
// AI Visibility: ChatGPT Score, Gemini Score, Perplexity Score, Overall AI Score
// Trust: Rating, Review Count, Brand Mentions, Reputation Score
// Conversion: Conversion Rate, Lead Form Submissions, WhatsApp Clicks
```

---

## Part E — Build Plan

---

## 26. Implementation Phases — 12 Weeks

### Phase 1 — Foundation (Days 1–7) [COMPLETED]

**Goal:** Running app, auth, core navigation, database up.

- [x] Flutter project setup with folder structure
- [x] Supabase project: run full schema v3.0
- [x] Enable RLS with all policies
- [x] Supabase Storage buckets: `reports`, `approvals`, `voice-messages`, `files`, `avatars`
- [x] GoRouter setup with routes for all screens (placeholder screens OK)
- [x] Riverpod setup with `SupabaseClient` provider
- [x] Login screen + auth flow + role-based routing (client → mobile app, team/admin → web panel redirect)
- [x] Bottom navigation with `StatefulShellRoute` (5 tabs)
- [x] Dark theme + Cairo font applied globally
- [x] Arabic locale set as default + `LocaleNotifier` + language switcher skeleton
- [x] All ARB files created (`app_ar.arb`, `app_en.arb`)
- [x] `AppColors`, `AppTextStyles`, `AppSpacing` constants

### Phase 2 — Core Screens (Days 8–21) [COMPLETED]

**Goal:** Client can see real data. Admin can input data.

- [x] Home Dashboard (complete with all sections)
- [x] Strategy Page (summary + 5 engines with progress bars)
- [x] Tasks list + filter + Task Detail sheet
- [x] Client Request Form
- [x] Results Screen (4 tabs: SEO, Ads, AI, Trust)
- [x] Reports list + Growth Story PageView
- [x] Approvals list + Approval Detail with actions
- [x] Admin Panel: Client list + Client Hub (all 10 tabs)
- [x] Admin: Results input form → feeds client charts
- [x] Admin: Task Kanban board
- [x] Admin: Report upload form with all fields
- [x] Admin: 5 Engines progress sliders
- [x] Skeleton loading screens for all data-heavy screens
- [x] Empty states for all lists

### Phase 3 — Arabic & Voice (Days 22–28) [COMPLETED]

**Goal:** Full Arabic RTL. Voice messages in chat.

- [x] Wire all `l10n.key` references (replace every hardcoded Arabic string)
- [x] `ArabicFormatter` utility integrated in all number/date/currency displays
- [x] RTL testing checklist — run on physical device
- [x] Chat screen with Supabase Realtime
- [x] `VoiceRecorderService` + `VoiceUploadService`
- [x] `VoiceRecordButton` + `RecordingBar` + `VoiceMessageBubble`
- [x] RTL slide-to-cancel for voice (right = cancel in Arabic)
- [x] Image sending in chat (pick + upload to Storage)
- [x] Unread message badge on bottom nav

### Phase 4 — Calls + Notifications (Days 29–42) [COMPLETED]

**Goal:** In-app video/voice calls. Push notifications working.

- [x] LiveKit Edge Function (`livekit-token`)
- [x] `CallService` class
- [x] `ActiveCallScreen` (video tiles, controls)
- [x] `callkeep` integration (iOS CallKit + Android ConnectionService)
- [x] FCM setup (Firebase project + `firebase_messaging`)
- [x] FCM token registration on app launch → save to `fcm_tokens`
- [x] `send-smart-notification` Edge Function with bilingual templates
- [x] Database triggers for: new report, new approval, task waiting client, milestone, call incoming
- [x] Notification preferences screen (toggles by category)
- [x] Voice update: admin records (web) → appears on client home
- [x] Test calls on physical iOS + Android devices

### Phase 5 — Onboarding + AI Features (Days 43–56) [COMPLETED]

**Goal:** First login experience. AI assistant. AI report summary.

- [x] 6-screen onboarding flow (welcome, team, goal, data collection, roadmap, ready)
- [x] Onboarding guard: check `onboarding_completed` on every app open
- [x] `onboarding_data` save + FCM to account manager
- [x] `ai-report-summary` Edge Function
- [x] AI summary bottom sheet in Reports screen
- [x] AI usage rate limiter (20/month check)
- [x] Usage counter display
- [x] `ai-assistant` Edge Function
- [x] AI Assistant floating button + bottom sheet chat UI
- [x] Response caching logic

### Phase 6 — Remaining Screens + Billing (Days 57–70) [COMPLETED]

**Goal:** Complete app. All screens functional.

- [x] Campaigns list + detail + results charts
- [x] Files Center (categories, upload, viewer)
- [x] Meetings screen (upcoming, past, request form, action items)
- [x] LiveKit join from meetings screen
- [x] Billing: current plan card + invoice list
- [x] Payment flow (Paymob for Egypt / Stripe for international) - Integrated as secure payment links
- [x] Support: ticket form + list + replies + FAQ
- [x] Admin: voice update recording (web audio)
- [x] Admin: notifications center (send to one/all clients)
      0

### Phase 7 — Engagement + Polish (Days 71–84) [COMPLETED]

**Goal:** Milestones, health score, NPS, final polish.

- [x] Milestones table + `pg_cron` daily check
- [x] `confetti` package + `MilestoneOverlay` widget
- [x] Health Score formula → saved to `projects` daily
- [x] Health Score gauge widget on home
- [x] NPS survey bottom sheet + timing logic
- [x] Activity Feed with animated entries
- [x] Animated metric counters on dashboard
- [x] "New since last visit" banner
- [x] Haptic feedback — all mapped actions
- [x] Offline detection banner
- [x] Pull-to-refresh on all list screens
- [x] App icon (iOS + Android) - Configured in pubspec
- [x] Splash screen (animated logo) - Configured in pubspec
- [x] Full RTL final testing pass

---

## 27. Complete Package List

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # Backend
  supabase_flutter: ^2.5.0

  # State & Routing
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0
  go_router: ^14.0.0

  # Typography
  google_fonts: ^6.2.0 # Cairo font

  # Charts & Visualization
  fl_chart: ^0.68.0 # SEO/Ads charts

  # PDF
  syncfusion_flutter_pdfviewer: ^25.0.0

  # In-App Video/Voice Calls
  livekit_client: ^2.2.0
  flutter_webrtc: ^0.10.0
  callkeep: ^4.0.0

  # Push Notifications
  firebase_messaging: ^14.9.0
  firebase_core: ^3.6.0
  flutter_local_notifications: ^17.2.0

  # Voice Messages
  record: ^5.1.0 # Recording
  just_audio: ^0.9.36 # Playback
  audio_waveforms: ^1.0.5 # Waveform visualization

  # Payments
  flutter_stripe: ^10.2.0 # Stripe (international)
  # Paymob: use url_launcher to open hosted checkout

  # File Handling
  image_picker: ^1.1.0
  file_picker: ^8.1.0
  path_provider: ^2.1.0
  url_launcher: ^6.3.0
  cached_network_image: ^3.4.0

  # UX
  confetti: ^0.7.0
  particles_flutter: ^0.1.0
  shimmer: ^3.0.0
  connectivity_plus: ^6.0.0
  permission_handler: ^11.3.0
  shared_preferences: ^2.3.0 # Persist locale
  haptic_feedback: ^0.0.1

  # Admin Panel Only
  appflowy_board: ^0.1.0 # Kanban

  # Utilities
  intl: ^0.19.0
  collection: ^1.18.0
  equatable: ^2.0.5
  json_annotation: ^4.9.0
  uuid: ^4.4.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  riverpod_generator: ^2.4.0
  build_runner: ^2.4.0
  json_serializable: ^6.8.0
  flutter_lints: ^4.0.0
```

---

## 28. Cost Breakdown

### Monthly costs (at launch, 0–30 clients)

| Service             | Cost            | Notes                                                    |
| ------------------- | --------------- | -------------------------------------------------------- |
| Supabase Free       | **$0**          | 500MB DB, 1GB storage, 50K MAU, 200 realtime connections |
| Firebase FCM        | **$0**          | Unlimited push notifications                             |
| LiveKit Cloud Free  | **$0**          | 10,000 participant-minutes/month                         |
| Vercel (admin web)  | **$0**          | Free for Flutter Web builds                              |
| Anthropic API (AI)  | **~$1–5**       | Depends on query volume, cached aggressively             |
| Apple Developer     | **$99/year**    | Required for iOS App Store + TestFlight                  |
| Google Play         | **$25 once**    | One-time fee                                             |
| **Total (ongoing)** | **~$1–5/month** |                                                          |

### When to upgrade (trigger-based)

| Trigger                                         | Action                            | New cost                 |
| ----------------------------------------------- | --------------------------------- | ------------------------ |
| > 200 realtime connections (40+ active clients) | Upgrade Supabase Pro              | +$25/mo                  |
| > 500MB DB                                      | Included in Pro                   | —                        |
| > 10,000 call minutes/month                     | LiveKit paid or self-host         | +$0.02/min or +$6/mo VPS |
| > 1GB file storage                              | Included in Supabase Pro          | —                        |
| > 50 clients using AI (~1000 queries/month)     | Monitor Anthropic costs           | ~$3/mo                   |
| > 50K MAU                                       | Supabase Pro already handles this | —                        |

### Revenue context

If Moharek charges clients $500–2000/month, even at $30/month infrastructure cost the margin is exceptional. The Apple Developer account ($99/year) is the biggest upfront cost.

---

## 29. What to Build vs What to Skip in MVP

### ✅ Build in MVP (Phases 1–4, first 6 weeks)

- Login + auth + role routing
- Home Dashboard (real data)
- Strategy page + 5 Engines tracker
- Tasks list + Client Request form
- Results screen (4 tabs)
- Reports list + Growth Story viewer
- Approvals (view + approve/reject)
- Chat (text + voice messages)
- In-app video/voice calls (LiveKit)
- Push notifications (core events only)
- Full Arabic support
- Admin panel: Client Hub (all 10 tabs)
- Admin panel: Kanban + Results input + Report upload

### ⏳ Build in Phase 2 (weeks 7–10)

- AI Report Summary
- AI Assistant
- Milestones + celebrations
- Health Score
- Onboarding flow
- Campaigns page
- Files Center
- Meetings screen
- Billing + payments
- Voice updates from account manager

### 🚫 Skip for now (Phase 3+, after launch)

- Multi-user per client company (Owner/Manager/Finance roles)
- Multi-channel chat (SEO team / Content team channels)
- Google Search Console integration
- Google Analytics integration
- Google Business Profile integration
- "Convert message to Task" feature
- In-app contract e-signing
- Looker Studio integration
- WhatsApp integration
- Support ticket system (use chat for now)
- AI transcript of meetings

---

_Moharek Growth Hub — Master Plan v3.0_
_Supersedes: v2.1 improvement plan + v1.6.0 base spec_
_All previous sections incorporated, updated, and extended._
_Ready for AI agent implementation — each phase is self-contained._
ok coantine but make a Implementation Plan first
