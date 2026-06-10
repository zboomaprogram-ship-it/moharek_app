import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/l10n/app_localizations.dart';
import 'package:moharek_app/shared/services/haptic_service.dart';
import 'package:moharek_app/shared/services/connectivity_service.dart';
import 'package:moharek_app/features/dashboard/presentation/widgets/milestone_celebration_overlay.dart';
import 'package:moharek_app/features/dashboard/presentation/widgets/main_drawer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/config/app_config.dart';
import 'package:moharek_app/features/notifications/data/notifications_provider.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({required this.navigationShell, Key? key})
    : super(key: key ?? const ValueKey<String>('MainShell'));

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onTap(BuildContext context, int index) {
    HapticService.light();
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final connectivity = ref.watch(connectivityStatusProvider);
    final isOffline = connectivity.value == ConnectivityStatus.isDisconnected;
    final l10n = AppLocalizations.of(context)!;
    final currentIndex = widget.navigationShell.currentIndex;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final isRabhan = AppConfig.flavorName == 'rabhan';

    final isMobile = MediaQuery.of(context).size.width < 1000;
    final scaffoldKey = GlobalKey<ScaffoldState>();

    // Unread counts logic
    final unreadChat = ref.watch(unreadChatNotificationsCountProvider);
    final unreadTasks = ref.watch(unreadTaskNotificationsCountProvider);
    final unreadApprovals = ref.watch(unreadApprovalNotificationsCountProvider);
    final unreadMeetings = ref.watch(unreadMeetingNotificationsCountProvider);
    final unreadReports = ref.watch(unreadReportNotificationsCountProvider);
    final unreadTotal = ref.watch(unreadNotificationsCountProvider);

    final totalWorkUnread = unreadTasks + unreadApprovals + unreadMeetings;

    Widget buildBadgeIcon({
      required IconData iconData,
      required int count,
      bool active = false,
    }) {
      return Icon(
        iconData,
        color: active ? AppTheme.primaryGreen : Colors.white70,
      );
    }

    return Scaffold(
      key: scaffoldKey,
      drawer: const MainDrawer(),
      body: Row(
        children: [
          if (!isMobile)
            _buildSidebar(
              context,
              l10n,
              currentIndex,
              unreadChat,
              totalWorkUnread,
              unreadTasks,
              unreadReports,
              unreadTotal,
            ),
          Expanded(
            child: Stack(
              children: [
                Column(
                  children: [
                    if (isMobile)
                      ClipRect(
                        child: AnimatedAlign(
                          alignment: Alignment.topCenter,
                          duration: const Duration(milliseconds: 300),
                          heightFactor: isOffline ? 1.0 : 0.0,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            color: Colors.redAccent,
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.wifi_off,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.offlineMessage,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    Expanded(child: widget.navigationShell),
                  ],
                ),
                const MilestoneCelebrationOverlay(),
                if (!isMobile && isOffline)
                  Positioned(
                    top: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.wifi_off,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.offlineMessage,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isMobile
          ? NavigationBar(
              selectedIndex: currentIndex.clamp(0, 4),
              onDestinationSelected: (index) {
                HapticService.light();
                widget.navigationShell.goBranch(
                  index,
                  initialLocation: index == widget.navigationShell.currentIndex,
                );
              },
              backgroundColor: AppTheme.background,
              indicatorColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: isRabhan
                  ? [
                      NavigationDestination(
                        icon: const Icon(Icons.home_outlined),
                        selectedIcon: const Icon(
                          Icons.home,
                          color: AppTheme.primaryGreen,
                        ),
                        label: isAr ? 'الرئيسية' : 'Home',
                      ),
                      NavigationDestination(
                        icon: buildBadgeIcon(
                          iconData: Icons.checklist_outlined,
                          count: totalWorkUnread,
                        ),
                        selectedIcon: buildBadgeIcon(
                          iconData: Icons.checklist,
                          count: totalWorkUnread,
                          active: true,
                        ),
                        label: isAr ? 'العمل' : 'Work',
                      ),
                      NavigationDestination(
                        icon: buildBadgeIcon(
                          iconData: Icons.chat_bubble_outline,
                          count: unreadChat,
                        ),
                        selectedIcon: buildBadgeIcon(
                          iconData: Icons.chat_bubble,
                          count: unreadChat,
                          active: true,
                        ),
                        label: isAr ? 'المحادثات' : 'Chat',
                      ),
                      NavigationDestination(
                        icon: buildBadgeIcon(
                          iconData: Icons.notifications_none_outlined,
                          count: unreadTotal,
                        ),
                        selectedIcon: buildBadgeIcon(
                          iconData: Icons.notifications,
                          count: unreadTotal,
                          active: true,
                        ),
                        label: isAr ? 'الإشعارات' : 'Notifications',
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.grid_view_outlined),
                        selectedIcon: const Icon(
                          Icons.grid_view,
                          color: AppTheme.primaryGreen,
                        ),
                        label: isAr ? 'المزيد' : 'More',
                      ),
                    ]
                  : [
                      NavigationDestination(
                        icon: const Icon(Icons.home_outlined),
                        selectedIcon: const Icon(
                          Icons.home,
                          color: AppTheme.primaryGreen,
                        ),
                        label: l10n.homeTab,
                      ),
                      NavigationDestination(
                        icon: buildBadgeIcon(
                          iconData: Icons.task_alt_outlined,
                          count: unreadTasks,
                        ),
                        selectedIcon: buildBadgeIcon(
                          iconData: Icons.task_alt,
                          count: unreadTasks,
                          active: true,
                        ),
                        label: l10n.tasksTab,
                      ),
                      NavigationDestination(
                        icon: buildBadgeIcon(
                          iconData: Icons.chat_bubble_outline,
                          count: unreadChat,
                        ),
                        selectedIcon: buildBadgeIcon(
                          iconData: Icons.chat_bubble,
                          count: unreadChat,
                          active: true,
                        ),
                        label: l10n.chatTab,
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.analytics_outlined),
                        selectedIcon: const Icon(
                          Icons.analytics,
                          color: AppTheme.primaryGreen,
                        ),
                        label: l10n.resultsTab,
                      ),
                      NavigationDestination(
                        icon: buildBadgeIcon(
                          iconData: Icons.description_outlined,
                          count: unreadReports,
                        ),
                        selectedIcon: buildBadgeIcon(
                          iconData: Icons.description,
                          count: unreadReports,
                          active: true,
                        ),
                        label: isAr ? 'التقارير' : 'Reports',
                      ),
                    ],
            )
          : null,
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    AppLocalizations l10n,
    int currentIndex,
    int unreadChat,
    int totalWorkUnread,
    int unreadTasks,
    int unreadReports,
    int unreadTotal,
  ) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final isRabhan = AppConfig.flavorName == 'rabhan';

    return Container(
      width: 260,
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Image.asset(
            AppConfig.logoAsset,
            height: 120,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 12),
          Text(
            AppConfig.appName,
            style: const TextStyle(
              color: AppTheme.primaryGreen,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 32),
          _SidebarItem(
            icon: Icons.home_outlined,
            label: isRabhan ? (isAr ? 'الرئيسية' : 'Home') : l10n.homeTab,
            active: currentIndex == 0,
            onTap: () => _onTap(context, 0),
          ),
          _SidebarItem(
            icon: isRabhan ? Icons.checklist_outlined : Icons.task_alt_outlined,
            label: isRabhan ? (isAr ? 'العمل' : 'Work') : l10n.tasksTab,
            active: currentIndex == 1,
            onTap: () => _onTap(context, 1),
            badgeCount: isRabhan ? totalWorkUnread : unreadTasks,
          ),
          _SidebarItem(
            icon: Icons.chat_bubble_outline,
            label: isRabhan ? (isAr ? 'المحادثات' : 'Chat') : l10n.chatTab,
            active: currentIndex == 2,
            onTap: () => _onTap(context, 2),
            badgeCount: unreadChat,
          ),
          _SidebarItem(
            icon: isRabhan
                ? Icons.notifications_none_outlined
                : Icons.analytics_outlined,
            label: isRabhan
                ? (isAr ? 'الإشعارات' : 'Notifications')
                : l10n.resultsTab,
            active: currentIndex == 3,
            onTap: () => _onTap(context, 3),
            badgeCount: isRabhan ? unreadTotal : 0,
          ),
          _SidebarItem(
            icon: isRabhan
                ? Icons.grid_view_outlined
                : Icons.description_outlined,
            label: isRabhan
                ? (isAr ? 'المزيد' : 'More')
                : (isAr ? 'التقارير' : 'Reports'),
            active: currentIndex == 4,
            onTap: () => _onTap(context, 4),
            badgeCount: isRabhan ? 0 : unreadReports,
          ),
          const Spacer(),
          _SidebarItem(
            icon: Icons.person_outline,
            label: isAr ? 'الملف الشخصي' : 'Profile',
            active: false,
            onTap: () => context.push('/profile'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final int badgeCount;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    Widget iconWidget = Icon(
      icon,
      color: active ? AppTheme.primaryGreen : Colors.grey,
      size: 20,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: active
                ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              iconWidget,
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: active ? AppTheme.primaryGreen : Colors.grey,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
