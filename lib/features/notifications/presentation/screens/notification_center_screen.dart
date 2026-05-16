import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/features/notifications/data/notifications_provider.dart';
import 'package:moharek_app/shared/models/notification.dart';
import 'package:moharek_app/shared/widgets/shimmer_placeholders.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'التنبيهات' : 'Notifications'),
        actions: [
          TextButton(
            onPressed: () => NotificationService.markAllAsRead(),
            child: Text(
              isAr ? 'تحديد الكل كمقروء' : 'Mark all read',
              style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 13),
            ),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const ShimmerList(itemCount: 6, itemHeight: 80),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState(isAr);
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return FadeInRight(
                delay: Duration(milliseconds: index * 50),
                child: _buildNotificationCard(context, notification, isAr),
              );
            },
          );
        },
      ),
    );
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
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            isAr ? 'سنقوم بإبلاغك هنا بكل جديد.' : 'We will notify you here of any updates.',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, AppNotification n, bool isAr) {
    return InkWell(
      onTap: () {
        NotificationService.markAsRead(n.id);
        if (n.linkPath != null) {
          context.push(n.linkPath!);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: n.isRead ? Colors.transparent : AppTheme.primaryGreen.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: n.isRead ? Colors.white.withValues(alpha: 0.05) : AppTheme.primaryGreen.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTypeIcon(n.type),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.getLocalizedTitle(isAr),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n.getLocalizedBody(isAr),
                    style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTime(n.createdAt, isAr),
                    style: const TextStyle(color: Colors.white24, fontSize: 10),
                  ),
                ],
              ),
            ),
            if (!n.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppTheme.primaryGreen, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeIcon(String type) {
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
        color = AppTheme.primaryGreen;
        break;
      case 'invoice':
        icon = Icons.receipt_long_outlined;
        color = Colors.redAccent;
        break;
      case 'chat':
        icon = Icons.chat_bubble_outline_rounded;
        color = Colors.purpleAccent;
        break;
      default:
        icon = Icons.notifications_outlined;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
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
}
