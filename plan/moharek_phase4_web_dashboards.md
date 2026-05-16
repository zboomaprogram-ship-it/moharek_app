# Moharek Growth Hub — Phase 4: Dual Web Dashboards
**Admin Dashboard + Account Manager Dashboard**
**Built with Flutter Web | Deployed free on Vercel | $0/month**
**Date: May 2026**

---

## Overview

Two completely separate web dashboards, same Flutter codebase, role-based routing after login.

```
https://admin.moharek.app  →  After login as 'admin'        → Admin Dashboard
https://admin.moharek.app  →  After login as 'account_manager' → AM Dashboard
```

Both are Flutter Web apps built from the same project. Role detected from `profiles.team_role` on login → GoRouter redirects to the correct dashboard automatically.

---

## ⚠️ Critical Architecture Decision

**Do NOT build two separate Flutter projects.** One project, one login screen, one router. The role determines which shell layout loads. This saves 40% of development time and keeps the codebase in sync.

```
lib/
  features/
    auth/                    ← shared login
    admin_dashboard/         ← admin-only screens
    am_dashboard/            ← account manager-only screens
    shared_client_hub/       ← client detail screens (shared by both dashboards)
```

---

## New Database Tables (run these first)

```sql
-- ============================================
-- AM Performance Tracking
-- ============================================
create table am_performance (
  id uuid primary key default gen_random_uuid(),
  am_id uuid references profiles(id),
  period_month date,  -- first day of the month: 2026-05-01
  total_clients int default 0,
  active_clients int default 0,
  avg_client_health_score numeric default 0,
  tasks_created int default 0,
  tasks_completed int default 0,
  reports_uploaded int default 0,
  approvals_created int default 0,
  avg_response_time_hours numeric default 0, -- avg time to reply in chat
  client_satisfaction_avg numeric default 0, -- avg NPS score from their clients
  updated_at timestamptz default now(),
  unique(am_id, period_month)
);

-- ============================================
-- Invitation System
-- ============================================
create table invitations (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  invited_role text check (invited_role in ('account_manager','client')),
  invited_by uuid references profiles(id),
  project_id uuid references projects(id),     -- null for AM invites
  assigned_am_id uuid references profiles(id), -- for client invites
  status text default 'pending' check (status in ('pending','accepted','expired')),
  token text unique default gen_random_uuid()::text,
  expires_at timestamptz default now() + interval '7 days',
  accepted_at timestamptz,
  created_at timestamptz default now()
);

-- ============================================
-- Admin Activity Log (audit trail)
-- ============================================
create table admin_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references profiles(id),
  action text,  -- 'created_am', 'assigned_client', 'deleted_report', etc.
  target_type text,
  target_id uuid,
  metadata jsonb,
  created_at timestamptz default now()
);

-- ============================================
-- New columns on existing tables
-- ============================================

-- Track who created each profile (for admin audit)
alter table profiles add column if not exists created_by uuid references profiles(id);
alter table profiles add column if not exists is_active boolean default true;
alter table profiles add column if not exists notes text; -- admin notes on AM or client

-- Track AM assignment history
alter table projects add column if not exists previous_am_ids uuid[] default '{}';
alter table projects add column if not exists am_assigned_at timestamptz;

-- ============================================
-- RLS additions
-- ============================================

-- AM can only see their own assigned projects
create policy "am_sees_own_projects" on projects for select using (
  account_manager_id = auth.uid() or
  exists (select 1 from profiles where id = auth.uid() and team_role = 'admin')
);

-- AM can update only their own projects
create policy "am_updates_own_projects" on projects for update using (
  account_manager_id = auth.uid() or
  exists (select 1 from profiles where id = auth.uid() and team_role = 'admin')
);

-- AM performance: AM sees own, admin sees all
create policy "am_performance_select" on am_performance for select using (
  am_id = auth.uid() or
  exists (select 1 from profiles where id = auth.uid() and team_role = 'admin')
);

-- Admin logs: admin only
create policy "admin_logs_admin_only" on admin_logs for select using (
  exists (select 1 from profiles where id = auth.uid() and team_role = 'admin')
);

-- Invitations
create policy "invitations_admin_only" on invitations for all using (
  exists (select 1 from profiles where id = auth.uid() and team_role = 'admin')
);
```

---

## Shared: Login + Role Router

### Login Screen (same for admin and AM)
```dart
// lib/features/auth/screens/web_login_screen.dart
class WebLoginScreen extends ConsumerStatefulWidget {
  const WebLoginScreen({super.key});
  @override ConsumerState<WebLoginScreen> createState() => _WebLoginScreenState();
}

class _WebLoginScreenState extends ConsumerState<WebLoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _email.text.trim(), password: _password.text);
      // Router redirect handles role-based navigation automatically
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0F172A),
    body: Center(child: Container(
      width: 400, padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Logo
        const Text('محرك', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 32, fontWeight: FontWeight.w900)),
        const Text('لوحة التحكم', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
        const SizedBox(height: 32),

        // Email
        TextField(controller: _email, textDirection: TextDirection.ltr,
          decoration: _inputDeco('البريد الإلكتروني', Icons.email_outlined)),
        const SizedBox(height: 16),

        // Password
        TextField(controller: _password, obscureText: true, textDirection: TextDirection.ltr,
          decoration: _inputDeco('كلمة المرور', Icons.lock_outlined)),

        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13))],
        const SizedBox(height: 24),

        SizedBox(width: double.infinity, height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: _loading ? null : _login,
            child: _loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('تسجيل الدخول', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)))),
      ]),
    )),
  );

  InputDecoration _inputDeco(String hint, IconData icon) => InputDecoration(
    hintText: hint, prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
    filled: true, fillColor: const Color(0xFF0F172A),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    hintStyle: const TextStyle(color: Color(0xFF64748B)));
}
```

### GoRouter — Role-Based Redirect
```dart
// lib/core/router/app_router.dart
final appRouter = GoRouter(
  refreshListenable: GoRouterRefreshStream(
    Supabase.instance.client.auth.onAuthStateChange),
  redirect: (context, state) async {
    final session = Supabase.instance.client.auth.currentSession;
    final isLoginPage = state.matchedLocation == '/login';

    if (session == null) return isLoginPage ? null : '/login';

    // Fetch role
    final profile = await Supabase.instance.client
        .from('profiles')
        .select('team_role, is_client, is_active')
        .eq('id', session.user.id)
        .single();

    // Block deactivated users
    if (!(profile['is_active'] ?? true)) {
      await Supabase.instance.client.auth.signOut();
      return '/login';
    }

    final role = profile['team_role'] as String?;
    final isClient = profile['is_client'] as bool? ?? false;

    // Clients should use the mobile app, not the web panel
    if (isClient) {
      await Supabase.instance.client.auth.signOut();
      return '/login'; // or show "use mobile app" page
    }

    if (isLoginPage) {
      return role == 'admin' ? '/admin' : '/am';
    }

    // Prevent AM from accessing admin routes
    if (state.matchedLocation.startsWith('/admin') && role != 'admin') return '/am';
    // Prevent admin from accidentally on AM routes (redirect back)
    if (state.matchedLocation.startsWith('/am') && role == 'admin') return '/admin';

    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const WebLoginScreen()),

    // ── ADMIN DASHBOARD ───────────────────────────────────
    ShellRoute(
      builder: (context, state, child) => AdminShell(child: child),
      routes: [
        GoRoute(path: '/admin', redirect: (_, __) async => '/admin/overview'),
        GoRoute(path: '/admin/overview',   builder: (_, __) => const AdminOverviewScreen()),
        GoRoute(path: '/admin/team',       builder: (_, __) => const AdminTeamScreen()),
        GoRoute(path: '/admin/team/:amId', builder: (_, s) => AdminAmDetailScreen(amId: s.pathParameters['amId']!)),
        GoRoute(path: '/admin/clients',    builder: (_, __) => const AdminClientsScreen()),
        GoRoute(path: '/admin/clients/:projectId', builder: (_, s) => SharedClientHubScreen(projectId: s.pathParameters['projectId']!, isAdmin: true)),
        GoRoute(path: '/admin/reports',    builder: (_, __) => const AdminReportsScreen()),
        GoRoute(path: '/admin/billing',    builder: (_, __) => const AdminBillingScreen()),
        GoRoute(path: '/admin/logs',       builder: (_, __) => const AdminLogsScreen()),
        GoRoute(path: '/admin/settings',   builder: (_, __) => const AdminSettingsScreen()),
      ],
    ),

    // ── ACCOUNT MANAGER DASHBOARD ──────────────────────────
    ShellRoute(
      builder: (context, state, child) => AmShell(child: child),
      routes: [
        GoRoute(path: '/am', redirect: (_, __) async => '/am/clients'),
        GoRoute(path: '/am/clients',   builder: (_, __) => const AmClientsScreen()),
        GoRoute(path: '/am/clients/:projectId', builder: (_, s) => SharedClientHubScreen(projectId: s.pathParameters['projectId']!, isAdmin: false)),
        GoRoute(path: '/am/tasks',     builder: (_, __) => const AmTasksScreen()),
        GoRoute(path: '/am/approvals', builder: (_, __) => const AmApprovalsScreen()),
        GoRoute(path: '/am/reports',   builder: (_, __) => const AmReportsScreen()),
        GoRoute(path: '/am/chat',      builder: (_, __) => const AmChatScreen()),
        GoRoute(path: '/am/calendar',  builder: (_, __) => const AmCalendarScreen()),
        GoRoute(path: '/am/profile',   builder: (_, __) => const AmProfileScreen()),
      ],
    ),
  ],
);
```

