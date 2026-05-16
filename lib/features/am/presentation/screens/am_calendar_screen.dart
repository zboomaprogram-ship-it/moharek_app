import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';
import 'package:moharek_app/features/am/data/am_providers.dart';
import 'package:moharek_app/shared/services/call_service.dart';
import 'package:intl/intl.dart';

class AmCalendarScreen extends ConsumerWidget {
  const AmCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetingsAsync = ref.watch(amMeetingsProvider);
    final isMobile = MediaQuery.of(context).size.width < 1000;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'مركز الاجتماعات',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'جدولة وإدارة اجتماعات الفيديو مع العملاء',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showCreateMeetingDialog(context, ref),
                      icon: const Icon(Icons.video_call, size: 18),
                      label: const Text('اجتماع جديد'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مركز الاجتماعات',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'جدولة وإدارة اجتماعات الفيديو مع العملاء',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateMeetingDialog(context, ref),
                    icon: const Icon(Icons.video_call, size: 18),
                    label: const Text('اجتماع جديد'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 32),
            Expanded(
              child: meetingsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryGreen,
                  ),
                ),
                error: (err, _) => Center(
                  child: Text(
                    'Error: $err',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                data: (meetings) {
                  if (meetings.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    color: AppTheme.primaryGreen,
                    onRefresh: () async => ref.invalidate(amMeetingsProvider),
                    child: ListView.builder(
                      itemCount: meetings.length,
                      itemBuilder: (context, index) =>
                          _buildMeetingCard(context, ref, meetings[index], isMobile),
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

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            color: Color(0xFF334155),
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            'لا توجد اجتماعات مجدولة',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'اضغط على "اجتماع جديد" لجدولة موعد مع عميل',
            style: TextStyle(color: Color(0xFF475569), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingCard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> meeting,
    bool isMobile,
  ) {
    final projectName = meeting['projects']?['name'] ?? 'مشروع';
    final scheduledAt = DateTime.parse(meeting['scheduled_at']);
    final dateStr = DateFormat('yyyy/MM/dd').format(scheduledAt);
    final timeStr = DateFormat('HH:mm').format(scheduledAt);
    final roomName =
        meeting['livekit_room_name'] ?? 'moharek-meeting-${meeting['id']}';

    final content = [
      Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.videocam_outlined,
              color: AppTheme.primaryBlue,
              size: isMobile ? 24 : 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meeting['title'] as String? ?? 'اجتماع عمل',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 16 : 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  projectName,
                  style: const TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      if (isMobile) const SizedBox(height: 16),
      if (isMobile)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 14,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(width: 6),
                Text(
                  '$dateStr - $timeStr',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            _buildActionButtons(context, ref, meeting, roomName, isMobile: true),
          ],
        )
      else ...[
        const SizedBox(width: 20),
        Row(
          children: [
            const Icon(
              Icons.access_time,
              size: 14,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(width: 6),
            Text(
              '$dateStr - $timeStr',
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const Spacer(),
        _buildActionButtons(context, ref, meeting, roomName, isMobile: false),
      ],
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: content,
            )
          : Row(
              children: content,
            ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> meeting,
    String roomName, {
    required bool isMobile,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: () => CallService.join(
            context,
            roomName: roomName,
            userName: 'Manager',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.black,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 24,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'دخول',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () async {
            final actions = ref.read(adminActionsProvider);
            await actions.deleteMeeting(
              meeting['id'],
              meeting['title'] ?? 'Meeting',
            );
            ref.invalidate(amMeetingsProvider);
          },
          child: const Text(
            'إلغاء',
            style: TextStyle(color: Colors.redAccent, fontSize: 12),
          ),
        ),
      ],
    );
  }

  void _showCreateMeetingDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    String? selectedProjectId;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'جدولة اجتماع جديد',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'اختر المشروع:',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
              const SizedBox(height: 8),
              Consumer(
                builder: (context, ref, _) {
                  final projectsAsync = ref.watch(amClientsProvider);
                  return projectsAsync.when(
                    data: (projects) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedProjectId,
                          hint: const Text(
                            'اختر المشروع',
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                          dropdownColor: const Color(0xFF1E293B),
                          isExpanded: true,
                          items: projects
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p['id'] as String,
                                  child: Text(
                                    p['name'] ?? 'مشروع',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setModalState(() => selectedProjectId = val),
                        ),
                      ),
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const Text('Error loading projects'),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildField(titleController, 'عنوان الاجتماع', Icons.title),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 90),
                          ),
                        );
                        if (date != null) {
                          setModalState(() => selectedDate = date);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          DateFormat('yyyy/MM/dd').format(selectedDate),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (time != null) {
                          setModalState(() => selectedTime = time);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          selectedTime.format(context),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'إلغاء',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedProjectId == null || titleController.text.isEmpty) {
                  return;
                }

                final scheduledAt = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                final actions = ref.read(adminActionsProvider);
                final roomName =
                    'moharek-${DateTime.now().millisecondsSinceEpoch}';

                await actions.createMeeting({
                  'project_id': selectedProjectId,
                  'title': titleController.text.trim(),
                  'scheduled_at': scheduledAt.toIso8601String(),
                  'livekit_room_name': roomName,
                  'status': 'upcoming',
                  'meeting_type': 'video',
                });

                ref.invalidate(amMeetingsProvider);
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.black,
              ),
              child: const Text(
                'جدولة',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String hint,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF64748B)),
        prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        border: const OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }
}
