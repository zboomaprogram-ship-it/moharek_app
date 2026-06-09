import 'package:flutter/material.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/shared/models/task.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class TaskDetailBottomSheet extends StatelessWidget {
  final ProjectTask task;

  const TaskDetailBottomSheet({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);

    // Color-coded priority
    Color priorityColor;
    String priorityText;
    switch (task.priority.toLowerCase()) {
      case 'high':
      case 'urgent':
        priorityColor = Colors.redAccent;
        priorityText = isAr ? 'عالية جداً' : 'Urgent';
        break;
      case 'normal':
      case 'medium':
        priorityColor = AppTheme.primaryBlue;
        priorityText = isAr ? 'متوسطة' : 'Normal';
        break;
      default:
        priorityColor = Colors.grey;
        priorityText = isAr ? 'منخفضة' : 'Low';
    }

    // Color-coded status
    Color statusColor;
    String statusText;
    switch (task.status.toLowerCase()) {
      case 'completed':
        statusColor = AppTheme.primaryGreen;
        statusText = isAr ? 'مكتملة' : 'Completed';
        break;
      case 'waiting_client':
        statusColor = Colors.orange;
        statusText = isAr ? 'بانتظار العميل' : 'Waiting Client';
        break;
      case 'in_progress':
        statusColor = AppTheme.primaryBlue;
        statusText = isAr ? 'قيد التنفيذ' : 'In Progress';
        break;
      default:
        statusColor = Colors.grey;
        statusText = isAr ? 'بانتظار البدء' : 'To Do';
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Top Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(color: Colors.white10, height: 1),

              // Content Body (Scrollable)
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Badges section (Category, Priority, Status)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // Category
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            task.category ?? (isAr ? 'عام' : 'General'),
                            style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        // Priority
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: priorityColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: priorityColor.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(color: priorityColor, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                priorityText,
                                style: TextStyle(color: priorityColor, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        // Status
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Date Section (Start Date / Deadline)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.play_arrow_outlined, color: Colors.grey, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      isAr ? 'تاريخ البدء' : 'Start Date',
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  task.startDate != null
                                      ? DateFormat('yyyy/MM/dd').format(task.startDate!)
                                      : '—',
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 40, color: Colors.white10),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, color: Colors.grey, size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      isAr ? 'تاريخ الاستحقاق' : 'Due Date',
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  task.deadline != null
                                      ? DateFormat('yyyy/MM/dd').format(task.deadline!)
                                      : '—',
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Description Section
                    Text(
                      isAr ? 'التفاصيل والوصف' : 'Description',
                      style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      task.description?.isNotEmpty == true
                          ? task.description!
                          : (isAr ? 'لا يوجد وصف متاح لهذه المهمة.' : 'No description provided.'),
                      style: const TextStyle(color: Colors.white60, fontSize: 14, height: 1.5),
                    ),

                    const SizedBox(height: 28),

                    // Subtasks Section
                    if (task.subtasks.isNotEmpty) ...[
                      Text(
                        isAr ? 'المهام الفرعية' : 'Subtasks',
                        style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Column(
                          children: task.subtasks.map((sub) {
                            final completed = sub['completed'] == true;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  Icon(
                                    completed ? Icons.check_circle : Icons.radio_button_unchecked,
                                    color: completed ? AppTheme.primaryGreen : Colors.grey,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      sub['title']?.toString() ?? '',
                                      style: TextStyle(
                                        color: completed ? Colors.grey : Colors.white70,
                                        fontSize: 13,
                                        decoration: completed ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],

                    // Attachments / Screenshots Section
                    if (task.attachmentUrls.isNotEmpty) ...[
                      Text(
                        isAr ? 'الملفات المرفقة لقطات الأداء' : 'Attachments & Screenshots',
                        style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: task.attachmentUrls.map((url) {
                          final isImage = url.toLowerCase().contains('.png') ||
                              url.toLowerCase().contains('.jpg') ||
                              url.toLowerCase().contains('.jpeg') ||
                              url.toLowerCase().contains('.gif');
                          final name = url.split('/').last.split('?').first;

                          return GestureDetector(
                            onTap: () => launchUrl(Uri.parse(url)),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isImage ? Icons.image_outlined : Icons.insert_drive_file_outlined,
                                    color: AppTheme.primaryGreen,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        color: AppTheme.primaryBlue,
                                        fontSize: 13,
                                        decoration: TextDecoration.underline,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(Icons.open_in_new, color: Colors.white24, size: 16),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
