# Phase 4 — Web Dashboard Reconciliation Note

**Read this BEFORE reading `moharek_phase4_web_dashboards.md`**
**For the AI agent: this explains exactly what already exists and what is new**

---

## What the Master Plan (v3.0) Already Had

Section 25 of `moharek_growth_hub_master_plan.md` already described a single admin web panel with:

- One sidebar navigation (11 items)
- One login → both `admin` and `account_manager` roles land on the SAME panel
- A 10-tab **Client Hub** (the core client management screen)
- Results input form, Kanban tasks board, report upload, approvals, voice updates
- Global notifications center
- Flutter Web, deployed on Vercel (free)

**That section describes WHAT the panel does — not HOW it is structured internally, and not the split between admin and AM.**

---

## What Phase 4 Changes and Adds

Phase 4 does NOT replace the Client Hub or any of its 10 tabs. It reorganizes WHO sees WHAT and adds new admin-only capabilities.

### Change 1 — Split one panel into two separate shells

**Before (master plan v3.0):**

```
Login → admin OR account_manager → same dashboard UI
```

**After (Phase 4):**

```
Login → admin           → AdminShell  → /admin/* routes
Login → account_manager → AmShell     → /am/*    routes
```

Same Flutter Web project. Same Vercel deployment. Same login screen.
Only the shell layout and available routes differ based on `profiles.team_role`.

The **GoRouter** from Phase 4 replaces the basic role redirect that was implied in the master plan. Use the GoRouter code from `moharek_phase4_web_dashboards.md` — it is more complete.

---

### Change 2 — The 10-tab Client Hub becomes `SharedClientHubScreen`

The 10-tab Client Hub from master plan Section 25 is preserved 100% — same tabs, same content. It is now called `SharedClientHubScreen` and accepts an `isAdmin` boolean flag.

```
isAdmin = true  → /admin/clients/:projectId  → shows extra controls (reassign AM, pause project)
isAdmin = false → /am/clients/:projectId     → same 10 tabs, no admin controls
```

**Do not rebuild the Client Hub. Wrap the existing one in `SharedClientHubScreen` and add the `isAdmin` flag.**

---

### Change 3 — Admin gets 3 new screens that did not exist before

These are 100% new — not in the master plan at all:

| New Screen     | Path                | What it does                                   |
| -------------- | ------------------- | ---------------------------------------------- |
| Admin Overview | `/admin/overview`   | KPI cards + AM performance table + alerts      |
| Admin Team     | `/admin/team`       | Create/manage AM accounts, view all AMs        |
| AM Detail      | `/admin/team/:amId` | One AM's profile + their clients + performance |

The existing screens from master plan Section 25 map to these admin routes:

| Master plan section  | Phase 4 route                      |
| -------------------- | ---------------------------------- |
| Clients list         | `/admin/clients`                   |
| Client Hub (10 tabs) | `/admin/clients/:projectId`        |
| Reports manager      | tab inside Client Hub              |
| Approvals manager    | tab inside Client Hub              |
| Files                | tab inside Client Hub              |
| Financials           | tab inside Client Hub              |
| Notifications        | `/admin/settings` or global button |
| Support tickets      | tab inside Client Hub              |

---

### Change 4 — Account Manager gets a dedicated dashboard

AM did not have a separate dashboard before. They shared the admin panel.

AM now has their own shell with these routes — all data is filtered to their assigned clients automatically by RLS:

| AM Screen     | Path                     | What it does                               |
| ------------- | ------------------------ | ------------------------------------------ |
| My Clients    | `/am/clients`            | Card grid of only their clients            |
| Client Hub    | `/am/clients/:projectId` | Same 10-tab hub, no admin controls         |
| All Tasks     | `/am/tasks`              | All tasks across all their clients         |
| All Approvals | `/am/approvals`          | All pending approvals across their clients |
| All Reports   | `/am/reports`            | Their clients' reports                     |
| Chat          | `/am/chat`               | All client conversations                   |
| Calendar      | `/am/calendar`           | All meetings                               |

---

### Change 5 — New database tables (add these, do not change existing ones)

These tables did not exist in the master plan schema. Run them in Supabase:

```sql
-- AM performance metrics (auto-updated by pg_cron daily)
create table am_performance (
  id uuid primary key default gen_random_uuid(),
  am_id uuid references profiles(id),
  period_month date,
  total_clients int default 0,
  active_clients int default 0,
  avg_client_health_score numeric default 0,
  tasks_created int default 0,
  tasks_completed int default 0,
  reports_uploaded int default 0,
  approvals_created int default 0,
  avg_response_time_hours numeric default 0,
  client_satisfaction_avg numeric default 0,
  updated_at timestamptz default now(),
  unique(am_id, period_month)
);

-- Invitation tracking
create table invitations (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  invited_role text check (invited_role in ('account_manager','client')),
  invited_by uuid references profiles(id),
  project_id uuid references projects(id),
  assigned_am_id uuid references profiles(id),
  status text default 'pending' check (status in ('pending','accepted','expired')),
  token text unique default gen_random_uuid()::text,
  expires_at timestamptz default now() + interval '7 days',
  accepted_at timestamptz,
  created_at timestamptz default now()
);

-- Admin audit log
create table admin_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references profiles(id),
  action text,
  target_type text,
  target_id uuid,
  metadata jsonb,
  created_at timestamptz default now()
);
```

### Change 6 — New columns on existing tables (ALTER, not recreate)

