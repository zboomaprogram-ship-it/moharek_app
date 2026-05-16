import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';

class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminOverviewProvider);

    final isMobile = MediaQuery.of(context).size.width < 1000;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تقارير النظام',
              style: TextStyle(color: Colors.white, fontSize: isMobile ? 24 : 28, fontWeight: FontWeight.w800),
            ),
            Text(
              'تحليل شامل لأداء الشركة والمشاريع',
              style: TextStyle(color: Color(0xFF64748B), fontSize: isMobile ? 13 : 14),
            ),
            const SizedBox(height: 32),
            
            stats.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
              data: (d) => Column(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cardWidth = isMobile 
                        ? (constraints.maxWidth > 600 ? (constraints.maxWidth - 20) / 2 : constraints.maxWidth)
                        : (constraints.maxWidth - 40) / 3;
                      return Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        children: [
                          _ReportStatCard('المشاريع النشطة', '${d.activeClients}', AppTheme.primaryGreen, Icons.rocket_launch_outlined, cardWidth),
                          _ReportStatCard('متوسط صحة المشاريع', '${d.avgHealthScore.toStringAsFixed(1)}%', Colors.blueAccent, Icons.favorite_border, cardWidth),
                          _ReportStatCard('مديري الحسابات', '${d.totalAMs}', Colors.purpleAccent, Icons.people_outline, cardWidth),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  
                  // Analytics Preview Section
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isMobile ? 24 : 32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF334155)),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF1E293B),
                          Colors.blueAccent.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.insights, color: Colors.blueAccent),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text(
                                'توقعات النمو والأداء',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 48),
                        const Icon(Icons.analytics_outlined, size: 64, color: Color(0xFF334155)),
                        const SizedBox(height: 24),
                        const Text(
                          'الرسوم البيانية التفاعلية قيد التجهيز',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                        const Text(
                          'نقوم حالياً بربط البيانات الحية لعرضها بشكل مرئي متطور',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ReportStatCard(String label, String value, Color color, IconData icon, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1)),
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                ),
                Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
