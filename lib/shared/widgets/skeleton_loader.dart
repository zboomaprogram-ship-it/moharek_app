import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:moharek_app/core/theme/app_theme.dart';

class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12.0,
  });

  factory SkeletonLoader.card({double width = double.infinity, double height = 120}) {
    return SkeletonLoader(width: width, height: height);
  }

  factory SkeletonLoader.text({double width = 100, double height = 16}) {
    return SkeletonLoader(width: width, height: height, borderRadius: 4);
  }

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withValues(alpha: 0.05),
      highlightColor: Colors.white.withValues(alpha: 0.1),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoader(width: 200, height: 28),
          const SizedBox(height: 24),
          SkeletonLoader.card(height: 160), // Banner
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: SkeletonLoader.card(height: 80)),
              const SizedBox(width: 12),
              Expanded(child: SkeletonLoader.card(height: 80)),
            ],
          ),
          const SizedBox(height: 24),
          const SkeletonLoader(width: 150, height: 20),
          const SizedBox(height: 16),
          SkeletonLoader.card(height: 200), // Chart or Engine
          const SizedBox(height: 24),
          const SkeletonLoader(width: 150, height: 20),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            itemBuilder: (_, __) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SkeletonLoader.card(height: 70),
            ),
          ),
        ],
      ),
    );
  }
}
