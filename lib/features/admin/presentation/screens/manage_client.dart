import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';

// Tab Imports
import '../widgets/manage_client/engines_tab.dart';
import '../widgets/manage_client/tasks_tab.dart';
import '../widgets/manage_client/results_tab.dart';
import '../widgets/manage_client/approvals_tab.dart';
import '../widgets/manage_client/reports_tab.dart';
import '../widgets/manage_client/files_tab.dart';
import '../widgets/manage_client/meetings_tab.dart';
import '../widgets/manage_client/campaigns_tab.dart';
import '../widgets/manage_client/voice_updates_tab.dart';
import '../widgets/manage_client/billing_tab.dart';
import '../widgets/manage_client/support_tab.dart';

// ── Providers ──
final adminProjectDetailStream = StreamProvider.family<Map<String, dynamic>, String>((ref, projectId) {
  final client = ref.watch(supabaseClientProvider);
  return client
      .from('projects')
      .stream(primaryKey: ['id'])
      .eq('id', projectId)
      .map((event) => event.isEmpty ? {} : event.first);
});

class AdminManageClient extends ConsumerWidget {
  final String projectId;
  final bool isAdmin;

  const AdminManageClient({
    super.key,
    required this.projectId,
    this.isAdmin = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(adminProjectDetailStream(projectId));
    final location = GoRouterState.of(context).matchedLocation;
    final isAmRoute = location.startsWith('/am');
    final isMobile = MediaQuery.of(context).size.width < 800;

    return DefaultTabController(
      length: 10,
      child: Scaffold(
        appBar: AppBar(
          title: projectAsync.when(
            data: (p) {
              if (p.isEmpty) return const Text('Project not found');
              final profiles = p['profiles'];
              final name = profiles is Map
                  ? profiles['company_name'] ?? profiles['full_name'] ?? 'Client'
                  : 'Client';
              return Text('Manage: $name', overflow: TextOverflow.ellipsis);
            },
            loading: () => const Text('Loading...'),
            error: (e, _) => Text('Error: $e'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.primaryBlue),
              tooltip: 'Chat with client',
              onPressed: () {
                final p = ref.read(adminProjectDetailStream(projectId)).value;
                if (p == null || p.isEmpty) return;
                final profiles = p['profiles'];
                final cName = profiles is Map ? profiles['full_name'] ?? 'Client' : 'Client';
                if (isAmRoute) {
                  context.push('/am/chat?projectId=$projectId');
                } else {
                  context.push('/admin/chat/$projectId?name=${Uri.encodeComponent(cName)}');
                }
              },
            ),
            if (isAdmin)
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.grey),
                tooltip: 'Settings',
                onPressed: () => _showProjectSettings(context, ref, projectId),
              ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppTheme.primaryGreen,
            labelColor: AppTheme.primaryGreen,
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(fontSize: isMobile ? 11 : 13, fontWeight: FontWeight.w600),
            tabs: [
              Tab(icon: Icon(Icons.rocket_launch_outlined, size: isMobile ? 14 : 18), text: 'Strategy'),
              Tab(icon: Icon(Icons.task_outlined, size: isMobile ? 14 : 18), text: 'Tasks'),
              Tab(icon: Icon(Icons.analytics_outlined, size: isMobile ? 14 : 18), text: 'Results'),
              Tab(icon: Icon(Icons.approval_outlined, size: isMobile ? 14 : 18), text: 'Approvals'),
              Tab(icon: Icon(Icons.description_outlined, size: isMobile ? 14 : 18), text: 'Reports'),
              Tab(icon: Icon(Icons.folder_outlined, size: isMobile ? 14 : 18), text: 'Files'),
              Tab(icon: Icon(Icons.videocam_outlined, size: isMobile ? 14 : 18), text: 'Meetings'),
              Tab(icon: Icon(Icons.campaign_outlined, size: isMobile ? 14 : 18), text: 'Campaigns'),
              Tab(icon: Icon(Icons.payments_outlined, size: isMobile ? 14 : 18), text: 'Billing'),
              Tab(icon: Icon(Icons.support_agent_outlined, size: isMobile ? 14 : 18), text: 'Support'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            EnginesTab(pid: projectId),
            TasksTab(pid: projectId),
            ResultsTab(pid: projectId),
            ApprovalsTab(pid: projectId),
            ReportsTab(pid: projectId),
            FilesTab(pid: projectId),
            MeetingsTab(pid: projectId),
            CampaignsTab(pid: projectId),
            BillingTab(pid: projectId),
            SupportTab(pid: projectId),
          ],
        ),
      ),
    );
  }

  void _showProjectSettings(BuildContext context, WidgetRef ref, String pid) {
    // This could also be extracted if needed, but keeping here for now as it's a small sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => _ProjectSettingsSheet(pid: pid),
    );
  }
}

class _ProjectSettingsSheet extends ConsumerWidget {
  final String pid;
  const _ProjectSettingsSheet({required this.pid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Placeholder for project settings logic
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Project Settings', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
            title: const Text('Delete Project', style: TextStyle(color: Colors.redAccent)),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF1E293B),
                  title: const Text('حذف المشروع', style: TextStyle(color: Colors.white)),
                  content: const Text('هل أنت متأكد من حذف هذا المشروع نهائياً؟ لا يمكن التراجع عن هذا الإجراء.', style: TextStyle(color: Colors.grey)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true), 
                      child: const Text('حذف نهائي', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                final actions = ref.read(adminActionsProvider);
                // We need the project name for logging, let's fetch it from the stream value
                final p = ref.read(adminProjectDetailStream(pid)).value;
                final name = p?['profiles']?['company_name'] ?? p?['profiles']?['full_name'] ?? 'Project';
                
                await actions.deleteProject(pid, name);
                if (context.mounted) {
                  context.go('/admin/clients');
                }
              }
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
