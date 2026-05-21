import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:moharek_app/core/theme/rabhan_theme_constants.dart';
import 'package:moharek_app/features/rabhan/providers/metrics_provider.dart';

class SalesTrendChart extends ConsumerWidget {
  final String projectId;
  const SalesTrendChart({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(projectMetricsHistoryProvider(projectId));
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return historyAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24.0),
          child: CircularProgressIndicator(color: RabhanTheme.primaryGreen),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (metricsHistory) {
        final published = metricsHistory
            .where((m) => m['is_published'] == true)
            .toList();

        if (published.isEmpty) return const SizedBox.shrink();

        // Sort ascending by period_end for the chart timeline
        final sorted = List<Map<String, dynamic>>.from(published)
          ..sort((a, b) {
            final aEnd = DateTime.tryParse(a['period_end'].toString()) ?? DateTime.now();
            final bEnd = DateTime.tryParse(b['period_end'].toString()) ?? DateTime.now();
            return aEnd.compareTo(bEnd);
          });

        // Use last 30 days (or last 6 periods if historical intervals are larger)
        final displayData = sorted.length > 6 ? sorted.sublist(sorted.length - 6) : sorted;

        final List<FlSpot> spots = [];
        double minY = double.infinity;
        double maxY = double.negativeInfinity;

        for (int i = 0; i < displayData.length; i++) {
          final profit = (displayData[i]['net_profit'] ?? 0).toDouble();
          spots.add(FlSpot(i.toDouble(), profit));
          if (profit < minY) minY = profit;
          if (profit > maxY) maxY = profit;
        }

        // Avoid division by zero/empty limits
        if (minY == double.infinity) {
          minY = 0;
          maxY = 1000;
        }
        if (minY == maxY) {
          minY -= 1000;
          maxY += 1000;
        }

        // Add some padding to Y axis
        final yDiff = maxY - minY;
        minY = (minY - yDiff * 0.15).clamp(0.0, double.infinity);
        maxY = maxY + yDiff * 0.15;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: RabhanTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withAlpha(8), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isAr ? 'صافي الربح (آخر 30 يوم)' : 'Net Profit (Last 30 Days)',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    Icons.trending_up,
                    color: RabhanTheme.primaryGreen.withAlpha(200),
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 140,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: yDiff > 0 ? yDiff / 3 : 100,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.white.withAlpha(5),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: yDiff > 0 ? yDiff / 3 : 500,
                          reservedSize: 45,
                          getTitlesWidget: (value, meta) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                _formatCompactNumber(value),
                                style: const TextStyle(
                                  color: RabhanTheme.textSecondary,
                                  fontSize: 9,
                                ),
                                textAlign: TextAlign.end,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= displayData.length) {
                              return const SizedBox.shrink();
                            }
                            final end = DateTime.tryParse(displayData[idx]['period_end'].toString()) ?? DateTime.now();
                            return Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Text(
                                '${end.day}/${end.month}',
                                style: const TextStyle(
                                  color: RabhanTheme.textSecondary,
                                  fontSize: 9,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (displayData.length - 1).toDouble(),
                    minY: minY,
                    maxY: maxY,
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
                          gradient: LinearGradient(
                            colors: [
                              RabhanTheme.primaryGreen.withAlpha(60),
                              RabhanTheme.primaryGreen.withAlpha(0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatCompactNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    }
    return number.toStringAsFixed(0);
  }
}
