import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:moharek_app/core/theme/rabhan_theme_constants.dart';
import 'package:moharek_app/features/rabhan/providers/metrics_provider.dart';
import 'package:moharek_app/shared/services/data_providers.dart';

class RabhanAnalyticsScreen extends ConsumerWidget {
  const RabhanAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(currentProjectProvider);
    final project = projectAsync.valueOrNull;
    final projectId = project?.id ?? '';

    if (projectId.isEmpty) {
      return Scaffold(
        backgroundColor: RabhanTheme.background,
        appBar: AppBar(title: const Text('التحليلات والمؤشرات'), centerTitle: true),
        body: const Center(child: Text('لا يوجد مشروع نشط حالياً', style: TextStyle(color: Colors.white))),
      );
    }

    final historyAsync = ref.watch(projectMetricsHistoryProvider(projectId));

    return Scaffold(
      backgroundColor: RabhanTheme.background,
      appBar: AppBar(
        title: const Text('أداء المتجر والتحليلات', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: RabhanTheme.background,
        elevation: 0,
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: RabhanTheme.primaryGreen)),
        error: (e, _) => Center(child: Text('خطأ في تحميل البيانات: $e', style: const TextStyle(color: Colors.red))),
        data: (metricsHistory) {
          // Filter to only published reports for the client view
          final published = metricsHistory.where((m) => m['is_published'] == true).toList();
          
          if (published.isEmpty) {
            return const Center(
              child: Text(
                'سيتم نشر التقارير والمؤشرات قريباً من قبل مدير الحساب',
                style: TextStyle(color: RabhanTheme.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            );
          }

          // Sort ascending for chart progression
          final sortedForChart = List<Map<String, dynamic>>.from(published)
            ..sort((a, b) => (a['period_end'] as String).compareTo(b['period_end'] as String));

          final latest = published.first;
          final currency = latest['currency'] ?? 'SAR';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. KPI cards row
                Row(
                  children: [
                    Expanded(
                      child: _buildKpiCard(
                        title: 'إجمالي المبيعات',
                        value: '${latest['total_sales']} $currency',
                        subText: 'آخر فترة مسجلة',
                        icon: Icons.monetization_on_outlined,
                        color: RabhanTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildKpiCard(
                        title: 'العائد الإعلاني ROAS',
                        value: '${latest['roas']}x',
                        subText: 'أداء الحملات الإعلانية',
                        icon: Icons.trending_up,
                        color: RabhanTheme.gold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildKpiCard(
                        title: 'الطلبات',
                        value: '${latest['orders_count']}',
                        subText: 'عمليات الشراء الناجحة',
                        icon: Icons.shopping_cart_outlined,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildKpiCard(
                        title: 'معدل التحويل CR',
                        value: '${((double.tryParse(latest['conversion_rate']?.toString() ?? '0') ?? 0.0) * 100).toStringAsFixed(2)}%',
                        subText: 'نسبة الشراء للزوار',
                        icon: Icons.percent,
                        color: Colors.purpleAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 2. Sales Trend Line Chart
                _buildCardWrapper(
                  title: 'منحنى نمو المبيعات',
                  subtitle: 'تطور حجم مبيعات متجرك عبر الفترات المتعاقبة',
                  child: SizedBox(
                    height: 200,
                    child: _buildLineChart(sortedForChart, currency),
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Profit vs Spend Bar Chart
                _buildCardWrapper(
                  title: 'صافي الأرباح مقابل الإنفاق الإعلاني',
                  subtitle: 'كفاءة الصرف الإعلاني وتحقيق الأرباح الفعالة',
                  child: SizedBox(
                    height: 200,
                    child: _buildBarChart(sortedForChart, currency),
                  ),
                ),
                const SizedBox(height: 24),

                // 4. Historical reports table
                const Text(
                  'تفاصيل فترات الأداء السابقة',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...published.map((m) => _buildHistoryRow(m, currency)),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subText,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RabhanTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha((0.04 * 255).round())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: RabhanTheme.textSecondary, fontSize: 11)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subText, style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildCardWrapper({required String title, required String subtitle, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: RabhanTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withAlpha((0.04 * 255).round())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: RabhanTheme.textSecondary, fontSize: 11)),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildLineChart(List<Map<String, dynamic>> sortedData, String currency) {
    final spots = <FlSpot>[];
    for (int i = 0; i < sortedData.length; i++) {
      spots.add(FlSpot(i.toDouble(), (sortedData[i]['total_sales'] as num).toDouble()));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.white10, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index < 0 || index >= sortedData.length) return const SizedBox.shrink();
                final endStr = sortedData[index]['period_end']?.toString() ?? '';
                // format like MM/DD
                final parts = endStr.split('-');
                final label = parts.length >= 3 ? '${parts[1]}/${parts[2]}' : endStr;
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(label, style: const TextStyle(color: RabhanTheme.textSecondary, fontSize: 9)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) {
                if (value == meta.max || value == meta.min) return const SizedBox.shrink();
                String label;
                if (value >= 1000000) {
                  label = '${(value / 1000000).toStringAsFixed(1)}M';
                } else if (value >= 1000) {
                  label = '${(value / 1000).toStringAsFixed(0)}K';
                } else {
                  label = value.toStringAsFixed(0);
                }
                return Text(label, style: const TextStyle(color: RabhanTheme.textSecondary, fontSize: 9));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: RabhanTheme.primaryGreen,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: RabhanTheme.primaryGreen.withAlpha((0.1 * 255).round()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> sortedData, String currency) {
    final groups = <BarChartGroupData>[];
    for (int i = 0; i < sortedData.length; i++) {
      final spend = (sortedData[i]['ad_spend'] as num?)?.toDouble() ?? 0.0;
      final profit = (sortedData[i]['net_profit'] as num?)?.toDouble() ?? 0.0;
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(toY: spend, color: RabhanTheme.error, width: 8, borderRadius: BorderRadius.circular(2)),
            BarChartRodData(toY: profit, color: RabhanTheme.primaryGreen, width: 8, borderRadius: BorderRadius.circular(2)),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index < 0 || index >= sortedData.length) return const SizedBox.shrink();
                final endStr = sortedData[index]['period_end']?.toString() ?? '';
                final parts = endStr.split('-');
                final label = parts.length >= 3 ? '${parts[1]}/${parts[2]}' : endStr;
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(label, style: const TextStyle(color: RabhanTheme.textSecondary, fontSize: 9)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) {
                String label;
                if (value >= 1000) {
                  label = '${(value / 1000).toStringAsFixed(0)}K';
                } else {
                  label = value.toStringAsFixed(0);
                }
                return Text(label, style: const TextStyle(color: RabhanTheme.textSecondary, fontSize: 9));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: groups,
      ),
    );
  }

  Widget _buildHistoryRow(Map<String, dynamic> m, String currency) {
    final start = m['period_start']?.toString() ?? '';
    final end = m['period_end']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RabhanTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha((0.03 * 255).round())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$start إلى $end', style: const TextStyle(color: RabhanTheme.textSecondary, fontSize: 11)),
              const Icon(Icons.arrow_back_ios_new, color: RabhanTheme.textSecondary, size: 12),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _detailCol('المبيعات', '${m['total_sales']} $currency'),
              ),
              Expanded(
                child: _detailCol('الإنفاق الإعلاني', '${m['ad_spend'] ?? 0.0} $currency'),
              ),
              Expanded(
                child: _detailCol('ROAS', '${m['roas']}x'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _detailCol('الطلبات', '${m['orders_count']}'),
              ),
              Expanded(
                child: _detailCol('الأرباح الصافية', '${m['net_profit'] ?? 0.0} $currency'),
              ),
              Expanded(
                child: _detailCol('معدل التحويل', '${(((m['conversion_rate'] ?? 0.0) as double) * 100).toStringAsFixed(2)}%'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailCol(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
        const SizedBox(height: 3),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
