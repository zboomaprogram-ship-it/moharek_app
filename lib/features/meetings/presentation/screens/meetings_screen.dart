import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/l10n/app_localizations.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/shared/services/call_service.dart';
import 'package:moharek_app/shared/models/meeting.dart';
import 'package:moharek_app/shared/widgets/shimmer_placeholders.dart';
import 'package:moharek_app/shared/widgets/empty_state.dart';
import 'package:moharek_app/shared/services/haptic_service.dart';

class MeetingsScreen extends ConsumerWidget {
  const MeetingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetingsAsync = ref.watch(meetingsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.meetings),
        actions: [
          TextButton.icon(
            onPressed: () {
              HapticService.light();
              _requestMeeting(context, ref);
            },
            icon: const Icon(Icons.add, color: AppTheme.primaryGreen),
            label: Text(
              l10n.request,
              style: const TextStyle(color: AppTheme.primaryGreen),
            ),
          ),
        ],
      ),
      body: meetingsAsync.when(
        loading: () => const ShimmerList(itemCount: 4, itemHeight: 140),
        error: (err, _) => Center(child: Text(l10n.errorOccurred(err.toString()))),
        data: (meetings) {
          final now = DateTime.now();
          final upcoming = meetings.where((m) => 
            m.status == 'upcoming' || m.status == 'ongoing'
          ).toList();
          final past = meetings.where((m) => 
            m.status == 'completed' || m.status == 'cancelled' || 
            (m.status != 'upcoming' && m.status != 'ongoing') // Fallback for other statuses
          ).toList();

          if (meetings.isEmpty) {
            return EmptyState.meetings(context);
          }

          return RefreshIndicator(
            color: AppTheme.primaryGreen,
            onRefresh: () async {
              ref.invalidate(meetingsProvider);
              HapticService.light();
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (upcoming.isNotEmpty) ...[
                  Text(
                    l10n.upcoming,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...upcoming.map((m) => _buildMeetingCard(context, ref, m, upcoming: true)),
                  const SizedBox(height: 32),
                ],
                if (past.isNotEmpty) ...[
                  Text(
                    l10n.pastMeetings,
                    style: const TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...past.map((m) => _buildMeetingCard(context, ref, m, upcoming: false)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMeetingCard(BuildContext context, WidgetRef ref, ProjectMeeting meeting, {required bool upcoming}) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final title = isAr ? (meeting.titleAr ?? meeting.title) : meeting.title;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: upcoming ? AppTheme.primaryBlue.withValues(alpha: 0.3) : Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMeetingTypeBadge(meeting.meetingType, l10n),
              _buildStatusBadge(context, meeting.status),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (meeting.scheduledAt != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.grey, size: 14),
                const SizedBox(width: 8),
                Text(
                  _formatDateTime(meeting.scheduledAt!),
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ],
          if (meeting.summary != null && meeting.summary!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              meeting.summary!,
              style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
            ),
          ],
          if (meeting.actionItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(l10n.actionItems, style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...meeting.actionItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: AppTheme.primaryGreen, size: 14),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item, style: const TextStyle(color: Colors.white70, fontSize: 13))),
                ],
              ),
            )),
          ],
          if (upcoming && meeting.status == 'ongoing') ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _joinMeeting(context, meeting),
                icon: const Icon(Icons.video_call),
                label: Text(l10n.joinMeeting),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
          if (!upcoming && (meeting.transcript != null || meeting.recordingUrl != null)) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white10),
            Builder(
              builder: (context) {
                final isMobile = MediaQuery.of(context).size.width < 600;
                final actions = [
                  if (meeting.transcript != null)
                    OutlinedButton.icon(
                      onPressed: () => _showTranscript(context, meeting),
                      icon: const Icon(Icons.description_outlined, size: 16),
                      label: const Text('عرض المحتوى'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  if (meeting.recordingUrl != null)
                    ElevatedButton.icon(
                      onPressed: () {
                        // Play recording logic
                      },
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('تشغيل التسجيل'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                ];

                if (isMobile) {
                  return Column(
                    children: [
                      for (int i = 0; i < actions.length; i++) ...[
                        SizedBox(width: double.infinity, child: actions[i]),
                        if (i < actions.length - 1) const SizedBox(height: 8),
                      ],
                    ],
                  );
                }

                return Row(
                  children: [
                    for (int i = 0; i < actions.length; i++) ...[
                      Expanded(child: actions[i]),
                      if (i < actions.length - 1) const SizedBox(width: 8),
                    ],
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMeetingTypeBadge(String type, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        type.toUpperCase(),
        style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    Color color;
    String label;

    switch (status) {
      case 'completed':
        color = AppTheme.primaryGreen;
        label = l10n.completed;
        break;
      case 'ongoing':
        color = Colors.orange;
        label = l10n.ongoing;
        break;
      case 'cancelled':
        color = Colors.red;
        label = l10n.cancelled;
        break;
      default:
        color = AppTheme.primaryBlue;
        label = l10n.upcoming;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _joinMeeting(BuildContext context, ProjectMeeting meeting) {
    HapticService.light();
    
    if (meeting.meetingType == 'external' && meeting.externalLink != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opening external meeting link...')),
      );
      // launchUrl(Uri.parse(meeting.externalLink!));
    } else {
      final roomName = meeting.livekitRoomName ?? 'moharek_${meeting.id.substring(0, 8)}';
      CallService.join(
        context, 
        roomName: roomName, 
        userName: 'Client', // Or use profile name
      );
    }
  }

  Future<void> _requestMeeting(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final titleCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    DateTime? selectedDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.request, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: l10n.topic,
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: dateCtrl,
              readOnly: true,
              style: const TextStyle(color: Colors.white),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (d != null) {
                  final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (t != null) {
                    selectedDate = DateTime(d.year, d.month, d.day, t.hour, t.minute);
                    dateCtrl.text = selectedDate.toString().split('.')[0];
                  }
                }
              },
              decoration: InputDecoration(
                labelText: l10n.date,
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                prefixIcon: const Icon(Icons.calendar_today, color: Colors.grey, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (titleCtrl.text.isEmpty || selectedDate == null) return;
                  final client = ref.read(supabaseClientProvider);
                  final projectId = ref.read(currentProjectProvider).value?.id;
                  if (projectId == null) return;

                  try {
                    await client.from('meetings').insert({
                      'project_id': projectId,
                      'title': titleCtrl.text.trim(),
                      'scheduled_at': selectedDate!.toIso8601String(),
                      'status': 'upcoming',
                      'meeting_type': 'internal',
                    });
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.requestSent), backgroundColor: AppTheme.primaryGreen));
                      ref.invalidate(meetingsProvider);
                    }
                  } catch (e) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(l10n.submit),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showTranscript(BuildContext context, ProjectMeeting meeting) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('AI Transcript', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  child: Text(
                    meeting.transcript!,
                    style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
