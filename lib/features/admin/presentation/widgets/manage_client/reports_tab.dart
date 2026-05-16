import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class ReportsTab extends ConsumerStatefulWidget {
  final String pid;
  const ReportsTab({super.key, required this.pid});

  @override
  ConsumerState<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends ConsumerState<ReportsTab> {
  bool _isUploading = false;

  Future<void> _uploadReport() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: kIsWeb,
    );
    if (result == null) return;

    setState(() => _isUploading = true);
    final file = result.files.first;
    final client = ref.read(supabaseClientProvider);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_report.pdf';

    try {
      if (kIsWeb && file.bytes != null) {
        await client.storage.from('reports').uploadBinary(fileName, file.bytes!);
      }
      
      final url = client.storage.from('reports').getPublicUrl(fileName);
      final actions = ref.read(adminActionsProvider);
      
      await actions.createReport({
        'project_id': widget.pid,
        'title': file.name,
        'file_url': url,
        'report_type': 'monthly',
        'period': '${DateTime.now().month}/${DateTime.now().year}',
      });

      ref.invalidate(projectReportsProvider(widget.pid));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم رفع التقرير بنجاح ✅'), backgroundColor: AppTheme.primaryGreen));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الرفع: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(projectReportsProvider(widget.pid));

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _isUploading 
        ? null 
        : FloatingActionButton(
            heroTag: 'upload_report_${widget.pid}',
            backgroundColor: Colors.redAccent,
            onPressed: _uploadReport,
            child: const Icon(Icons.picture_as_pdf_outlined, color: Colors.white),
          ),
      body: Stack(
        children: [
          reportsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (reports) {
              if (reports.isEmpty) {
                return const Center(child: Text('لا توجد تقارير مرفوعة', style: TextStyle(color: Colors.grey)));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final r = reports[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                      title: Text(r['title'] ?? 'Report', style: const TextStyle(color: Colors.white, fontSize: 14)),
                      subtitle: Text(r['period'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryGreen, size: 20),
                            onPressed: () => _showEditReport(r),
                            tooltip: 'تعديل',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            onPressed: () => _confirmDelete(r),
                            tooltip: 'حذف',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          if (_isUploading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primaryGreen),
                    SizedBox(height: 16),
                    Text('جاري رفع التقرير...', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showEditReport(Map<String, dynamic> r) {
    final titleCtrl = TextEditingController(text: r['title'] ?? '');
    final periodCtrl = TextEditingController(text: r['period'] ?? '');
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('تعديل التقرير', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(titleCtrl, 'عنوان التقرير', Icons.title),
              const SizedBox(height: 12),
              _field(periodCtrl, 'الفترة (مثال: 05/2026)', Icons.calendar_month),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.black),
              onPressed: saving ? null : () async {
                if (titleCtrl.text.trim().isEmpty) return;
                setState(() => saving = true);
                try {
                  await ref.read(adminActionsProvider).updateReport(r['id'], {
                    'title': titleCtrl.text.trim(),
                    'period': periodCtrl.text.trim(),
                  });
                  ref.invalidate(projectReportsProvider(widget.pid));
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
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

  Future<void> _confirmDelete(Map<String, dynamic> r) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('حذف التقرير', style: TextStyle(color: Colors.white)),
        content: Text('هل تريد حذف "${r['title']}"؟', style: const TextStyle(color: Color(0xFF94A3B8))),
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
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(adminActionsProvider).deleteReport(r['id'], r['title'] ?? '');
      ref.invalidate(projectReportsProvider(widget.pid));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف ✅'), backgroundColor: AppTheme.primaryGreen));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
    }
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon) {
    return TextField(
      controller: ctrl,
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
