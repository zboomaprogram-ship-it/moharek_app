import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/features/am/data/am_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AmShell extends StatelessWidget {
  final Widget child;
  const AmShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 1000;
    final scaffoldKey = GlobalKey<ScaffoldState>();

    if (isMobile) {
      return Scaffold(
        key: scaffoldKey,
        backgroundColor: const Color(0xFF080B12),
        drawer: const Drawer(
          width: 260,
          backgroundColor: Color(0xFF0F172A),
          child: AmSidebar(),
        ),
        body: Column(
          children: [
            AmTopBar(
              onMenuPressed: () => scaffoldKey.currentState?.openDrawer(),
              isMobile: true,
            ),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF080B12),
      body: Row(
        children: [
          const AmSidebar(),
          Expanded(
            child: Column(
              children: [
                const AmTopBar(),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AmSidebar extends ConsumerWidget {
  const AmSidebar({super.key});

  static const _items = [
    (
      icon: Icons.business_center_outlined,
      label: 'عملائي',
      path: '/am/clients',
    ),
    (icon: Icons.task_alt_outlined, label: 'المهام', path: '/am/tasks'),
    (
      icon: Icons.pending_actions_outlined,
      label: 'الموافقات',
      path: '/am/approvals',
    ),
    (icon: Icons.bar_chart_outlined, label: 'التقارير', path: '/am/reports'),
    (icon: Icons.chat_bubble_outline, label: 'المحادثات', path: '/am/chat'),
    (
      icon: Icons.calendar_month_outlined,
      label: 'الاجتماعات',
      path: '/am/calendar',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = GoRouterState.of(context).matchedLocation;

    return Container(
      width: 260,
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Image.asset(
                  'assets/logo.png',
                  height: 32,
                  fit: BoxFit.contain,
                ),
                SizedBox(width: 12),
                Text(
                  'محرك',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'AM',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF1E293B), height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
              children: _items.map((item) {
                final active = current.startsWith(item.path);
                return _SidebarItem(
                  icon: item.icon,
                  label: item.label,
                  path: item.path,
                  active: active,
                );
              }).toList(),
            ),
          ),

          // Profile & Logout
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _SidebarItem(
                  icon: Icons.person_outline,
                  label: 'الملف الشخصي',
                  path: '/am/profile',
                  active: current == '/am/profile',
                ),
                _SidebarItem(
                  icon: Icons.logout,
                  label: 'تسجيل الخروج',
                  path: '',
                  active: false,
                  onTap: () async {
                    // 1. Invalidate first
                    ref.invalidate(profileProvider);
                    ref.invalidate(currentProjectProvider);
                    ref.invalidate(tasksProvider);
                    ref.invalidate(meetingsProvider);
                    ref.invalidate(invoicesProvider);

                    try {
                      await Supabase.instance.client.auth.signOut();
                    } catch (e) {
                      // Ignore
                    }
                    
                    if (context.mounted) context.go('/login');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String path;
  final bool active;
  final VoidCallback? onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.path,
    required this.active,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (onTap != null) {
          onTap!();
        } else {
          context.go(path);
        }
        // Auto-close drawer if we are in one
        if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
          Navigator.pop(context);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.primaryGreen.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: active ? AppTheme.primaryGreen : const Color(0xFF64748B),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: active ? AppTheme.primaryGreen : const Color(0xFF94A3B8),
                fontSize: 14,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AmTopBar extends ConsumerWidget {
  final VoidCallback? onMenuPressed;
  final bool isMobile;

  const AmTopBar({
    super.key,
    this.onMenuPressed,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF080B12),
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        children: [
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: onMenuPressed,
            ),
          const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.notifications_none,
              color: Color(0xFF64748B),
            ),
            onPressed: () => _showNotifications(context, ref),
          ),
          const SizedBox(width: 16),
          const VerticalDivider(
            color: Color(0xFF1E293B),
            indent: 20,
            endIndent: 20,
          ),
          const SizedBox(width: 16),
          profile.when(
            loading: () => const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFF1E293B),
            ),
            error: (_, __) => const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFF1E293B),
              child: Icon(Icons.error, size: 16),
            ),
            data: (p) => Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      p?.fullName ?? 'AM',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'مدير حسابات',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  backgroundImage: p?.avatarUrl != null
                      ? NetworkImage(p!.avatarUrl!)
                      : null,
                  child: p?.avatarUrl == null
                      ? Text(
                          p?.fullName.isNotEmpty == true ? p!.fullName[0] : 'A',
                          style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showNotifications(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final notificationsAsync = ref.watch(amNotificationsProvider);
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                child: const Row(
                  children: [
                    Icon(Icons.notifications_outlined, color: AppTheme.primaryGreen),
                    SizedBox(width: 12),
                    Text(
                      'التنبيهات والنشاط',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF1E293B), height: 1),
              Expanded(
                child: notificationsAsync.when(
                  data: (logs) => logs.isEmpty 
                    ? const Center(child: Text('لا توجد تنبيهات جديدة', style: TextStyle(color: Color(0xFF64748B))))
                    : ListView.separated(
                        itemCount: logs.length,
                        separatorBuilder: (context, index) => const Divider(color: Color(0xFF1E293B), height: 1),
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          final action = log['action_ar'] ?? log['action'] ?? 'نشاط جديد';
                          final projectName = log['projects']?['name'] ?? 'مشروع';
                          final time = DateFormat('HH:mm').format(DateTime.parse(log['created_at']));
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            title: Text(action, style: const TextStyle(color: Colors.white, fontSize: 14)),
                            subtitle: Text(projectName, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                            trailing: Text(time, style: const TextStyle(color: Color(0xFF475569), fontSize: 11)),
                          );
                        },
                      ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
