import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/features/admin/widgets/admin_activity_feed.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:moharek_app/features/admin/widgets/admin_voice_recorder.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Screen ───────────────────────────────────────────────────────

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(allProjectsProvider);
    final l10n = AppLocalizations.of(context)!;
    final pendingTasksAsync = ref.watch(allPendingTasksProvider);
    final pendingApprovalsAsync = ref.watch(allPendingApprovalsProvider);
    final pendingContractsAsync = ref.watch(allPendingContractsProvider);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.adminConsole,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          l10n.operations,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateClientSheet(context, ref),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(
                      l10n.newClient,
                      style: TextStyle(fontSize: isMobile ? 12 : 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12 : 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Stats Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = isMobile
                      ? (constraints.maxWidth - 12) / 2
                      : (constraints.maxWidth - 48) / 4;

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildStatCard(
                        l10n.activeClients,
                        projectsAsync.when(
                          data: (p) => p.length.toString(),
                          loading: () => '...',
                          error: (_, __) => '?',
                        ),
                        Icons.people_outline,
                        AppTheme.primaryGreen,
                        cardWidth,
                      ),
                      _buildStatCard(
                        l10n.pendingTasksCount(pendingTasksAsync.value ?? 0),
                        pendingTasksAsync.when(
                          data: (n) => n.toString(),
                          loading: () => '...',
                          error: (_, __) => '?',
                        ),
                        Icons.task_outlined,
                        AppTheme.primaryBlue,
                        cardWidth,
                      ),
                      _buildStatCard(
                        l10n.approvalsWaitingCount(
                          pendingApprovalsAsync.value ?? 0,
                        ),
                        pendingApprovalsAsync.when(
                          data: (n) => n.toString(),
                          loading: () => '...',
                          error: (_, __) => '?',
                        ),
                        Icons.pending_actions_outlined,
                        Colors.orange,
                        cardWidth,
                      ),
                      _buildStatCard(
                        l10n.unsignedContractsCount(
                          pendingContractsAsync.value ?? 0,
                        ),
                        pendingContractsAsync.when(
                          data: (n) => n.toString(),
                          loading: () => '...',
                          error: (_, __) => '?',
                        ),
                        Icons.description_outlined,
                        Colors.amber,
                        cardWidth,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 40),

              Row(
                children: [
                  Text(
                    l10n.allClients,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 18 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  _buildFilterButton(context, ref),
                ],
              ),
              const SizedBox(height: 16),

              projectsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
                error: (err, _) => Center(
                  child: Text(
                    l10n.errorOccurred(err.toString()),
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                data: (projects) {
                  final filter = ref.watch(adminClientFilterProvider);
                  final filteredProjects = filter == 'all'
                      ? projects
                      : projects
                            .where((p) => p['current_stage'] == filter)
                            .toList();

                  if (filteredProjects.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(48),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.people_outline,
                              color: Colors.grey,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              filter == 'all'
                                  ? l10n.noClientsFound
                                  : 'لا يوجد عملاء في هذه المرحلة',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (filter == 'all')
                              Text(
                                l10n.clickNewClientToAdd,
                                style: const TextStyle(color: Colors.white38),
                              ),
                          ],
                        ),
                      ),
                    );
                  }
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 1 : 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: isMobile ? 2.5 : 1.6,
                    ),
                    itemCount: filteredProjects.length,
                    itemBuilder: (context, index) {
                      return _buildClientCard(
                        context,
                        ref,
                        filteredProjects[index],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 48),

              // ── Activity Feed ──────────────────────────────────────
              const AdminActivityFeed(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    double width,
  ) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> project,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final client = project['profiles'] as Map<String, dynamic>?;
    final clientName = client?['full_name'] as String? ?? l10n.unknownUser;
    final companyName = client?['company_name'] as String? ?? l10n.companyName;
    final stage = project['current_stage'] as String? ?? 'audit';

    return Container(
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
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                child: Text(
                  clientName.isNotEmpty ? clientName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clientName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      companyName,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: Colors.white24,
                  size: 18,
                ),
                color: AppTheme.cardColor,
                onSelected: (value) {
                  if (value == 'contract') {
                    _showUploadContractSheet(
                      context,
                      ref,
                      project['id'] as String,
                    );
                  } else if (value == 'stage') {
                    _showChangeStageSheet(context, ref, project);
                  } else if (value == 'voice') {
                    _showVoiceRecorderSheet(context, ref, project['id']);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'contract',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.upload_file,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.uploadContract,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'stage',
                    child: Row(
                      children: [
                        Icon(Icons.swap_horiz, color: Colors.white70, size: 16),
                        SizedBox(width: 8),
                        const Text(
                          'تغيير المرحلة',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'voice',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.mic_none,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Growth Update',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              stage.toUpperCase(),
              style: const TextStyle(
                color: AppTheme.primaryGreen,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildAction(
                Icons.chat_bubble_outline,
                () => context.push(
                  '/admin/chat/${project['id']}?name=${Uri.encodeComponent(clientName)}',
                ),
              ),
              const SizedBox(width: 8),
              _buildAction(
                Icons.upload_file,
                () => _showUploadContractSheet(
                  context,
                  ref,
                  project['id'] as String,
                ),
              ),
              const SizedBox(width: 8),
              _buildAction(
                Icons.open_in_new,
                () => context.push('/admin/manage/${project['id']}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(adminClientFilterProvider);

    return PopupMenuButton<String>(
      initialValue: filter,
      icon: Icon(
        Icons.filter_list,
        color: filter == 'all' ? Colors.grey : AppTheme.primaryGreen,
        size: 20,
      ),
      onSelected: (val) =>
          ref.read(adminClientFilterProvider.notifier).state = val,
      color: AppTheme.cardColor,
      itemBuilder: (ctx) => [
        const PopupMenuItem(
          value: 'all',
          child: Text('جميع العملاء', style: TextStyle(color: Colors.white)),
        ),
        const PopupMenuItem(
          value: 'audit',
          child: Text('مرحلة التدقيق', style: TextStyle(color: Colors.white)),
        ),
        const PopupMenuItem(
          value: 'strategy',
          child: Text(
            'مرحلة الاستراتيجية',
            style: TextStyle(color: Colors.white),
          ),
        ),
        const PopupMenuItem(
          value: 'growth',
          child: Text('مرحلة النمو', style: TextStyle(color: Colors.white)),
        ),
        const PopupMenuItem(
          value: 'scale',
          child: Text('مرحلة التوسع', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildAction(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: Colors.white70, size: 16),
      ),
    );
  }

  void _showCreateClientSheet(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final companyController = TextEditingController();
    final projectController = TextEditingController();
    String? generatedPassword;
    bool showPassword = false;

    String _makePassword() {
      const chars = 'ABCDEFGHJKMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789!@#';
      final now = DateTime.now().millisecondsSinceEpoch;
      return List.generate(
        12,
        (i) => chars[(now ~/ (i + 1)) % chars.length],
      ).join();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.newClient,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildField(
                  nameController,
                  l10n.fullName,
                  Icons.person_outline,
                ),
                const SizedBox(height: 12),
                _buildField(
                  emailController,
                  l10n.emailLabel,
                  Icons.email_outlined,
                ),
                const SizedBox(height: 12),
                _buildField(
                  companyController,
                  l10n.companyName,
                  Icons.business_outlined,
                ),
                const SizedBox(height: 12),
                _buildField(
                  projectController,
                  l10n.projectName,
                  Icons.rocket_launch_outlined,
                ),
                const SizedBox(height: 24),

                // Show generated password if available
                if (generatedPassword != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'كلمة المرور المؤقتة للعميل:',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                showPassword
                                    ? generatedPassword!
                                    : '••••••••••••',
                                style: const TextStyle(
                                  color: AppTheme.primaryGreen,
                                  fontFamily: 'monospace',
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                showPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                                size: 16,
                              ),
                              onPressed: () => setModalState(
                                () => showPassword = !showPassword,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.copy,
                                color: AppTheme.primaryGreen,
                                size: 16,
                              ),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: generatedPassword!),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تم نسخ كلمة المرور'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '⚠️ احتفظ بها — لن تُعرض مرة أخرى',
                          style: TextStyle(color: Colors.orange, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('تم، أغلق'),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.isEmpty ||
                            emailController.text.isEmpty ||
                            companyController.text.isEmpty ||
                            projectController.text.isEmpty)
                          return;

                        final supabase = ref.read(supabaseClientProvider);
                        final password = _makePassword();
                        try {
                          showDialog(
                            context: ctx,
                            barrierDismissible: false,
                            builder: (c) => const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          );

                          final actions = ref.read(adminActionsProvider);
                          await actions.createClient({
                            'email': emailController.text.trim(),
                            'password': password,
                            'full_name': nameController.text.trim(),
                            'company_name': companyController.text.trim(),
                            'project_name': projectController.text.trim(),
                          });

                          if (ctx.mounted) Navigator.pop(ctx);

                          setModalState(() => generatedPassword = password);
                          ref.invalidate(allProjectsProvider);
                        } catch (e) {
                          if (ctx.mounted) Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.errorOccurred(e.toString())),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        l10n.createClient,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showVoiceRecorderSheet(
    BuildContext context,
    WidgetRef ref,
    String projectId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdminVoiceRecorder(
        projectId: projectId,
        onComplete: (url) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Growth Update shared!')),
          );
          ref.invalidate(allProjectsProvider);
        },
      ),
    );
  }

  void _showUploadContractSheet(
    BuildContext context,
    WidgetRef ref,
    String projectId,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    // Pick PDF file
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: kIsWeb,
    );

    if (result == null) return;
    final file = result.files.first;

    if (!context.mounted) return;

    final titleCtrl = TextEditingController(
      text: file.name.replaceAll('.pdf', ''),
    );

    final bool? proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: Text(
          l10n.uploadContract,
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.picture_as_pdf,
                  color: Colors.redAccent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    file.name,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Contract Title',
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
            ),
            child: Text(l10n.send, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (proceed != true) return;

    final supabase = ref.read(supabaseClientProvider);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';

    try {
      if (kIsWeb && file.bytes != null) {
        await supabase.storage
            .from('files')
            .uploadBinary('contracts/$fileName', file.bytes!);
      } else if (!kIsWeb && file.path != null) {
        // Mobile/Desktop
        final ioFile = Supabase.instance.client.storage.from('files');
        // This is handled by supabase_flutter's upload method which takes File
      }

      final url = supabase.storage
          .from('files')
          .getPublicUrl('contracts/$fileName');

      final actions = ref.read(adminActionsProvider);
      await actions.uploadContract({
        'project_id': projectId,
        'title': titleCtrl.text.trim(),
        'file_url': url,
      });

      ref.invalidate(allPendingContractsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.contractSentSuccess),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorOccurred(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showChangeStageSheet(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> project,
  ) {
    final stages = [
      ('audit', 'التدقيق والتقييم', Icons.search, Colors.orange),
      (
        'strategy',
        'بناء الاستراتيجية',
        Icons.lightbulb_outline,
        AppTheme.primaryBlue,
      ),
      (
        'setup',
        'الإعداد والإطلاق',
        Icons.rocket_launch_outlined,
        Colors.purple,
      ),
      ('execution', 'التنفيذ والتشغيل', Icons.play_circle_outline, Colors.cyan),
      ('optimization', 'التحسين المستمر', Icons.trending_up, Colors.amber),
      ('results', 'النتائج والتوسع', Icons.star_outline, AppTheme.primaryGreen),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تغيير مرحلة العميل',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...stages.map((s) {
              final (id, label, icon, color) = s;
              final isSelected = project['current_stage'] == id;
              return ListTile(
                leading: Icon(
                  icon,
                  color: isSelected ? color : Colors.white30,
                  size: 22,
                ),
                title: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: color, size: 20)
                    : null,
                onTap: () async {
                  final actions = ref.read(adminActionsProvider);
                  await actions.updateProjectStage(project['id'], id, label);
                  ref.invalidate(allProjectsProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم تغيير المرحلة إلى: $label'),
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                    );
                  }
                },
              );
            }),
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
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),
        filled: true,
        fillColor: const Color(0xFF1A2235),
        border: const OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }
}
