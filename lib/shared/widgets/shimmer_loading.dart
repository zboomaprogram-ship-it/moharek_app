import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:moharek_app/core/theme/app_theme.dart';

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsets? margin;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withValues(alpha: 0.05),
      highlightColor: Colors.white.withValues(alpha: 0.1),
      child: Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  static Widget card() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ShimmerLoading(
        width: double.infinity,
        height: 120,
        borderRadius: 16,
      ),
    );
  }

  static Widget listTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          ShimmerLoading(width: 40, height: 40, borderRadius: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoading(width: 150, height: 14),
                const SizedBox(height: 8),
                ShimmerLoading(width: 100, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget dashboardMetric() {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerLoading(width: 24, height: 24, borderRadius: 12),
          const SizedBox(height: 12),
          ShimmerLoading(width: 80, height: 12),
          const SizedBox(height: 8),
          ShimmerLoading(width: 40, height: 20),
        ],
      ),
    );
  }

  static Widget aiMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerLoading(width: 32, height: 32, borderRadius: 16),
          const SizedBox(width: 12),
          Expanded(
            child: ShimmerLoading(width: double.infinity, height: 60, borderRadius: 16),
          ),
        ],
      ),
    );
  }

  static Widget timelineItem() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          ShimmerLoading(width: 2, height: 100, borderRadius: 0),
          const SizedBox(width: 16),
          Expanded(
            child: ShimmerLoading(width: double.infinity, height: 100, borderRadius: 16),
          ),
        ],
      ),
    );
  }
}
