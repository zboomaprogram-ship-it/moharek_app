import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/core/config/app_config.dart';

class ResultsTab extends ConsumerWidget {
  final String pid;
  const ResultsTab({super.key, required this.pid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(projectResultsProvider(pid));
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_metric_$pid',
        backgroundColor: AppTheme.primaryGreen,
        onPressed: () => _showEditResult(context, ref, null),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: resultsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
        data: (results) {
          if (results.isEmpty) {
            return const Center(child: Text('لا توجد نتائج', style: TextStyle(color: Colors.grey)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final r = results[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
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
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  (r['result_type'] ?? 'general').toString().toUpperCase(),
                                  style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(r['metric_label'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${r['metric_value']} ${r['metric_unit'] ?? ''}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryGreen, size: 18),
                      onPressed: () => _showEditResult(context, ref, r),
                      tooltip: 'تعديل',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                      onPressed: () => _confirmDelete(context, ref, r),
                      tooltip: 'حذف',
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showEditResult(BuildContext context, WidgetRef ref, Map<String, dynamic>? r) {
    final isEditing = r != null;
    final isRabhan = AppConfig.flavorName == 'rabhan';
    final labelCtrl = TextEditingController(text: r?['metric_label'] ?? '');
    final valCtrl = TextEditingController(text: r?['metric_value']?.toString() ?? '');
    final unitCtrl = TextEditingController(text: r?['metric_unit'] ?? '');
    
    final types = isRabhan
        ? ['store', 'product', 'ads', 'sales_page', 'operations', 'analytics', 'general']
        : ['seo', 'ads', 'ai_visibility', 'trust_engine', 'conversion', 'leads', 'general'];

    String selectedType = r?['result_type'] ?? (isRabhan ? 'store' : 'seo');
    if (!types.contains(selectedType)) {
      selectedType = isRabhan ? 'store' : 'seo';
    }
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isEditing ? 'تعديل النتيجة' : 'تسجيل نتيجة',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedType,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1E293B),
                      items: types.map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.toUpperCase(), style: const TextStyle(color: Colors.white)),
                      )).toList(),
                      onChanged: (v) => setState(() => selectedType = v!),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _field(labelCtrl, 'اسم المقياس (مثال: زيارات SEO)', Icons.label_outline),
                const SizedBox(height: 12),
                _field(valCtrl, 'القيمة', Icons.numbers, type: TextInputType.number),
                const SizedBox(height: 12),
                _field(unitCtrl, 'الوحدة (مثال: %, زيارة)', Icons.straighten),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.black),
              onPressed: saving ? null : () async {
                if (labelCtrl.text.trim().isEmpty || valCtrl.text.trim().isEmpty) return;
                setState(() => saving = true);
                try {
                  final actions = ref.read(adminActionsProvider);
                  if (isEditing) {
                    await actions.updateResult(r['id'], {
                      'result_type': selectedType,
                      'metric_label': labelCtrl.text.trim(),
                      'metric_value': double.tryParse(valCtrl.text),
                      'metric_unit': unitCtrl.text.trim(),
                    });
                    ref.invalidate(projectResultsProvider(pid));
                  } else {
                    await actions.createResult({
                      'project_id': pid,
                      'result_type': selectedType,
                      'metric_name': labelCtrl.text.trim().toLowerCase().replaceAll(' ', '_'),
                      'metric_label': labelCtrl.text.trim(),
                      'metric_value': double.tryParse(valCtrl.text),
                      'metric_unit': unitCtrl.text.trim(),
                      'recorded_at': DateTime.now().toIso8601String(),
                    });
                    ref.invalidate(projectResultsProvider(pid));
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
                } finally {
                  if (ctx.mounted) setState(() => saving = false);
                }
              },
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : Text(isEditing ? 'حفظ' : 'تسجيل', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Map<String, dynamic> r) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('حذف النتيجة', style: TextStyle(color: Colors.white)),
        content: Text('حذف "${r['metric_label']}"؟', style: const TextStyle(color: Color(0xFF94A3B8))),
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
      await ref.read(adminActionsProvider).deleteResult(r['id'], r['metric_label'] ?? '');
      ref.invalidate(projectResultsProvider(pid));
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف ✅'), backgroundColor: AppTheme.primaryGreen));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
    }
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon, {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
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
