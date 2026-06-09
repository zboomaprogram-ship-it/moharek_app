import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:appflowy_board/appflowy_board.dart';

final allTasksProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final data = await client
      .from('tasks')
      .select('*, projects(profiles!projects_client_id_fkey(full_name, company_name))')
      .order('created_at', ascending: false);
  return (data as List).cast<Map<String, dynamic>>();
});

class AdminTasksScreen extends ConsumerStatefulWidget {
  const AdminTasksScreen({super.key});

  @override
  ConsumerState<AdminTasksScreen> createState() => _AdminTasksScreenState();
}

class _AdminTasksScreenState extends ConsumerState<AdminTasksScreen> {
  late AppFlowyBoardController controller;
  bool _isControllerInitialized = false;

  @override
  void initState() {
    super.initState();
    controller = AppFlowyBoardController(
      onMoveGroup: (fromGroupId, fromIndex, toGroupId, toIndex) {},
      onMoveGroupItem: (groupId, fromIndex, toIndex) {},
      onMoveGroupItemToGroup: (fromGroupId, fromIndex, toGroupId, toIndex) {
        _updateTaskStatus(fromGroupId, toGroupId, fromIndex, toIndex);
      },
    );
  }

  void _updateTaskStatus(String fromGroupId, String toGroupId, int fromIndex, int toIndex) async {
    final taskData = controller.getGroupController(toGroupId)?.items[toIndex] as _TaskItem?;
    if (taskData == null) return;

    String newStatus = 'todo';
    if (toGroupId == '1') newStatus = 'todo';
    if (toGroupId == '2') newStatus = 'in_progress';
    if (toGroupId == '3') newStatus = 'review';
    if (toGroupId == '4') newStatus = 'done';

    final actions = ref.read(adminActionsProvider);
    await actions.updateTask(taskData.task['id'], {'status': newStatus});
  }