---

## Part 1 — Admin Dashboard

### Shell Layout
```dart
// lib/features/admin_dashboard/widgets/admin_shell.dart
class AdminShell extends StatelessWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF080B12),
    body: Row(children: [
      // Fixed sidebar (260px)
      const AdminSidebar(),
      // Main content area
      Expanded(child: Column(children: [
        const AdminTopBar(),
        Expanded(child: child),
      ])),
    ]),
  );
}

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({super.key});

  static const _items = [
    (icon: Icons.dashboard_outlined,    label: 'النظرة العامة',    path: '/admin/overview'),
    (icon: Icons.people_alt_outlined,   label: 'فريق العمل',      path: '/admin/team'),
    (icon: Icons.business_center_outlined, label: 'العملاء',       path: '/admin/clients'),
    (icon: Icons.bar_chart_outlined,    label: 'التقارير',        path: '/admin/reports'),
    (icon: Icons.payments_outlined,     label: 'المالية',         path: '/admin/billing'),
    (icon: Icons.history_outlined,      label: 'سجل العمليات',    path: '/admin/logs'),
    (icon: Icons.settings_outlined,     label: 'الإعدادات',      path: '/admin/settings'),
  ];

  @override Widget build(BuildContext context) {
    final current = GoRouterState.of(context).matchedLocation;
    return Container(
      width: 260, color: const Color(0xFF0F172A),
      child: Column(children: [
        // Logo
        Container(padding: const EdgeInsets.all(24),
          child: const Row(children: [
            Text('محرك', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 22, fontWeight: FontWeight.w900)),
            SizedBox(width: 8),
            Text('Admin', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
          ])),
        const Divider(color: Color(0xFF1E293B)),
        Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          children: _items.map((item) {
            final active = current.startsWith(item.path);
            return _SidebarItem(icon: item.icon, label: item.label, path: item.path, active: active);
          }).toList())),
        // Logged-in admin info at bottom
        const _SidebarUserCard(),
      ]),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon; final String label; final String path; final bool active;
  const _SidebarItem({required this.icon, required this.label, required this.path, required this.active});
  @override Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(10),
    onTap: () => context.go(path),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF4CAF50).withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: active ? Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)) : null),
      child: Row(children: [
        Icon(icon, size: 20, color: active ? const Color(0xFF4CAF50) : const Color(0xFF64748B)),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: active ? const Color(0xFF4CAF50) : const Color(0xFF94A3B8), fontSize: 14, fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
      ])));
}
```

---

### Screen 1 — Admin Overview
**Path:** `/admin/overview`

```dart
// lib/features/admin_dashboard/screens/admin_overview_screen.dart
class AdminOverviewScreen extends ConsumerWidget {
  const AdminOverviewScreen({super.key});

  @override Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminOverviewProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _PageHeader(title: 'النظرة العامة', subtitle: 'ملخص أداء محرك هذا الشهر'),
        const SizedBox(height: 24),

        // ── Top KPI cards (4 across) ──────────────────────
        stats.when(
          loading: () => const _KpiRowSkeleton(),
          error: (e, _) => Text('$e'),
          data: (d) => Row(children: [
            _KpiCard(label: 'إجمالي العملاء',        value: '${d.totalClients}',       icon: Icons.business_center, color: const Color(0xFF4CAF50)),
            const SizedBox(width: 16),
            _KpiCard(label: 'عملاء نشطون',           value: '${d.activeClients}',      icon: Icons.check_circle_outline, color: const Color(0xFF2196F3)),
            const SizedBox(width: 16),
            _KpiCard(label: 'مديرو الحسابات',        value: '${d.totalAMs}',           icon: Icons.people_alt_outlined, color: const Color(0xFFFFC107)),
            const SizedBox(width: 16),
            _KpiCard(label: 'متوسط مؤشر الصحة',     value: '${d.avgHealthScore.toStringAsFixed(0)}%', icon: Icons.favorite_outline, color: const Color(0xFFEF4444)),
          ]),
        ),

        const SizedBox(height: 28),

        // ── Two columns: AM performance table + Alerts ────
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // AM Performance Table (60%)
          Expanded(flex: 6, child: _AmPerformanceTable()),
          const SizedBox(width: 20),
          // Alerts & pending actions (40%)
          Expanded(flex: 4, child: Column(children: [
            _AlertsCard(),
            const SizedBox(height: 16),
            _RecentActivityCard(),
          ])),
        ]),

        const SizedBox(height: 28),

        // ── Client health distribution chart ──────────────
        _ClientHealthDistributionChart(),
      ]),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label; final String value; final IconData icon; final Color color;
  const _KpiCard({required this.label, required this.value, required this.icon, required this.color});
  @override Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20)),
        ]),
        const SizedBox(height: 16),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
      ]),
    ),
  );
}

// AM Performance table widget
class _AmPerformanceTable extends ConsumerWidget {
  @override Widget build(BuildContext context, WidgetRef ref) {
    final ams = ref.watch(amPerformanceListProvider);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('أداء مديري الحسابات', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        // Table header
        const _TableHeader(),
        const Divider(color: Color(0xFF334155)),
        // Rows
        ams.when(
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFF4CAF50)))),
          error: (e, _) => Text('$e', style: const TextStyle(color: Colors.red)),
          data: (list) => Column(children: list.map((am) => _AmPerformanceRow(am: am)).toList())),
      ]),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();
  @override Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Expanded(flex: 3, child: _TH('مدير الحساب')),
      Expanded(flex: 1, child: _TH('العملاء')),
      Expanded(flex: 2, child: _TH('متوسط الصحة')),
      Expanded(flex: 2, child: _TH('المهام المكتملة')),
      Expanded(flex: 2, child: _TH('رضا العملاء')),
      Expanded(flex: 2, child: _TH('وقت الاستجابة')),
      Expanded(flex: 1, child: _TH('')),
    ]),
  );
}

class _TH extends StatelessWidget {
  final String t; const _TH(this.t);
  @override Widget build(_) => Text(t, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600));
}

class _AmPerformanceRow extends StatelessWidget {
  final AmPerformance am;
  const _AmPerformanceRow({required this.am});
  @override Widget build(BuildContext context) => InkWell(
    onTap: () => context.go('/admin/team/${am.amId}'),
    child: Padding(padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        // Name + avatar
        Expanded(flex: 3, child: Row(children: [
          CircleAvatar(radius: 16, backgroundColor: const Color(0xFF4CAF50).withOpacity(0.2),
            backgroundImage: am.avatarUrl != null ? NetworkImage(am.avatarUrl!) : null,
            child: am.avatarUrl == null ? Text(am.name[0], style: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.w700)) : null),
          const SizedBox(width: 10),
          Expanded(child: Text(am.name, style: const TextStyle(color: Colors.white, fontSize: 14),
            overflow: TextOverflow.ellipsis)),
        ])),
        // Client count
        Expanded(flex: 1, child: Text('${am.totalClients}', style: const TextStyle(color: Color(0xFF94A3B8)))),
        // Avg health score with bar
        Expanded(flex: 2, child: Row(children: [
          Container(width: 60, height: 6, decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(3)),
            child: FractionallySizedBox(widthFactor: am.avgHealthScore / 100, alignment: AlignmentDirectional.centerStart,
              child: Container(decoration: BoxDecoration(
                color: am.avgHealthScore >= 70 ? const Color(0xFF4CAF50) : am.avgHealthScore >= 40 ? const Color(0xFFFFC107) : const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(3))))),
          const SizedBox(width: 6),
          Text('${am.avgHealthScore.toStringAsFixed(0)}%', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
        ])),
        // Task completion rate
        Expanded(flex: 2, child: Text(
          am.tasksCreated > 0 ? '${((am.tasksCompleted / am.tasksCreated) * 100).toStringAsFixed(0)}%' : '—',
          style: const TextStyle(color: Color(0xFF94A3B8)))),
        // Client satisfaction
        Expanded(flex: 2, child: Row(children: [
          const Icon(Icons.star, size: 14, color: Color(0xFFFFC107)),
          const SizedBox(width: 4),
          Text(am.clientSatisfactionAvg > 0 ? am.clientSatisfactionAvg.toStringAsFixed(1) : '—',
            style: const TextStyle(color: Color(0xFF94A3B8))),
        ])),
        // Avg response time
        Expanded(flex: 2, child: Text(
          am.avgResponseTimeHours > 0 ? '${am.avgResponseTimeHours.toStringAsFixed(1)} ساعة' : '—',
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13))),
        // Action
        Expanded(flex: 1, child: TextButton(
          onPressed: () => context.go('/admin/team/${am.amId}'),
          child: const Text('تفاصيل', style: TextStyle(color: Color(0xFF2196F3), fontSize: 13)))),
      ]),
    ),
  );
}
```

