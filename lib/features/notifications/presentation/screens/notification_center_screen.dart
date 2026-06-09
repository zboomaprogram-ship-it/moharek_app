import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/core/theme/rabhan_theme_constants.dart';
import 'package:moharek_app/features/notifications/data/notifications_provider.dart';
import 'package:moharek_app/shared/models/notification.dart';
import 'package:moharek_app/shared/widgets/shimmer_placeholders.dart';
import 'package:go_router/go_router.dart';
import 'package:moharek_app/core/router/app_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:moharek_app/core/config/app_config.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/features/rabhan/providers/package_provider.dart';
import 'package:moharek_app/shared/models/profile.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends ConsumerState<NotificationCenterScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final projectAsync = ref.watch(currentProjectProvider);
    final project = projectAsync.valueOrNull;
    final projectId = project?.id ?? '';
    
    final isRabhan = AppConfig.flavorName == 'rabhan';
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    
    final themeBg = isRabhan ? RabhanTheme.background : const Color(0xFF0F172A);
    final themeCard = isRabhan ? RabhanTheme.card : AppTheme.cardColor;
    final themePrimary = isRabhan ? RabhanTheme.primaryGreen : AppTheme.primaryGreen;

    return Scaffold(
      backgroundColor: themeBg,
      appBar: AppBar(
        backgroundColor: themeBg,
        elevation: 0,
        title: Text(
          isAr ? 'التنبيهات' : 'Notifications',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => NotificationService.markAllAsRead(),
            child: Text(
              isAr ? 'تحديد الكل كمقروء' : 'Mark all read',
              style: TextStyle(color: themePrimary, fontSize: 13),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Account Manager Preview (Rabhan Only)
          if (isRabhan && projectId.isNotEmpty) ...[
            _buildAmPreviewSection(projectId, themeCard, isAr),
          ],

          // 2. Sub-Tabs (Rabhan Only)
          if (isRabhan) ...[
            _buildSubTabs(isAr),
          ],

          // 3. Notification List
          Expanded(
            child: notificationsAsync.when(
              loading: () => const ShimmerList(itemCount: 6, itemHeight: 80),
              error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white70))),
              data: (notifications) {
                // Filter notifications based on selected tab if Rabhan
                final filtered = isRabhan 
                    ? _filterNotifications(notifications, _selectedTabIndex)
                    : notifications;

                if (filtered.isEmpty) {
                  return _buildEmptyState(isAr);
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final notification = filtered[index];
                    return FadeInRight(
                      delay: Duration(milliseconds: index * 50),
                      child: _buildNotificationCard(context, notification, isAr, isRabhan, themeCard, themePrimary),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildAmPreviewSection(String projectId, Color cardBg, bool isAr) {
    final amAsync = ref.watch(accountManagerProvider(projectId));

    return amAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (am) {
        if (am == null) return const SizedBox.shrink();

        return FadeInDown(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: RabhanTheme.gold.withAlpha((0.3 * 255).round()), width: 0.5),
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundImage: am.avatarUrl != null && am.avatarUrl!.isNotEmpty 
                          ? NetworkImage(am.avatarUrl!) 
                          : null,
                      backgroundColor: Colors.grey[800],
                      child: am.avatarUrl == null || am.avatarUrl!.isEmpty
                          ? Text(
                              _getInitials(am.fullName), 
                              style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          color: RabhanTheme.primaryGreen,
                          shape: BoxShape.circle,
                          border: Border.all(color: cardBg, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'تواصل مع مدير حسابك' : 'Contact Account Manager',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        am.fullName,
                        style: const TextStyle(
                          color: RabhanTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => context.push('/chat'),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: RabhanTheme.gold),
                  label: Text(
                    isAr ? 'محادثة' : 'Chat',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RabhanTheme.gold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RabhanTheme.gold.withAlpha((0.15 * 255).round()),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: RabhanTheme.gold.withAlpha((0.3 * 255).round())),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubTabs(bool isAr) {
    final List<String> tabLabels = isAr
        ? ['الكل', 'موافقات', 'تحديثات', 'تنبيهات']
        : ['All', 'Approvals', 'Updates', 'Alerts'];

    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(4, (index) {
          final isSelected = _selectedTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(
                  left: isAr ? (index == 0 ? 0 : 8) : (index == 3 ? 0 : 8),
                  right: isAr ? (index == 3 ? 0 : 8) : (index == 0 ? 0 : 8),
                ),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? RabhanTheme.primaryGreen.withAlpha((0.15 * 255).round())
                      : Colors.white.withAlpha(5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected 
                        ? RabhanTheme.primaryGreen.withAlpha((0.4 * 255).round())
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  tabLabels[index],
                  style: TextStyle(
                    color: isSelected ? RabhanTheme.primaryGreen : RabhanTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  List<AppNotification> _filterNotifications(List<AppNotification> list, int tabIndex) {
    switch (tabIndex) {
      case 1: // Approvals
        return list.where((n) => n.type == 'approval').toList();
      case 2: // Updates
        return list.where((n) => n.type == 'task' || n.type == 'milestone' || n.type == 'metrics').toList();
      case 3: // Alerts
        return list.where((n) => n.type == 'invoice' || n.type == 'ticket' || n.type == 'package_alert' || n.type == 'info').toList();
      default: // All
        return list;
    }
  }

  Widget _buildEmptyState(bool isAr) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_none_rounded, color: Colors.white10, size: 80),
          const SizedBox(height: 24),
          Text(
            isAr ? 'لا توجد تنبيهات' : 'No notifications yet',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            isAr ? 'سنقوم بإبلاغك هنا بكل جديد.' : 'We will notify you here of any updates.',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context, 
    AppNotification n, 
    bool isAr, 
    bool isRabhan,
    Color cardBg,
    Color primaryColor,
  ) {
    final showUnreadIndicator = !n.isRead;
    final cardColor = showUnreadIndicator 
        ? primaryColor.withAlpha((0.05 * 255).round())
        : (isRabhan ? cardBg : Colors.transparent);
    final borderColor = showUnreadIndicator 
        ? primaryColor.withAlpha((0.25 * 255).round()) 
        : (isRabhan ? Colors.white.withAlpha(5) : Colors.white12);

    return InkWell(
      onTap: () {
        NotificationService.markAsRead(n.id);
        if (n.linkPath != null && n.linkPath!.isNotEmpty) {
          final resolved = resolveNotificationPath(n.linkPath!);
          context.push(resolved);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 0.8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTypeIcon(n.type, primaryColor),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.getLocalizedTitle(isAr),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    n.getLocalizedBody(isAr),
                    style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _formatTime(n.createdAt, isAr),
                    style: const TextStyle(color: Colors.white24, fontSize: 9),
                  ),
                ],
              ),
            ),
            if (showUnreadIndicator)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeIcon(String type, Color primaryColor) {
    IconData icon;
    Color color;

    switch (type) {
      case 'ticket':
        icon = Icons.confirmation_number_outlined;
        color = Colors.blueAccent;
        break;
      case 'task':
        icon = Icons.assignment_outlined;
        color = Colors.orangeAccent;
        break;
      case 'milestone':
        icon = Icons.emoji_events_outlined;
        color = primaryColor;
        break;
      case 'invoice':
        icon = Icons.receipt_long_outlined;
        color = Colors.redAccent;
        break;
      case 'chat':
        icon = Icons.chat_bubble_outline_rounded;
        color = Colors.purpleAccent;
        break;
      case 'metrics':
        icon = Icons.trending_up;
        color = RabhanTheme.primaryGreen;
        break;
      case 'package_alert':
        icon = Icons.workspace_premium;
        color = RabhanTheme.gold;
        break;
      default:
        icon = Icons.notifications_outlined;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  String _formatTime(DateTime dt, bool isAr) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return isAr ? 'منذ ${diff.inMinutes} دقيقة' : '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return isAr ? 'منذ ${diff.inHours} ساعة' : '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}
