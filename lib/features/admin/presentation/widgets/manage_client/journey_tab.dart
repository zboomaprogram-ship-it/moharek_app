import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';
import 'package:moharek_app/core/theme/app_theme.dart';

class JourneyTab extends ConsumerWidget {
  final String pid;
  const JourneyTab({super.key, required this.pid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stagesAsync = ref.watch(adminProjectJourneyStagesProvider(pid));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: stagesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
        data: (stages) {
          if (stages.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, color: Colors.grey, size: 48),
                  SizedBox(height: 16),
                  Text('لا توجد مراحل مسجلة لهذه الرحلة', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: stages.length,
            itemBuilder: (context, index) => _buildStageCard(context, ref, stages[index]),
          );
        },
      ),
    );
  }

  Widget _buildStageCard(BuildContext context, WidgetRef ref, Map<String, dynamic> stage) {
    final status = stage['status'] as String? ?? 'not_started';
    final name = stage['stage_name'] as String? ?? 'بدون عنوان';
    final desc = stage['stage_description'] as String? ?? '';
    final notes = stage['notes'] as String? ?? '';
    final orderIndex = stage['order_index'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'مرحلة ${orderIndex + 1}',
                  style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              _statusBadge(status),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryGreen, size: 18),
                onPressed: () => _showEditStage(context, ref, stage),
                tooltip: 'تعديل التفاصيل',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              desc,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes, size: 14, color: AppTheme.primaryBlue),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      notes,
                      style: const TextStyle(color: Colors.white70, fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('تغيير الحالة:', style: TextStyle(color: Colors.grey, fontSize: 11)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: status,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    items: const [
                      DropdownMenuItem(value: 'not_started', child: Text('لم تبدأ', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'in_progress', child: Text('قيد التنفيذ', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'completed', child: Text('مكتملة', style: TextStyle(color: Colors.white))),
                    ],
                    onChanged: (newStatus) async {
                      if (newStatus != null) {
                        final updates = {
                          'status': newStatus,
                          if (newStatus == 'completed') 'completed_at': DateTime.now().toIso8601String(),
                          if (newStatus != 'completed') 'completed_at': null,
                        };
                        try {
                          await ref.read(adminActionsProvider).updateJourneyStage(stage['id'], updates);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color = Colors.grey;
    String label = 'لم تبدأ';
    switch (status) {
      case 'completed':
        color = AppTheme.primaryGreen;
        label = 'مكتملة';
        break;
      case 'in_progress':
        color = AppTheme.primaryBlue;
        label = 'قيد التنفيذ';
        break;
      case 'not_started':
        color = Colors.orange;
        label = 'لم تبدأ';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _showEditStage(BuildContext context, WidgetRef ref, Map<String, dynamic> stage) {
    final nameCtrl = TextEditingController(text: stage['stage_name'] ?? '');
    final descCtrl = TextEditingController(text: stage['stage_description'] ?? '');
    final notesCtrl = TextEditingController(text: stage['notes'] ?? '');
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('تعديل تفاصيل المرحلة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _field(nameCtrl, 'عنوان المرحلة', Icons.title),
                const SizedBox(height: 12),
                _field(descCtrl, 'الوصف / الأهداف', Icons.description_outlined, maxLines: 3),
                const SizedBox(height: 12),
                _field(notesCtrl, 'ملاحظات إضافية', Icons.notes, maxLines: 2),
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
                      if (nameCtrl.text.trim().isEmpty) return;
                      setState(() => saving = true);
                      try {
                        await ref.read(adminActionsProvider).updateJourneyStage(stage['id'], {
                          'stage_name': nameCtrl.text.trim(),
                          'stage_description': descCtrl.text.trim(),
                          'notes': notesCtrl.text.trim(),
                        });
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
                  : const Text('حفظ', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
        prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 18),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        border: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(10))),
      ),
    );
  }
}
