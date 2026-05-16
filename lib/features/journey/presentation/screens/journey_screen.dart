import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/shared/models/journey_stage.dart';
import 'package:moharek_app/shared/models/task.dart';
import 'package:moharek_app/shared/widgets/shimmer_loading.dart';
import 'package:moharek_app/features/journey/presentation/widgets/journey_timeline_connector.dart';
import 'package:moharek_app/features/journey/presentation/widgets/stage_progress_bar.dart';
import 'package:moharek_app/features/journey/presentation/widgets/next_stage_preview.dart';
import 'package:moharek_app/l10n/app_localizations.dart';
import 'package:animate_do/animate_do.dart';

class JourneyScreen extends ConsumerStatefulWidget {
  const JourneyScreen({super.key});

  @override
  ConsumerState<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends ConsumerState<JourneyScreen> {
  String? _expandedStage;

  List<Map<String, dynamic>> _getStageOrder(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      {'key': 'audit', 'label': l10n.audit, 'icon': Icons.search},
      {'key': 'strategy', 'label': l10n.strategy, 'icon': Icons.lightbulb_outline},
      {'key': 'setup', 'label': l10n.setup, 'icon': Icons.settings_outlined},
      {'key': 'execution', 'label': l10n.execution, 'icon': Icons.rocket_launch_outlined},
      {'key': 'optimization', 'label': l10n.optimization, 'icon': Icons.trending_up},
      {'key': 'results', 'label': l10n.results, 'icon': Icons.bar_chart},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final stagesAsync = ref.watch(journeyStagesProvider);
    final tasksAsync = ref.watch(tasksProvider);
    final l10n = AppLocalizations.of(context)!;
    final stageOrder = _getStageOrder(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(l10n.growthJourney),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppTheme.primaryGreen.withValues(alpha: 0.2), Colors.black],
                  ),
                ),
              ),
            ),
          ),
          stagesAsync.when(
            loading: () => SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => ShimmerLoading.card(),
                  childCount: 5,
                ),
              ),
            ),
            error: (err, _) => SliverFillRemaining(
              child: Center(child: Text(l10n.errorOccurred(err.toString()), style: const TextStyle(color: Colors.white))),
            ),
            data: (stages) {
              final tasks = tasksAsync.asData?.value ?? [];
              final stageMap = {for (var s in stages) s.stageName: s};

              // Find current and next stage
              JourneyStage? currentStage;
              JourneyStage? nextStage;
              for (var i = 0; i < stageOrder.length; i++) {
                final s = stageMap[stageOrder[i]['key']];
                if (s?.status == 'in_progress') {
                  currentStage = s;
                  if (i + 1 < stageOrder.length) {
                    nextStage = stageMap[stageOrder[i + 1]['key']];
                  }
                  break;
                }
              }

              return SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      // Bottom: Next Stage Preview
                      if (index == stageOrder.length) {
                        if (nextStage == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 24, bottom: 40),
                          child: NextStagePreview(
                            title: stageOrder.firstWhere((o) => o['key'] == nextStage!.stageName)['label'],
                            description: nextStage.stageDescription ?? l10n.nextPhaseGrowth,
                            estimatedDate: nextStage.deadline,
                          ),
                        );
                      }

                      final stageInfo = stageOrder[index];
                      final stage = stageMap[stageInfo['key']];
                      final isLast = index == stageOrder.length - 1;
                      
                      return _buildTimelineItem(
                        stageInfo: stageInfo,
                        stage: stage,
                        tasks: tasks.where((t) => t.stageName == stageInfo['key']).toList(),
                        isLast: isLast,
                        l10n: l10n,
                      );
                    },
                    childCount: stageOrder.length + 1,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required Map<String, dynamic> stageInfo,
    required JourneyStage? stage,
    required List<ProjectTask> tasks,
    required bool isLast,
    required AppLocalizations l10n,
  }) {
    final status = stage?.status ?? 'not_started';
    final isCompleted = status == 'completed';
    final isInProgress = status == 'in_progress';
    final isExpanded = _expandedStage == stageInfo['key'] || isInProgress;
    final color = _statusColor(status);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Pillar
          SizedBox(
            width: 32,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCompleted ? AppTheme.primaryGreen : Colors.black,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCompleted ? AppTheme.primaryGreen : (isInProgress ? AppTheme.primaryBlue : Colors.white24),
                      width: 2,
                    ),
                    boxShadow: isInProgress ? [
                      BoxShadow(color: AppTheme.primaryBlue.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2),
                    ] : null,
                  ),
                  child: isCompleted 
                    ? const Icon(Icons.check, color: Colors.black, size: 14)
                    : (isInProgress ? Center(child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.primaryBlue, shape: BoxShape.circle))) : null),
                ),
                Expanded(
                  child: JourneyTimelineConnector(
                    isCompleted: isCompleted,
                    isLast: isLast,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Content Card
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _expandedStage = isExpanded ? null : stageInfo['key']),
              child: FadeInRight(
                duration: const Duration(milliseconds: 400),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isInProgress ? AppTheme.primaryBlue.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.05),
                      width: isInProgress ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(stageInfo['icon'], color: color, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            stageInfo['label'],
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: isInProgress ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          if (isCompleted)
                            const Icon(Icons.verified, color: AppTheme.primaryGreen, size: 16),
                        ],
                      ),
                      
                      if (isExpanded) ...[
                        const SizedBox(height: 12),
                        Text(
                          stage?.stageDescription ?? l10n.trackingProgress,
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 13, height: 1.5),
                        ),
                        const SizedBox(height: 16),
                        StageProgressBar(
                          progress: _calculateProgress(tasks),
                          color: color,
                        ),
                        if (tasks.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ...tasks.take(3).map((t) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(
                                  t.status == 'completed' ? Icons.check_circle : Icons.radio_button_unchecked,
                                  color: t.status == 'completed' ? AppTheme.primaryGreen : Colors.white24,
                                  size: 12,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    t.title,
                                    style: TextStyle(color: Colors.white70, fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed': return AppTheme.primaryGreen;
      case 'in_progress': return AppTheme.primaryBlue;
      default: return Colors.white24;
    }
  }

  double _calculateProgress(List<ProjectTask> tasks) {
    if (tasks.isEmpty) return 0.0;
    final completed = tasks.where((t) => t.status == 'completed').length;
    return completed / tasks.length;
  }
}
