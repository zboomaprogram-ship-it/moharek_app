import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/shared/models/task.dart';
import 'package:moharek_app/l10n/app_localizations.dart';
import 'package:moharek_app/shared/services/haptic_service.dart';
import 'package:moharek_app/shared/widgets/empty_state.dart';
import 'package:moharek_app/shared/widgets/shimmer_placeholders.dart';
import 'package:moharek_app/features/tasks/presentation/widgets/client_request_sheet.dart';
import 'package:moharek_app/core/config/app_config.dart';
import 'package:moharek_app/features/rabhan/widgets/journey_stage_tracker.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);

    final isRabhan = AppConfig.flavorName == 'rabhan';
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isRabhan 
              ? (isAr ? 'العمل' : 'Work') 
              : AppLocalizations.of(context)!.tasksTitle),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: AppTheme.primaryGreen,
            labelColor: AppTheme.primaryGreen,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: AppLocalizations.of(context)!.allTab),
              Tab(text: AppLocalizations.of(context)!.inProgress),
              Tab(text: AppLocalizations.of(context)!.waitingMeTab),
              Tab(text: AppLocalizations.of(context)!.completed),
            ],
          ),
        ),
        body: tasksAsync.when(
          loading: () => const ShimmerList(itemCount: 5, itemHeight: 100),
          error: (err, stack) => Center(child: Text(AppLocalizations.of(context)!.errorOccurred(err.toString()), style: const TextStyle(color: Colors.white))),
          data: (tasks) {
            final view = TabBarView(
              children: [
                _buildTaskList(context, ref, tasks, 'all'),
                _buildTaskList(context, ref, tasks, 'in_progress'),
                _buildTaskList(context, ref, tasks, 'waiting_client'),
                _buildTaskList(context, ref, tasks, 'completed'),
              ],
            );

            if (isRabhan) {
              return Column(
                children: [
                  JourneyStageTracker(tasks: tasks),
                  Expanded(child: view),
                ],
              );
            }
            return view;
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            HapticService.light();
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (ctx) => const ClientRequestBottomSheet(),
            );
          },
          backgroundColor: AppTheme.primaryGreen,
          icon: const Icon(Icons.add_task, color: Colors.black),
          label: Text(
            Localizations.localeOf(context).languageCode == 'ar' ? 'طلب جديد' : 'New Request',
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskList(BuildContext context, WidgetRef ref, List<ProjectTask> tasks, String filter) {
    final selectedStage = AppConfig.flavorName == 'rabhan' ? ref.watch(selectedJourneyStageProvider) : null;
    final filteredTasks = tasks.where((task) {
      if (selectedStage != null && task.stageType != selectedStage) return false;
      if (filter == 'all') return true;
      return task.status == filter;
    }).toList();

    if (filteredTasks.isEmpty) {
      return EmptyState.tasks(context);
    }

    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      onRefresh: () async {
        ref.invalidate(tasksProvider);
        HapticService.light();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: filteredTasks.length,
        itemBuilder: (context, index) {
          final task = filteredTasks[index];
          return _buildTaskCard(context, task);
        },
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, ProjectTask task) {
    final l10n = AppLocalizations.of(context)!;
    Color statusColor;
    String statusText = task.status;
    final isUrgent = task.priority == 'high' || task.priority == 'urgent';
    
    switch (task.status) {
      case 'completed':
        statusColor = AppTheme.primaryGreen;
        statusText = l10n.completed;
        break;
      case 'waiting_client':
        statusColor = Colors.orange;
        statusText = l10n.waitingApproval;
        break;
      case 'in_progress':
        statusColor = AppTheme.primaryBlue;
        statusText = l10n.inProgress;
        break;
      default:
        statusColor = Colors.grey;
        statusText = task.status.replaceAll('_', ' ').toUpperCase();
    }

    final int totalSubtasks = task.subtasks.length;
    final int completedSubtasks = task.subtasks.where((s) => s['completed'] == true).length;
    final double progress = totalSubtasks > 0 ? completedSubtasks / totalSubtasks : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent ? Colors.redAccent.withValues(alpha: 0.5) : Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  task.category ?? l10n.general,
                  style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              if (task.deadline != null)
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.grey, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '${task.deadline!.day}/${task.deadline!.month}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            task.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (task.description != null && task.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              task.description!,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (totalSubtasks > 0) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress == 1.0 ? AppTheme.primaryGreen : AppTheme.primaryBlue,
                      ),
                      minHeight: 4,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$completedSubtasks/$totalSubtasks',
                  style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontSize: 12),
                  ),
                  if (task.status == 'completed') ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.check_circle_outline, color: AppTheme.primaryGreen, size: 14),
                  ],
                ],
              ),
              if (totalSubtasks > 0)
                const Icon(Icons.list_alt, color: Colors.white24, size: 16)
              else
                const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
            ],
          ),
        ],
      ),
    );
  }
}