---

### Screen 2 — Admin Team Management
**Path:** `/admin/team`

```dart
class AdminTeamScreen extends ConsumerWidget {
  const AdminTeamScreen({super.key});

  @override Widget build(BuildContext context, WidgetRef ref) {
    final ams = ref.watch(allAmProfilesProvider);
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const _PageHeader(title: 'فريق العمل', subtitle: 'إدارة مديري الحسابات وصلاحياتهم'),
          const Spacer(),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
            icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
            label: const Text('إضافة مدير حساب', style: TextStyle(color: Colors.white)),
            onPressed: () => _showInviteAmDialog(context)),
        ]),
        const SizedBox(height: 24),

        // AM cards grid
        ams.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50))),
          error: (e, _) => Text('$e'),
          data: (list) => Expanded(child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, childAspectRatio: 1.6, crossAxisSpacing: 16, mainAxisSpacing: 16),
            itemCount: list.length,
            itemBuilder: (_, i) => _AmCard(am: list[i])))),
      ]),
    );
  }

  void _showInviteAmDialog(BuildContext context) => showDialog(
    context: context, builder: (_) => const _InviteAmDialog());
}

class _AmCard extends StatelessWidget {
  final AmProfile am;
  const _AmCard({required this.am});
  @override Widget build(BuildContext context) => InkWell(
    onTap: () => context.go('/admin/team/${am.id}'),
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(14),
        border: !am.isActive ? Border.all(color: const Color(0xFFEF4444).withOpacity(0.4)) : null),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 22, backgroundColor: const Color(0xFF4CAF50).withOpacity(0.2),
            backgroundImage: am.avatarUrl != null ? NetworkImage(am.avatarUrl!) : null,
            child: am.avatarUrl == null ? Text(am.name[0], style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 18, fontWeight: FontWeight.w700)) : null),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: am.isActive ? const Color(0xFF4CAF50).withOpacity(0.12) : const Color(0xFFEF4444).withOpacity(0.12),
              borderRadius: BorderRadius.circular(6)),
            child: Text(am.isActive ? 'نشط' : 'موقوف',
              style: TextStyle(color: am.isActive ? const Color(0xFF4CAF50) : const Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 14),
        Text(am.name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
        Text(am.email, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
        const Spacer(),
        Row(children: [
          _StatChip(icon: Icons.people_outline, label: '${am.clientCount} عميل'),
          const SizedBox(width: 8),
          _StatChip(icon: Icons.favorite_outline, label: '${am.avgHealthScore.toStringAsFixed(0)}%'),
        ]),
      ]),
    ),
  );
}

// Invite AM Dialog
class _InviteAmDialog extends ConsumerStatefulWidget {
  const _InviteAmDialog();
  @override ConsumerState<_InviteAmDialog> createState() => _InviteAmDialogState();
}

class _InviteAmDialogState extends ConsumerState<_InviteAmDialog> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _done = false;

  Future<void> _invite() async {
    if (_name.text.isEmpty || _email.text.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      // 1. Invite via Supabase Auth (sends email automatically)
      await Supabase.instance.client.auth.admin.inviteUserByEmail(
        _email.text.trim(),
        data: {'full_name': _name.text.trim(), 'team_role': 'account_manager'},
      );
      // 2. Log the action
      await Supabase.instance.client.from('admin_logs').insert({
        'actor_id': Supabase.instance.client.auth.currentUser!.id,
        'action': 'invited_am',
        'target_type': 'profile',
        'metadata': {'email': _email.text.trim(), 'name': _name.text.trim()},
      });
      // 3. Store in invitations table
      await Supabase.instance.client.from('invitations').insert({
        'email': _email.text.trim(),
        'invited_role': 'account_manager',
        'invited_by': Supabase.instance.client.auth.currentUser!.id,
      });
      setState(() { _loading = false; _done = true; });
    } catch (e) {
      setState(() { _error = '$e'; _loading = false; });
    }
  }

  @override Widget build(BuildContext context) => AlertDialog(
    backgroundColor: const Color(0xFF1E293B),
    title: const Text('إضافة مدير حساب جديد', style: TextStyle(color: Colors.white)),
    content: _done
      ? Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 48),
          const SizedBox(height: 12),
          const Text('تم إرسال دعوة بالبريد الإلكتروني', style: TextStyle(color: Colors.white)),
          Text('سيتلقى ${_email.text} رابط تفعيل الحساب', style: const TextStyle(color: Color(0xFF94A3B8))),
        ])
      : SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _name, decoration: _inputDeco('الاسم الكامل')),
          const SizedBox(height: 14),
          TextField(controller: _email, textDirection: TextDirection.ltr,
            decoration: _inputDeco('البريد الإلكتروني')),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12))],
        ])),
    actions: _done
      ? [TextButton(onPressed: () => Navigator.pop(context), child: const Text('تم', style: TextStyle(color: Color(0xFF4CAF50))))]
      : [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Color(0xFF64748B)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
            onPressed: _loading ? null : _invite,
            child: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('إرسال الدعوة', style: TextStyle(color: Colors.white))),
        ],
  );

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint, hintStyle: const TextStyle(color: Color(0xFF64748B)),
    filled: true, fillColor: const Color(0xFF0F172A),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none));
}
```

### Screen 3 — AM Detail (Admin view of one AM)
**Path:** `/admin/team/:amId`

