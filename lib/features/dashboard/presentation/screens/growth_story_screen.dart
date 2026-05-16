import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/shared/models/milestone.dart';
import 'package:moharek_app/l10n/app_localizations.dart';
import 'package:moharek_app/shared/widgets/shimmer_loading.dart';
import 'package:animate_do/animate_do.dart';

class GrowthStoryScreen extends ConsumerWidget {
  const GrowthStoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final milestonesAsync = ref.watch(milestonesProvider);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'قصة نموك' : 'Your Growth Story'),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0F172A),
              AppTheme.primaryGreen.withValues(alpha: 0.02),
            ],
          ),
        ),
        child: milestonesAsync.when(
          loading: () => ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: 5,
            itemBuilder: (context, index) => ShimmerLoading.timelineItem(),
          ),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (milestones) {
            if (milestones.isEmpty) {
              return _buildEmptyStory(isAr);
            }
            
            // Sort by date descending
            final sorted = milestones.toList()..sort((a, b) => b.achievedAt!.compareTo(a.achievedAt!));

            return ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final m = sorted[index];
                return _buildTimelineItem(context, m, index == 0, index == sorted.length - 1, isAr);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyStory(bool isAr) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_stories_outlined, color: Colors.white10, size: 80),
          const SizedBox(height: 24),
          Text(
            isAr ? 'بدأت رحلتنا للتو' : 'Our journey just started',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            isAr ? 'ستظهر هنا كافة إنجازاتك الكبرى قريباً.' : 'All your major achievements will appear here soon.',
            style: const TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, Milestone m, bool isFirst, bool isLast, bool isAr) {
    final dateStr = '${m.achievedAt!.day}/${m.achievedAt!.month}/${m.achievedAt!.year}';
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Line & Dot
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: 20,
                  color: isFirst ? Colors.transparent : AppTheme.primaryGreen.withValues(alpha: 0.2),
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.4),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : AppTheme.primaryGreen.withValues(alpha: 0.2),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32, left: 16, right: 16),
              child: FadeInRight(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTypeBadge(m.milestoneType),
                          Text(dateStr, style: const TextStyle(color: Colors.white24, fontSize: 10)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isAr ? m.titleAr : m.titleEn,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isAr ? m.descriptionAr : m.descriptionEn,
                        style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    Color color = AppTheme.primaryGreen;
    IconData icon = Icons.star_border;

    if (type == 'milestone') {
      color = AppTheme.primaryBlue;
      icon = Icons.flag_outlined;
    } else if (type == 'win') {
      color = Colors.orangeAccent;
      icon = Icons.emoji_events_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 10),
          const SizedBox(width: 4),
          Text(
            type.toUpperCase(),
            style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
