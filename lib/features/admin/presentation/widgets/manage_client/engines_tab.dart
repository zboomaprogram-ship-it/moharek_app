import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/core/config/app_config.dart';

class EnginesTab extends ConsumerWidget {
  final String pid;
  const EnginesTab({super.key, required this.pid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enginesAsync = ref.watch(projectEnginesProvider(pid));
    final projectAsync = ref.watch(adminProjectDetailStream(pid));
    final isRabhan = AppConfig.flavorName == 'rabhan';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: projectAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (project) {
          if (project.isEmpty) {
            return const Center(child: Text('Project not found'));
          }

          final goal = project['project_goal'] ?? '';
          final market = project['target_market'] ?? '';
          final audience = project['target_audience'] ?? '';
          final competitorsList = (project['competitors'] as List?)?.cast<String>() ?? [];

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Strategy Card
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isRabhan ? 'Ecom Strategy Details' : 'Strategy Details',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryGreen, size: 20),
                          onPressed: () => _showEditStrategy(context, ref, project),
                          tooltip: 'Edit Strategy',
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white10, height: 24),
                    _strategyField(isRabhan ? 'Project Goal' : 'Goal', goal),
                    const SizedBox(height: 12),
                    _strategyField(isRabhan ? 'Target Market' : 'Market', market),
                    const SizedBox(height: 12),
                    _strategyField(isRabhan ? 'Target Audience' : 'Audience', audience),
                    const SizedBox(height: 12),
                    _strategyField('Competitors', competitorsList.isEmpty ? '-' : competitorsList.join(', ')),
                  ],
                ),
              ),

              const Text(
                'Growth Engines Progress',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Engines List
              enginesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (engines) {
                  final engineList = isRabhan
                      ? [
                          {'key': 'store', 'label': 'Store Engine', 'icon': Icons.storefront_outlined},
                          {'key': 'product', 'label': 'Product Engine', 'icon': Icons.inventory_2_outlined},
                          {'key': 'ads', 'label': 'Ads Engine', 'icon': Icons.campaign_outlined},
                          {'key': 'sales_page', 'label': 'Sales Page Engine', 'icon': Icons.web_outlined},
                          {'key': 'operations', 'label': 'Operations Engine', 'icon': Icons.engineering_outlined},
                          {'key': 'analytics', 'label': 'Analytics Engine', 'icon': Icons.analytics_outlined},
                        ]
                      : [
                          {'key': 'content', 'label': 'Content Engine', 'icon': Icons.article_outlined},
                          {'key': 'seo', 'label': 'SEO Engine', 'icon': Icons.search},
                          {'key': 'ai_visibility', 'label': 'AI Visibility', 'icon': Icons.auto_awesome},
                          {'key': 'trust', 'label': 'Trust Engine', 'icon': Icons.verified_user_outlined},
                          {'key': 'conversion', 'label': 'Conversion Engine', 'icon': Icons.shopping_cart_outlined},
                        ];

                  return Column(
                    children: engineList.map((e) {
                      final progress = engines[e['key']] ?? 0.0;
                      return EngineProgressCard(
                        pid: pid,
                        engineKey: e['key'] as String,
                        label: e['label'] as String,
                        icon: e['icon'] as IconData,
                        initialProgress: progress,
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _strategyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value.isEmpty ? '-' : value,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  void _showEditStrategy(BuildContext context, WidgetRef ref, Map<String, dynamic> project) {
    final goalCtrl = TextEditingController(text: project['project_goal'] ?? '');
    final marketCtrl = TextEditingController(text: project['target_market'] ?? '');
    final audienceCtrl = TextEditingController(text: project['target_audience'] ?? '');
    final compsCtrl = TextEditingController(text: (project['competitors'] as List?)?.join(', ') ?? '');
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Strategy Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(goalCtrl, 'Project Goal', Icons.rocket_launch_outlined),
                const SizedBox(height: 12),
                _field(marketCtrl, 'Target Market', Icons.public),
                const SizedBox(height: 12),
                _field(audienceCtrl, 'Target Audience', Icons.groups),
                const SizedBox(height: 12),
                _field(compsCtrl, 'Competitors (comma separated)', Icons.compare_arrows),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.black),
              onPressed: saving ? null : () async {
                setState(() => saving = true);
                try {
                  final competitors = compsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                  await ref.read(adminActionsProvider).updateProject(project['id'], {
                    'project_goal': goalCtrl.text.trim(),
                    'target_market': marketCtrl.text.trim(),
                    'target_audience': audienceCtrl.text.trim(),
                    'competitors': competitors,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                } finally {
                  if (ctx.mounted) setState(() => saving = false);
                }
              },
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon) {
    return TextField(
      controller: ctrl,
      maxLines: hint == 'Project Goal' ? 3 : 1,
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

class EngineProgressCard extends StatefulWidget {
  final String pid;
  final String engineKey;
  final String label;
  final IconData icon;
  final double initialProgress;

  const EngineProgressCard({
    super.key,
    required this.pid,
    required this.engineKey,
    required this.label,
    required this.icon,
    required this.initialProgress,
  });

  @override
  State<EngineProgressCard> createState() => _EngineProgressCardState();
}

class _EngineProgressCardState extends State<EngineProgressCard> {
  late double _localProgress;

  @override
  void initState() {
    super.initState();
    _localProgress = widget.initialProgress;
  }

  @override
  void didUpdateWidget(EngineProgressCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the DB value changes from outside, update local state
    if (oldWidget.initialProgress != widget.initialProgress) {
      _localProgress = widget.initialProgress;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(widget.icon, color: AppTheme.primaryGreen, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '${(_localProgress * 100).toInt()}%',
                style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.primaryGreen,
              inactiveTrackColor: Colors.white10,
              thumbColor: Colors.white,
              overlayColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
            ),
            child: Consumer(
              builder: (context, ref, child) {
                return Slider(
                  value: _localProgress,
                  onChanged: (v) {
                    setState(() => _localProgress = v);
                  },
                  onChangeEnd: (v) async {
                    final actions = ref.read(adminActionsProvider);
                    await actions.updateEngineProgress({
                      'project_id': widget.pid,
                      'engine': widget.engineKey,
                      'progress_percent': (v * 100).toInt(),
                      'updated_at': DateTime.now().toIso8601String(),
                    });
                    // Invalidate the mobile provider so next open reflects the change
                    ref.invalidate(projectEnginesProvider(widget.pid));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