```dart
class AdminAmDetailScreen extends ConsumerWidget {
  final String amId;
  const AdminAmDetailScreen({super.key, required this.amId});

  @override Widget build(BuildContext context, WidgetRef ref) {
    final am = ref.watch(amDetailProvider(amId));
    final clients = ref.watch(amClientsProvider(amId));
    final perf = ref.watch(amPerformanceHistoryProvider(amId));

    return SingleChildScrollView(padding: const EdgeInsets.all(28), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Back button
        TextButton.icon(icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('الفريق'), onPressed: () => context.go('/admin/team'),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF64748B))),
        const SizedBox(height: 16),

        am.when(loading: () => const SizedBox.shrink(), error: (e,_) => Text('$e'),
          data: (profile) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // AM Profile card
            _AmProfileCard(profile: profile, onToggleActive: () => _toggleActive(context, ref, profile),
              onResetPassword: () => _resetPassword(context, profile.email)),
            const SizedBox(width: 20),
            // Performance summary cards
            Expanded(child: Column(children: [
              perf.when(loading: () => const SizedBox.shrink(), error: (e,_) => Text('$e'),
                data: (p) => Row(children: [
                  _KpiCard(label: 'العملاء',        value: '${p.totalClients}',   icon: Icons.people_outline, color: const Color(0xFF4CAF50)),
                  const SizedBox(width: 12),
                  _KpiCard(label: 'متوسط الصحة',    value: '${p.avgHealthScore.toStringAsFixed(0)}%', icon: Icons.favorite_outline, color: const Color(0xFF2196F3)),
                  const SizedBox(width: 12),
                  _KpiCard(label: 'رضا العملاء',    value: p.clientSatisfactionAvg > 0 ? '${p.clientSatisfactionAvg.toStringAsFixed(1)}/5' : '—', icon: Icons.star_outline, color: const Color(0xFFFFC107)),
                  const SizedBox(width: 12),
                  _KpiCard(label: 'وقت الاستجابة',  value: p.avgResponseTimeHours > 0 ? '${p.avgResponseTimeHours.toStringAsFixed(1)}h' : '—', icon: Icons.timer_outlined, color: const Color(0xFFEF4444)),
                ])),
            ])),
          ])),

        const SizedBox(height: 28),

        // Clients assigned to this AM
        Row(children: [
          const Text('عملاء مُعيَّنون', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const Spacer(),
          OutlinedButton.icon(
            icon: const Icon(Icons.person_add_alt_1, size: 16),
            label: const Text('إضافة عميل'),
            style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF4CAF50), side: const BorderSide(color: Color(0xFF4CAF50))),
            onPressed: () => _showCreateClientDialog(context, amId)),
        ]),
        const SizedBox(height: 16),
        clients.when(
          loading: () => const CircularProgressIndicator(color: Color(0xFF4CAF50)),
          error: (e, _) => Text('$e'),
          data: (list) => _ClientsTable(clients: list, showReassignButton: true, currentAmId: amId)),
      ]),
    );
  }

  Future<void> _toggleActive(BuildContext context, WidgetRef ref, AmProfile profile) async {
    final confirm = await showDialog<bool>(context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(profile.isActive ? 'إيقاف الحساب' : 'تفعيل الحساب',
          style: const TextStyle(color: Colors.white)),
        content: Text(profile.isActive
          ? 'سيفقد ${profile.name} القدرة على تسجيل الدخول. عملاؤه لن يتأثروا.'
          : 'سيستعيد ${profile.name} القدرة على تسجيل الدخول.',
          style: const TextStyle(color: Color(0xFF94A3B8))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: profile.isActive ? Colors.red : const Color(0xFF4CAF50)),
            onPressed: () => Navigator.pop(context, true),
            child: Text(profile.isActive ? 'إيقاف' : 'تفعيل', style: const TextStyle(color: Colors.white))),
        ]));
    if (confirm != true) return;
    await Supabase.instance.client.from('profiles')
        .update({'is_active': !profile.isActive}).eq('id', amId);
    await Supabase.instance.client.from('admin_logs').insert({
      'actor_id': Supabase.instance.client.auth.currentUser!.id,
      'action': profile.isActive ? 'deactivated_am' : 'activated_am',
      'target_type': 'profile', 'target_id': amId,
    });
    ref.invalidate(amDetailProvider(amId));
  }

  Future<void> _resetPassword(BuildContext context, String email) async {
    await Supabase.instance.client.auth.resetPasswordForEmail(email);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إرسال رابط إعادة تعيين كلمة المرور')));
  }
}
```

---

### Screen 4 — Admin Clients
**Path:** `/admin/clients`

