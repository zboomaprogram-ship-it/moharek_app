import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moharek_app/core/theme/rabhan_theme_constants.dart';
import 'package:moharek_app/shared/services/data_providers.dart';

class JourneyMiniProgress extends ConsumerWidget {
  final String projectId;
  const JourneyMiniProgress({super.key, required this.projectId});

  static const List<Map<String, String>> stageMetadata = [
    {'type': 'research', 'label': 'البحث', 'en': 'Research'},
    {'type': 'showcase', 'label': 'الإنشاء والعرض', 'en': 'Showcase'},
    {'type': 'creative', 'label': 'الإنتاج الإبداعي', 'en': 'Creative'},
    {
      'type': 'client_approval',
      'label': 'موافقة العميل',
      'en': 'Client Approval',
    },
    {'type': 'launch', 'label': 'الإطلاق', 'en': 'Launch'},
    {'type': 'optimize', 'label': 'التحسين', 'en': 'Optimize'},
    {'type': 'scale', 'label': 'التوسع', 'en': 'Scale'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journeyAsync = ref.watch(journeyStagesProvider);
    final tasksAsync = ref.watch(tasksProvider);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return journeyAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (stages) {
        if (stages.isEmpty) return const SizedBox.shrink();

        // Calculate progress based on how many tasks are completed in each stage
        final tasks = tasksAsync.valueOrNull ?? [];

        // 1. Identify which stages have tasks and if they are all completed
        final Map<String, bool> stageCompleted = {};
        for (var s in stageMetadata) {
          final type = s['type']!;
          final stageTasks = tasks.where((t) => t.stageType == type).toList();
          if (stageTasks.isEmpty) {
            stageCompleted[type] = false;
          } else {
            stageCompleted[type] = stageTasks.every(
              (t) => t.status == 'completed',
            );
          }
        }

        // 2. Determine active stage (first incomplete stage)
        String _activeType = 'research'; // ignore: unused_local_variable
        String activeLabel = isAr ? 'البحث' : 'Research';
        int _activeIndex = 0; // ignore: unused_local_variable

        for (var i = 0; i < stageMetadata.length; i++) {
          final type = stageMetadata[i]['type']!;
          if (!stageCompleted[type]!) {
            _activeType = type;
            activeLabel = isAr
                ? stageMetadata[i]['label']!
                : stageMetadata[i]['en']!;
            _activeIndex = i;
            break;
          }
        }

        // Calculate progress percentage
        // Completed stages count / total stages count
        final completedCount = stageMetadata
            .where((s) => stageCompleted[s['type']!] == true)
            .length;
        final double progressPercent = stageMetadata.isEmpty
            ? 0.0
            : completedCount / stageMetadata.length;

        return Card(
          margin: EdgeInsets.zero,
          color: RabhanTheme.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withAlpha(8), width: 0.5),
          ),
          child: InkWell(
            onTap: () {
              // Navigate to tasks tab (branch index 1 /tasks)
              context.go('/tasks');
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isAr ? 'أين نحن الآن؟' : 'Where are we now?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${(progressPercent * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: RabhanTheme.gold,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progressPercent,
                      minHeight: 8,
                      backgroundColor: Colors.white.withAlpha(12),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        RabhanTheme.gold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isAr
                            ? 'المرحلة الحالية: $activeLabel'
                            : 'Current Stage: $activeLabel',
                        style: const TextStyle(
                          color: RabhanTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            isAr ? 'تفاصيل المهام' : 'Task Details',
                            style: const TextStyle(
                              color: RabhanTheme.primaryGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: RabhanTheme.primaryGreen,
                            size: 10,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
