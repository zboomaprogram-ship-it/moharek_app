import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/features/admin/widgets/admin_activity_feed.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:moharek_app/core/config/app_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/shared/services/data_providers.dart';

class AdminShell extends StatelessWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

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
          child: AdminSidebar(),
        ),
        body: Column(
          children: [
            AdminTopBar(
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
          const AdminSidebar(),
          Expanded(
            child: Column(
              children: [
                const AdminTopBar(),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminSidebar extends ConsumerWidget {
  const AdminSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String current = GoRouterState.of(context).matchedLocation;
    final isRabhan = AppConfig.flavorName == 'rabhan';

    final items = [
      (
        icon: Icons.dashboard_outlined,
        label: 'النظرة العامة',
        path: '/admin/overview',
      ),
      (icon: Icons.people_alt_outlined, label: 'فريق العمل', path: '/admin/team'),
      (
        icon: Icons.business_center_outlined,
        label: 'العملاء',
        path: '/admin/clients',
      ),
      if (isRabhan)
        (
          icon: Icons.inventory_2_outlined,
          label: 'الباقات',
          path: '/admin/packages',
        ),
      (
        icon: Icons.bar_chart_outlined,
        label: isRabhan ? 'تقارير الأداء' : 'التقارير',
        path: '/admin/reports',
      ),
      (icon: Icons.payments_outlined, label: 'المالية', path: '/admin/billing'),
      (icon: Icons.support_agent_outlined, label: 'مركز الدعم', path: '/admin/support'),
      (icon: Icons.history_outlined, label: 'سجل العمليات', path: '/admin/logs'),
      (
        icon: Icons.settings_outlined,
        label: 'الإعدادات',
        path: '/admin/settings',
      ),
    ];

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
                  AppConfig.logoAsset,
                  height: 32,
                  fit: BoxFit.contain,
                ),
                SizedBox(width: 12),
                Text(
                  AppConfig.appName,
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Admin',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF1E293B), height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
              children: items.map((item) {
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

          // Logout
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _SidebarItem(
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

class AdminTopBar extends ConsumerWidget {
  final VoidCallback? onMenuPressed;
  final bool isMobile;

  const AdminTopBar({
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
                if (!isMobile)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        p?.fullName ?? 'Admin',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'مدير النظام',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                      ),
                    ],
                  ),
                const SizedBox(width: 12),
                PopupMenuButton(
                  offset: const Offset(0, 48),
                  color: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.primaryGreen.withValues(
                      alpha: 0.1,
                    ),
                    backgroundImage: p?.avatarUrl != null
                        ? NetworkImage(p!.avatarUrl!)
                        : null,
                    child: p?.avatarUrl == null
                        ? Text(
                            p?.fullName[0] ?? 'A',
                            style: const TextStyle(
                              color: AppTheme.primaryGreen,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  itemBuilder: (context) => <PopupMenuEntry>[
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'الملف الشخصي',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      onTap: () => context.push('/admin/settings'),
                    ),
                    const PopupMenuDivider(color: Color(0xFF334155)),
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(Icons.logout, color: Colors.redAccent, size: 18),
                          SizedBox(width: 12),
                          Text(
                            'تسجيل الخروج',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ],
                      ),
                      onTap: () async {
                        // 1. Invalidate first
                        ref.invalidate(profileProvider);
                        ref.invalidate(currentProjectProvider);
                        ref.invalidate(tasksProvider);
                        ref.invalidate(meetingsProvider);
                        ref.invalidate(invoicesProvider);

                        try {
                          await ref.read(supabaseClientProvider).auth.signOut();
                        } catch (e) {
                          // Ignore
                        }
                        
                        if (context.mounted) context.go('/login');
                      },
                    ),
                  ],
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final feedAsync = ref.watch(activityFeedProvider);
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_outlined,
                      color: AppTheme.primaryGreen,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'نشاط العملاء والنظام',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/admin/notifications');
                      },
                      icon: const Icon(Icons.broadcast_on_home, size: 16),
                      label: const Text(
                        'إرسال تنبيه',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF1E293B), height: 1),
              Expanded(
                child: feedAsync.when(
                  data: (logs) => logs.isEmpty
                      ? const Center(
                          child: Text(
                            'لا يوجد نشاط جديد',
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        )
                      : ListView.separated(
                          itemCount: logs.length,
                          separatorBuilder: (context, index) => const Divider(
                            color: Color(0xFF1E293B),
                            height: 1,
                          ),
                          itemBuilder: (context, index) {
                            final log = logs[index];
                            final action =
                                log['action_ar'] ??
                                log['action'] ??
                                'نشاط جديد';
                            final time = log['created_at'] != null
                                ? log['created_at']
                                      .toString()
                                      .split('T')[1]
                                      .substring(0, 5)
                                : '--:--';
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 8,
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                if (log['project_id'] != null) {
                                  context.push(
                                    '/admin/clients/${log['project_id']}',
                                  );
                                }
                              },
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.flash_on,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                              ),
                              title: Text(
                                action,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                log['entity_type'] ?? 'نظام',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 11,
                                ),
                              ),
                              trailing: Text(
                                time,
                                style: const TextStyle(
                                  color: Color(0xFF475569),
                                  fontSize: 11,
                                ),
                              ),
                            );
                          },
                        ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
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