```dart
class AdminClientsScreen extends ConsumerStatefulWidget {
  const AdminClientsScreen({super.key});
  @override ConsumerState<AdminClientsScreen> createState() => _AdminClientsScreenState();
}

class _AdminClientsScreenState extends ConsumerState<AdminClientsScreen> {
  String _search = '';
  String? _filterAmId;
  String _filterStatus = 'all';

  @override Widget build(BuildContext context) {
    final clients = ref.watch(allClientsProvider);
    final ams = ref.watch(allAmProfilesProvider);
    return Padding(padding: const EdgeInsets.all(28), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const _PageHeader(title: 'العملاء', subtitle: 'جميع عملاء محرك'),
          const Spacer(),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('إضافة عميل جديد', style: TextStyle(color: Colors.white)),
            onPressed: () => _showCreateClientDialog(context, null)),
        ]),
        const SizedBox(height: 20),

        // Filters row
        Row(children: [
          // Search
          SizedBox(width: 260, child: TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: 'بحث باسم العميل أو الشركة...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
              filled: true, fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)))),
          const SizedBox(width: 12),

          // Filter by AM
          ams.whenOrNull(data: (list) => DropdownButton<String?>(
            value: _filterAmId,
            dropdownColor: const Color(0xFF1E293B),
            style: const TextStyle(color: Colors.white),
            hint: const Text('كل المديرين', style: TextStyle(color: Color(0xFF64748B))),
            items: [
              const DropdownMenuItem(value: null, child: Text('كل المديرين', style: TextStyle(color: Color(0xFF94A3B8)))),
              ...list.map((am) => DropdownMenuItem(value: am.id, child: Text(am.name))),
            ],
            onChanged: (v) => setState(() => _filterAmId = v))) ?? const SizedBox.shrink(),
          const SizedBox(width: 12),

          // Filter by status
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'all', label: Text('الكل')),
              ButtonSegment(value: 'active', label: Text('نشط')),
              ButtonSegment(value: 'paused', label: Text('موقوف')),
            ],
            selected: {_filterStatus},
            onSelectionChanged: (s) => setState(() => _filterStatus = s.first),
            style: ButtonStyle(backgroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? const Color(0xFF4CAF50).withOpacity(0.2) : const Color(0xFF1E293B)))),
        ]),
        const SizedBox(height: 16),

        // Clients table
        Expanded(child: clients.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50))),
          error: (e, _) => Text('$e'),
          data: (list) {
            final filtered = list.where((c) {
              final matchSearch = _search.isEmpty || c.companyName.contains(_search) || c.clientName.contains(_search);
              final matchAm = _filterAmId == null || c.amId == _filterAmId;
              final matchStatus = _filterStatus == 'all' || c.status == _filterStatus;
              return matchSearch && matchAm && matchStatus;
            }).toList();
            return _FullClientsTable(clients: filtered);
          })),
      ]),
    );
  }
}

class _FullClientsTable extends StatelessWidget {
  final List<ClientSummary> clients;
  const _FullClientsTable({required this.clients});

  @override Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(14)),
    child: Column(children: [
      // Header row
      const Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(children: [
          Expanded(flex: 3, child: _TH('العميل / الشركة')),
          Expanded(flex: 2, child: _TH('مدير الحساب')),
          Expanded(flex: 1, child: _TH('الحالة')),
          Expanded(flex: 2, child: _TH('مؤشر الصحة')),
          Expanded(flex: 2, child: _TH('آخر نشاط')),
          Expanded(flex: 1, child: _TH('تاريخ البدء')),
          Expanded(flex: 1, child: _TH('')),
        ])),
      const Divider(color: Color(0xFF334155), height: 1),
      // Data rows
      ...clients.asMap().entries.map((e) => Column(children: [
        _ClientTableRow(client: e.value),
        if (e.key < clients.length - 1) const Divider(color: Color(0xFF1E293B), height: 1),
      ])),
    ]),
  );
}

class _ClientTableRow extends StatelessWidget {
  final ClientSummary client;
  const _ClientTableRow({required this.client});
  @override Widget build(BuildContext context) => InkWell(
    onTap: () => context.go('/admin/clients/${client.projectId}'),
    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(children: [
        Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(client.companyName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          Text(client.clientName, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
        ])),
        Expanded(flex: 2, child: Row(children: [
          CircleAvatar(radius: 12, backgroundColor: const Color(0xFF4CAF50).withOpacity(0.2),
            child: Text(client.amName[0], style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 11))),
          const SizedBox(width: 6),
          Text(client.amName, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
        ])),
        Expanded(flex: 1, child: _StatusChip(status: client.status)),
        Expanded(flex: 2, child: _HealthBar(score: client.healthScore)),
        Expanded(flex: 2, child: Text(client.lastActivityAgo, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13))),
        Expanded(flex: 1, child: Text(client.startDateFormatted, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12))),
        Expanded(flex: 1, child: Row(children: [
          IconButton(icon: const Icon(Icons.open_in_new, size: 16, color: Color(0xFF2196F3)),
            tooltip: 'فتح ملف العميل', onPressed: () => context.go('/admin/clients/${client.projectId}')),
          IconButton(icon: const Icon(Icons.swap_horiz, size: 16, color: Color(0xFF64748B)),
            tooltip: 'إعادة تعيين مدير الحساب', onPressed: () => _showReassignDialog(context, client)),
        ])),
      ])),
  );

  void _showReassignDialog(BuildContext context, ClientSummary client) => showDialog(
    context: context, builder: (_) => _ReassignAmDialog(client: client));
}

class _ReassignAmDialog extends ConsumerStatefulWidget {
  final ClientSummary client;
  const _ReassignAmDialog({required this.client});
  @override ConsumerState<_ReassignAmDialog> createState() => _ReassignAmDialogState();
}

class _ReassignAmDialogState extends ConsumerState<_ReassignAmDialog> {
  String? _selectedAmId;
  bool _loading = false;

  Future<void> _reassign() async {
    if (_selectedAmId == null) return;
    setState(() => _loading = true);
    await Supabase.instance.client.from('projects').update({
      'account_manager_id': _selectedAmId,
      'am_assigned_at': DateTime.now().toIso8601String(),
    }).eq('id', widget.client.projectId);
    await Supabase.instance.client.from('admin_logs').insert({
      'actor_id': Supabase.instance.client.auth.currentUser!.id,
      'action': 'reassigned_client',
      'target_type': 'project', 'target_id': widget.client.projectId,
      'metadata': {'old_am': widget.client.amId, 'new_am': _selectedAmId},
    });
    if (mounted) Navigator.pop(context);
    ref.invalidate(allClientsProvider);
  }

  @override Widget build(BuildContext context) {
    final ams = ref.watch(allAmProfilesProvider);
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: const Text('إعادة تعيين مدير الحساب', style: TextStyle(color: Colors.white)),
      content: SizedBox(width: 360, child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('عميل: ${widget.client.companyName}', style: const TextStyle(color: Color(0xFF94A3B8))),
        Text('المدير الحالي: ${widget.client.amName}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        const SizedBox(height: 16),
        ams.when(
          loading: () => const CircularProgressIndicator(color: Color(0xFF4CAF50)),
          error: (e, _) => Text('$e'),
          data: (list) => DropdownButton<String>(
            value: _selectedAmId, isExpanded: true,
            dropdownColor: const Color(0xFF1E293B),
            hint: const Text('اختر مدير حساب جديد', style: TextStyle(color: Color(0xFF64748B))),
            items: list.where((a) => a.id != widget.client.amId).map((am) =>
              DropdownMenuItem(value: am.id, child: Row(children: [
                CircleAvatar(radius: 12, backgroundColor: const Color(0xFF4CAF50).withOpacity(0.2),
                  child: Text(am.name[0], style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 11))),
                const SizedBox(width: 8),
                Text(am.name, style: const TextStyle(color: Colors.white)),
                const Spacer(),
                Text('${am.clientCount} عميل', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
              ]))).toList(),
            onChanged: (v) => setState(() => _selectedAmId = v))),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
          onPressed: _selectedAmId == null || _loading ? null : _reassign,
          child: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('تأكيد التعيين', style: TextStyle(color: Colors.white))),
      ]);
  }
}
```

---

### Create Client Dialog (used by admin)
```dart
class _CreateClientDialog extends ConsumerStatefulWidget {
  final String? preAssignedAmId; // if opened from AM detail screen
  const _CreateClientDialog({this.preAssignedAmId});
  @override ConsumerState<_CreateClientDialog> createState() => _CreateClientDialogState();
}

class _CreateClientDialogState extends ConsumerState<_CreateClientDialog> {
  final _name = TextEditingController();
  final _company = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  String? _selectedAmId;
  bool _loading = false;
  String? _error;
  bool _done = false;

  @override void initState() {
    super.initState();
    _selectedAmId = widget.preAssignedAmId;
  }

  Future<void> _create() async {
    if (_name.text.isEmpty || _email.text.isEmpty || _selectedAmId == null) {
      setState(() => _error = 'يرجى تعبئة جميع الحقول المطلوبة');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      // 1. Create auth user + profile via Supabase invite
      final invite = await Supabase.instance.client.auth.admin.inviteUserByEmail(
        _email.text.trim(),
        data: {
          'full_name': _name.text.trim(),
          'company_name': _company.text.trim(),
          'is_client': true,
          'phone': _phone.text.trim(),
        },
      );

      // 2. Create profile row (trigger handles this via auth webhook, but ensure it exists)
      await Supabase.instance.client.from('profiles').upsert({
        'id': invite.user!.id,
        'full_name': _name.text.trim(),
        'company_name': _company.text.trim(),
        'is_client': true,
        'phone': _phone.text.trim(),
        'preferred_locale': 'ar',
        'created_by': Supabase.instance.client.auth.currentUser!.id,
      });

      // 3. Create project
      final project = await Supabase.instance.client.from('projects').insert({
        'client_id': invite.user!.id,
        'account_manager_id': _selectedAmId,
        'name': '${_company.text.trim()} — Growth Project',
        'start_date': DateTime.now().toIso8601String().split('T')[0],
        'am_assigned_at': DateTime.now().toIso8601String(),
      }).select().single();

      // 4. Create default chat channel for client ↔ AM
      await Supabase.instance.client.from('chat_channels').insert({
        'project_id': project['id'],
        'name': 'Account Manager',
        'name_ar': 'مدير الحساب',
        'channel_type': 'account_manager',
      });

      // 5. Create default journey stages
      final stages = ['audit','strategy','setup','execution','optimization','results'];
      await Supabase.instance.client.from('journey_stages').insert(
        stages.asMap().entries.map((e) => {
          'project_id': project['id'],
          'stage_name': e.value,
          'order_index': e.key,
        }).toList());

      // 6. Create 5 engine progress rows
      final engines = ['content','ai_visibility','seo','trust','conversion'];
      await Supabase.instance.client.from('engine_progress').insert(
        engines.map((e) => {'project_id': project['id'], 'engine': e, 'progress_percent': 0}).toList());

      // 7. Log
      await Supabase.instance.client.from('admin_logs').insert({
        'actor_id': Supabase.instance.client.auth.currentUser!.id,
        'action': 'created_client',
        'target_type': 'project', 'target_id': project['id'],
        'metadata': {'client_name': _name.text.trim(), 'am_id': _selectedAmId},
      });

      setState(() { _done = true; _loading = false; });
    } catch (e) {
      setState(() { _error = '$e'; _loading = false; });
    }
  }

  @override Widget build(BuildContext context) {
    final ams = ref.watch(allAmProfilesProvider);
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: const Text('إضافة عميل جديد', style: TextStyle(color: Colors.white)),
      content: _done ? _successContent() : _formContent(ams),
      actions: _done
        ? [ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
            onPressed: () { Navigator.pop(context); ref.invalidate(allClientsProvider); },
            child: const Text('تم', style: TextStyle(color: Colors.white)))]
        : [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
              onPressed: _loading ? null : _create,
              child: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('إنشاء الحساب', style: TextStyle(color: Colors.white))),
          ]);
  }

  Widget _successContent() => SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 56),
    const SizedBox(height: 12),
    const Text('تم إنشاء حساب العميل', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
    const SizedBox(height: 6),
    Text('سيتلقى ${_email.text} رسالة تفعيل الحساب وتنزيل التطبيق',
      style: const TextStyle(color: Color(0xFF94A3B8)), textAlign: TextAlign.center),
  ]));

  Widget _formContent(AsyncValue ams) => SizedBox(width: 480, child: Column(mainAxisSize: MainAxisSize.min, children: [
    Row(children: [
      Expanded(child: _Field('الاسم الكامل *', _name)),
      const SizedBox(width: 12),
      Expanded(child: _Field('اسم الشركة', _company)),
    ]),
    const SizedBox(height: 12),
    Row(children: [
      Expanded(child: _Field('البريد الإلكتروني *', _email, ltr: true)),
      const SizedBox(width: 12),
      Expanded(child: _Field('رقم الهاتف', _phone, ltr: true)),
    ]),
    const SizedBox(height: 12),
    // AM assignment dropdown
    ams.when(
      loading: () => const CircularProgressIndicator(color: Color(0xFF4CAF50)),
      error: (e, _) => Text('$e'),
      data: (list) => DropdownButtonFormField<String>(
        value: _selectedAmId, isExpanded: true,
        dropdownColor: const Color(0xFF1E293B),
        decoration: InputDecoration(labelText: 'تعيين مدير حساب *',
          labelStyle: const TextStyle(color: Color(0xFF64748B)),
          filled: true, fillColor: const Color(0xFF0F172A),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
        hint: const Text('اختر مدير الحساب', style: TextStyle(color: Color(0xFF64748B))),
        items: list.map((am) => DropdownMenuItem(value: am.id,
          child: Text(am.name, style: const TextStyle(color: Colors.white)))).toList(),
        onChanged: (v) => setState(() => _selectedAmId = v))),
    if (_error != null) ...[
      const SizedBox(height: 10),
      Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12))],
  ]));

  Widget _Field(String label, TextEditingController ctrl, {bool ltr = false}) =>
    TextField(controller: ctrl, textDirection: ltr ? TextDirection.ltr : TextDirection.rtl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Color(0xFF64748B)),
        filled: true, fillColor: const Color(0xFF0F172A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)));
}
```

