import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';
import 'package:moharek_app/core/config/app_config.dart';
import 'package:moharek_app/features/notifications/data/notifications_provider.dart';

// Tab Imports
import '../widgets/manage_client/client_info_tab.dart';
import '../widgets/manage_client/engines_tab.dart';
import '../widgets/manage_client/tasks_tab.dart';
import '../widgets/manage_client/results_tab.dart';
import '../widgets/manage_client/approvals_tab.dart';
import '../widgets/manage_client/reports_tab.dart';
import '../widgets/manage_client/files_tab.dart';
import '../widgets/manage_client/meetings_tab.dart';
import '../widgets/manage_client/campaigns_tab.dart';
import '../widgets/manage_client/billing_tab.dart';
import '../widgets/manage_client/support_tab.dart';
import '../widgets/manage_client/rabhan_package_tab.dart';
import '../widgets/manage_client/rabhan_metrics_tab.dart';
import '../widgets/manage_client/journey_tab.dart';
import '../widgets/manage_client/brief_tab.dart';



class AdminManageClient extends ConsumerStatefulWidget {
  final String projectId;
  final bool isAdmin;

  const AdminManageClient({
    super.key,
    required this.projectId,
    this.isAdmin = true,
  });

  @override
  ConsumerState<AdminManageClient> createState() => _AdminManageClientState();
}

