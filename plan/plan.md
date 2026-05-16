Here's your complete technical blueprint — I'll give you the architecture diagram first, then the full phased plan you can send directly to an AI agent.Now here's the full phased plan — copy this entire thing and send it to your AI agent:

---

## 🚀 Moharek Client Portal App — Complete Build Plan

### Tech Stack (Zero Monthly Cost)

**Flutter** — single codebase for iOS + Android + Web (admin panel)
**Supabase** (free tier) — PostgreSQL database, Auth, Realtime, Storage, Edge Functions, Row-Level Security
**Firebase Cloud Messaging** — push notifications (free, unlimited)
**Jitsi Meet Flutter SDK** — video + voice calls (100% free, open source)
**Stripe** or **Paymob** — payments (no monthly fee, only per-transaction %)
**Native modules** — only for call notifications background (CallKit on iOS, ConnectionService on Android)

---

## Phase 1 — Foundation & Auth (Week 1–2)

**Goal:** Project setup, Supabase schema, authentication, role system.

**Tasks for AI agent:**

1. Create a Flutter project with the following folder structure:

```
lib/
  core/         (theme, router, constants, di)
  features/
    auth/
    dashboard/
    tasks/
    results/
    reports/
    approvals/
    chat/
    calls/
    contracts/
    payments/
    journey/
    meetings/
    files/
    notifications/
  shared/       (widgets, services, models)
```

2. Set up Supabase with these tables:

```sql
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
```

3. Enable Row-Level Security on all tables. Rules:
   - Clients can only read/write their own project data
   - Account managers can read/write projects assigned to them
   - Team members can only update tasks in their category
   - Admins can access everything

4. Set up Flutter with:
   - `supabase_flutter` package
   - `go_router` for navigation
   - `riverpod` for state management
   - Dark theme with colors: background `#080B12`, cards `#111827`, primary green `#2EE59D`, primary blue `#3B82F6`
   - Custom font: Inter or Plus Jakarta Sans

5. Build the Auth screens:
   - Login screen (email + password) — design: dark background, logo centered, "Welcome to Moharek" tagline, email + password fields with `#2EE59D` accent
   - Forgot password screen
   - On login, check profile role → route to Client App or Admin Panel accordingly
   - Persist session with Supabase

---

## Phase 2 — Core Client Portal Screens (Week 3–5)

**Goal:** All 9 main screens for the client.

**Screens to build:**

**1. Home Dashboard**

- Top: "Welcome, [Name]" + company name + avatar
- Growth progress card: circular progress bar showing overall project % complete
- Stats row: Tasks Done · In Progress · Keywords · Leads
- Performance cards: Traffic, Leads, Rankings, Ads ROAS — each with a small sparkline chart (use `fl_chart` package)
- Project stages progress: Audit → Strategy → Setup → Execution → Optimization → Results (horizontal stepper with color status)
- Activity feed: last 5 items from `activity_feed` table, realtime subscription
- Quick actions row: View Tasks · Contact Team · View Report · Request Meeting
- Pull-to-refresh

**2. Growth Journey Screen**

- Show all 6 stages as vertical cards
- Each card: stage icon + name + status badge (Not Started / In Progress / Completed) + assigned person + deadline + notes
- Tap a stage to expand and show files + sub-tasks
- Animated progress line connecting stages

**3. Tasks Screen**

- Tab bar: All / In Progress / Waiting Me / Completed
- Task cards showing: title, status badge (color-coded), category tag, assignee avatar, deadline countdown
- "Waiting Client Approval" tasks shown at top with orange highlight and action button
- Filter by category (SEO / Ads / Content / Design / Tech / AI)
- Tap task → detail sheet showing full description + history

**4. Results Screen**

- Tab bar: SEO · Ads · AI Visibility · Trust Engine
- SEO tab: keywords table (keyword, position, change arrow), traffic chart (line chart 30 days), impressions, clicks, indexed pages, technical score
- Ads tab: spend, leads, cost per lead, ROAS, conversion rate — all as metric cards + bar chart
- AI Visibility tab: Visibility in ChatGPT / Gemini / Perplexity (simple yes/no badges + percentage), key questions brand should appear in, overall visibility score
- Trust Engine tab: Google rating, reviews count, brand mentions, reputation score with gauge chart
- All data from `results` table filtered by `result_type` and `project_id`

**5. Reports Screen**

- List of report cards: title, type badge, period, summary preview, status (Ready / Draft)
- Tap → Report Detail: full summary, metrics snapshot, download PDF button (opens `file_url` from Supabase Storage)
- Filter by type

**6. Approvals Screen**