  void _populateBoard(List<Map<String, dynamic>> tasks) {
    controller.clear();
    final groups = {
      '1': tasks.where((t) => t['status'] == 'todo' || t['status'] == null).toList(),
      '2': tasks.where((t) => t['status'] == 'in_progress').toList(),
      '3': tasks.where((t) => t['status'] == 'review').toList(),
      '4': tasks.where((t) => t['status'] == 'done').toList(),
    };
    final names = {'1': 'قيد الانتظار', '2': 'قيد التنفيذ', '3': 'قيد المراجعة', '4': 'مكتملة'};
    for (final entry in groups.entries) {
      controller.addGroup(AppFlowyGroupData(
        id: entry.key,
        name: names[entry.key]!,
        items: entry.value.map((t) => _TaskItem(t)).toList(),
      ));
    }
    _isControllerInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(allTasksProvider);
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            if (isMobile) ...[
              const Text('لوحة المهام', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showTaskModal(context, ref),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('مهمة جديدة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppTheme.primaryGreen),
                    onPressed: () {
                      _isControllerInitialized = false;
                      ref.invalidate(allTasksProvider);
                    },
                  ),
                ],
              ),
            ] else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('لوحة المهام (Kanban)', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                      Text('إدارة وتتبع سير العمل لجميع المشاريع', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.refresh, color: AppTheme.primaryGreen),
                        onPressed: () {
                          _isControllerInitialized = false;
                          ref.invalidate(allTasksProvider);
                        },
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _showTaskModal(context, ref),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('مهمة جديدة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 24),

            // Body
            Expanded(
              child: tasksAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
                error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
                data: (tasks) {
                  if (isMobile) {
                    return _buildMobileList(tasks);
                  }
                  if (!_isControllerInitialized) _populateBoard(tasks);
                  return AppFlowyBoard(
                    controller: controller,
                    cardBuilder: (context, group, groupItem) {
                      final task = (groupItem as _TaskItem).task;
                      return AppFlowyGroupCard(
                        key: ValueKey(groupItem.id),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: InkWell(
                          onTap: () => _showTaskModal(context, ref, task: task),
                          borderRadius: BorderRadius.circular(16),
                          child: _buildTaskCard(task),
                        ),
                      );
                    },
                    boardScrollController: AppFlowyBoardScrollController(),
                    headerBuilder: (context, columnData) => AppFlowyGroupHeader(
                      icon: const Icon(Icons.circle, size: 10, color: AppTheme.primaryGreen),
                      title: Text(columnData.headerData.groupName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      height: 50,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    groupConstraints: const BoxConstraints.tightFor(width: 300),
                    config: AppFlowyBoardConfig(
                      groupBackgroundColor: Colors.transparent,
                      stretchGroupHeight: true,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileList(List<Map<String, dynamic>> tasks) {
    if (tasks.isEmpty) {
      return const Center(child: Text('لا توجد مهام', style: TextStyle(color: Color(0xFF64748B))));
    }
    return ListView.separated(
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final t = tasks[index];
        return InkWell(
          onTap: () => _showTaskModal(context, ref, task: t),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: _buildTaskCard(t),
          ),
        );
      },
    );
  }

  void _showTaskModal(BuildContext context, WidgetRef ref, {Map<String, dynamic>? task}) {
    final isEditing = task != null;
    final titleController = TextEditingController(text: task?['title']);
    final descController = TextEditingController(text: task?['description']);
    final projectsAsync = ref.read(allProjectsProvider.future);
    String? selectedProjectId = task?['project_id'];
    String selectedStatus = task?['status'] ?? 'todo';
    double progress = ((task?['progress_percent'] as num?) ?? 0).toDouble();
    bool saving = false;

    // Parse existing dates if present
    DateTime? selectedStartDate = task?['start_date'] != null 
        ? DateTime.tryParse(task!['start_date'].toString()) 
        : null;
    DateTime? selectedDeadline = task?['deadline'] != null 
        ? DateTime.tryParse(task!['deadline'].toString()) 
        : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(isEditing ? 'تعديل المهمة' : 'إنشاء مهمة جديدة',
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isEditing) ...[
                    const Text('المشروع:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    const SizedBox(height: 8),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: projectsAsync,
                      builder: (context, snap) {
                        if (!snap.hasData) return const LinearProgressIndicator();
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedProjectId,
                              hint: const Text('اختر المشروع', style: TextStyle(color: Color(0xFF64748B))),
                              dropdownColor: const Color(0xFF1E293B),
                              isExpanded: true,
                              items: snap.data!.map((p) => DropdownMenuItem(
                                value: p['id'] as String,
                                child: Text(p['profiles']?['company_name'] ?? 'عميل',
                                    style: const TextStyle(color: Colors.white)),
                              )).toList(),
                              onChanged: (val) => setModalState(() => selectedProjectId = val),
                            ),
                          ),
                        );
                      },
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        'المشروع: ${task['projects']?['profiles']?['company_name'] ?? 'غير معروف'}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Status (always shown when editing)
                  if (isEditing) ...[
                    const Text('الحالة:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedStatus,
                          dropdownColor: const Color(0xFF1E293B),
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 'todo', child: Text('قيد الانتظار', style: TextStyle(color: Colors.white))),
                            DropdownMenuItem(value: 'in_progress', child: Text('قيد التنفيذ', style: TextStyle(color: Colors.white))),
                            DropdownMenuItem(value: 'review', child: Text('قيد المراجعة', style: TextStyle(color: Colors.white))),
                            DropdownMenuItem(value: 'done', child: Text('مكتملة', style: TextStyle(color: Colors.white))),
                          ],
                          onChanged: (val) => setModalState(() => selectedStatus = val!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Progress slider
                    Row(
                      children: [
                        const Text('التقدم:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                        const Spacer(),
                        Text('${progress.toInt()}%', style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppTheme.primaryGreen,
                        inactiveTrackColor: const Color(0xFF334155),
                        thumbColor: Colors.white,
                        overlayColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                      ),
                      child: Slider(
                        value: progress,
                        min: 0,
                        max: 100,
                        divisions: 20,
                        onChanged: (v) => setModalState(() => progress = v),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  _buildField(titleController, 'عنوان المهمة', Icons.title),
                  const SizedBox(height: 12),
                  _buildField(descController, 'وصف المهمة', Icons.description_outlined, maxLines: 3),
                  const SizedBox(height: 16),

                  // Date Pickers
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('تاريخ البدء:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedStartDate ?? DateTime.now(),
                                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                                  builder: (context, child) => Theme(
                                    data: ThemeData.dark().copyWith(
                                      colorScheme: const ColorScheme.dark(
                                        primary: AppTheme.primaryGreen,
                                        onPrimary: Colors.black,
                                        surface: Color(0xFF1E293B),
                                      ),
                                    ),
                                    child: child!,
                                  ),
                                );
                                if (picked != null) {
                                  setModalState(() => selectedStartDate = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      selectedStartDate == null ? 'اختر التاريخ' : selectedStartDate!.toString().split(' ')[0],
                                      style: TextStyle(color: selectedStartDate == null ? const Color(0xFF64748B) : Colors.white, fontSize: 13),
                                    ),
                                    const Icon(Icons.calendar_today, color: Color(0xFF64748B), size: 16),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('تاريخ الاستحقاق:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDeadline ?? DateTime.now(),
                                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                                  builder: (context, child) => Theme(
                                    data: ThemeData.dark().copyWith(
                                      colorScheme: const ColorScheme.dark(
                                        primary: AppTheme.primaryGreen,
                                        onPrimary: Colors.black,
                                        surface: Color(0xFF1E293B),
                                      ),
                                    ),
                                    child: child!,
                                  ),
                                );
                                if (picked != null) {
                                  setModalState(() => selectedDeadline = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      selectedDeadline == null ? 'اختر التاريخ' : selectedDeadline!.toString().split(' ')[0],
                                      style: TextStyle(color: selectedDeadline == null ? const Color(0xFF64748B) : Colors.white, fontSize: 13),
                                    ),
                                    const Icon(Icons.calendar_today, color: Color(0xFF64748B), size: 16),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            if (isEditing)
              TextButton(
                onPressed: saving ? null : () async {
                  final confirmed = await _confirm(context, 'حذف المهمة', 'هل تريد حذف هذه المهمة نهائياً؟');
                  if (!confirmed) return;
                  setModalState(() => saving = true);
                  try {
                    await ref.read(adminActionsProvider).deleteTask(task['id'], task['title'] ?? '');
                    _isControllerInitialized = false;
                    ref.invalidate(allTasksProvider);
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) _showError(context, e);
                  } finally {
                    if (context.mounted) setModalState(() => saving = false);
                  }
                },
                child: const Text('حذف', style: TextStyle(color: Colors.redAccent)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: saving ? null : () async {
                if (titleController.text.trim().isEmpty) return;
                if (!isEditing && selectedProjectId == null) return;
                setModalState(() => saving = true);
                try {
                  final actions = ref.read(adminActionsProvider);
                  if (isEditing) {
                    await actions.updateTask(task['id'], {
                      'title': titleController.text.trim(),
                      'description': descController.text.trim(),
                      'status': selectedStatus,
                      'progress_percent': progress.toInt(),
                      'start_date': selectedStartDate?.toIso8601String(),
                      'deadline': selectedDeadline?.toIso8601String(),
                    });
                  } else {
                    await actions.createTask({
                      'project_id': selectedProjectId!,
                      'title': titleController.text.trim(),
                      'description': descController.text.trim(),
                      'status': 'todo',
                      'start_date': selectedStartDate?.toIso8601String(),
                      'deadline': selectedDeadline?.toIso8601String(),
                    });
                  }
                  _isControllerInitialized = false;
                  ref.invalidate(allTasksProvider);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) _showError(context, e);
                } finally {
                  if (context.mounted) setModalState(() => saving = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.black),
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : Text(isEditing ? 'حفظ التغييرات' : 'إنشاء', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirm(BuildContext context, String title, String msg) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: Text(title, style: const TextStyle(color: Colors.white)),
            content: Text(msg, style: const TextStyle(color: Color(0xFF94A3B8))),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('تأكيد', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showError(BuildContext context, Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
    );
  }

  Widget _buildField(TextEditingController controller, String hint, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF64748B)),
        prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        border: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12))),
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final title = task['title'] as String? ?? 'بدون عنوان';
    final desc = task['description'] as String? ?? '';
    final project = task['projects'] as Map<String, dynamic>?;
    final profile = project?['profiles'] as Map<String, dynamic>?;
    final clientName = profile?['company_name'] as String? ?? profile?['full_name'] as String? ?? 'عميل';
    final progress = ((task['progress_percent'] as num?) ?? 0).toDouble();

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(clientName,
                style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(desc, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          if (progress > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    backgroundColor: const Color(0xFF334155),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${progress.toInt()}%', style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.calendar_today, size: 12, color: Color(0xFF475569)),
            const SizedBox(width: 4),
            Text(
              task['deadline'] != null ? task['deadline'].toString().split('T')[0] : 'بدون موعد',
              style: const TextStyle(color: Color(0xFF475569), fontSize: 11),
            ),
          ]),
        ],
      ),
    );
  }
}

class _TaskItem extends AppFlowyGroupItem {
  final Map<String, dynamic> task;
  _TaskItem(this.task);
  @override
  String get id => task['id'] as String;
}