---

## Part 2 — Account Manager Dashboard

### AM Shell Layout
```dart
// lib/features/am_dashboard/widgets/am_shell.dart
class AmShell extends ConsumerWidget {
  final Widget child;
  const AmShell({super.key, required this.child});

  @override Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF080B12),
      body: Row(children: [
        // Sidebar (220px)
        Container(width: 220, color: const Color(0xFF0F172A),
          child: Column(children: [
            // Header
            Container(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('محرك', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              profile.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (p) => Text(p?.fullName ?? '', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12), overflow: TextOverflow.ellipsis)),
            ])),
            const Divider(color: Color(0xFF1E293B)),

            // Nav items
            Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              children: const [
                _AmNavItem(icon: Icons.people_alt_outlined,      label: 'عملائي',          path: '/am/clients'),
                _AmNavItem(icon: Icons.task_alt_outlined,         label: 'المهام',          path: '/am/tasks'),
                _AmNavItem(icon: Icons.check_box_outlined,        label: 'الموافقات',       path: '/am/approvals'),
                _AmNavItem(icon: Icons.description_outlined,      label: 'التقارير',        path: '/am/reports'),
                _AmNavItem(icon: Icons.chat_bubble_outline,       label: 'المحادثات',       path: '/am/chat'),
                _AmNavItem(icon: Icons.calendar_month_outlined,   label: 'الاجتماعات',      path: '/am/calendar'),
              ])),

            // Profile + logout at bottom
            const Divider(color: Color(0xFF1E293B)),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFF64748B), size: 18),
              title: const Text('تسجيل الخروج', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) context.go('/login');
              }),
          ])),

        // Content
        Expanded(child: Column(children: [
          const AmTopBar(),
          Expanded(child: child),
        ])),
      ]),
    );
  }
}
```

---

### AM Screen 1 — My Clients
**Path:** `/am/clients`

```dart
class AmClientsScreen extends ConsumerStatefulWidget {
  const AmClientsScreen({super.key});
  @override ConsumerState<AmClientsScreen> createState() => _AmClientsScreenState();
}

class _AmClientsScreenState extends ConsumerState<AmClientsScreen> {
  String _search = '';
  String _filter = 'all'; // all, on_track, needs_attention, delayed

  @override Widget build(BuildContext context) {
    // AM only sees their own clients via RLS automatically
    final clients = ref.watch(myClientsProvider);

    return Padding(padding: const EdgeInsets.all(24), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const _PageHeader(title: 'عملائي', subtitle: 'العملاء المُعيَّنون لك'),
          const Spacer(),
          // Quick stats chips
          clients.whenOrNull(data: (list) => Row(children: [
            _QuickStatChip(label: 'إجمالي', value: list.length, color: const Color(0xFF64748B)),
            const SizedBox(width: 8),
            _QuickStatChip(label: 'سير منتظم', value: list.where((c) => c.status == 'on_track').length, color: const Color(0xFF4CAF50)),
            const SizedBox(width: 8),
            _QuickStatChip(label: 'يحتاج اهتمام', value: list.where((c) => c.healthScore < 50).length, color: const Color(0xFFFFC107)),
          ])) ?? const SizedBox.shrink(),
        ]),
        const SizedBox(height: 20),

        // Search + filter
        Row(children: [
          SizedBox(width: 280, child: TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: 'بحث...', prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
              filled: true, fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)))),
          const SizedBox(width: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'all', label: Text('الكل')),
              ButtonSegment(value: 'on_track', label: Text('سير منتظم')),
              ButtonSegment(value: 'needs_attention', label: Text('يحتاج اهتمام')),
              ButtonSegment(value: 'delayed', label: Text('متأخر')),
            ],
            selected: {_filter},
            onSelectionChanged: (s) => setState(() => _filter = s.first)),
        ]),
        const SizedBox(height: 16),

        // Client cards grid
        Expanded(child: clients.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50))),
          error: (e, _) => Text('$e'),
          data: (list) {
            final filtered = list.where((c) {
              final matchSearch = _search.isEmpty || c.companyName.toLowerCase().contains(_search.toLowerCase());
              final matchFilter = _filter == 'all' ||
                (_filter == 'on_track' && c.healthScore >= 70) ||
                (_filter == 'needs_attention' && c.healthScore < 50) ||
                (_filter == 'delayed' && c.hasDelayedTasks);
              return matchSearch && matchFilter;
            }).toList();

            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, childAspectRatio: 1.8, crossAxisSpacing: 16, mainAxisSpacing: 16),
              itemCount: filtered.length,
              itemBuilder: (_, i) => _AmClientCard(client: filtered[i]));
          })),
      ]),
    );
  }
}

class _AmClientCard extends StatelessWidget {
  final ClientSummary client;
  const _AmClientCard({required this.client});
  @override Widget build(BuildContext context) => InkWell(
    onTap: () => context.go('/am/clients/${client.projectId}'),
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: client.healthScore >= 70 ? const Color(0xFF4CAF50).withOpacity(0.3)
            : client.healthScore >= 40 ? const Color(0xFFFFC107).withOpacity(0.3)
            : const Color(0xFFEF4444).withOpacity(0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(client.companyName, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
          _HealthBadge(score: client.healthScore),
        ]),
        Text(client.clientName, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
        const Spacer(),

        // Quick metrics
        Row(children: [
          _MiniStat(label: 'مهام', value: '${client.tasksInProgress}', icon: Icons.task_alt, color: const Color(0xFF2196F3)),
          const SizedBox(width: 12),
          _MiniStat(label: 'موافقات', value: '${client.pendingApprovals}', icon: Icons.pending_actions, color: const Color(0xFFFFC107)),
          const SizedBox(width: 12),
          _MiniStat(label: 'رسائل', value: '${client.unreadMessages}', icon: Icons.chat_bubble_outline, color: const Color(0xFF4CAF50)),
        ]),

        // Progress bar
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: client.healthScore / 100,
          backgroundColor: const Color(0xFF334155),
          valueColor: AlwaysStoppedAnimation<Color>(
            client.healthScore >= 70 ? const Color(0xFF4CAF50)
              : client.healthScore >= 40 ? const Color(0xFFFFC107)
              : const Color(0xFFEF4444)),
          minHeight: 4, borderRadius: BorderRadius.circular(2)),
      ]),
    ),
  );
}
```

