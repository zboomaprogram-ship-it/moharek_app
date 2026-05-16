import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';
import 'package:moharek_app/core/theme/app_theme.dart';

class TasksTab extends ConsumerWidget {
  final String pid;
  const TasksTab({super.key, required this.pid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(projectTasksProvider(pid));

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_task_$pid',
        backgroundColor: AppTheme.primaryGreen,
        onPressed: () => _showEditTask(context, ref, null),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
        data: (tasks) {
          if (tasks.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.task_alt, color: Colors.grey, size: 48),
                  SizedBox(height: 16),
                  Text('لا توجد مهام', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) => _buildTaskCard(context, ref, tasks[index]),
          );
        },
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, WidgetRef ref, Map<String, dynamic> t) {
    final status = t['status'] as String? ?? 'todo';
    final progress = (t['progress_percent'] as num?)?.toDouble() ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: InkWell(
        onTap: () => _showEditTask(context, ref, t),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _statusBadge(status),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryGreen, size: 18),
                  onPressed: () => _showEditTask(context, ref, t),
                  tooltip: 'تعديل',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                  onPressed: () => _confirmDelete(context, ref, t),
                  tooltip: 'حذف',
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(t['title'] ?? 'بدون عنوان',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            if (t['description'] != null && t['description'].toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(t['description'].toString(),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      status == 'done' ? AppTheme.primaryGreen : AppTheme.primaryBlue,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text('${progress.toInt()}%', style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTask(BuildContext context, WidgetRef ref, Map<String, dynamic>? task) {
    final isEditing = task != null;
    final titleCtrl = TextEditingController(text: task?['title'] ?? '');
    final descCtrl = TextEditingController(text: task?['description'] ?? '');
    String selectedStatus = task?['status'] ?? 'todo';
    double progress = ((task?['progress_percent'] as num?) ?? 0).toDouble();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isEditing ? 'تعديل المهمة' : 'مهمة جديدة',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _field(titleCtrl, 'عنوان المهمة', Icons.title),
                const SizedBox(height: 12),
                _field(descCtrl, 'الوصف', Icons.description_outlined, maxLines: 3),
                const SizedBox(height: 16),
                // Status
                const Text('الحالة:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedStatus,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1E293B),
                      items: const [
                        DropdownMenuItem(value: 'todo', child: Text('قيد الانتظار', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'in_progress', child: Text('قيد التنفيذ', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'review', child: Text('قيد المراجعة', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'done', child: Text('مكتملة', style: TextStyle(color: Colors.white))),
                      ],
                      onChanged: (v) => setState(() => selectedStatus = v!),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Progress
                Row(
                  children: [
                    const Text('التقدم:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    const Spacer(),
                    Text('${progress.toInt()}%',
                        style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(ctx).copyWith(
                    activeTrackColor: AppTheme.primaryGreen,
                    inactiveTrackColor: const Color(0xFF334155),
                    thumbColor: Colors.white,
                    overlayColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
                  ),
                  child: Slider(
                    value: progress,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    onChanged: (v) => setState(() => progress = v),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.black),
              onPressed: saving
                  ? null
                  : () async {
                      if (titleCtrl.text.trim().isEmpty) return;
                      setState(() => saving = true);
                      try {
                        final actions = ref.read(adminActionsProvider);
                        if (isEditing) {
                          await actions.updateTask(task['id'], {
                            'title': titleCtrl.text.trim(),
                            'description': descCtrl.text.trim(),
                            'status': selectedStatus,
                            'progress_percent': progress.toInt(),
                          });
                        } else {
                          await actions.createTask({
                            'project_id': pid,
                            'title': titleCtrl.text.trim(),
                            'description': descCtrl.text.trim(),
                            'status': selectedStatus,
                            'progress_percent': progress.toInt(),
                          });
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
                          );
                        }
                      } finally {
                        if (ctx.mounted) setState(() => saving = false);
                      }
                    },
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : Text(isEditing ? 'حفظ' : 'إنشاء', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Map<String, dynamic> t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('حذف المهمة', style: TextStyle(color: Colors.white)),
        content: Text('هل تريد حذف "${t['title']}"؟ لا يمكن التراجع.',
            style: const TextStyle(color: Color(0xFF94A3B8))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(adminActionsProvider).deleteTask(t['id'], t['title'] ?? '');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف المهمة ✅'), backgroundColor: AppTheme.primaryGreen),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _statusBadge(String status) {
    Color color = Colors.grey;
    String label = status;
    switch (status) {
      case 'done': color = AppTheme.primaryGreen; label = 'مكتملة'; break;
      case 'in_progress': color = AppTheme.primaryBlue; label = 'جارية'; break;
      case 'todo': color = Colors.orange; label = 'انتظار'; break;
      case 'review': color = Colors.purple; label = 'مراجعة'; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF64748B)),
        prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 18),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        border: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(10))),
      ),
    );
  }
}
