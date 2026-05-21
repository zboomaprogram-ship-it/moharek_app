# 🚀 RABHAN FLAVOR — MASTER AI AGENT IMPLEMENTATION PROMPT

> Copy this entire document and paste it as the first message to each AI agent.
> Each agent section is self-contained and tells the agent exactly what to build,
> what already exists, and what it must NOT touch.

---

## 📌 PROJECT CONTEXT (READ FIRST — ALL AGENTS)

You are implementing **Rabhan (ربحان)** — a new **Flutter flavor** of an existing app called **Moharek**.

### What "flavor" means

- This is NOT a new app. It shares 100% of the same Dart codebase.
- It uses Flutter's `--flavor` build system to produce a separate branded binary.
- You NEVER duplicate screens. You reuse all existing widgets, providers, and services.
- Brand differences (colors, logo, strings, feature flags) are injected via a flavor config class.

### What Rabhan IS

An **e-commerce operating system** for online store owners in Saudi Arabia.

- Clients are store owners who pay Rabhan (the company) to grow their e-commerce business.
- The company manages their store, ads, products, analytics, and operations.
- Clients see their KPIs, approve creative assets, chat with their account manager, and track their subscription package.
- The company's team (admins + account managers) control everything from a **web dashboard**.

### Existing stack (DO NOT BREAK THESE)

- **Flutter** (Dart) with GoRouter for routing
- **Supabase** for database, auth, real-time, storage, and edge functions
- **OneSignal** for push notifications
- **Riverpod** for state management
- **Role-based access control** via `profiles.role` column:
  `admin | account_manager | seo_team | ads_team | content_team | design_team | tech_team | client`

### Moharek flavor config location

```
lib/core/config/app_config.dart         ← base config interface
lib/core/theme/app_theme.dart           ← base theme
lib/core/router/app_router.dart         ← all routes (GoRouter)
assets/logo.png                         ← main logo
pubspec.yaml                            ← assets + fonts declared here
```

### Rabhan brand tokens

```
Background:      #080B12
Card color:      #111827
Primary green:   #2EE59D
Gold accent:     #D4A017
Error/alert:     #E8593C
Text primary:    #FFFFFF
Text secondary:  #9CA3AF
Font family:     Cairo (Arabic RTL support)
Direction:       RTL (Arabic default, English fallback)
```

---

## 👥 AGENT ROSTER & RESPONSIBILITIES

| Agent                           | Responsibility                                    | Runs after |
| ------------------------------- | ------------------------------------------------- | ---------- |
| **Agent 1 — Flavor Scaffold**   | Flutter flavor wiring, theme, config, assets, RTL | — (first)  |
| **Agent 2 — Database**          | Supabase schema additions on existing project     | Agent 1    |
| **Agent 3 — Client Mobile UI**  | Remap existing client screens + new screens       | Agent 2    |
| **Agent 4 — Growth Pro Screen** | The package subscription screen                   | Agent 3    |
| **Agent 5 — Web Dashboard**     | Admin + AM web shell additions for Rabhan         | Agent 3    |
| **Agent 6 — Edge Functions**    | New Supabase edge functions + notifications       | Agent 2    |
| **Agent 7 — QA & Integration**  | Cross-flavor regression + RTL audit               | All done   |

---

---

# ═══════════════════════════════════════════════

# AGENT 1 — FLUTTER FLAVOR SCAFFOLD

# ═══════════════════════════════════════════════

## Your job

Wire up the `rabhan` Flutter flavor. Do not write any business logic. Just the scaffold.

## Step 1 — Create flavor config

Create `lib/core/config/rabhan_config.dart`:

```dart
import 'app_config.dart';

class RabhanConfig implements AppConfig {
  @override
  String get supabaseUrl => const String.fromEnvironment('RABHAN_SUPABASE_URL');

  @override
  String get supabaseAnonKey => const String.fromEnvironment('RABHAN_SUPABASE_ANON_KEY');

  @override
  String get oneSignalAppId => const String.fromEnvironment('RABHAN_ONESIGNAL_APP_ID');

  @override
  String get wordpressMediaUrl => const String.fromEnvironment('RABHAN_WP_MEDIA_URL');

  @override
  String get appName => 'ربحان';

  @override
  String get flavorName => 'rabhan';

  // Feature flags
  @override bool get enableBilling => true;
  @override bool get enableVideoCalls => true;
  @override bool get enableAiAssistant => true;

  // Rabhan-only flags (add to AppConfig interface too)
  bool get enableGrowthSystem => true;
  bool get enableEcomMetrics => true;
  bool get enablePackageTiers => true;
  bool get enableAdCampaigns => true;
}
```

## Step 2 — Create Rabhan theme

Create `lib/core/theme/rabhan_theme.dart`:

```dart
import 'package:flutter/material.dart';

class RabhanTheme {
  static const background   = Color(0xFF080B12);
  static const card         = Color(0xFF111827);
  static const primaryGreen = Color(0xFF2EE59D);
  static const gold         = Color(0xFFD4A017);
  static const error        = Color(0xFFE8593C);
  static const textPrimary  = Color(0xFFFFFFFF);
  static const textSecondary= Color(0xFF9CA3AF);

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    cardColor: card,
    colorScheme: const ColorScheme.dark(
      primary: primaryGreen,
      secondary: gold,
      surface: card,
      background: background,
      error: error,
    ),
    fontFamily: 'Cairo',
    textTheme: const TextTheme(
      displayLarge:  TextStyle(color: textPrimary,   fontFamily: 'Cairo'),
      bodyLarge:     TextStyle(color: textPrimary,   fontFamily: 'Cairo'),
      bodyMedium:    TextStyle(color: textSecondary, fontFamily: 'Cairo'),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: textPrimary,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: card,
      selectedItemColor: primaryGreen,
      unselectedItemColor: textSecondary,
    ),
  );
}
```

## Step 3 — Main entry point per flavor

Create `lib/main_rabhan.dart`:

```dart
import 'package:flutter/material.dart';
import 'core/config/rabhan_config.dart';
import 'core/theme/rabhan_theme.dart';
import 'app.dart'; // your existing App widget

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = RabhanConfig();
  await initializeApp(config); // your existing init function
  runApp(App(
    config: config,
    theme: RabhanTheme.dark,
    textDirection: TextDirection.rtl,
  ));
}
```

## Step 4 — pubspec.yaml additions

Add under `flutter:` → `fonts:`:

