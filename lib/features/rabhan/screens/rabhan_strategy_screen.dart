import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/rabhan_theme_constants.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/features/rabhan/providers/growth_provider.dart';
import 'package:moharek_app/features/rabhan/models/growth_engine_model.dart';

/// Full-featured Rabhan e-commerce strategy screen — shows goal, market info,
/// competitors, and the six growth-engine health bars fed from the DB.
class RabhanStrategyScreen extends ConsumerWidget {
  const RabhanStrategyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(currentProjectProvider);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: RabhanTheme.background,
      appBar: AppBar(
        backgroundColor: RabhanTheme.background,
        elevation: 0,
        title: Text(
          isAr ? 'استراتيجية التجارة الإلكترونية' : 'E-Commerce Strategy',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: projectAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: RabhanTheme.primaryGreen)),
        error: (e, _) => Center(child: Text('خطأ: $e', style: const TextStyle(color: Colors.white))),
        data: (project) {
          if (project == null) {
            return Center(
              child: Text(
                isAr ? 'لا يوجد مشروع نشط' : 'No active project found',
                style: const TextStyle(color: RabhanTheme.textSecondary),
              ),
            );
          }

          return RefreshIndicator(
            color: RabhanTheme.primaryGreen,
            onRefresh: () async {
              ref.invalidate(currentProjectProvider);
              ref.invalidate(growthEnginesProvider(project.id));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Goal Banner ──────────────────────────────────────────
                  _GoalBanner(
                    goal: project.projectGoal,
                    tier: project.subscriptionTier,
                    isAr: isAr,
                  ),
                  const SizedBox(height: 20),

                  // ── Info Grid ────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.public_outlined,
                          label: isAr ? 'السوق المستهدف' : 'Target Market',
                          value: project.targetMarket,
                          color: const Color(0xFF06B6D4),
                          isAr: isAr,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.groups_outlined,
                          label: isAr ? 'الجمهور المستهدف' : 'Target Audience',
                          value: project.targetAudience,
                          color: const Color(0xFFA78BFA),
                          isAr: isAr,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Competitors ──────────────────────────────────────────
                  if ((project.competitors ?? []).isNotEmpty) ...[
                    _CompetitorsCard(competitors: project.competitors!, isAr: isAr),
                    const SizedBox(height: 20),
                  ],

                  // ── Growth Engines ───────────────────────────────────────
                  _SectionHeader(
                    title: isAr ? 'محركات النمو الستة' : '6 E-Commerce Growth Engines',
                    subtitle: isAr
                        ? 'مؤشرات تقدم تحسين كل محرك في مشروعك'
                        : 'Progress of each engine in your project',
                  ),
                  const SizedBox(height: 12),
                  _GrowthEnginesSection(projectId: project.id, isAr: isAr),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// GOAL BANNER
// ═══════════════════════════════════════════════════════════════
class _GoalBanner extends StatelessWidget {
  final String? goal;
  final String? tier;
  final bool isAr;

  const _GoalBanner({this.goal, this.tier, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final tierLabel = _tierLabel(tier, isAr);
    final tierColor = _tierColor(tier);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A2A1A), Color(0xFF0F3D24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: RabhanTheme.primaryGreen.withAlpha(50)),
        boxShadow: [
          BoxShadow(
            color: RabhanTheme.primaryGreen.withAlpha(20),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: RabhanTheme.primaryGreen.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.rocket_launch_outlined, color: RabhanTheme.primaryGreen, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                isAr ? 'هدف المشروع' : 'Project Goal',
                style: const TextStyle(color: RabhanTheme.primaryGreen, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              if (tierLabel != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: tierColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: tierColor.withAlpha(80)),
                  ),
                  child: Text(
                    tierLabel,
                    style: TextStyle(color: tierColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Text(
            goal?.isNotEmpty == true
                ? goal!
                : (isAr ? 'لم يتم تحديد هدف المشروع بعد' : 'Project goal not set yet'),
            style: TextStyle(
              color: goal?.isNotEmpty == true ? Colors.white : RabhanTheme.textSecondary,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  String? _tierLabel(String? t, bool isAr) {
    if (t == null) return null;
    switch (t.toLowerCase()) {
      case 'startup': case 'basic': return isAr ? 'باقة الانطلاق' : 'Startup';
      case 'growth': case 'pro':    return isAr ? 'باقة النمو' : 'Growth Pro';
      case 'scale': case 'enterprise': return isAr ? 'باقة التوسع' : 'Scale';
      default: return t;
    }
  }

  Color _tierColor(String? t) {
    switch ((t ?? '').toLowerCase()) {
      case 'scale': case 'enterprise': return RabhanTheme.gold;
      case 'growth': case 'pro':        return RabhanTheme.primaryGreen;
      default: return const Color(0xFF60A5FA);
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// INFO CARD
// ═══════════════════════════════════════════════════════════════
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Color color;
  final bool isAr;

  const _InfoCard({required this.icon, required this.label, this.value, required this.color, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RabhanTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: RabhanTheme.textSecondary, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value?.isNotEmpty == true ? value! : (isAr ? 'غير محدد' : 'Not set'),
            style: TextStyle(
              color: value?.isNotEmpty == true ? Colors.white : RabhanTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// COMPETITORS CARD
// ═══════════════════════════════════════════════════════════════
class _CompetitorsCard extends StatelessWidget {
  final List<String> competitors;
  final bool isAr;
  const _CompetitorsCard({required this.competitors, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RabhanTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.compare_arrows_rounded, color: Colors.redAccent, size: 18),
            const SizedBox(width: 8),
            Text(isAr ? 'المنافسون' : 'Competitors',
                style: const TextStyle(color: RabhanTheme.textSecondary, fontSize: 12)),
          ]),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: competitors.map((c) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.redAccent.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.redAccent.withAlpha(60)),
              ),
              child: Text(c, style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w500)),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SECTION HEADER
// ═══════════════════════════════════════════════════════════════
class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(color: RabhanTheme.textSecondary, fontSize: 12)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// GROWTH ENGINES SECTION
// ═══════════════════════════════════════════════════════════════
class _GrowthEnginesSection extends ConsumerWidget {
  final String projectId;
  final bool isAr;
  const _GrowthEnginesSection({required this.projectId, required this.isAr});

  static const _engineMeta = [
    {'key': 'store',      'ar': 'محرك المتجر',         'en': 'Store Engine',       'icon': Icons.storefront_outlined,               'color': Color(0xFFF97316)},
    {'key': 'product',    'ar': 'محرك المنتجات',       'en': 'Product Engine',     'icon': Icons.inventory_2_outlined,              'color': Color(0xFF60A5FA)},
    {'key': 'ads',        'ar': 'محرك الإعلانات',      'en': 'Ads Engine',         'icon': Icons.campaign_outlined,                 'color': Color(0xFFA78BFA)},
    {'key': 'sales_page', 'ar': 'محرك صفحات البيع',   'en': 'Sales Page Engine',  'icon': Icons.web_outlined,                      'color': Color(0xFFFBBF24)},
    {'key': 'operations', 'ar': 'محرك العمليات',       'en': 'Operations Engine',  'icon': Icons.engineering_outlined,              'color': Color(0xFF2DD4BF)},
    {'key': 'analytics',  'ar': 'محرك التحليلات',      'en': 'Analytics Engine',   'icon': Icons.analytics_outlined,                'color': Color(0xFF34D399)},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enginesAsync = ref.watch(growthEnginesProvider(projectId));

    return enginesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: RabhanTheme.primaryGreen)),
      error: (_, __) => const SizedBox.shrink(),
      data: (engines) {
        final engineMap = {for (var e in engines) e.engineType: e};

        return Column(
          children: _engineMeta.map((meta) {
            final key = meta['key'] as String;
            final engine = engineMap[key] ?? GrowthEngineModel(
              engineType: key, status: 'pending', healthScore: 0,
            );
            return _EngineProgressTile(
              label: isAr ? (meta['ar'] as String) : (meta['en'] as String),
              icon: meta['icon'] as IconData,
              color: meta['color'] as Color,
              health: engine.healthScore,
              status: engine.status,
              isAr: isAr,
            );
          }).toList(),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ENGINE PROGRESS TILE
// ═══════════════════════════════════════════════════════════════
class _EngineProgressTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final int health;
  final String status;
  final bool isAr;

  const _EngineProgressTile({
    required this.label, required this.icon, required this.color,
    required this.health, required this.status, required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (status) {
      'active'     => RabhanTheme.primaryGreen,
      'optimizing' => RabhanTheme.gold,
      'critical'   => RabhanTheme.error,
      _            => Colors.blueAccent,
    };

    final statusLabel = isAr
        ? switch (status) {
            'active'     => 'نشط',
            'optimizing' => 'يحسَّن',
            'critical'   => 'يحتاج تدخل',
            _            => 'قيد الإعداد',
          }
        : switch (status) {
            'active'     => 'Active',
            'optimizing' => 'Optimizing',
            'critical'   => 'Critical',
            _            => 'Pending',
          };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RabhanTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(8)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withAlpha(28),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Text('$health%', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: health / 100,
                    minHeight: 6,
                    backgroundColor: Colors.white.withAlpha(12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
