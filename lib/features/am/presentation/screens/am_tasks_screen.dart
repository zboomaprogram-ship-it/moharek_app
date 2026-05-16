import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/features/am/data/am_providers.dart';

class AmTasksScreen extends ConsumerWidget {
  const AmTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(amGlobalTasksProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'المهام العامة',
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const Text(
              'نظرة شاملة على جميع المهام عبر كافة المشاريع المسندة إليك',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
            const SizedBox(height: 32),

            Expanded(
              child: tasks.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (list) {
                  if (list.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildTaskTable(list);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt_outlined, size: 64, color: const Color(0xFF334155)),
          const SizedBox(height: 16),
          const Text(
            'لا توجد مهام حالياً',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTable(List<Map<String, dynamic>> tasks) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFF0F172A)),
            dataRowMaxHeight: 70,
            horizontalMargin: 24,
            columnSpacing: 40,
            columns: const [
              DataColumn(label: Text('المهمة', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold))),
              DataColumn(label: Text('المشروع', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold))),
              DataColumn(label: Text('الحالة', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold))),
              DataColumn(label: Text('الأولوية', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold))),
              DataColumn(label: Text('تاريخ الاستحقاق', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold))),
            ],
            rows: tasks.map((task) {
              final project = task['projects'] as Map<String, dynamic>;
              final status = task['status'] as String? ?? 'todo';
              final priority = task['priority'] as String? ?? 'normal';
              
              return DataRow(
                cells: [
                  DataCell(Text(task['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
                  DataCell(Text(project['name'] ?? '', style: const TextStyle(color: Color(0xFF94A3B8)))),
                  DataCell(_buildStatusChip(status)),
                  DataCell(_buildPriorityChip(priority)),
                  DataCell(Text(task['deadline']?.toString().split('T')[0] ?? '—', style: const TextStyle(color: Color(0xFF64748B)))),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = Colors.grey;
    String label = status;
    if (status == 'todo') { color = Colors.blue; label = 'بانتظار البدء'; }
    if (status == 'in_progress') { color = Colors.orange; label = 'قيد التنفيذ'; }
    if (status == 'completed') { color = AppTheme.primaryGreen; label = 'مكتملة'; }
    if (status == 'waiting_client') { color = Colors.purple; label = 'بانتظار العميل'; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPriorityChip(String priority) {
    Color color = Colors.grey;
    String label = priority;
    if (priority == 'high') { color = Colors.red; label = 'عالية'; }
    if (priority == 'normal') { color = Colors.blue; label = 'متوسطة'; }
    if (priority == 'low') { color = Colors.green; label = 'منخفضة'; }

    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}
