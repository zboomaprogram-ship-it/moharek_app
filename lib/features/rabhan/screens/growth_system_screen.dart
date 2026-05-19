import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/rabhan_theme_constants.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import '../providers/growth_provider.dart';
import '../models/growth_engine_model.dart';

class GrowthSystemScreen extends ConsumerWidget {
  const GrowthSystemScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(currentProjectProvider);
    final project = projectAsync.valueOrNull;
    final projectId = project?.id ?? '';

    if (projectId.isEmpty) {
      return Scaffold(
        backgroundColor: RabhanTheme.background,
        appBar: AppBar(title: const Text('محرك النمو'), centerTitle: true),
        body: const Center(
          child: Text(
            'لا يوجد مشروع نشط حالياً',
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
        ),
      );
    }

    final enginesAsync = ref.watch(growthEnginesProvider(projectId));

    return Scaffold(
      backgroundColor: RabhanTheme.background,
      appBar: AppBar(
        title: const Text('لوحة قيادة محرك النمو', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: RabhanTheme.background,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: RabhanTheme.primaryGreen,
        onRefresh: () async {
          ref.invalidate(growthEnginesProvider(projectId));
        },
        child: enginesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: RabhanTheme.primaryGreen)),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: RabhanTheme.error, size: 48),
                const SizedBox(height: 12),
                Text('خطأ في تحميل محركات النمو: $e', style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
          data: (engines) {
            // Define all 6 required engines to ensure they show up even if not in DB
            final requiredTypes = ['store', 'product', 'ads', 'sales_page', 'operations', 'analytics'];
            final engineMap = {for (var e in engines) e.engineType: e};

            final allEngines = requiredTypes.map((type) {
              return engineMap[type] ?? GrowthEngineModel(
                engineType: type,
                status: 'pending',
                healthScore: 0,
              );
            }).toList();

            // Calculate overall health score
            final totalScore = allEngines.fold(0, (sum, e) => sum + e.healthScore);
            final avgScore = (allEngines.isNotEmpty) ? (totalScore / allEngines.length).round() : 0;

            final overallColor = avgScore > 80 ? RabhanTheme.primaryGreen
                               : avgScore > 50 ? RabhanTheme.gold
                               : RabhanTheme.error;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Overall Health Gauge Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                    decoration: BoxDecoration(
                      color: RabhanTheme.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: overallColor.withAlpha((0.15 * 255).round()), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'مؤشر صحة محرك النمو العام',
                          style: TextStyle(color: RabhanTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 16),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 110,
                              height: 110,
                              child: CircularProgressIndicator(
                                value: avgScore / 100,
                                strokeWidth: 10,
                                backgroundColor: Colors.white.withAlpha(15),
                                valueColor: AlwaysStoppedAnimation<Color>(overallColor),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$avgScore%',
                                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                                ),
                                const Text(
                                  'جاهزية النمو',
                                  style: TextStyle(color: RabhanTheme.textSecondary, fontSize: 10),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _getOverallAssessment(avgScore),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: overallColor, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. Section Subtitle
                  const Text(
                    'حالة المحركات التفصيلية',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // 3. ListView of engines
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: allEngines.length,
                    itemBuilder: (context, index) {
                      final engine = allEngines[index];
                      return _buildEngineCard(engine);
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _getOverallAssessment(int score) {
    if (score >= 85) return 'ممتاز! متجرك مهيأ تماماً وقابل للتوسع والنمو السريع 🚀';
    if (score >= 60) return 'جيد. هناك بعض الجوانب بحاجة للتحسين لضمان كفاءة التوسع 📈';
    return 'تنبيه: محركات المتجر تعاني من ثغرات تعطل أداء نمو المبيعات ⚠️';
  }

  Widget _buildEngineCard(GrowthEngineModel engine) {
    final statusColor = switch (engine.status) {
      'active'     => RabhanTheme.primaryGreen,
      'optimizing' => RabhanTheme.gold,
      'critical'   => RabhanTheme.error,
      _            => Colors.blueAccent,
    };

    final statusLabel = switch (engine.status) {
      'active'     => 'نشط وفعال',
      'optimizing' => 'جاري تحسينه',
      'critical'   => 'يحتاج تدخل',
      _            => 'قيد الانتظار',
    };

    final icon = switch (engine.engineType) {
      'store'      => Icons.storefront_outlined,
      'product'    => Icons.shopping_bag_outlined,
      'ads'        => Icons.campaign_outlined,
      'sales_page' => Icons.layers_outlined,
      'operations' => Icons.settings_input_component_outlined,
      _            => Icons.bar_chart_outlined,
    };

    final desc = switch (engine.engineType) {
      'store'      => 'تحسين سرعة التصفح، تجربة العميل وثقة الشراء بالمتجر.',
      'product'    => 'تحليل ربحية المنتجات، تسعيرها، ومعدلات الطلب عليها.',
      'ads'        => 'أداء الحملات الإعلانية المدفوعة وكفاءة الاستهداف والعائد.',
      'sales_page' => 'كفاءة صفحات الهبوط، العروض الترويجية وخطوات الدفع السلسة.',
      'operations' => 'سرعة تنفيذ الطلبات، الدعم الفني، وربط الخدمات اللوجستية.',
      _            => 'تقارير المبيعات، تصنيف العملاء، وتحليلات سلات الشراء المهجورة.',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RabhanTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Radial indicator for individual score
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  value: engine.healthScore / 100,
                  strokeWidth: 4,
                  backgroundColor: Colors.white.withAlpha(15),
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
              Text(
                '${engine.healthScore}',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Center: Title, status badge, and description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      engine.arabicName,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(35),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withAlpha(100), width: 0.5),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: const TextStyle(color: RabhanTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