```yaml
- family: Cairo
  fonts:
    - asset: assets/fonts/Cairo-Regular.ttf
      weight: 400
    - asset: assets/fonts/Cairo-Medium.ttf
      weight: 500
    - asset: assets/fonts/Cairo-Bold.ttf
      weight: 700
```

Add under `flutter:` → `assets:`:

```yaml
- assets/rabhan/
```

Create the folder `assets/rabhan/` and place inside it:

- `logo.png` — the ربحان green calligraphy logo (black background, green text)
- `logo_dark.png` — same on transparent background
- `splash.png` — dark splash screen with centered logo

## Step 5 — Android flavor

In `android/app/build.gradle`, add:

```groovy
flavorDimensions "app"
productFlavors {
    moharek { dimension "app"; applicationId "com.yourcompany.moharek" }
    rabhan  {
        dimension "app"
        applicationId "com.yourcompany.rabhan"
        resValue "string", "app_name", "ربحان"
    }
}
```

Create `android/app/src/rabhan/res/` with a `mipmap-*/` icon set using the Rabhan logo.

## Step 6 — iOS flavor

In Xcode (or via `ios/Runner.xcodeproj`):

- Duplicate the "Runner" scheme, rename to "Rabhan"
- Set bundle ID to `com.yourcompany.rabhan`
- Point to `Assets.xcassets/RabhanIcon.appiconset`

## Step 7 — RTL wrapper

In `lib/app.dart`, wrap MaterialApp with:

```dart
Directionality(
  textDirection: widget.textDirection ?? TextDirection.ltr,
  child: MaterialApp.router(...),
)
```

## ✅ Agent 1 done when

- `flutter run --flavor rabhan -t lib/main_rabhan.dart` launches
- Dark background, green accent, Cairo font, RTL Arabic renders
- `flutter run --flavor moharek -t lib/main_moharek.dart` still works identically

---

---

# ═══════════════════════════════════════════════

# AGENT 2 — SUPABASE DATABASE ADDITIONS

# ═══════════════════════════════════════════════

## Your job

Add new tables and columns to the **existing** Moharek Supabase project.
Do NOT drop or rename any existing tables, columns, or policies.
All new tables get Row Level Security enabled immediately.

## Existing tables (DO NOT TOUCH STRUCTURE)

`profiles`, `projects`, `tasks`, `messages`, `channels`, `reports`,
`files`, `approvals`, `meetings`, `invoices`, `call_signals`, `support_tickets`

## Run these SQL migrations in order

### Migration 001 — packages table

```sql
create table public.packages (
  id                uuid default gen_random_uuid() primary key,
  project_id        uuid references public.projects(id) on delete cascade not null,
  package_name      text not null,                        -- e.g. "Growth Pro"
  package_tier      text not null default 'starter',      -- starter | growth | pro | enterprise
  status            text not null default 'active',        -- active | trial | expired | suspended
  renews_at         timestamptz,
  trial_ends_at     timestamptz,
  requests_used     int default 0,
  requests_limit    int default 200,
  services          jsonb default '[]'::jsonb,             -- array of service name strings
  notes             text,
  created_at        timestamptz default now(),
  updated_at        timestamptz default now()
);

alter table public.packages enable row level security;

-- Client: read own project package
create policy "client_read_own_package" on public.packages
  for select using (
    project_id in (
      select id from public.projects
      where client_id = auth.uid()
    )
  );

-- AM: read + update assigned projects
create policy "am_manage_packages" on public.packages
  for all using (
    project_id in (
      select id from public.projects
      where account_manager_id = auth.uid()
    )
  );

-- Admin: full access
create policy "admin_full_packages" on public.packages
  for all using (
    (select role from public.profiles where id = auth.uid()) = 'admin'
  );

-- Auto-update updated_at
create or replace function public.update_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;
create trigger packages_updated_at before update on public.packages
  for each row execute function public.update_updated_at();
```

### Migration 002 — ecom_metrics table

```sql
create table public.ecom_metrics (
  id                   uuid default gen_random_uuid() primary key,
  project_id           uuid references public.projects(id) on delete cascade not null,
  period_start         date not null,
  period_end           date not null,
  period_type          text default 'monthly',   -- daily | weekly | monthly
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

alter table public.ecom_metrics enable row level security;

create policy "client_read_own_metrics" on public.ecom_metrics
  for select using (
    is_published = true and
    project_id in (select id from public.projects where client_id = auth.uid())
  );

create policy "am_manage_metrics" on public.ecom_metrics
  for all using (
    project_id in (select id from public.projects where account_manager_id = auth.uid())
  );

create policy "admin_full_metrics" on public.ecom_metrics
  for all using (
    (select role from public.profiles where id = auth.uid()) = 'admin'
  );

create trigger ecom_metrics_updated_at before update on public.ecom_metrics
  for each row execute function public.update_updated_at();
```

### Migration 003 — growth_engines table

```sql
create type public.engine_type as enum (
  'store', 'product', 'ads', 'sales_page', 'operations', 'analytics'
);

create table public.growth_engines (
  id             uuid default gen_random_uuid() primary key,
  project_id     uuid references public.projects(id) on delete cascade not null,
  engine_type    public.engine_type not null,
  status         text default 'pending',    -- active | pending | paused | completed
  health_score   int default 0 check (health_score between 0 and 100),
  current_tasks  jsonb default '[]'::jsonb, -- array of task summary objects
  notes          text,
  last_updated_by uuid references public.profiles(id),
  created_at     timestamptz default now(),
  updated_at     timestamptz default now(),
  unique(project_id, engine_type)
);

alter table public.growth_engines enable row level security;

create policy "client_read_engines" on public.growth_engines
  for select using (
    project_id in (select id from public.projects where client_id = auth.uid())
  );

create policy "team_manage_engines" on public.growth_engines
  for all using (
    (select role from public.profiles where id = auth.uid())
    in ('admin', 'account_manager', 'ads_team', 'seo_team', 'content_team', 'design_team', 'tech_team')
  );

create trigger growth_engines_updated_at before update on public.growth_engines
  for each row execute function public.update_updated_at();
```

### Migration 004 — ad_campaigns table

