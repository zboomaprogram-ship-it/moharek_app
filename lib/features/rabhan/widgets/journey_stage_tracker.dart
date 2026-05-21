import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/rabhan_theme_constants.dart';
import 'package:moharek_app/shared/models/task.dart';

final selectedJourneyStageProvider = StateProvider<String?>((ref) => null);

class JourneyStageTracker extends ConsumerWidget {
  final List<ProjectTask> tasks;

  const JourneyStageTracker({
    super.key,
    required this.tasks,
  });

  static const List<Map<String, String>> stages = [
    {'type': 'research', 'label': 'البحث', 'en': 'Research'},
    {'type': 'showcase', 'label': 'الإنشاء والعرض', 'en': 'Showcase'},
    {'type': 'creative', 'label': 'الإنتاج الإبداعي', 'en': 'Creative'},
    {'type': 'client_approval', 'label': 'موافقة العميل', 'en': 'Client Approval'},
    {'type': 'launch', 'label': 'الإطلاق', 'en': 'Launch'},
    {'type': 'optimize', 'label': 'التحسين', 'en': 'Optimize'},
    {'type': 'scale', 'label': 'التوسع', 'en': 'Scale'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedStage = ref.watch(selectedJourneyStageProvider);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    // Calculate stage states
    final Map<String, String> stageStates = {}; // 'completed', 'active', 'pending'
    
    // 1. Identify which stages have tasks and if they are all completed
    final Map<String, bool> stageCompleted = {};
    for (var s in stages) {
      final type = s['type']!;
      final stageTasks = tasks.where((t) => t.stageType == type).toList();
      if (stageTasks.isEmpty) {
        stageCompleted[type] = false;
      } else {
        stageCompleted[type] = stageTasks.every((t) => t.status == 'completed');
      }
    }

    // 2. Chronologically mark stages. First incomplete stage is active, prior are completed, after are pending.
    bool foundActive = false;
    for (var i = 0; i < stages.length; i++) {
      final type = stages[i]['type']!;
      final hasTasks = tasks.any((t) => t.stageType == type);
      
      if (stageCompleted[type] == true) {
        stageStates[type] = 'completed';
      } else if (!foundActive) {
        stageStates[type] = 'active';
        foundActive = true;
      } else {
        stageStates[type] = 'pending';
      }
    }

    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: RabhanTheme.background,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: stages.length,
        itemBuilder: (context, index) {
          final s = stages[index];
          final type = s['type']!;
          final label = isAr ? s['label']! : s['en']!;
          final state = stageStates[type] ?? 'pending';
          final isSelected = selectedStage == type;

          Color borderColor;
          Color bgColor;
          Color textColor;
          Widget icon;

          if (state == 'completed') {
            borderColor = RabhanTheme.primaryGreen.withValues(alpha: 0.3);
            bgColor = isSelected 
                ? RabhanTheme.primaryGreen.withValues(alpha: 0.2) 
                : RabhanTheme.card;
            textColor = RabhanTheme.primaryGreen;
            icon = const Icon(Icons.check_circle, color: RabhanTheme.primaryGreen, size: 14);
          } else if (state == 'active') {
            borderColor = RabhanTheme.gold;
            bgColor = isSelected 
                ? RabhanTheme.gold.withValues(alpha: 0.2) 
                : RabhanTheme.card;
            textColor = Colors.white;
            icon = Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: RabhanTheme.gold,
                shape: BoxShape.circle,
              ),
            );
          } else {
            borderColor = Colors.white10;
            bgColor = isSelected 
                ? Colors.white.withValues(alpha: 0.05) 
                : Colors.transparent;
            textColor = RabhanTheme.textSecondary;
            icon = Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
              ),
            );
          }

          if (isSelected) {
            borderColor = state == 'completed' ? RabhanTheme.primaryGreen 
                        : state == 'active' ? RabhanTheme.gold 
                        : Colors.white;
          }

          return GestureDetector(
            onTap: () {
              if (isSelected) {
                ref.read(selectedJourneyStageProvider.notifier).state = null;
              } else {
                ref.read(selectedJourneyStageProvider.notifier).state = type;
              }
            },
            child: Container(
              margin: const EdgeInsetsDirectional.only(end: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: (state == 'completed' ? RabhanTheme.primaryGreen : RabhanTheme.gold)
                        .withValues(alpha: 0.1),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ] : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
