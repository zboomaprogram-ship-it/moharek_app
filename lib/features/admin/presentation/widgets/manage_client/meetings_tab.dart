import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/features/calls/services/call_service.dart';
import 'package:moharek_app/features/notifications/data/notifications_provider.dart';

final _meetingsForProject = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, pid) {
  final c = ref.watch(supabaseClientProvider);
  return robustQueryStream<Map<String, dynamic>>(
    client: c,
    table: 'meetings',
    filterColumn: 'project_id',
    filterValue: pid,
    fromJson: (json) => json,
    orderColumn: 'scheduled_at',
    ascending: false,
  );
});

class MeetingsTab extends ConsumerWidget {
  final String pid;
  const MeetingsTab({super.key, required this.pid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.markProjectNotificationsAsRead(pid, 'meeting');
      ref.invalidate(notificationsProvider);
    });

    final meetingsAsync = ref.watch(projectMeetingsProvider(pid));
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_meeting_$pid',
        backgroundColor: AppTheme.primaryBlue,
        onPressed: () => _showEditMeeting(context, ref, null),
        child: const Icon(Icons.videocam_outlined, color: Colors.white),
      ),
      body: meetingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (meetings) {
          if (meetings.isEmpty) {
            return const Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.videocam_outlined, color: Colors.grey, size: 48),
                SizedBox(height: 16),
                Text('لا توجد اجتماعات مجدولة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('جدول مكالمة استراتيجية أو مراجعة', style: TextStyle(color: Colors.white24, fontSize: 12)),
              ]),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: meetings.length,
            itemBuilder: (context, index) => _buildCard(context, ref, meetings[index]),
          );
        },
      ),
    );
  }

  Widget _buildCard(BuildContext context, WidgetRef ref, Map<String, dynamic> m) {
    final date = DateTime.tryParse(m['scheduled_at']?.toString() ?? '') ?? DateTime.now();
    final isPast = date.isBefore(DateTime.now());
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPast ? Colors.white10 : AppTheme.primaryBlue.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isPast ? Colors.grey : AppTheme.primaryBlue).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(isPast ? Icons.history : Icons.videocam, color: isPast ? Colors.grey : AppTheme.primaryBlue),
        ),
        title: Text(m['title'] ?? 'اجتماع', style: TextStyle(color: isPast ? Colors.white60 : Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')} @ ${date.hour}:${date.minute.toString().padLeft(2,'0')}',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryGreen, size: 20),
              onPressed: () => _showEditMeeting(context, ref, m),
              tooltip: 'تعديل',
            ),
            if (!isPast)
              IconButton(
                icon: const Icon(Icons.video_call, color: AppTheme.primaryGreen),
                onPressed: () => _joinMeeting(context, ref, m),
                tooltip: 'الانضمام',
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
              onPressed: () => _confirmDelete(context, ref, m),
              tooltip: 'حذف',
            ),
          ],
        ),
      ),
    );
  }

  void _showEditMeeting(BuildContext context, WidgetRef ref, Map<String, dynamic>? m) {
    final isEditing = m != null;
    final titleCtrl = TextEditingController(text: m?['title'] ?? '');
    DateTime selectedDate = isEditing
        ? (DateTime.tryParse(m['scheduled_at']?.toString() ?? '') ?? DateTime.now().add(const Duration(days: 1)))
        : DateTime.now().add(const Duration(days: 1));
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isEditing ? 'تعديل الاجتماع' : 'جدولة اجتماع',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(titleCtrl, 'عنوان الاجتماع', Icons.title),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) {
                    final t = await showTimePicker(context: ctx, initialTime: TimeOfDay.fromDateTime(selectedDate));
                    if (t != null) setState(() => selectedDate = DateTime(d.year, d.month, d.day, t.hour, t.minute));
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month, color: AppTheme.primaryBlue, size: 18),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('التاريخ والوقت', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                          Text('${selectedDate.year}-${selectedDate.month.toString().padLeft(2,'0')}-${selectedDate.day.toString().padLeft(2,'0')} @ ${selectedDate.hour}:${selectedDate.minute.toString().padLeft(2,'0')}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
              onPressed: saving ? null : () async {
                if (titleCtrl.text.trim().isEmpty) return;
                setState(() => saving = true);
                try {
                  final actions = ref.read(adminActionsProvider);
                  if (isEditing) {
                    await actions.updateMeeting(m['id'], {
                      'title': titleCtrl.text.trim(),
                      'scheduled_at': selectedDate.toIso8601String(),
                    });
                  } else {
                    await actions.createMeeting({
                      'project_id': pid,
                      'title': titleCtrl.text.trim(),
                      'scheduled_at': selectedDate.toIso8601String(),
                      'status': 'scheduled',
                      'meeting_type': 'video',
                      'livekit_room_name': 'moharek_${pid.substring(0, 8)}',
                    });
                    ref.invalidate(projectMeetingsProvider(pid));
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
                  : Text(isEditing ? 'حفظ' : 'جدولة', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Map<String, dynamic> m) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('حذف الاجتماع', style: TextStyle(color: Colors.white)),
        content: Text('حذف "${m['title']}"؟', style: const TextStyle(color: Color(0xFF94A3B8))),
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
      await ref.read(adminActionsProvider).deleteMeeting(m['id'], m['title'] ?? '');
      ref.invalidate(projectMeetingsProvider(pid));
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف ✅'), backgroundColor: AppTheme.primaryGreen));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _joinMeeting(BuildContext context, WidgetRef ref, Map<String, dynamic> m) async {
    final roomName = m['livekit_room_name'] ?? 'moharek_${pid.substring(0, 8)}';
    await CallService.join(context, roomName: roomName, userName: 'Admin');
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
