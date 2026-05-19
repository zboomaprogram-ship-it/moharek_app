import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/metrics_provider.dart';
import 'kpi_card.dart';

class EcomKpiSection extends ConsumerWidget {
  final String projectId;
  const EcomKpiSection({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(latestMetricsProvider(projectId));

    return metricsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24.0),
          child: CircularProgressIndicator(color: Color(0xFF2EE59D)),
        ),
      ),
      error: (e, _) => const SizedBox.shrink(),
      data: (metrics) {
        if (metrics == null) return const SizedBox.shrink();
        
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: KpiCard(
                    label: 'المبيعات',
                    value: 'ر.س ${metrics.totalSales.toStringAsFixed(0)}',
                    delta: metrics.salesDeltaPercent,
                    icon: Icons.shopping_bag_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: KpiCard(
                    label: 'الطلبات',
                    value: metrics.ordersCount.toString(),
                    delta: metrics.ordersDeltaPercent,
                    icon: Icons.receipt_long_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: KpiCard(
                    label: 'ROAS',
                    value: '${metrics.roas.toStringAsFixed(2)}x',
                    delta: metrics.roasDeltaPercent,
                    icon: Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: KpiCard(
                    label: 'معدل التحويل',
                    value: '${(metrics.conversionRate * 100).toStringAsFixed(2)}%',
                    delta: metrics.conversionDeltaPercent,
                    icon: Icons.swap_horiz,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
