import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/features/notifications/data/notifications_provider.dart';

class SupportTab extends ConsumerWidget {
  final String pid;
  const SupportTab({super.key, required this.pid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.markProjectNotificationsAsRead(pid, 'support');
      ref.invalidate(notificationsProvider);
    });

    final ticketsAsync = ref.watch(projectTicketsProvider(pid));
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_ticket_$pid',
        backgroundColor: Colors.orange,
        onPressed: () => _showCreateTicket(context, ref),
        child: const Icon(Icons.add_comment_outlined, color: Colors.white),
      ),
      body: ticketsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (tickets) {
          if (tickets.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.support_agent, color: Colors.grey, size: 48),
                  SizedBox(height: 16),
                  Text('لا توجد تذاكر دعم', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final t = tickets[index];
              return _buildTicketCard(context, ref, t);
            },
          );
        },
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context, WidgetRef ref, Map<String, dynamic> t) {
    final status = t['status'] as String? ?? 'open';
    
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
              Text(
                (t['created_at'] as String).split('T')[0],
                style: const TextStyle(color: Colors.white24, fontSize: 10),
              ),
              IconButton(
                icon: const Icon(Icons.edit_note, color: AppTheme.primaryBlue, size: 20),
                onPressed: () => _showUpdateStatus(context, ref, t),
                tooltip: 'تحديث الحالة',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                onPressed: () => _confirmDelete(context, ref, t),
                tooltip: 'حذف التذكرة',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(t['title'] ?? 'بدون عنوان', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          if (t['description'] != null && t['description'].toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              t['description'].toString(),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color = Colors.grey;
    String label = status;
    if (status == 'open') { color = AppTheme.primaryBlue; label = 'مفتوحة'; }
    if (status == 'pending') { color = Colors.orange; label = 'معلقة'; }
    if (status == 'resolved') { color = AppTheme.primaryGreen; label = 'تم الحل'; }
    if (status == 'closed') { color = Colors.white24; label = 'مغلقة'; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _showCreateTicket(BuildContext context, WidgetRef ref) {
    final subCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String priority = 'medium';
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('إدخال تذكرة دعم يدوياً', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(subCtrl, 'الموضوع', Icons.subject),
                const SizedBox(height: 12),
                _field(descCtrl, 'الوصف / المشكلة', Icons.description, maxLines: 3),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: priority,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1E293B),
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('منخفضة', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'medium', child: Text('متوسطة', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'high', child: Text('عالية', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'urgent', child: Text('عاجلة جداً', style: TextStyle(color: Colors.white))),
                      ],
                      onChanged: (v) => setState(() => priority = v!),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
              onPressed: saving ? null : () async {
                if (subCtrl.text.isEmpty) return;
                setState(() => saving = true);
                try {
                  await ref.read(adminActionsProvider).createSupportTicket({
                    'project_id': pid,
                    'title': subCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'priority': priority,
                    'status': 'open',
                  });
                  ref.invalidate(projectTicketsProvider(pid));
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
                } finally {
                  if (ctx.mounted) setState(() => saving = false);
                }
              },
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('إنشاء التذكرة', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateStatus(BuildContext context, WidgetRef ref, Map<String, dynamic> t) {
    String status = t['status'];
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('تحديث حالة التذكرة', style: TextStyle(color: Colors.white)),
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: status,
                isExpanded: true,
                dropdownColor: const Color(0xFF1E293B),
                items: const [
                  DropdownMenuItem(value: 'open', child: Text('مفتوحة', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'pending', child: Text('معلقة', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'resolved', child: Text('تم الحل', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'closed', child: Text('مغلقة', style: TextStyle(color: Colors.white))),
                ],
                onChanged: (v) => setState(() => status = v!),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
              onPressed: saving ? null : () async {
                setState(() => saving = true);
                try {
                  await ref.read(adminActionsProvider).updateSupportTicket(t['id'], {'status': status});
                  ref.invalidate(projectTicketsProvider(pid));
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
                } finally {
                  if (ctx.mounted) setState(() => saving = false);
                }
              },
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('تحديث', style: TextStyle(fontWeight: FontWeight.bold)),
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
        title: const Text('حذف التذكرة', style: TextStyle(color: Colors.white)),
        content: Text('هل تريد حذف "${t['title']}"؟ لا يمكن التراجع عن هذا الإجراء.', style: const TextStyle(color: Color(0xFF94A3B8))),
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
      await ref.read(adminActionsProvider).deleteSupportTicket(t['id'], t['title'] ?? '');
      ref.invalidate(projectTicketsProvider(pid));
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف التذكرة بنجاح ✅'), backgroundColor: AppTheme.primaryGreen));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
    }
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