```sql
-- profiles: track who created the account, whether it's active, admin notes
alter table profiles add column if not exists created_by uuid references profiles(id);
alter table profiles add column if not exists is_active boolean default true;
alter table profiles add column if not exists notes text;

-- projects: track AM assignment history
alter table projects add column if not exists previous_am_ids uuid[] default '{}';
alter table projects add column if not exists am_assigned_at timestamptz;
```

### Change 7 — New RLS policies (add to existing RLS, do not replace)

The master plan already has RLS. Add these on top:

```sql
-- AM can only see/update their own projects (master plan had admin access only)
create policy "am_sees_own_projects" on projects for select using (
  account_manager_id = auth.uid() or
  exists (select 1 from profiles where id = auth.uid() and team_role = 'admin')
);

create policy "am_updates_own_projects" on projects for update using (
  account_manager_id = auth.uid() or
  exists (select 1 from profiles where id = auth.uid() and team_role = 'admin')
);

-- AM performance: AM sees own row, admin sees all
alter table am_performance enable row level security;
create policy "am_performance_select" on am_performance for select using (
  am_id = auth.uid() or
  exists (select 1 from profiles where id = auth.uid() and team_role = 'admin')
);

-- Admin logs: admin only
alter table admin_logs enable row level security;
create policy "admin_logs_admin_only" on admin_logs for all using (
  exists (select 1 from profiles where id = auth.uid() and team_role = 'admin')
);

-- Invitations: admin only
alter table invitations enable row level security;
create policy "invitations_admin_only" on invitations for all using (
  exists (select 1 from profiles where id = auth.uid() and team_role = 'admin')
);
```

### Change 8 — pg_cron job for AM performance (new, not in master plan)

Enable pg_cron in Supabase Dashboard → Extensions → pg_cron, then run:

```sql
select cron.schedule('update-am-performance', '0 1 * * *', $$
  insert into am_performance (am_id, period_month, total_clients, active_clients, avg_client_health_score, tasks_created, tasks_completed, reports_uploaded, approvals_created)
  select
    p.account_manager_id,
    date_trunc('month', current_date)::date,
    count(*),
    count(*) filter (where p.status = 'active'),
    coalesce(avg(p.health_score), 0),
    (select count(*) from tasks t where t.project_id = any(array_agg(p.id)) and date_trunc('month', t.created_at) = date_trunc('month', current_date)),
    (select count(*) from tasks t where t.project_id = any(array_agg(p.id)) and t.status = 'done' and date_trunc('month', t.updated_at) = date_trunc('month', current_date)),
    (select count(*) from reports r where r.project_id = any(array_agg(p.id)) and date_trunc('month', r.created_at) = date_trunc('month', current_date)),
    (select count(*) from approvals a where a.project_id = any(array_agg(p.id)) and date_trunc('month', a.created_at) = date_trunc('month', current_date))
  from projects p
  where p.account_manager_id is not null
  group by p.account_manager_id
  on conflict (am_id, period_month) do update set
    total_clients = excluded.total_clients,
    active_clients = excluded.active_clients,
    avg_client_health_score = excluded.avg_client_health_score,
    tasks_created = excluded.tasks_created,
    tasks_completed = excluded.tasks_completed,
    reports_uploaded = excluded.reports_uploaded,
    approvals_created = excluded.approvals_created,
    updated_at = now();
$$);
```

---

## Summary for the AI Agent — What to Do

```
1. KEEP everything from master plan Section 25 (Client Hub 10 tabs, all tab content)

2. RENAME the existing admin panel shell to AdminShell
   — Add AdminSidebar with routes: /admin/overview, /admin/team, /admin/clients, /admin/reports, /admin/billing, /admin/logs, /admin/settings

3. ADD 3 new admin screens:
   — AdminOverviewScreen  (/admin/overview)
   — AdminTeamScreen      (/admin/team)
   — AdminAmDetailScreen  (/admin/team/:amId)

4. WRAP existing Client Hub in SharedClientHubScreen(isAdmin: bool)
   — /admin/clients/:projectId → isAdmin: true  (shows reassign + pause controls)
   — /am/clients/:projectId   → isAdmin: false  (no extra controls)

5. BUILD new AmShell with sidebar: /am/clients, /am/tasks, /am/approvals, /am/reports, /am/chat, /am/calendar

6. BUILD 5 AM screens:
   — AmClientsScreen    (/am/clients)      — only their clients, card grid
   — AmTasksScreen      (/am/tasks)        — all tasks across their clients
   — AmApprovalsScreen  (/am/approvals)    — all pending approvals
   — AmReportsScreen    (/am/reports)      — their clients' reports
   — AmChatScreen       (/am/chat)         — all conversations

7. REPLACE the GoRouter from master plan with the one in Phase 4 file
   — It handles admin vs AM routing correctly

8. RUN the 3 new SQL tables + 2 ALTER statements in Supabase

9. ADD the 5 new RLS policies

10. ENABLE pg_cron + run the AM performance cron job SQL

11. The invitation flow (admin creates AM/client accounts):
    — Use Supabase Edge Function to call auth.admin.inviteUserByEmail()
    — NEVER put service role key in Flutter client code
```

---

## What Does NOT Change

- The 10-tab Client Hub content (النظرة العامة, الاستراتيجية, المهام, النتائج, التقارير, الموافقات, الحملات, الملفات, الفواتير, التحديثات الصوتية)
- All Riverpod providers for client data
- All Supabase queries for tasks, results, reports, approvals, campaigns, files
- The Vercel deployment (same build, same URL)
- The login screen
- The design tokens (colors, fonts, dark theme)
- All existing DB tables and columns (only additions, no changes)
