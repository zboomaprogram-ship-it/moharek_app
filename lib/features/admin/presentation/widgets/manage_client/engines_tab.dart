import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/core/config/app_config.dart';
import 'package:moharek_app/features/strategy/presentation/screens/strategy_screen.dart';

class EnginesTab extends ConsumerWidget {
  final String pid;
  const EnginesTab({super.key, required this.pid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enginesAsync = ref.watch(adminProjectEngineProgressProvider(pid));
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
                'Growth Engines Progress & Phases',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Engines List
              enginesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (progressList) {
                  final engineList = isRabhan
                      ? [
                          {'key': 'store', 'label': 'Store Engine', 'icon': Icons.storefront_outlined, 'color': Colors.blueAccent},
                          {'key': 'product', 'label': 'Product Engine', 'icon': Icons.inventory_2_outlined, 'color': Colors.purpleAccent},
                          {'key': 'ads', 'label': 'Ads Engine', 'icon': Icons.campaign_outlined, 'color': Colors.redAccent},
                          {'key': 'sales_page', 'label': 'Sales Page Engine', 'icon': Icons.web_outlined, 'color': Colors.orangeAccent},
                          {'key': 'operations', 'label': 'Operations Engine', 'icon': Icons.engineering_outlined, 'color': Colors.cyanAccent},
                          {'key': 'analytics', 'label': 'Analytics Engine', 'icon': Icons.analytics_outlined, 'color': Colors.greenAccent},
                        ]
                      : [
                          {'key': 'content', 'label': 'Content Engine', 'icon': Icons.article_outlined, 'color': Colors.blueAccent},
                          {'key': 'seo', 'label': 'SEO Engine', 'icon': Icons.search, 'color': Colors.purpleAccent},
                          {'key': 'ai_visibility', 'label': 'AI Visibility', 'icon': Icons.auto_awesome, 'color': Colors.redAccent},
                          {'key': 'trust', 'label': 'Trust Engine', 'icon': Icons.verified_user_outlined, 'color': Colors.orangeAccent},
                          {'key': 'conversion', 'label': 'Conversion Engine', 'icon': Icons.shopping_cart_outlined, 'color': Colors.greenAccent},
                        ];

                  return Column(
                    children: engineList.map((e) {
                      final key = e['key'] as String;
                      // Find engine progress map
                      final dbProgress = progressList.firstWhere(
                        (item) => (item['engine'] ?? item['engine_type']) == key,
                        orElse: () => <String, dynamic>{},
                      );

                      return EngineProgressCard(
                        pid: pid,
                        engineKey: key,
                        label: e['label'] as String,
                        icon: e['icon'] as IconData,
                        color: e['color'] as Color,
                        dbProgress: dbProgress,
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

class EngineProgressCard extends ConsumerStatefulWidget {
  final String pid;
  final String engineKey;
  final String label;
  final IconData icon;
  final Color color;
  final Map<String, dynamic> dbProgress;

  const EngineProgressCard({
    super.key,
    required this.pid,
    required this.engineKey,
    required this.label,
    required this.icon,
    required this.color,
    required this.dbProgress,
  });

  @override
  ConsumerState<EngineProgressCard> createState() => _EngineProgressCardState();
}

class _EngineProgressCardState extends ConsumerState<EngineProgressCard> {
  bool _isExpanded = false;
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    final client = ref.watch(supabaseClientProvider);
    final steps = StrategyScreen.engineSteps[widget.engineKey] ?? [];
    final totalSteps = steps.length;

    // Decode checked steps
    List<String> checkedSteps = [];
    final statusNotes = widget.dbProgress['status_notes'] as String?;
    if (statusNotes != null && statusNotes.isNotEmpty) {
      try {
        final decoded = jsonDecode(statusNotes);
        if (decoded is List) {
          checkedSteps = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    final double progressPercent = totalSteps > 0 ? (checkedSteps.length / totalSteps) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          // Header Row (Clickable to Expand)
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progressPercent,
                            backgroundColor: Colors.white.withValues(alpha: 0.05),
                            valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(progressPercent * 100).toInt()}%',
                        style: TextStyle(color: widget.color, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Icon(
                        _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: Colors.white38,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Steps list (Phases)
          if (_isExpanded) ...[
            const Divider(color: Colors.white10, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_isUpdating)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: LinearProgressIndicator(color: AppTheme.primaryGreen, minHeight: 2),
                    ),
                  ...steps.map((step) {
                    final enText = step['en']!;
                    final arText = step['ar']!;
                    final isChecked = checkedSteps.contains(enText);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isChecked,
                            activeColor: widget.color,
                            checkColor: Colors.black,
                            side: const BorderSide(color: Colors.white30),
                            onChanged: _isUpdating
                                ? null
                                : (val) async {
                                    setState(() {
                                      _isUpdating = true;
                                    });

                                    final newChecked = List<String>.from(checkedSteps);
                                    if (val == true) {
                                      newChecked.add(enText);
                                    } else {
                                      newChecked.remove(enText);
                                    }

                                    final newPercent = ((newChecked.length / totalSteps) * 100).toInt();
                                    final engineId = widget.dbProgress['id'] as String? ?? '';

                                    try {
                                      // 1. Update/Insert into engine_progress
                                      if (engineId.isNotEmpty) {
                                        await client.from('engine_progress').update({
                                          'progress_percent': newPercent,
                                          'status_notes': jsonEncode(newChecked),
                                          'updated_at': DateTime.now().toIso8601String(),
                                        }).eq('id', engineId);
                                      } else {
                                        await client.from('engine_progress').insert({
                                          'project_id': widget.pid,
                                          'engine': widget.engineKey,
                                          'progress_percent': newPercent,
                                          'status_notes': jsonEncode(newChecked),
                                          'updated_at': DateTime.now().toIso8601String(),
                                        });
                                      }

                                      // 2. Sync to growth_engines table (updates the main engine health status)
                                      final actions = ref.read(adminActionsProvider);
                                      await actions.updateEngineProgress({
                                        'project_id': widget.pid,
                                        'engine': widget.engineKey,
                                        'progress_percent': newPercent,
                                      });

                                      // Invalidate providers to push live streams
                                      ref.invalidate(adminProjectEngineProgressProvider(widget.pid));
                                      ref.invalidate(projectEnginesProvider(widget.pid));
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.redAccent),
                                        );
                                      }
                                    } finally {
                                      if (mounted) {
                                        setState(() {
                                          _isUpdating = false;
                                        });
                                      }
                                    }
                                  },
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  arText,
                                  style: TextStyle(
                                    color: isChecked ? Colors.white70 : Colors.white,
                                    fontSize: 13,
                                    decoration: isChecked ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  enText,
                                  style: TextStyle(
                                    color: Colors.white30,
                                    fontSize: 11,
                                    decoration: isChecked ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