```sql
create table public.ad_campaigns (
  id                   uuid default gen_random_uuid() primary key,
  project_id           uuid references public.projects(id) on delete cascade not null,
  campaign_name        text not null,
  platform             text not null,   -- meta | google | tiktok | snapchat | other
  status               text default 'active',  -- active | paused | ended | draft
  budget               numeric(12,2) default 0,
  spend                numeric(12,2) default 0,
  roas                 numeric(6,2) default 0,
  clicks               bigint default 0,
  impressions          bigint default 0,
  conversions          int default 0,
  platform_campaign_id text,            -- external ID for future API sync
  start_date           date,
  end_date             date,
  currency             text default 'SAR',
  created_at           timestamptz default now(),
  updated_at           timestamptz default now()
);

alter table public.ad_campaigns enable row level security;

create policy "client_read_campaigns" on public.ad_campaigns
  for select using (
    project_id in (select id from public.projects where client_id = auth.uid())
  );

create policy "ads_team_manage" on public.ad_campaigns
  for all using (
    (select role from public.profiles where id = auth.uid())
    in ('admin', 'account_manager', 'ads_team')
  );

create trigger ad_campaigns_updated_at before update on public.ad_campaigns
  for each row execute function public.update_updated_at();
```

### Migration 005 — extend existing tasks table for journey stages

```sql
-- Add Rabhan-specific columns to existing tasks table
-- (safe — only adds, never removes)
alter table public.tasks
  add column if not exists stage_type text,
  -- values: research | showcase | creative | client_approval | launch | optimize | scale
  add column if not exists is_client_pending boolean default false,
  add column if not exists journey_order int default 0;
```

### Migration 006 — database functions for dashboard

```sql
-- Returns latest ecom_metrics snapshot for a project
create or replace function public.get_latest_metrics(p_project_id uuid)
returns table (
  total_sales numeric, prev_sales numeric,
  orders_count int, prev_orders int,
  roas numeric, prev_roas numeric,
  conversion_rate numeric, net_profit numeric,
  period_start date, period_end date
)
language sql security definer as $$
  select total_sales, prev_sales, orders_count, prev_orders,
         roas, prev_roas, conversion_rate, net_profit,
         period_start, period_end
  from public.ecom_metrics
  where project_id = p_project_id and is_published = true
  order by period_end desc limit 1;
$$;

-- Returns health summary of all engines for a project
create or replace function public.get_engine_health(p_project_id uuid)
returns table (engine_type text, status text, health_score int)
language sql security definer as $$
  select engine_type::text, status, health_score
  from public.growth_engines
  where project_id = p_project_id
  order by engine_type;
$$;
```

## ✅ Agent 2 done when

- All 6 migrations run without error on existing Supabase project
- `select * from public.packages limit 1;` returns no error
- RLS test: a client JWT cannot select rows from another project
- Existing tables (`profiles`, `tasks`, etc.) have no changed columns

---

---

# ═══════════════════════════════════════════════

# AGENT 3 — CLIENT MOBILE UI REMAPPING

# ═══════════════════════════════════════════════

## Your job

Remap existing client-facing screens to show Rabhan's e-commerce data.
Do NOT rewrite widget logic. Swap providers and labels only.
All new providers go in `lib/features/rabhan/`.

## Flavor guard pattern

Every Rabhan-specific widget must be wrapped:

```dart
// In any screen widget
if (config.flavorName == 'rabhan') ...[
  RabhanMetricsCard(projectId: projectId),
] else ...[
  MoharekMetricsCard(projectId: projectId),
],
```

Or better, use a `RabhanFeature` wrapper widget:

```dart
class RabhanFeature extends StatelessWidget {
  final Widget child;
  final Widget? fallback;
  const RabhanFeature({required this.child, this.fallback});

  @override
  Widget build(BuildContext context) {
    final config = context.read<AppConfig>();
    if (config.flavorName != 'rabhan') return fallback ?? const SizedBox.shrink();
    return child;
  }
}
```

## Screen 1 — DashboardScreen (الرئيسية)

Add this section to the TOP of the existing dashboard body, inside a `RabhanFeature`:

```dart
// lib/features/rabhan/widgets/ecom_kpi_section.dart
class EcomKpiSection extends ConsumerWidget {
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(latestMetricsProvider(projectId));

    return metricsAsync.when(
      loading: () => const KpiSkeletonRow(),
      error: (e, _) => const SizedBox.shrink(),
      data: (m) => Column(
        children: [
          // Row 1: Sales + Orders
          Row(children: [
            Expanded(child: KpiCard(
              label: 'المبيعات',
              value: 'ر.س ${m.totalSales.toStringAsFixed(0)}',
              delta: m.salesDeltaPercent,
              icon: Icons.shopping_bag_outlined,
            )),
            const SizedBox(width: 12),
            Expanded(child: KpiCard(
              label: 'الطلبات',
              value: m.ordersCount.toString(),
              delta: m.ordersDeltaPercent,
              icon: Icons.receipt_long_outlined,
            )),
          ]),
          const SizedBox(height: 12),
          // Row 2: ROAS + Conversion
          Row(children: [
            Expanded(child: KpiCard(
              label: 'ROAS',
              value: '${m.roas.toStringAsFixed(2)}x',
              delta: m.roasDeltaPercent,
              icon: Icons.trending_up,
            )),
            const SizedBox(width: 12),
            Expanded(child: KpiCard(
              label: 'معدل التحويل',
              value: '${(m.conversionRate * 100).toStringAsFixed(2)}%',
              delta: m.conversionDeltaPercent,
              icon: Icons.swap_horiz,
            )),
          ]),
          const SizedBox(height: 16),
          // Net profit chart — reuse existing LineChartWidget
          SalesLineChart(projectId: projectId),
          const SizedBox(height: 16),
          // Journey mini-progress
          JourneyMiniProgress(projectId: projectId),
        ],
      ),
    );
  }
}
```

Provider:

```dart
// lib/features/rabhan/providers/metrics_provider.dart
final latestMetricsProvider = FutureProvider.family<EcomMetrics?, String>((ref, projectId) async {
  final supabase = ref.read(supabaseProvider);
  final data = await supabase.rpc('get_latest_metrics', params: {'p_project_id': projectId});
  if (data == null || (data as List).isEmpty) return null;
  return EcomMetrics.fromJson(data.first);
});
```

## Screen 2 — TasksScreen → رحلة العمل (Journey + Approvals)

Rename the screen tab label to `العمل` in the Rabhan flavor.
Add a journey stage progress tracker at the TOP of TasksScreen inside `RabhanFeature`:

```dart
// Journey stage tracker widget
class JourneyStageTracker extends ConsumerWidget {
  // stages list: research, showcase, creative, client_approval, launch, optimize, scale
  // Arabic labels: البحث, الإنشاء العرض, الإنتاج الإبداعي, موافقة العميل, الإطلاق, التحسين, التوسع
  // Show horizontal scrollable stage pills with completed/active/pending states
}
```

Below the tracker, show the existing approvals list filtered to `is_client_pending = true`.

