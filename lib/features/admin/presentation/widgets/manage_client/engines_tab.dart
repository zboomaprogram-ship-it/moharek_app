import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/core/theme/app_theme.dart';

class EnginesTab extends ConsumerWidget {
  final String pid;
  const EnginesTab({super.key, required this.pid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enginesAsync = ref.watch(projectEnginesProvider(pid));
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: enginesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (engines) {
          final engineList = [
            {'key': 'content', 'label': 'Content Engine', 'icon': Icons.article_outlined},
            {'key': 'seo', 'label': 'SEO Engine', 'icon': Icons.search},
            {'key': 'ai_visibility', 'label': 'AI Visibility', 'icon': Icons.auto_awesome},
            {'key': 'trust', 'label': 'Trust Engine', 'icon': Icons.verified_user_outlined},
            {'key': 'conversion', 'label': 'Conversion Engine', 'icon': Icons.shopping_cart_outlined},
          ];

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: engineList.length,
            itemBuilder: (context, index) {
              final e = engineList[index];
              final progress = engines[e['key']] ?? 0.0;
              return EngineProgressCard(
                pid: pid,
                engineKey: e['key'] as String,
                label: e['label'] as String,
                icon: e['icon'] as IconData,
                initialProgress: progress,
              );
            },
          );
        },
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
