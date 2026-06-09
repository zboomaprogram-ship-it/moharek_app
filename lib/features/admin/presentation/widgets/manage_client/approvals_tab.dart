import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:moharek_app/shared/services/wordpress_upload_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:moharek_app/features/notifications/data/notifications_provider.dart';

final _approvalsForProject = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, pid) {
  final c = ref.watch(supabaseClientProvider);
  return robustQueryStream<Map<String, dynamic>>(
    client: c,
    table: 'approvals',
    filterColumn: 'project_id',
    filterValue: pid,
    fromJson: (json) => json,
    orderColumn: 'created_at',
    ascending: false,
  );
});

class ApprovalsTab extends ConsumerWidget {
  final String pid;
  const ApprovalsTab({super.key, required this.pid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.markProjectNotificationsAsRead(pid, 'approval');
      ref.invalidate(notificationsProvider);
    });

    final approvalsAsync = ref.watch(_approvalsForProject(pid));
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_approval_$pid',
        backgroundColor: Colors.purpleAccent,
        onPressed: () => _showEditApproval(context, ref, null),
        child: const Icon(Icons.add_task, color: Colors.white),
      ),
      body: approvalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (approvals) {
          if (approvals.isEmpty) {
            return const Center(child: Text('لا توجد طلبات موافقة', style: TextStyle(color: Colors.grey)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: approvals.length,
            itemBuilder: (context, index) => _buildCard(context, ref, approvals[index]),
          );
        },
      ),
    );
  }

  Widget _buildCard(BuildContext context, WidgetRef ref, Map<String, dynamic> a) {
    final status = a['status'] as String? ?? 'pending';
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
              _statusBadge(status),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryGreen, size: 18),
                onPressed: () => _showEditApproval(context, ref, a),
                tooltip: 'تعديل',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                onPressed: () => _confirmDelete(context, ref, a),
                tooltip: 'حذف',
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(a['title'] ?? 'طلب', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          if (a['description'] != null && a['description'].toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(a['description'].toString(), style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          if (a['file_url'] != null && a['file_url'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final uri = Uri.tryParse(a['file_url'].toString());
                if (uri != null) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.attach_file, color: Colors.purpleAccent, size: 14),
                  const SizedBox(width: 4),
                  const Text(
                    'عرض المرفق / الملف المراد اعتماده',
                    style: TextStyle(color: Colors.purpleAccent, fontSize: 12, decoration: TextDecoration.underline),
                  ),
                ],
              ),
            ),
          ],
          // Quick status update
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['pending', 'approved', 'rejected'].map((s) {
              final isActive = s == status;
              Color c = s == 'approved' ? AppTheme.primaryGreen : s == 'rejected' ? Colors.redAccent : Colors.orange;
              return GestureDetector(
                onTap: isActive ? null : () async {
                  try {
                    await ref.read(adminActionsProvider).updateApproval(a['id'], {'status': s});
                  } catch (e) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? c.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isActive ? c : Colors.white10),
                  ),
                  child: Text(
                    s == 'approved' ? 'موافق' : s == 'rejected' ? 'مرفوض' : 'معلق',
                    style: TextStyle(color: isActive ? c : Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showEditApproval(BuildContext context, WidgetRef ref, Map<String, dynamic>? a) {
    final isEditing = a != null;
    final titleCtrl = TextEditingController(text: a?['title'] ?? '');
    final descCtrl = TextEditingController(text: a?['description'] ?? '');
    bool saving = false;

    String? selectedFileUrl = a?['file_url'];
    String? pickedFileName;
    PlatformFile? pickedFile;
    bool uploadingFile = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isEditing ? 'تعديل الطلب' : 'طلب موافقة جديد',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(titleCtrl, 'العنوان', Icons.title),
              const SizedBox(height: 12),
              _field(descCtrl, 'التفاصيل / رابط', Icons.link, maxLines: 3),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      pickedFileName ?? (selectedFileUrl != null ? 'ملف مرفق موجود' : 'لا يوجد ملف مرفق'),
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (uploadingFile)
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.purpleAccent))
                  else
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
                      onPressed: () async {
                        final result = await FilePicker.pickFiles(withData: true);
                        if (result != null) {
                          setState(() {
                            pickedFile = result.files.first;
                            pickedFileName = pickedFile!.name;
                          });
                        }
                      },
                      icon: const Icon(Icons.attach_file, size: 16),
                      label: const Text('إرفاق ملف'),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
              onPressed: saving ? null : () async {
                if (titleCtrl.text.trim().isEmpty) return;
                setState(() => saving = true);
                try {
                  String? fileUrl = selectedFileUrl;
                  if (pickedFile != null) {
                    setState(() => uploadingFile = true);
                    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${pickedFile!.name}';
                    if (pickedFile!.bytes != null) {
                      fileUrl = await WordPressUploadService.uploadBytes(pickedFile!.bytes!, fileName);
                    } else if (pickedFile!.path != null) {
                      fileUrl = await WordPressUploadService.uploadFile(pickedFile!.path!, fileName);
                    }
                  }

                  final actions = ref.read(adminActionsProvider);
                  if (isEditing) {
                    await actions.updateApproval(a['id'], {
                      'title': titleCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                      'file_url': fileUrl,
                    });
                  } else {
                    await actions.createApproval({
                      'project_id': pid,
                      'title': titleCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                      'file_url': fileUrl,
                      'status': 'pending',
                    });
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
                } finally {
                  if (ctx.mounted) setState(() => saving = false);
                }
              },
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(isEditing ? 'حفظ' : 'إرسال', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Map<String, dynamic> a) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('حذف الطلب', style: TextStyle(color: Colors.white)),
        content: Text('حذف "${a['title']}"؟', style: const TextStyle(color: Color(0xFF94A3B8))),
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
      await ref.read(adminActionsProvider).deleteApproval(a['id'], a['title'] ?? '');
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف ✅'), backgroundColor: AppTheme.primaryGreen));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
    }
  }

  Widget _statusBadge(String status) {
    Color color = Colors.orange;
    String label = 'معلق';
    if (status == 'approved') { color = AppTheme.primaryGreen; label = 'موافق'; }
    if (status == 'rejected') { color = Colors.redAccent; label = 'مرفوض'; }
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