## Screen 3 — ResultsScreen → النتائج

Add tabs inside `RabhanFeature`: **الإعلانات | المتجر | المنتجات | التحليلات**

Each tab pulls from:

- `ad_campaigns` filtered by platform group
- `ecom_metrics` for store + products tab
- `growth_engines` for analytics tab

Reuse the existing `MetricChart` widget — just change the data source.

## Screen 4 — Bottom Navigation (الـ 5 tabs)

In Rabhan flavor, override bottom nav labels:

```dart
// Inject via flavor config or override in RabhanScaffold
final rabhanNavItems = [
  BottomNavItem(label: 'الرئيسية', icon: Icons.bar_chart_outlined, route: '/dashboard'),
  BottomNavItem(label: 'العمل',    icon: Icons.checklist_outlined,  route: '/tasks'),
  BottomNavItem(label: 'المحادثات',icon: Icons.chat_bubble_outline, route: '/chat'),
  BottomNavItem(label: 'الإشعارات',icon: Icons.notifications_none, route: '/dashboard/notifications'),
  BottomNavItem(label: 'المزيد',   icon: Icons.grid_view_outlined,  route: '/profile'),
];
```

## New route — Growth Pro screen

Add to `app_router.dart`:

```dart
GoRoute(
  path: '/dashboard/package',
  name: 'package',
  builder: (ctx, state) => const GrowthProScreen(),
),
```

This screen is built entirely by **Agent 4** — just add the route here.

## New route — Growth System screen

```dart
GoRoute(
  path: '/dashboard/growth-system',
  name: 'growth-system',
  builder: (ctx, state) => const GrowthSystemScreen(),
),
```

## New route — Analytics screen

```dart
GoRoute(
  path: '/dashboard/analytics',
  name: 'rabhan-analytics',
  builder: (ctx, state) => const RabhanAnalyticsScreen(),
),
```

## Model classes to create

```dart
// lib/features/rabhan/models/ecom_metrics.dart
class EcomMetrics {
  final double totalSales, prevSales, roas, prevRoas, conversionRate, netProfit, adSpend;
  final int ordersCount, prevOrders;
  final DateTime periodStart, periodEnd;

  double get salesDeltaPercent =>
    prevSales == 0 ? 0 : ((totalSales - prevSales) / prevSales) * 100;
  double get ordersDeltaPercent =>
    prevOrders == 0 ? 0 : ((ordersCount - prevOrders) / prevOrders) * 100;
  double get roasDeltaPercent =>
    prevRoas == 0 ? 0 : ((roas - prevRoas) / prevRoas) * 100;
  double get conversionDeltaPercent => 0; // compute from prev if available

  factory EcomMetrics.fromJson(Map<String, dynamic> j) => EcomMetrics(
    totalSales: (j['total_sales'] ?? 0).toDouble(),
    prevSales: (j['prev_sales'] ?? 0).toDouble(),
    ordersCount: j['orders_count'] ?? 0,
    prevOrders: j['prev_orders'] ?? 0,
    roas: (j['roas'] ?? 0).toDouble(),
    prevRoas: (j['prev_roas'] ?? 0).toDouble(),
    conversionRate: (j['conversion_rate'] ?? 0).toDouble(),
    netProfit: (j['net_profit'] ?? 0).toDouble(),
    adSpend: 0,
    periodStart: DateTime.parse(j['period_start']),
    periodEnd: DateTime.parse(j['period_end']),
  );
}

// lib/features/rabhan/models/package_model.dart
class PackageModel {
  final String id, packageName, packageTier, status;
  final DateTime? renewsAt, trialEndsAt;
  final int requestsUsed, requestsLimit;
  final List<String> services;
  final String? notes;

  int get daysUntilRenewal =>
    renewsAt == null ? 0 : renewsAt!.difference(DateTime.now()).inDays;
  double get requestsUsedPercent => requestsLimit == 0 ? 0 : requestsUsed / requestsLimit;

  factory PackageModel.fromJson(Map<String, dynamic> j) => PackageModel(
    id: j['id'],
    packageName: j['package_name'],
    packageTier: j['package_tier'] ?? 'starter',
    status: j['status'] ?? 'active',
    renewsAt: j['renews_at'] != null ? DateTime.parse(j['renews_at']) : null,
    trialEndsAt: j['trial_ends_at'] != null ? DateTime.parse(j['trial_ends_at']) : null,
    requestsUsed: j['requests_used'] ?? 0,
    requestsLimit: j['requests_limit'] ?? 200,
    services: (j['services'] as List?)?.cast<String>() ?? [],
    notes: j['notes'],
  );
}

// lib/features/rabhan/models/growth_engine_model.dart
class GrowthEngineModel {
  final String engineType, status;
  final int healthScore;

  String get arabicName => {
    'store':      'محرك المتجر',
    'product':    'محرك المنتجات',
    'ads':        'محرك الإعلانات',
    'sales_page': 'محرك صفحات البيع',
    'operations': 'محرك العمليات',
    'analytics':  'محرك التحليلات',
  }[engineType] ?? engineType;

  factory GrowthEngineModel.fromJson(Map<String, dynamic> j) => GrowthEngineModel(
    engineType: j['engine_type'],
    status: j['status'],
    healthScore: j['health_score'] ?? 0,
  );
}
```

## ✅ Agent 3 done when

- Dashboard shows KPI cards (sales, orders, ROAS, conversion) from real Supabase data
- Journey stage tracker visible on العمل tab
- All 5 bottom nav items show Arabic labels in Rabhan flavor
- Routes `/dashboard/package`, `/dashboard/growth-system`, `/dashboard/analytics` exist (screens can be empty stubs)

---

---

# ═══════════════════════════════════════════════

# AGENT 4 — GROWTH PRO SCREEN (PACKAGE SCREEN)

# ═══════════════════════════════════════════════

## Your job

Build the `GrowthProScreen` — the screen where the client sees their subscription
package with Rabhan. This is the most important Rabhan-exclusive screen.

**Route:** `/dashboard/package`
**Accessed from:** Profile menu → "الباقة والحساب" OR directly from bottom nav "المزيد"

## What it shows (based on screenshots)

### Section 1 — Package header card

```
┌─────────────────────────────────────┐
│  👑  Growth Pro            [الباقة] │
│      ● نشطة                         │
│      تتجدد في 28 يوليو 2025         │
└─────────────────────────────────────┘
```

- Gold crown icon (👑 or custom SVG)
- Package name from `packages.package_name`
- Status badge: نشطة (green) | تجريبية (amber) | منتهية (red)
- Renewal date from `packages.renews_at` formatted in Arabic

