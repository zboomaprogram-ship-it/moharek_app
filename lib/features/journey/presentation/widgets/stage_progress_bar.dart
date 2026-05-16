import 'package:flutter/material.dart';
import 'package:moharek_app/core/theme/app_theme.dart';

class StageProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final Color color;

  const StageProgressBar({
    super.key,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tasks Progress',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