---

### Shared: Client Hub (used by BOTH admin and AM)
**Path:** `/admin/clients/:projectId` and `/am/clients/:projectId`

This is the most important screen. Same widget, `isAdmin` flag controls what extra controls appear.

```dart
// lib/features/shared_client_hub/screens/shared_client_hub_screen.dart
class SharedClientHubScreen extends ConsumerStatefulWidget {
  final String projectId;
  final bool isAdmin;
  const SharedClientHubScreen({super.key, required this.projectId, required this.isAdmin});
  @override ConsumerState<SharedClientHubScreen> createState() => _SharedClientHubScreenState();
}

class _SharedClientHubScreenState extends ConsumerState<SharedClientHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  // 10 tabs — same as original plan
  static const _tabLabels = [
    'النظرة العامة', 'الاستراتيجية', 'المهام',
    'النتائج', 'التقارير', 'الموافقات',
    'الحملات', 'الملفات', 'الفواتير', 'تحديث صوتي',
  ];

  @override void initState() {
    super.initState();
    _tabs = TabController(length: 10, vsync: this);
  }

  @override Widget build(BuildContext context) {
    final project = ref.watch(projectDetailProvider(widget.projectId));
    return project.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50))),
      error: (e, _) => Center(child: Text('$e')),
      data: (p) => Column(children: [
        // Client header bar
        _ClientHeaderBar(project: p, isAdmin: widget.isAdmin),
        // Tab bar
        Container(color: const Color(0xFF0F172A),
          child: TabBar(controller: _tabs, isScrollable: true,
            labelColor: const Color(0xFF4CAF50), unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: const Color(0xFF4CAF50), indicatorSize: TabBarIndicatorSize.label,
            tabs: _tabLabels.map((t) => Tab(text: t)).toList())),
        // Tab content
        Expanded(child: TabBarView(controller: _tabs, children: [
          ClientOverviewTab(projectId: widget.projectId),
          ClientStrategyTab(projectId: widget.projectId),
          ClientTasksTab(projectId: widget.projectId),
          ClientResultsTab(projectId: widget.projectId),
          ClientReportsTab(projectId: widget.projectId),
          ClientApprovalsTab(projectId: widget.projectId),
          ClientCampaignsTab(projectId: widget.projectId),
          ClientFilesTab(projectId: widget.projectId),
          ClientBillingTab(projectId: widget.projectId, isAdmin: widget.isAdmin),
          ClientVoiceUpdateTab(projectId: widget.projectId),
        ])),
      ]),
    );
  }
}

class _ClientHeaderBar extends StatelessWidget {
  final ProjectDetail project;
  final bool isAdmin;
  const _ClientHeaderBar({required this.project, required this.isAdmin});
  @override Widget build(BuildContext context) => Container(
    color: const Color(0xFF1E293B), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    child: Row(children: [
      // Back button
      IconButton(icon: const Icon(Icons.arrow_back_ios, size: 16, color: Color(0xFF64748B)),
        onPressed: () => context.pop()),
      const SizedBox(width: 8),
      // Client info
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(project.companyName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        Text('${project.clientName} · مدير الحساب: ${project.amName}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
      ]),
      const Spacer(),
      // Health badge
      _HealthBadge(score: project.healthScore),
      const SizedBox(width: 16),
      // Status chip
      _StatusChip(status: project.status),
      // Admin-only: extra controls
      if (isAdmin) ...[
        const SizedBox(width: 16),
        OutlinedButton.icon(
          icon: const Icon(Icons.swap_horiz, size: 16),
          label: const Text('إعادة تعيين'),
          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF64748B), side: const BorderSide(color: Color(0xFF334155))),
          onPressed: () => _showReassign(context)),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.pause_circle_outline, size: 16),
          label: Text(project.status == 'active' ? 'إيقاف مؤقت' : 'تفعيل'),
          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFFFC107), side: const BorderSide(color: Color(0xFFFFC107))),
          onPressed: () => _toggleStatus(context, project)),
      ],
    ]),
  );

  void _showReassign(BuildContext context) => showDialog(
    context: context, builder: (_) => _ReassignAmDialog(client: ClientSummary.fromProject(project)));

  Future<void> _toggleStatus(BuildContext context, ProjectDetail p) async {
    final newStatus = p.status == 'active' ? 'paused' : 'active';
    await Supabase.instance.client.from('projects').update({'status': newStatus}).eq('id', p.id);
  }
}
```

### AM Tasks Screen — All tasks across all AM's clients
**Path:** `/am/tasks`
```dart
class AmTasksScreen extends ConsumerStatefulWidget {
  const AmTasksScreen({super.key});
  @override ConsumerState<AmTasksScreen> createState() => _AmTasksScreenState();
}

class _AmTasksScreenState extends ConsumerState<AmTasksScreen> {
  String _filterStatus = 'all';
  String? _filterClientId;

  @override Widget build(BuildContext context) {
    // RLS ensures only tasks for AM's clients are returned
    final tasks = ref.watch(amAllTasksProvider);
    final clients = ref.watch(myClientsProvider);

    return Padding(padding: const EdgeInsets.all(24), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const _PageHeader(title: 'المهام', subtitle: 'كل مهام عملائك'),
          const Spacer(),
          // Filter by client
          clients.whenOrNull(data: (list) => DropdownButton<String?>(
            value: _filterClientId, dropdownColor: const Color(0xFF1E293B),
            hint: const Text('كل العملاء', style: TextStyle(color: Color(0xFF64748B))),
            items: [
              const DropdownMenuItem(value: null, child: Text('كل العملاء', style: TextStyle(color: Color(0xFF94A3B8)))),
              ...list.map((c) => DropdownMenuItem(value: c.projectId, child: Text(c.companyName, style: const TextStyle(color: Colors.white)))),
            ],
            onChanged: (v) => setState(() => _filterClientId = v))) ?? const SizedBox.shrink(),
        ]),
        const SizedBox(height: 16),

        // Status filter tabs
        SingleChildScrollView(scrollDirection: Axis.horizontal,
          child: Row(children: ['all','new','in_progress','waiting_client','under_review','done','delayed'].map((s) =>
            Padding(padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(_statusLabel(s)),
                selected: _filterStatus == s,
                onSelected: (_) => setState(() => _filterStatus = s),
                selectedColor: const Color(0xFF4CAF50).withOpacity(0.2),
                checkmarkColor: const Color(0xFF4CAF50)))).toList())),
        const SizedBox(height: 16),

        // Tasks list
        Expanded(child: tasks.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50))),
          error: (e, _) => Text('$e'),
          data: (list) {
            final filtered = list.where((t) {
              final matchStatus = _filterStatus == 'all' || t.status == _filterStatus;
              final matchClient = _filterClientId == null || t.projectId == _filterClientId;
              return matchStatus && matchClient;
            }).toList();
            return ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, i) => _AmTaskRow(task: filtered[i]));
          })),
      ]),
    );
  }

  String _statusLabel(String s) => {
    'all': 'الكل', 'new': 'جديد', 'in_progress': 'جاري',
    'waiting_client': 'بانتظار العميل', 'under_review': 'قيد المراجعة',
    'done': 'مكتمل', 'delayed': 'متأخر',
  }[s] ?? s;
}
```