### Section 2 — Included services list (الخدمات المشمولة)

```
✓ إدارة المتاجر والمنصات
✓ إعلانات مدفوعة بالذكاء الاصطناعي
✓ الإنتاج الإبداعي
✓ تحسين وتحليل البيانات
✓ مدير حساب مخصص
✓ تقارير أداء أسبوعية
```

Rendered from `packages.services` JSON array.

### Section 3 — Monthly requests usage bar

```
استخدام الطلبات الشهرية
████████████░░░░  128 من 200 شهري
                  64 متبقي
```

- Linear progress bar: `requests_used / requests_limit`
- Color: green when < 70%, amber when 70–90%, red when > 90%
- Show count: "{used} من {limit} شهري"
- Show remaining: "{remaining} متبقي"

### Section 4 — Account manager card (مدير الحساب)

```
┌─────────────────────────────────────┐
│  [Avatar]  أحمد الشحيلي             │
│            ● متصل الآن              │
│                                     │
│  [💬 محادثة]  [📅 اجتماع]  [✉️ بريد]│
└─────────────────────────────────────┘
```

- AM data pulled from `projects.account_manager_id` → `profiles` join
- Online status from existing presence system
- Three action buttons: navigate to chat, navigate to meetings, launch email

### Section 5 — Quick links menu

```
> الفواتير والمدفوعات
> تقارير الأداء
> مركز المساعدة والدعم
> الإعدادات
```

Existing routes: `/dashboard/billing`, `/reports`, `/dashboard/ai-assistant`, `/profile`

## Full screen implementation

```dart
// lib/features/rabhan/screens/growth_pro_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/package_model.dart';
import '../providers/package_provider.dart';
import '../../shared/widgets/...'; // your existing widgets

class GrowthProScreen extends ConsumerWidget {
  const GrowthProScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectId = ref.watch(currentProjectIdProvider);
    final packageAsync = ref.watch(packageProvider(projectId));
    final amAsync = ref.watch(accountManagerProvider(projectId));

    return Scaffold(
      backgroundColor: RabhanTheme.background,
      appBar: AppBar(
        title: const Text('الحساب والباقة'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/dashboard/notifications'),
          ),
        ],
      ),
      body: packageAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ في تحميل البيانات')),
        data: (package) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // SECTION 1: Package header
              _PackageHeaderCard(package: package),
              const SizedBox(height: 16),

              // SECTION 2: Services list
              _ServicesCard(services: package?.services ?? []),
              const SizedBox(height: 16),

              // SECTION 3: Requests usage
              _RequestsUsageCard(package: package),
              const SizedBox(height: 16),

              // SECTION 4: Account manager
              amAsync.when(
                loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
                error: (_, __) => const SizedBox.shrink(),
                data: (am) => am != null ? _AccountManagerCard(am: am) : const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),

              // SECTION 5: Quick links
              _QuickLinksSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Package header card ──────────────────────────────
class _PackageHeaderCard extends StatelessWidget {
  final PackageModel? package;
  const _PackageHeaderCard({this.package});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (package?.status) {
      'active' => RabhanTheme.primaryGreen,
      'trial'  => RabhanTheme.gold,
      _        => Colors.red,
    };
    final statusLabel = switch (package?.status) {
      'active' => 'نشطة',
      'trial'  => 'تجريبية',
      'expired'=> 'منتهية',
      _        => package?.status ?? '—',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RabhanTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RabhanTheme.gold.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        children: [
          // Crown icon
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: RabhanTheme.gold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.workspace_premium, color: RabhanTheme.gold, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  package?.packageName ?? 'Growth Pro',
                  style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 13)),
                ]),
                if (package?.renewsAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'تتجدد في ${_formatArabicDate(package!.renewsAt!)}',
                    style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          // Tier badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: RabhanTheme.gold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: RabhanTheme.gold.withOpacity(0.4)),
            ),
            child: Text(
              'الباقة',
              style: TextStyle(color: RabhanTheme.gold, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _formatArabicDate(DateTime d) {
    const months = ['يناير','فبراير','مارس','أبريل','مايو','يونيو',
                    'يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ── Services card ────────────────────────────────────
class _ServicesCard extends StatelessWidget {
  final List<String> services;
  const _ServicesCard({required this.services});

  @override
  Widget build(BuildContext context) {
    return _RabhanCard(
      title: 'الخدمات المشمولة',
      child: Column(
        children: services.map((s) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            Icon(Icons.check_circle_outline, color: RabhanTheme.primaryGreen, size: 18),
            const SizedBox(width: 10),
            Text(s, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ]),
        )).toList(),
      ),
    );
  }
}

// ── Requests usage card ──────────────────────────────
class _RequestsUsageCard extends StatelessWidget {
  final PackageModel? package;
  const _RequestsUsageCard({this.package});

  @override
  Widget build(BuildContext context) {
    final used  = package?.requestsUsed ?? 0;
    final limit = package?.requestsLimit ?? 200;
    final pct   = limit == 0 ? 0.0 : used / limit;
    final barColor = pct > 0.9 ? Colors.red
                   : pct > 0.7 ? RabhanTheme.gold
                   : RabhanTheme.primaryGreen;

    return _RabhanCard(
      title: 'استخدام الطلبات الشهرية',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$used من $limit شهري',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              Text(
                '${limit - used} متبقي',
                style: TextStyle(color: barColor, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Account manager card ─────────────────────────────
class _AccountManagerCard extends StatelessWidget {
  final ProfileModel am; // your existing profile model
  const _AccountManagerCard({required this.am});

  @override
  Widget build(BuildContext context) {
    return _RabhanCard(
      title: 'مدير الحساب',
      child: Row(
        children: [
          // Avatar
          Stack(children: [
            CircleAvatar(
              radius: 26,
              backgroundImage: am.avatarUrl != null ? NetworkImage(am.avatarUrl!) : null,
              child: am.avatarUrl == null ? Text(am.initials, style: const TextStyle(fontSize: 18)) : null,
            ),
            // Online indicator
            Positioned(
              bottom: 0, right: 0,
              child: Container(
                width: 12, height: 12,
                decoration: BoxDecoration(
                  color: RabhanTheme.primaryGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: RabhanTheme.card, width: 2),
                ),
              ),
            ),
          ]),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(am.fullName, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                const Text('متصل الآن', style: TextStyle(color: Color(0xFF2EE59D), fontSize: 12)),
              ],
            ),
          ),
          // Action buttons
          Row(children: [
            _AmActionBtn(icon: Icons.chat_bubble_outline, onTap: () => context.push('/chat')),
            const SizedBox(width: 8),
            _AmActionBtn(icon: Icons.video_call_outlined, onTap: () => context.push('/dashboard/meetings')),
            const SizedBox(width: 8),
            _AmActionBtn(icon: Icons.mail_outline, onTap: () { /* launch email */ }),
          ]),
        ],
      ),
    );
  }
}

class _AmActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _AmActionBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: Colors.white70, size: 18),
    ),
  );
}

// ── Quick links ──────────────────────────────────────
class _QuickLinksSection extends StatelessWidget {
  final links = const [
    (label: 'الفواتير والمدفوعات', icon: Icons.receipt_outlined,    route: '/dashboard/billing'),
    (label: 'تقارير الأداء',       icon: Icons.bar_chart_outlined,  route: '/reports'),
    (label: 'مركز المساعدة والدعم',icon: Icons.help_outline,        route: '/dashboard/ai-assistant'),
    (label: 'الإعدادات',           icon: Icons.settings_outlined,   route: '/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RabhanTheme.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: links.map((l) => ListTile(
          leading: Icon(l.icon, color: const Color(0xFF9CA3AF), size: 20),
          title: Text(l.label, style: const TextStyle(color: Colors.white, fontSize: 14)),
          trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF), size: 18),
          onTap: () => context.push(l.route),
        )).toList(),
      ),
    );
  }
}

// ── Reusable card wrapper ────────────────────────────
class _RabhanCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _RabhanCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RabhanTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(
            color: Color(0xFF9CA3AF), fontSize: 13, fontWeight: FontWeight.w500,
          )),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
```

