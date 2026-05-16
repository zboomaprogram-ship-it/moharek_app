import 'package:flutter/material.dart';
import 'package:moharek_app/core/theme/app_theme.dart';

class JourneyTimelineConnector extends StatelessWidget {
  final bool isCompleted;
  final bool isLast;

  const JourneyTimelineConnector({
    super.key,
    required this.isCompleted,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLast) return const SizedBox(height: 16);

    return Container(
      width: 2,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isCompleted
              ? [AppTheme.primaryGreen, AppTheme.primaryGreen]
              : [AppTheme.primaryGreen, AppTheme.primaryGreen.withValues(alpha: 0.1)],
        ),
      ),
    );
  }
}
