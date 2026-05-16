import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:moharek_app/core/theme/app_theme.dart';

/// A reusable shimmer placeholder for list screens while data loads.
class ShimmerList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const ShimmerList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Shimmer.fromColors(
          baseColor: AppTheme.cardColor,
          highlightColor: const Color(0xFF1E2D4A),
          child: Container(
            height: itemHeight,
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}

/// A shimmer placeholder for a grid of cards.
class ShimmerGrid extends StatelessWidget {
  final int crossAxisCount;
  final int itemCount;
  final double itemHeight;

  const ShimmerGrid({
    super.key,
    this.crossAxisCount = 2,
    this.itemCount = 6,
    this.itemHeight = 100,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: AppTheme.cardColor,
        highlightColor: const Color(0xFF1E2D4A),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

/// A shimmer placeholder for a stat row (3 equal cards).
class ShimmerStatRow extends StatelessWidget {
  const ShimmerStatRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.cardColor,
      highlightColor: const Color(0xFF1E2D4A),
      child: Row(
        children: List.generate(
          3,
          (i) => Expanded(
            child: Container(
              margin: EdgeInsetsDirectional.only(end: i < 2 ? 12 : 0),
              height: 70,
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A simple card placeholder.
class ShimmerCard extends StatelessWidget {
  final double height;
  const ShimmerCard({super.key, this.height = 100});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.cardColor,
      highlightColor: const Color(0xFF1E2D4A),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