## Provider for package data

```dart
// lib/features/rabhan/providers/package_provider.dart
final packageProvider = FutureProvider.family<PackageModel?, String>((ref, projectId) async {
  final supabase = ref.read(supabaseProvider);
  final data = await supabase
      .from('packages')
      .select()
      .eq('project_id', projectId)
      .order('created_at', ascending: false)
      .limit(1)
      .maybeSingle();
  return data != null ? PackageModel.fromJson(data) : null;
});

final accountManagerProvider = FutureProvider.family<ProfileModel?, String>((ref, projectId) async {
  final supabase = ref.read(supabaseProvider);
  final project = await supabase
      .from('projects')
      .select('account_manager_id, profiles!account_manager_id(*)')
      .eq('id', projectId)
      .single();
  final amData = project['profiles'];
  return amData != null ? ProfileModel.fromJson(amData) : null;
});
```

## ✅ Agent 4 done when

- Growth Pro screen renders with gold crown, package name, status, renewal date
- Services list populates from `packages.services` JSON array
- Requests usage bar shows correct percentage with color coding
- Account manager card shows AM name, avatar, online status, 3 action buttons
- Quick links navigate to correct existing routes

---

---

# ═══════════════════════════════════════════════

# AGENT 5 — WEB DASHBOARD (ADMIN + AM)

# ═══════════════════════════════════════════════

## Your job

Extend the existing admin and account manager web dashboard with Rabhan-specific
screens. All web screens are Flutter Web — same codebase, same Riverpod.

## New admin routes to add (web only)

```dart
// Add to existing admin GoRoute children
GoRoute(
  path: 'packages',
  builder: (ctx, s) => const AdminPackagesScreen(),
  routes: [
    GoRoute(
      path: ':projectId',
      builder: (ctx, s) => AdminPackageDetailScreen(projectId: s.pathParameters['projectId']!),
    ),
  ],
),
GoRoute(
  path: 'metrics',
  builder: (ctx, s) => const AdminMetricsScreen(),
),
```

## New AM routes to add

```dart
// Add to existing AM GoRoute children
GoRoute(
  path: 'metrics',
  builder: (ctx, s) => const AmMetricsInputScreen(),
),
```

## Screen: AdminPackagesScreen

**What it shows:** Table of all client packages across all projects.

```
┌──────────────────────────────────────────────────────────────────┐
│  إدارة الباقات                              [+ باقة جديدة]        │
├──────────────────────────────────────────────────────────────────┤
│ العميل        │ الباقة      │ الحالة  │ التجديد  │ الاستخدام │ ⋯  │
├───────────────┼─────────────┼─────────┼──────────┼────────────┼───┤
│ متجر النخبة   │ Growth Pro  │ ● نشطة  │ 28 يوليو │ 128/200    │ ✎ │
│ ستور برو      │ Starter     │ ● نشطة  │ 15 أغسطس │ 44/100     │ ✎ │
│ ماركة مودة    │ Growth Pro  │ ⚠ قريباً │ 3 يوليو  │ 189/200    │ ✎ │
└──────────────────────────────────────────────────────────────────┘
```

Columns: Client name, Package name, Status badge, Renewal date, Requests used/limit, Edit button.

Filter bar: All / نشطة / تجريبية / تنتهي خلال 7 أيام

## Screen: AdminPackageDetailScreen / Edit Modal

Fields to edit:

- Package name (text field)
- Package tier (dropdown: starter | growth | pro | enterprise)
- Status (dropdown: active | trial | expired | suspended)
- Renewal date (date picker)
- Requests limit (number field)
- Requests used (number field — for manual correction)
- Services (multi-line tag input — each line = one service)

On save → `UPDATE packages SET ... WHERE id = ?`
On save → trigger OneSignal notification if status changed to expired.

## Screen: AdminMetricsScreen

**Purpose:** Admin-level view of ALL client metrics.

Shows a sortable table:

- Client name | Period | Sales | ROAS | Orders | Conversion | Published? | AM

Filter by: AM name, date range, published/draft

## Screen: AmMetricsInputScreen

**Purpose:** AM enters or updates e-commerce metrics for their assigned projects.

```
┌─────────────────────────────────────────────────────┐
│  إدخال مقاييس الأداء                                  │
│  المشروع: متجر النخبة ▼                               │
├─────────────────────────────────────────────────────┤
│  الفترة الزمنية                                       │
│  من: [تاريخ]     إلى: [تاريخ]    النوع: [شهري ▼]    │
├─────────────────────────────────────────────────────┤
│  المقاييس الحالية        المقاييس السابقة (مقارنة)    │
│  المبيعات: [______]      المبيعات السابقة: [______]   │
│  الطلبات:  [______]      الطلبات السابقة:  [______]   │
│  ROAS:     [______]      ROAS السابق:       [______]   │
│  معدل التحويل: [___]     معدل التحويل السابق: [___]   │
│  صافي الربح: [______]                                 │
│  إجمالي الإنفاق: [____]                               │
│  الانطباعات: [_____]     النقرات: [________]          │
│  إضافة للسلة: [____]                                   │
├─────────────────────────────────────────────────────┤
│              [معاينة]  [حفظ كمسودة]  [نشر للعميل]    │
└─────────────────────────────────────────────────────┘
```

