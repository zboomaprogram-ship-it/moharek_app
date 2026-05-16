import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/shared/models/campaign.dart';
import 'package:moharek_app/l10n/app_localizations.dart';
import 'package:moharek_app/shared/widgets/empty_state.dart';
import 'package:moharek_app/shared/widgets/shimmer_placeholders.dart';
import 'package:moharek_app/shared/services/haptic_service.dart';

class CampaignsScreen extends ConsumerWidget {
  const CampaignsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignsAsync = ref.watch(campaignsProvider);
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.campaigns)),
      body: campaignsAsync.when(
        loading: () => const ShimmerList(itemCount: 4, itemHeight: 120),
        error: (err, _) => Center(child: Text(l10n.errorOccurred(err.toString()))),
        data: (campaigns) {
          if (campaigns.isEmpty) {
            return EmptyState.campaigns(context);
          }
          return RefreshIndicator(
            color: AppTheme.primaryGreen,
            onRefresh: () async {
              ref.invalidate(campaignsProvider);
              HapticService.light();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: campaigns.length,
              itemBuilder: (context, index) {
                final campaign = campaigns[index];
                return _buildCampaignCard(context, campaign, isAr, l10n);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildCampaignCard(BuildContext context, ProjectCampaign campaign, bool isAr, AppLocalizations l10n) {
    final statusColor = _getStatusColor(campaign.status);
    final name = isAr ? (campaign.nameAr ?? campaign.name) : campaign.name;

    return InkWell(
      onTap: () {
        HapticService.light();
        context.push('/dashboard/campaigns/${campaign.id}');
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
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
                _buildChannelBadge(campaign.channel, isAr, l10n),
                _buildStatusBadge(campaign.status, statusColor),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (campaign.goal != null)
              Text(
                isAr ? (campaign.goalAr ?? campaign.goal!) : campaign.goal!,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (campaign.budget != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.budget, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      Text(
                        '${campaign.budget} ${campaign.currency}',
                        style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                if (campaign.startDate != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(l10n.duration, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      Text(
                        _formatDateRange(campaign.startDate, campaign.endDate),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelBadge(String channel, bool isAr, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        channel.replaceAll('_', ' ').toUpperCase(),
        style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active': return AppTheme.primaryGreen;
      case 'completed': return Colors.white54;
      case 'paused': return Colors.orangeAccent;
      case 'planned': return AppTheme.primaryBlue;
      default: return Colors.grey;
    }
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null) return '--';
    final s = '${start.day}/${start.month}';
    if (end == null) return s;
    final e = '${end.day}/${end.month}';
    return '$s - $e';
  }
}
