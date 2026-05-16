import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:timeago/timeago.dart' as timeago;

// ── Provider ──────────────────────────────────────────────────────────────────

final activityFeedProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  
  final stream = client
      .from('activity_feed')
      .stream(primaryKey: ['id'])
      .order('created_at')
      .limit(30);
      
  return stream.map((data) => data.reversed.toList().cast<Map<String, dynamic>>());
});


// ── Activity Feed Widget ──────────────────────────────────────────────────────

class AdminActivityFeed extends ConsumerWidget {
  const AdminActivityFeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(activityFeedProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(color: AppTheme.primaryGreen, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              const Text('النشاط الأخير', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton(
                onPressed: () => ref.invalidate(activityFeedProvider),
                child: const Text('تحديث', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          feedAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppTheme.primaryGreen, strokeWidth: 2),
              ),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(12),
              child: Text('خطأ في تحميل النشاط: $e', style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),
            data: (activities) {
              if (activities.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('لا يوجد نشاط بعد', style: TextStyle(color: Colors.grey)),
                  ),
                );
              }
              return Column(
                children: activities.take(10).map((a) => _ActivityRow(activity: a)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final Map<String, dynamic> activity;
  const _ActivityRow({required this.activity});

  @override
  Widget build(BuildContext context) {
    final action = activity['action'] as String? ?? '';
    final entityType = activity['entity_type'] as String? ?? '';
    final createdAt = activity['created_at'] as String?;
    final ago = createdAt != null
        ? timeago.format(DateTime.parse(createdAt), locale: 'ar')
        : '';

    final (icon, color) = _iconFor(entityType, action);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final actionText = isAr 
        ? (activity['action_ar'] as String? ?? activity['action_en'] as String? ?? action)
        : (activity['action_en'] as String? ?? activity['action_ar'] as String? ?? action);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(actionText,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (ago.isNotEmpty)
                  Text(ago, style: const TextStyle(color: Colors.white30, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color) _iconFor(String entityType, String action) {
    if (entityType == 'approval') return (Icons.approval_outlined, Colors.orange);
    if (entityType == 'task') {
      if (action.contains('completed') || action.contains('done')) {
        return (Icons.check_circle_outline, AppTheme.primaryGreen);
      }
      return (Icons.task_outlined, AppTheme.primaryBlue);
    }
    if (entityType == 'message') return (Icons.chat_bubble_outline, AppTheme.primaryGreen);
    if (entityType == 'contract') return (Icons.description_outlined, Colors.amber);
    if (entityType == 'report') return (Icons.analytics_outlined, AppTheme.primaryBlue);
    if (entityType == 'login') return (Icons.login, Colors.green);
    if (entityType == 'invoice') return (Icons.receipt_long_outlined, Colors.purple);
    return (Icons.circle_outlined, Colors.grey);
  }
}