### AM Approvals Screen — Pending across all clients
```dart
class AmApprovalsScreen extends ConsumerWidget {
  const AmApprovalsScreen({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final approvals = ref.watch(amPendingApprovalsProvider);
    return Padding(padding: const EdgeInsets.all(24), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _PageHeader(title: 'الموافقات', subtitle: 'الموافقات المعلقة من عملائك'),
        const SizedBox(height: 20),
        Expanded(child: approvals.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50))),
          error: (e, _) => Text('$e'),
          data: (list) => list.isEmpty
            ? const Center(child: Text('لا توجد موافقات معلقة ✅', style: TextStyle(color: Color(0xFF64748B), fontSize: 16)))
            : ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) => _ApprovalRow(approval: list[i])))),
      ]),
    );
  }
}
```

---

## AM Performance — Auto-update via pg_cron

```sql
-- Run once per day: update am_performance table
select cron.schedule('update-am-performance', '0 1 * * *', $$
  insert into am_performance (
    am_id, period_month,
    total_clients, active_clients,
    avg_client_health_score,
    tasks_created, tasks_completed,
    reports_uploaded, approvals_created
  )
  select
    p.account_manager_id,
    date_trunc('month', current_date)::date,
    count(*) as total_clients,
    count(*) filter (where p.status = 'active') as active_clients,
    avg(p.health_score) as avg_health_score,
    (select count(*) from tasks t where t.project_id = any(array_agg(p.id)) and date_trunc('month', t.created_at) = date_trunc('month', current_date)) as tasks_created,
    (select count(*) from tasks t where t.project_id = any(array_agg(p.id)) and t.status = 'done' and date_trunc('month', t.updated_at) = date_trunc('month', current_date)) as tasks_completed,
    (select count(*) from reports r where r.project_id = any(array_agg(p.id)) and date_trunc('month', r.created_at) = date_trunc('month', current_date)) as reports_uploaded,
    (select count(*) from approvals a where a.project_id = any(array_agg(p.id)) and date_trunc('month', a.created_at) = date_trunc('month', current_date)) as approvals_created
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

## Riverpod Providers

```dart
// lib/features/admin_dashboard/providers/admin_providers.dart

// Admin overview stats
final adminOverviewProvider = FutureProvider<AdminOverviewStats>((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final [clients, ams, health] = await Future.wait([
    supabase.from('projects').select('status, health_score'),
    supabase.from('profiles').select('id').eq('team_role', 'account_manager').eq('is_active', true),
    supabase.from('projects').select('health_score'),
  ]);
  return AdminOverviewStats(
    totalClients: (clients as List).length,
    activeClients: (clients as List).where((c) => c['status'] == 'active').length,
    totalAMs: (ams as List).length,
    avgHealthScore: (health as List).isEmpty ? 0 : (health as List).map((h) => (h['health_score'] as num?)?.toDouble() ?? 0).reduce((a, b) => a + b) / (health as List).length,
  );
});

// All AM profiles with client counts
final allAmProfilesProvider = StreamProvider<List<AmProfile>>((ref) {
  return Supabase.instance.client.from('profiles')
    .stream(primaryKey: ['id'])
    .eq('team_role', 'account_manager')
    .map((rows) => rows.map(AmProfile.fromJson).toList());
});

// All clients (admin sees all via RLS)
final allClientsProvider = FutureProvider<List<ClientSummary>>((ref) async {
  final data = await Supabase.instance.client.from('projects').select('''
    id, status, health_score, health_label, start_date, current_stage,
    client:profiles!client_id(id, full_name, company_name),
    am:profiles!account_manager_id(id, full_name),
    tasks(status),
    approvals(status)
  ''').order('created_at', ascending: false);
  return data.map(ClientSummary.fromJson).toList();
});

// AM's own clients (RLS filters automatically)
final myClientsProvider = StreamProvider<List<ClientSummary>>((ref) {
  return Supabase.instance.client.from('projects').stream(primaryKey: ['id']).map((rows) => rows.map(ClientSummary.fromJson).toList());
});

// AM performance list for overview table
final amPerformanceListProvider = FutureProvider<List<AmPerformance>>((ref) async {
  final thisMonth = DateTime(DateTime.now().year, DateTime.now().month);
  final data = await Supabase.instance.client.from('am_performance')
    .select('*, am:profiles!am_id(full_name, avatar_url)')
    .eq('period_month', thisMonth.toIso8601String().split('T')[0])
    .order('avg_client_health_score', ascending: false);
  return data.map(AmPerformance.fromJson).toList();
});

// AM detail
final amDetailProvider = FutureProvider.family<AmProfile, String>((ref, amId) async {
  final data = await Supabase.instance.client.from('profiles').select().eq('id', amId).single();
  return AmProfile.fromJson(data);
});

// AM's assigned clients
final amClientsProvider = FutureProvider.family<List<ClientSummary>, String>((ref, amId) async {
  final data = await Supabase.instance.client.from('projects')
    .select('*, client:profiles!client_id(full_name, company_name)')
    .eq('account_manager_id', amId);
  return data.map(ClientSummary.fromJson).toList();
});

// AM's all tasks across all their clients
final amAllTasksProvider = StreamProvider<List<Task>>((ref) {
  return Supabase.instance.client.from('tasks').stream(primaryKey: ['id'])
    .order('created_at', ascending: false)
    .map((rows) => rows.map(Task.fromJson).toList());
});

// AM's pending approvals across all their clients
final amPendingApprovalsProvider = StreamProvider<List<Approval>>((ref) {
  return Supabase.instance.client.from('approvals').stream(primaryKey: ['id'])
    .eq('status', 'pending')
    .map((rows) => rows.map(Approval.fromJson).toList());
});
```

---

## Deployment — Vercel (Free)

```bash
# Build Flutter Web for both dashboards (same build)
flutter build web --release --base-href "/"

# Deploy to Vercel (free, unlimited)
npm install -g vercel
cd build/web
vercel --prod

# Custom domain setup (optional, free on Vercel):
# admin.moharek.app → same Vercel deployment
# Role-based routing handles admin vs AM after login
```

---

## ⚠️ Critical Reminders

1. **`Supabase.auth.admin.inviteUserByEmail()` requires the service role key.** Never use the service role key in Flutter client code. Call it from a Supabase Edge Function instead.

2. **AM can only call `inviteUserByEmail` if admin delegates — don't give AMs this permission.** In MVP, only admin creates client accounts.

3. **RLS is your security layer** — test every query from an AM's JWT to confirm they only see their assigned projects. Do this with Supabase's "Test RLS policies" feature in the Dashboard before launch.

4. **AM performance metrics run at 1am daily via pg_cron.** The first time you see zeros is because the cron hasn't run yet — manually run the SQL once after setup.

5. **Supabase admin API (for `inviteUserByEmail`) costs nothing on free tier** — it's included.

6. **Flutter Web on Vercel is free** — no server, no cost, deploys in 2 minutes.

---

## Cost Summary

| Item | Cost |
|---|---|
| Flutter Web build | $0 (local) |
| Vercel hosting | $0 (free tier) |
| Supabase (RLS, DB, auth invites) | $0 (free tier) |
| pg_cron for AM performance | $0 (included in Supabase) |
| Custom domain | $0 (use Vercel subdomain) |
| **Total** | **$0/month** |