class _AdminManageClientState extends ConsumerState<AdminManageClient> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _tabsCount;

  @override
  void initState() {
    super.initState();
    final isRabhan = AppConfig.flavorName == 'rabhan';
    _tabsCount = isRabhan ? 15 : 14;
    _tabController = TabController(length: _tabsCount, vsync: this);

    _tabController.addListener(_onTabChanged);

    // Initial clear
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _clearNotificationsForIndex(_tabController.index);
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _clearNotificationsForIndex(_tabController.index);
    }
  }

  Future<void> _clearNotificationsForIndex(int index) async {
    final isRabhan = AppConfig.flavorName == 'rabhan';
    String? type;
    if (isRabhan) {
      type = switch (index) {
        0 => null, // Client Info
        4 => 'task',
        7 => 'metrics',
        8 => 'approval',
        9 => 'report',
        10 => 'info',
        11 => 'meeting',
        13 => 'invoice',
        14 => 'support',
        _ => null,
      };
    } else {
      type = switch (index) {
        0 => null, // Client Info
        4 => 'task',
        6 => 'metrics',
        7 => 'approval',
        8 => 'report',
        9 => 'info',
        10 => 'meeting',
        12 => 'invoice',
        13 => 'support',
        _ => null,
      };
    }

    if (type != null) {
      await NotificationService.markProjectNotificationsAsRead(widget.projectId, type);
      if (mounted) {
        ref.invalidate(notificationsProvider);
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(adminProjectDetailStream(widget.projectId));
    final location = GoRouterState.of(context).matchedLocation;
    final isAmRoute = location.startsWith('/am');
    final isMobile = MediaQuery.of(context).size.width < 800;
    final isRabhan = AppConfig.flavorName == 'rabhan';

    Widget buildTabIcon({
      required IconData iconData,
      required String? notificationType,
    }) {
      final icon = Icon(iconData, size: isMobile ? 14 : 18);
      if (notificationType == null) return icon;

      return Consumer(
        builder: (context, ref, child) {
          final unreadCount = ref.watch(unreadNotificationsByProjectAndTypeProvider('${widget.projectId}:$notificationType'));
          if (unreadCount > 0) {
            return Badge(
              label: Text('$unreadCount'),
              backgroundColor: Colors.redAccent,
              child: icon,
            );
          }
          return icon;
        },
      );
    }

    return Scaffold(
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
          Consumer(
            builder: (context, ref, child) {
              final unreadChat = ref.watch(unreadNotificationsByProjectAndTypeProvider('${widget.projectId}:chat_message'));
              return Badge(
                isLabelVisible: unreadChat > 0,
                label: Text('$unreadChat'),
                backgroundColor: Colors.redAccent,
                child: IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.primaryBlue),
                  tooltip: 'Chat with client',
                  onPressed: () {
                    final p = ref.read(adminProjectDetailStream(widget.projectId)).value;
                    if (p == null || p.isEmpty) return;
                    final profiles = p['profiles'];
                    final cName = profiles is Map ? profiles['full_name'] ?? 'Client' : 'Client';
                    if (isAmRoute) {
                      context.push('/am/chat?projectId=${widget.projectId}');
                    } else {
                      context.push('/admin/chat/${widget.projectId}?name=${Uri.encodeComponent(cName)}');
                    }
                  },
                ),
              );
            },
          ),
          if (widget.isAdmin)
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.grey),
              tooltip: 'Settings',
              onPressed: () => _showProjectSettings(context, ref, widget.projectId),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: Colors.grey,
          labelStyle: TextStyle(fontSize: isMobile ? 11 : 13, fontWeight: FontWeight.w600),
          tabs: [
            Tab(icon: buildTabIcon(iconData: Icons.person_pin_outlined, notificationType: null), text: 'Client Info'),
            Tab(icon: buildTabIcon(iconData: Icons.rocket_launch_outlined, notificationType: null), text: isRabhan ? 'Ecom Strategy' : 'Strategy'),
            Tab(icon: buildTabIcon(iconData: Icons.assignment_outlined, notificationType: null), text: 'Brief'),
            Tab(icon: buildTabIcon(iconData: Icons.map_outlined, notificationType: null), text: 'Journey'),
            Tab(icon: buildTabIcon(iconData: Icons.task_outlined, notificationType: 'task'), text: 'Tasks'),
            Tab(icon: buildTabIcon(iconData: Icons.workspace_premium_outlined, notificationType: null), text: 'Package'),
            if (isRabhan)
              Tab(icon: buildTabIcon(iconData: Icons.shopping_bag_outlined, notificationType: null), text: 'Ecom Metrics'),
            Tab(icon: buildTabIcon(iconData: Icons.analytics_outlined, notificationType: 'metrics'), text: isRabhan ? 'Ecom Results' : 'Results'),
            Tab(icon: buildTabIcon(iconData: Icons.approval_outlined, notificationType: 'approval'), text: 'Approvals'),
            Tab(icon: buildTabIcon(iconData: Icons.description_outlined, notificationType: 'report'), text: 'Reports'),
            Tab(icon: buildTabIcon(iconData: Icons.folder_outlined, notificationType: 'info'), text: 'Files'),
            Tab(icon: buildTabIcon(iconData: Icons.videocam_outlined, notificationType: 'meeting'), text: 'Meetings'),
            Tab(icon: buildTabIcon(iconData: Icons.campaign_outlined, notificationType: null), text: 'Campaigns'),
            Tab(icon: buildTabIcon(iconData: Icons.payments_outlined, notificationType: 'invoice'), text: 'Billing'),
            Tab(icon: buildTabIcon(iconData: Icons.support_agent_outlined, notificationType: 'support'), text: 'Support'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ClientInfoTab(pid: widget.projectId, isAdmin: widget.isAdmin),
          EnginesTab(pid: widget.projectId),
          BriefTab(pid: widget.projectId),
          JourneyTab(pid: widget.projectId),
          TasksTab(pid: widget.projectId),
          RabhanPackageTab(pid: widget.projectId),
          if (isRabhan)
            RabhanMetricsTab(pid: widget.projectId),
          ResultsTab(pid: widget.projectId),
          ApprovalsTab(pid: widget.projectId),
          ReportsTab(pid: widget.projectId),
          FilesTab(pid: widget.projectId),
          MeetingsTab(pid: widget.projectId),
          CampaignsTab(pid: widget.projectId),
          BillingTab(pid: widget.projectId),
          SupportTab(pid: widget.projectId),
        ],
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
                ref.invalidate(allProjectsProvider);
                ref.invalidate(adminOverviewProvider);
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
