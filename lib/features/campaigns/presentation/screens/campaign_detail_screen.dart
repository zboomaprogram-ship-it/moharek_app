import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/shared/models/campaign.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:moharek_app/l10n/app_localizations.dart';

class CampaignDetailScreen extends ConsumerWidget {
  final String campaignId;
  const CampaignDetailScreen({super.key, required this.campaignId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignsAsync = ref.watch(campaignsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.campaignDetail)),
      body: campaignsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
        error: (err, _) => Center(child: Text(l10n.errorOccurred(err.toString()))),
        data: (campaigns) {
          final campaign = campaigns.firstWhere(
            (c) => c.id == campaignId,
            orElse: () => throw Exception('Campaign not found'),
          );
          return _buildBody(context, ref, campaign, l10n);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, ProjectCampaign campaign, AppLocalizations l10n) {
    final resultsAsync = ref.watch(campaignResultsProvider(campaign.id));
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(campaign, isAr),
          const SizedBox(height: 32),
          Text(l10n.performance, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          resultsAsync.when(
            loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
            error: (err, _) => Text('Error: $err'),
            data: (results) => results.isEmpty 
              ? _buildNoResults(l10n)
              : _buildResultsCharts(results),
          ),
          const SizedBox(height: 32),
          _buildBudgetProgress(campaign, l10n),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildHeader(ProjectCampaign campaign, bool isAr) {
    final name = isAr ? (campaign.nameAr ?? campaign.name) : campaign.name;
    final goal = isAr ? (campaign.goalAr ?? campaign.goal) : campaign.goal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (goal != null)
          Text(goal, style: const TextStyle(color: Colors.grey, fontSize: 16)),
      ],
    );
  }

  Widget _buildNoResults(AppLocalizations l10n) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.show_chart, color: Colors.white24, size: 48),
            const SizedBox(height: 12),
            Text(l10n.noDataYet, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCharts(List<CampaignResult> results) {
    // Group by metric label
    final Map<String, List<CampaignResult>> grouped = {};
    for (var r in results) {
      grouped.putIfAbsent(r.metricLabel, () => []).add(r);
    }

    return Column(
      children: grouped.entries.map((entry) {
        return _buildMetricChart(entry.key, entry.value);
      }).toList(),
    );
  }

  Widget _buildMetricChart(String label, List<CampaignResult> data) {
    data.sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      height: 260,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(
                '${data.last.metricValue} ${data.last.metricUnit}',
                style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.metricValue)).toList(),
                    isCurved: true,
                    color: AppTheme.primaryGreen,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetProgress(ProjectCampaign campaign, AppLocalizations l10n) {
    if (campaign.budget == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.budgetUsed, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(
                '${campaign.budget} ${campaign.currency}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: 0.65, // Dummy value
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '65% of monthly budget utilized',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
