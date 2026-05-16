import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';
import 'package:moharek_app/shared/services/data_providers.dart';

// ── Admin Notification Center ─────────────────────────────────────

class AdminNotificationsScreen extends ConsumerWidget {
  const AdminNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications Center')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionTitle('Send Push Notification'),
          const SizedBox(height: 16),
          _buildSendCard(context, ref, toAll: false),
          const SizedBox(height: 16),
          _buildSendCard(context, ref, toAll: true),
          const SizedBox(height: 32),
          _buildSectionTitle('Quick Broadcast Templates'),
          const SizedBox(height: 16),
          _buildTemplateCard(
            context, ref,
            '📊 New Report Ready',
            'Your latest performance report is now available in the portal.',
            Icons.analytics_outlined,
            AppTheme.primaryBlue,
          ),
          _buildTemplateCard(
            context, ref,
            '✅ Task Completed',
            'A task has been completed for your project. Check your task list for details.',
            Icons.check_circle_outline,
            AppTheme.primaryGreen,
          ),
          _buildTemplateCard(
            context, ref,
            '📋 Action Required',
            'You have a pending approval request that needs your attention.',
            Icons.pending_actions_outlined,
            Colors.orange,
          ),
          _buildTemplateCard(
            context, ref,
            '📝 Contract Available',
            'A new contract has been uploaded for your review and signature.',
            Icons.description_outlined,
            Colors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSendCard(BuildContext context, WidgetRef ref, {required bool toAll}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                toAll ? Icons.broadcast_on_personal : Icons.person_outline,
                color: toAll ? Colors.orange : AppTheme.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                toAll ? 'Broadcast to All Clients' : 'Send to Specific Client',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _showSendNotificationSheet(context, ref, toAll: toAll),
            style: ElevatedButton.styleFrom(
              backgroundColor: toAll ? Colors.orange.withValues(alpha: 0.2) : AppTheme.primaryBlue.withValues(alpha: 0.2),
              foregroundColor: toAll ? Colors.orange : AppTheme.primaryBlue,
              elevation: 0,
              minimumSize: const Size(double.infinity, 42),
              side: BorderSide(color: toAll ? Colors.orange.withValues(alpha: 0.3) : AppTheme.primaryBlue.withValues(alpha: 0.3)),
            ),
            child: Text(toAll ? 'Send to All Clients' : 'Select Client & Send'),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(
    BuildContext context,
    WidgetRef ref,
    String title,
    String body,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(body, style: const TextStyle(color: Colors.grey, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _sendQuickNotification(context, ref, title: title, body: body),
            icon: Icon(Icons.send, color: color, size: 20),
            tooltip: 'Send to all',
          ),
        ],
      ),
    );
  }

  void _showSendNotificationSheet(BuildContext context, WidgetRef ref, {required bool toAll}) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    String? selectedProjectId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  toAll ? 'Broadcast to All Clients' : 'Send to Client',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Client selector (only if not broadcasting to all)
                if (!toAll)
                  Consumer(
                    builder: (context, ref, _) {
                      final projectsAsync = ref.watch(allProjectsProvider);
                      return projectsAsync.when(
                        data: (projects) => Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(color: const Color(0xFF1A2235), borderRadius: BorderRadius.circular(12)),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedProjectId,
                                  hint: const Text('Select Client', style: TextStyle(color: Colors.grey)),
                                  dropdownColor: AppTheme.cardColor,
                                  isExpanded: true,
                                  items: projects.map((p) {
                                    final profile = p['profiles'] as Map<String, dynamic>?;
                                    final name = profile?['company_name'] as String? ?? 'Client';
                                    return DropdownMenuItem(value: p['id'] as String, child: Text(name, style: const TextStyle(color: Colors.white)));
                                  }).toList(),
                                  onChanged: (val) => setModalState(() => selectedProjectId = val),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const SizedBox.shrink(),
                      );
                    },
                  ),

                _buildField(titleController, 'Notification Title', Icons.title),
                const SizedBox(height: 12),
                _buildField(bodyController, 'Notification Body', Icons.message_outlined, maxLines: 3),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (titleController.text.isEmpty || bodyController.text.isEmpty) return;
                      if (!toAll && selectedProjectId == null) return;

                      final supabase = ref.read(supabaseClientProvider);
                      try {
                        await supabase.functions.invoke(
                          'send-notification',
                          body: {
                            'title': titleController.text.trim(),
                            'body': bodyController.text.trim(),
                            if (!toAll && selectedProjectId != null) 'project_id': selectedProjectId,
                          },
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Notification sent ✅'), backgroundColor: AppTheme.primaryGreen),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      toAll ? 'Broadcast to All' : 'Send Notification',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendQuickNotification(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String body,
  }) async {
    final supabase = ref.read(supabaseClientProvider);
    try {
      await supabase.functions.invoke(
        'send-notification',
        body: {'title': title, 'body': body},
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Broadcast sent to all clients ✅'), backgroundColor: AppTheme.primaryGreen),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildField(TextEditingController controller, String hint, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),
        filled: true,
        fillColor: const Color(0xFF1A2235),
        border: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12))),
      ),
    );
  }
}