On **نشر للعميل** → set `is_published = true`, `published_at = now()`, `published_by = auth.uid()`
→ invoke edge function `send-metrics-update` to push notification to client

## Extended: SharedClientHubScreen

Add these new tabs inside `RabhanFeature` to the existing SharedClientHubScreen:

```dart
// Add after existing tabs (Tasks, Approvals, Files, Reports, Chat)
if (config.flavorName == 'rabhan') ...[
  Tab(text: 'المقاييس'),    // → shows ecom_metrics history for this project
  Tab(text: 'محركات النمو'), // → shows growth_engines cards for this project
  Tab(text: 'الباقة'),       // → shows package card + edit button for admin/AM
  Tab(text: 'الحملات'),      // → shows ad_campaigns table for this project
],
```

## Extended: AdminClientsScreen (Rabhan flavor)

Add columns to the existing clients table:

- Package tier badge (Growth Pro, Starter, etc.)
- Current ROAS
- Renewal days remaining (show red if < 7)
- Pending approvals count badge

## Extended: AdminOverviewScreen (Rabhan flavor)

Replace existing KPI cards with e-commerce aggregate stats:

```dart
// Top stats row (admin dashboard)
[
  KpiCard(label: 'إجمالي المبيعات (الشهر)', value: 'ر.س 1,256,800'),
  KpiCard(label: 'متوسط ROAS',               value: '4.2x'),
  KpiCard(label: 'عملاء نشطون',             value: '48'),
  KpiCard(label: 'موافقات معلقة',            value: '12', isAlert: true),
]
```

Data from: aggregate SQL query across all projects' latest `ecom_metrics`.

## ✅ Agent 5 done when

- `/admin/packages` shows filterable table of all client packages
- AM can fill in and publish metrics for a client project
- Client immediately sees updated KPIs on mobile after AM publishes
- SharedClientHubScreen has the 4 new Rabhan tabs

---

---

# ═══════════════════════════════════════════════

# AGENT 6 — SUPABASE EDGE FUNCTIONS

# ═══════════════════════════════════════════════

## Your job

Create 3 new Supabase Edge Functions. All use the existing
`send-notification` pattern (OneSignal HTTP API).

## Function 1 — send-metrics-update

**Trigger:** Called manually from AmMetricsInputScreen when AM clicks "نشر للعميل"

```typescript
// supabase/functions/send-metrics-update/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  const { project_id, metrics_id } = await req.json();

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Get client's OneSignal player ID
  const { data: project } = await supabase
    .from("projects")
    .select("client_id, project_name")
    .eq("id", project_id)
    .single();

  const { data: profile } = await supabase
    .from("profiles")
    .select("onesignal_player_id")
    .eq("id", project.client_id)
    .single();

  if (!profile?.onesignal_player_id) {
    return new Response(
      JSON.stringify({ sent: false, reason: "no player id" }),
    );
  }

  // Send via OneSignal
  const notifRes = await fetch("https://onesignal.com/api/v1/notifications", {
    method: "POST",
    headers: {
      Authorization: `Basic ${Deno.env.get("ONESIGNAL_REST_API_KEY")}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      app_id: Deno.env.get("ONESIGNAL_APP_ID"),
      include_player_ids: [profile.onesignal_player_id],
      headings: { ar: "تقرير الأداء الجديد 📊" },
      contents: {
        ar: `تم نشر مقاييس ${project.project_name} — اطلع عليها الآن`,
      },
      data: { route: "/dashboard", type: "metrics_update", project_id },
    }),
  });

  return new Response(JSON.stringify({ sent: notifRes.ok }));
});
```

## Function 2 — send-package-expiry-alert

**Trigger:** Supabase scheduled cron job — runs daily at 9am

```typescript
// supabase/functions/send-package-expiry-alert/index.ts
// Find all packages expiring in exactly 7 days and notify clients
serve(async (_req) => {
  const supabase = createClient(...)

  const sevenDaysFromNow = new Date()
  sevenDaysFromNow.setDate(sevenDaysFromNow.getDate() + 7)
  const targetDate = sevenDaysFromNow.toISOString().split('T')[0]

  const { data: expiringPackages } = await supabase
    .from('packages')
    .select('id, package_name, project_id, projects(client_id, project_name)')
    .eq('status', 'active')
    .gte('renews_at', targetDate + 'T00:00:00')
    .lte('renews_at', targetDate + 'T23:59:59')

  for (const pkg of expiringPackages ?? []) {
    const clientId = pkg.projects.client_id
    const { data: profile } = await supabase
      .from('profiles')
      .select('onesignal_player_id')
      .eq('id', clientId)
      .single()

    if (!profile?.onesignal_player_id) continue

    await fetch('https://onesignal.com/api/v1/notifications', {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${Deno.env.get('ONESIGNAL_REST_API_KEY')}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        app_id: Deno.env.get('ONESIGNAL_APP_ID'),
        include_player_ids: [profile.onesignal_player_id],
        headings: { ar: 'تجديد الباقة قريباً 👑' },
        contents: { ar: `باقتك "${pkg.package_name}" ستنتهي خلال 7 أيام` },
        data: { route: '/dashboard/package', type: 'package_expiry' },
      }),
    })
  }

  return new Response(JSON.stringify({ processed: expiringPackages?.length ?? 0 }))
})
```

Add the cron schedule in `supabase/config.toml`:

```toml
[functions.send-package-expiry-alert]
schedule = "0 9 * * *"
```

## Function 3 — send-approval-request (extend existing)

If the existing `send-notification` function doesn't already handle approvals,
add this case to it. When a new row is inserted into `approvals` with
`status = 'pending'`, a database trigger fires this function.

```sql
-- Database trigger
create or replace function public.notify_approval_created()
returns trigger language plpgsql as $$
begin
  perform net.http_post(
    url := current_setting('app.edge_function_url') || '/send-approval-request',
    body := json_build_object(
      'project_id', NEW.project_id,
      'approval_id', NEW.id,
      'title', NEW.title
    )::text
  );
  return NEW;
end;
$$;

create trigger on_approval_created
  after insert on public.approvals
  for each row execute function public.notify_approval_created();