- Pending approvals at top (highlighted orange border)
- Each approval card: title, type, team notes, file preview (image or PDF thumbnail)
- Tap → full screen: description, file viewer (image or PDF), team notes, "Approve" green button + "Request Changes" with text input
- On action → update `approvals` table status → trigger notification to team

**7. Files Screen**

- Grid/list toggle
- Categories: Brand · Reports · Content · Campaigns · Contracts · Strategy
- File cards: icon by type, name, upload date, size
- Tap → open file (use `url_launcher` or `flutter_pdfview`)
- Admin can upload from web panel; client views only

**8. Meetings Screen**

- Upcoming meetings list with date, time, title, type
- Past meetings with summary and action items
- "Request Meeting" button → opens form (preferred date/time + topic) → creates row in `meetings` table → triggers notification to account manager
- Tap upcoming meeting → Join button (launches Jitsi — see Phase 3)

**9. Settings / Profile Screen**

- Avatar, name, company, phone (read-only from profile)
- Language toggle: Arabic / English
- Notification preferences
- Logout

---

## Phase 3 — Communication: Chat + Video + Voice Calls (Week 6–7)

**Goal:** Real-time messaging, video calls, voice calls.

**Chat:**

1. Use Supabase Realtime on the `messages` table with `channel_id` filter
2. Chat screen: message bubbles (right = client, left = team), timestamp, read receipts (update `is_read`)
3. Support: text, image (pick from gallery → upload to Supabase Storage → send URL), voice messages (use `flutter_sound` to record → upload → send URL with play button)
4. Unread badge on bottom nav Chat tab
5. Typing indicator using Supabase Presence (broadcast channel)
6. Client sees one channel: their account manager only

**Video + Voice Calls (Jitsi):**

1. Add `jitsi_meet_flutter_sdk` package
2. When client taps "Start Call" or "Video Call" button in chat or meetings screen:
   - Generate a unique room ID: `moharek-{project_id}-{timestamp}`
   - Launch Jitsi with `JitsiMeet().join(JitsiMeetConferenceOptions(room: roomId, serverURL: "https://meet.jit.si", userInfo: ...))`
   - Send a message in chat with the room link so the other party can join
3. For incoming call notifications (native):
   - iOS: integrate CallKit via a Swift method channel so incoming calls show the native iOS call screen
   - Android: use `flutter_callkeep` package for ConnectionService
   - When one user initiates a call → create a row in `meetings` table with `status = 'ongoing'` and `jitsi_room_id` → trigger FCM notification to recipient with call data → recipient app receives FCM in background and shows native call UI → on accept, launch Jitsi with the room ID
4. Call quality: Jitsi on `meet.jit.si` is free and handles infrastructure. For premium self-hosting later, can deploy on a VPS.

---

## Phase 4 — Contracts + Payments (Week 8–9)

**Goal:** Clients view contracts and pay invoices inside the app.

**Contracts:**

1. Contracts Screen: list of contracts from `contracts` table
2. Each contract card: title, date, status badge (Pending / Signed / Expired)
3. Tap → open PDF from Supabase Storage using `flutter_pdfview`
4. If status is Pending → show "Sign Contract" button → for MVP, this can open an external DocuSign/HelloSign link OR implement a simple "I agree" acknowledgment that updates the status

**Payments:**

1. Invoices Screen: list with amount, due date, status (Pending / Paid / Overdue)
2. Each invoice card: amount, service period, status badge
3. Tap Pending invoice → Payment Sheet:
   - Option A (Stripe): use `flutter_stripe` package, create a PaymentIntent via a Supabase Edge Function (server-side), present Stripe's native payment sheet → on success update `invoices` table
   - Option B (Paymob — Egypt): generate payment link via Paymob API in a Supabase Edge Function → open `url_launcher` to Paymob hosted payment page → use webhook to update invoice status
4. Supabase Edge Function for Stripe:

```typescript
// supabase/functions/create-payment-intent/index.ts
import Stripe from "stripe";
const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY"));
Deno.serve(async (req) => {
  const { amount, currency, invoice_id } = await req.json();
  const paymentIntent = await stripe.paymentIntents.create({
    amount,
    currency,
    metadata: { invoice_id },
  });
  return Response.json({ clientSecret: paymentIntent.client_secret });
});
```

5. Receipt screen showing payment confirmation + option to download receipt PDF

---

## Phase 5 — Admin Web Panel (Week 10–12)

**Goal:** Flutter Web admin panel for the internal team.

**Build as a Flutter Web app, separate route/flavor of the same codebase.**

**Admin screens:**

