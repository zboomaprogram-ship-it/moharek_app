import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/shared/models/result.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:moharek_app/l10n/app_localizations.dart';
import 'package:moharek_app/shared/services/haptic_service.dart';
import 'package:moharek_app/core/utils/arabic_formatter.dart';
import 'package:moharek_app/core/config/app_config.dart';
import 'package:moharek_app/features/rabhan/widgets/rabhan_results_view.dart';

import 'package:url_launcher/url_launcher.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final List<String> _resultTypes = ['seo', 'ads', 'ai_visibility', 'trust_engine', 'conversion', 'leads'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _resultTypes.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppConfig.flavorName == 'rabhan') {
      return const RabhanResultsView();
    }

    final resultsAsync = ref.watch(resultsProvider);
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.resultsTab),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: Colors.grey,
          tabs: _resultTypes.map((type) => Tab(
            icon: Icon(_getIconForType(type), size: 18),
            text: _getLabelForType(type, isAr),
          )).toList(),
        ),
      ),
      body: resultsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
        error: (err, _) => Center(child: Text(l10n.errorOccurred(err.toString()))),
        data: (results) {
          return TabBarView(
            controller: _tabController,
            children: _resultTypes.map((type) {
              final typeResults = results.where((r) => r.resultType == type).toList();
              return _buildResultsTab(typeResults, _getLabelForType(type, isAr), l10n);
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildResultsTab(List<ResultMetric> metrics, String type, AppLocalizations l10n) {
    if (metrics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_outlined, color: Colors.grey.withValues(alpha: 0.5), size: 64),
            const SizedBox(height: 16),
            Text(l10n.noDataYet, style: const TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 8),
            Text(l10n.resultsAppearLater(type), style: const TextStyle(color: Colors.white38, fontSize: 13)),
          ],
        ),
      );
    }

    // Sort by label then date to group metrics
    final Map<String, List<ResultMetric>> groupedByLabel = {};
    for (var m in metrics) {
      final label = m.metricLabel ?? m.metricName;
      groupedByLabel.putIfAbsent(label, () => []).add(m);
    }

    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      onRefresh: () async {
        ref.invalidate(resultsProvider);
        HapticService.light();
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: groupedByLabel.length,
          itemBuilder: (context, index) {
            final label = groupedByLabel.keys.elementAt(index);
            final latestMetric = groupedByLabel[label]!.first;
            return _buildMetricCard(latestMetric);
          },
        ),
        const SizedBox(height: 32),
        ...groupedByLabel.entries.where((e) => e.value.length > 1).map((e) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${e.key} ${l10n.history}',
                style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildLineChart(e.value),
              const SizedBox(height: 32),
            ],
          );
        }).toList(),
      ],
    ),
  );
}

  Widget _buildMetricCard(ResultMetric metric) {
    final change = metric.changeFromLast;
    final isPositive = change != null && change >= 0;
    final hasAttachment = metric.fileUrl != null && metric.fileUrl!.isNotEmpty;

    final cardContent = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasAttachment ? AppTheme.primaryGreen.withValues(alpha: 0.3) : Colors.white10,
        ),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                metric.metricLabel ?? metric.metricName,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              FittedBox(
                child: Text(
                  '${ArabicFormatter.number(metric.metricValue.truncateToDouble() == metric.metricValue ? metric.metricValue.toInt() : metric.metricValue.toStringAsFixed(1), isAr: Localizations.localeOf(context).languageCode == 'ar')} ${metric.metricUnit ?? ''}',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              if (change != null)
                Row(
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      color: isPositive ? AppTheme.primaryGreen : Colors.redAccent,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${isPositive ? '+' : ''}${ArabicFormatter.number(change.toStringAsFixed(1), isAr: Localizations.localeOf(context).languageCode == 'ar')}%',
                      style: TextStyle(
                        color: isPositive ? AppTheme.primaryGreen : Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              else
                const SizedBox(height: 14),
            ],
          ),
          if (hasAttachment)
            const Positioned(
              top: 0,
              right: 0,
              child: Icon(Icons.attach_file, color: AppTheme.primaryGreen, size: 14),
            ),
        ],
      ),
    );

    if (hasAttachment) {
      return InkWell(
        onTap: () async {
          final uri = Uri.tryParse(metric.fileUrl!);
          if (uri != null) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: cardContent,
      );
    }
    return cardContent;
  }

  Widget _buildLineChart(List<ResultMetric> metrics) {
    final sorted = List<ResultMetric>.from(metrics)..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    final spots = sorted.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.metricValue.toDouble())).toList();

    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppTheme.primaryGreen,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'seo': return Icons.search;
      case 'ads': return Icons.campaign;
      case 'ai_visibility': return Icons.smart_toy;
      case 'trust_engine': return Icons.star_outline;
      case 'conversion': return Icons.shopping_cart_outlined;
      case 'leads': return Icons.people_outline;
      default: return Icons.analytics;
    }
  }

  String _getLabelForType(String type, bool isAr) {
    switch (type) {
      case 'seo': return isAr ? 'SEO' : 'SEO';
      case 'ads': return isAr ? 'الإعلانات' : 'Ads';
      case 'ai_visibility': return isAr ? 'الظهور AI' : 'AI Visibility';
      case 'trust_engine': return isAr ? 'الثقة' : 'Trust';
      case 'conversion': return isAr ? 'التحويل' : 'Conversion';
      case 'leads': return isAr ? 'العملاء' : 'Leads';
      default: return type.toUpperCase();
    }
  }
}