```

## ✅ Agent 6 done when

- `supabase functions deploy send-metrics-update` deploys without error
- `supabase functions deploy send-package-expiry-alert` deploys without error
- Test call: AM publishes metrics → client receives push notification within 5 seconds
- Cron job listed in Supabase dashboard scheduled functions

---

---

# ═══════════════════════════════════════════════

# AGENT 7 — QA & INTEGRATION CHECKLIST

# ═══════════════════════════════════════════════

## Your job

Run through every item below. Fix whatever fails. Do NOT add new features.

## Build verification

```bash
# Both flavors must build without error
flutter build apk --flavor moharek -t lib/main_moharek.dart
flutter build apk --flavor rabhan  -t lib/main_rabhan.dart
flutter build web --flavor rabhan  -t lib/main_rabhan.dart
```

## Flavor isolation checks

- [ ] Moharek flavor shows Moharek logo, Outfit font, original green, NO e-commerce KPI section
- [ ] Rabhan flavor shows ربحان logo, Cairo font, dark background with gold accents
- [ ] `enableGrowthSystem` flag: set to false → GrowthSystemScreen route returns 404 or redirects
- [ ] `enableEcomMetrics` flag: set to false → no KPI section on dashboard

## RTL checks (Rabhan only)

- [ ] All padding/margin direction flips correctly (start = right in RTL)
- [ ] Icons that imply direction (chevron_right becomes chevron_left in RTL) flip correctly
- [ ] Charts/graphs don't mirror incorrectly (numeric axis stays on correct side)
- [ ] Text in all cards/headers aligns right

## Data flow end-to-end tests

- [ ] AM creates metrics in web dashboard → client sees updated KPIs on mobile within 10s (real-time)
- [ ] Admin creates package for project → client sees package on Growth Pro screen
- [ ] AM publishes metrics → push notification arrives on test device
- [ ] Package expiry edge function returns `{ processed: N }` on manual invocation
- [ ] Client approves item on mobile → AM sees status change in web hub immediately

## RLS security tests

```sql
-- Run these as a CLIENT JWT (use Supabase Auth test user)
-- All of these should return 0 rows or permission denied

-- Client cannot see other projects' metrics
select * from ecom_metrics where project_id != '<own_project_id>';

-- Client cannot see other projects' packages
select * from packages where project_id != '<own_project_id>';

-- Client cannot insert metrics
insert into ecom_metrics (project_id, period_start, period_end)
values ('<own_project_id>', now(), now());
-- Should fail with RLS violation
```

## Growth Pro screen visual checks

- [ ] Gold border on package header card renders correctly
- [ ] Status badge: active=green, trial=gold, expired=red
- [ ] Progress bar color changes: < 70% green, 70–90% gold, > 90% red
- [ ] AM card shows correct avatar (not broken image) and name
- [ ] Quick links all navigate to correct routes

## Performance checks

- [ ] Dashboard with KPI section loads in < 3 seconds on 4G
- [ ] Package screen loads in < 2 seconds
- [ ] No loading flicker on Growth Pro screen (use cached providers)

## ✅ Agent 7 done when

- All checkboxes above are checked
- Both flavors build and run on physical device
- No crashes on cold start, session restore, or deep links

---

---

## 📁 FILE TREE — NEW FILES CREATED BY ALL AGENTS

```
lib/
├── main_rabhan.dart                              ← Agent 1
├── core/
│   ├── config/
│   │   └── rabhan_config.dart                   ← Agent 1
│   └── theme/
│       └── rabhan_theme.dart                    ← Agent 1
├── features/
│   └── rabhan/
│       ├── models/
│       │   ├── ecom_metrics.dart                ← Agent 3
│       │   ├── package_model.dart               ← Agent 4
│       │   ├── growth_engine_model.dart          ← Agent 3
│       │   └── ad_campaign_model.dart            ← Agent 3
│       ├── providers/
│       │   ├── metrics_provider.dart            ← Agent 3
│       │   ├── package_provider.dart            ← Agent 4
│       │   ├── engines_provider.dart            ← Agent 3
│       │   └── campaigns_provider.dart          ← Agent 3
│       ├── screens/
│       │   ├── growth_pro_screen.dart           ← Agent 4 ★
│       │   ├── growth_system_screen.dart        ← Agent 3
│       │   └── rabhan_analytics_screen.dart     ← Agent 3
│       └── widgets/
│           ├── ecom_kpi_section.dart            ← Agent 3
│           ├── journey_stage_tracker.dart       ← Agent 3
│           ├── kpi_card.dart                    ← Agent 3
│           └── rabhan_feature.dart              ← Agent 3
assets/
└── rabhan/
    ├── logo.png                                 ← Agent 1
    ├── logo_dark.png                            ← Agent 1
    └── splash.png                              ← Agent 1
supabase/
├── migrations/
│   ├── 001_packages.sql                        ← Agent 2
│   ├── 002_ecom_metrics.sql                    ← Agent 2
│   ├── 003_growth_engines.sql                  ← Agent 2
│   ├── 004_ad_campaigns.sql                    ← Agent 2
│   ├── 005_tasks_extension.sql                 ← Agent 2
│   └── 006_db_functions.sql                    ← Agent 2
└── functions/
    ├── send-metrics-update/index.ts             ← Agent 6
    ├── send-package-expiry-alert/index.ts       ← Agent 6
    └── send-approval-request/index.ts           ← Agent 6
```

---

## 🔑 ENV VARIABLES REQUIRED

Add these to your CI/CD and local `.env.rabhan`:

```bash
RABHAN_SUPABASE_URL=https://your-project.supabase.co
RABHAN_SUPABASE_ANON_KEY=eyJ...
RABHAN_ONESIGNAL_APP_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
ONESIGNAL_REST_API_KEY=your_rest_api_key
RABHAN_WP_MEDIA_URL=https://your-wordpress-site.com/wp-json/wp/v2/media
```

---

## ⚠️ CRITICAL RULES FOR ALL AGENTS

1. **Never drop or rename existing tables, columns, or routes.** Only add.
2. **Never modify Moharek-flavored screens.** Wrap everything in `RabhanFeature`.
3. **Never hardcode project IDs or user IDs.** Always read from auth context.
4. **All new text in Arabic.** English only for code identifiers and technical labels.
5. **All new Supabase tables must have RLS enabled immediately** — no exceptions.
6. **The Growth Pro screen is client-read-only.** Only admin/AM can edit packages via web dashboard.
7. **Use the existing `ProfileModel`, `ProjectModel`, and auth providers.** Don't rewrite them.
8. **Test with a real Supabase JWT** before marking any database task done.
