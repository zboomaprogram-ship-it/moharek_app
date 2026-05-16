import 'package:flutter/material.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/l10n/app_localizations.dart';
import 'package:moharek_app/shared/models/milestone.dart';
import 'package:intl/intl.dart';

class MilestonesFeed extends StatelessWidget {
  final List<Milestone> milestones;

  const MilestonesFeed({super.key, required this.milestones});

  @override
  Widget build(BuildContext context) {
    if (milestones.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            l10n.recentWins,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: milestones.length,
            itemBuilder: (context, index) {
              final milestone = milestones[index];
              return _buildMilestoneCard(milestone, context);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMilestoneCard(Milestone milestone, BuildContext context) {
    return Container(
      width: 220,
      margin: const EdgeInsetsDirectional.only(end: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events,
              color: AppTheme.primaryGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  milestone.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat(
                    'MMM d, yyyy',
                    Localizations.localeOf(context).toString(),
                  ).format(milestone.achievedAt),
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