1. **Clients List** — table of all clients with project status, last activity, health score
2. **Client Detail** — full view of one client: all tabs (tasks, results, reports, approvals, chat, invoices, files)
3. **Create Client** — form: name, email, company, assign account manager, create project, set start date
4. **Task Manager** — Kanban board (use `appflowy_board` package): columns = Todo / In Progress / Waiting Client / In Review / Completed. Drag-drop to update status.
5. **Reports Manager** — upload new report (PDF to Supabase Storage), write summary, select type, assign to client → status auto-set to "ready" → FCM notification fires
6. **Approvals Manager** — create new approval item, upload file, write team notes, assign to client
7. **Chat** — same realtime chat, but team sees all their client channels in sidebar
8. **Invoices** — create invoice (client, amount, due date, description) → auto-generates payment link
9. **Notifications Center** — send manual notification to one client or all clients
10. **Activity Dashboard** — real-time feed of all client activity across all projects
11. **Results Input** — form to add new result metrics per client (connected to `results` table)

---

## Phase 6 — Notifications, Polish & Launch (Week 13–14)

**Goal:** Push notifications, UI polish, testing, app store submission.

**Push Notifications with FCM:**

1. Add `firebase_messaging` to Flutter
2. On app open, register device token → save to `fcm_tokens` table
3. Create a Supabase Edge Function `send-notification` that calls FCM HTTP v1 API
4. Create database triggers (Supabase Functions + webhooks) that call `send-notification` when:
   - New report is uploaded (status changes to 'ready') → notify client
   - New approval item created → notify client
   - Task status changes to 'waiting_client' → notify client
   - Approval is responded to (approved/changes) → notify team
   - New message in chat → notify recipient
   - Meeting scheduled → notify client
   - Result keyword improves by 3+ positions → notify client with: "Your keyword '[keyword]' moved from #X to #Y"
   - Invoice created → notify client
   - Contract uploaded → notify client

**Polish:**

1. Add skeleton loading screens for all data-fetching screens
2. Add empty states with illustration + CTA for all lists
3. Add haptic feedback on key actions (approve, pay, send message)
4. Implement Arabic localization using `flutter_localizations` + `intl` — all strings in `/l10n/` folder, RTL layout support
5. Add pull-to-refresh on all list screens
6. Offline awareness: show banner when no internet, cache last data with `hive` or `flutter_cache_manager`
7. App icon: dark background, Moharek logo
8. Splash screen: dark bg, logo centered, brief fade animation

**Testing:**

1. Test auth flows (login, session expiry, role routing)
2. Test realtime (send message from admin panel → appears instantly in client app)
3. Test Jitsi call (both iOS and Android)
4. Test payment flow end-to-end (Stripe test mode)
5. Test all notification triggers

**Launch:**

1. Apple App Store: requires $99/year Apple Developer account
2. Google Play Store: requires $25 one-time fee
3. Admin web panel: deploy free on Vercel or Netlify (`flutter build web`)

---

## Cost Breakdown

| Service            | Free Tier                      | Paid Upgrade                  |
| ------------------ | ------------------------------ | ----------------------------- |
| Supabase           | 500MB DB, 1GB storage, 50K MAU | $25/mo (Pro) when scaling     |
| Firebase FCM       | Unlimited                      | —                             |
| Jitsi Meet         | Unlimited (meet.jit.si)        | Self-host on ~$5/mo VPS later |
| Stripe             | No monthly fee                 | 2.9% + $0.30 per transaction  |
| Paymob (Egypt)     | No monthly fee                 | Small per-transaction %       |
| Vercel (web panel) | Free                           | —                             |
| **Total**          | **$0/month**                   | Scales only with usage        |

---

## Key Packages List

```yaml
dependencies:
  supabase_flutter: ^2.0.0
  riverpod: ^2.0.0
  go_router: ^13.0.0
  fl_chart: ^0.68.0
  jitsi_meet_flutter_sdk: ^9.0.0
  flutter_stripe: ^10.0.0
  firebase_messaging: ^14.0.0
  flutter_local_notifications: ^17.0.0
  flutter_callkeep: ^1.0.0
  flutter_sound: ^9.0.0
  flutter_pdfview: ^1.3.0
  image_picker: ^1.0.0
  file_picker: ^8.0.0
  cached_network_image: ^3.3.0
  hive_flutter: ^1.1.0
  url_launcher: ^6.2.0
  appflowy_board: ^0.1.0
  intl: ^0.19.0
  flutter_localizations: sdk: flutter
  permission_handler: ^11.0.0
  connectivity_plus: ^6.0.0
  shimmer: ^3.0.0
```
