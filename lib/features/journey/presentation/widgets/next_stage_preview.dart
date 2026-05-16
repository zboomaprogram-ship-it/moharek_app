import 'package:flutter/material.dart';
import 'package:moharek_app/core/theme/app_theme.dart';

class NextStagePreview extends StatelessWidget {
  final String title;
  final String? description;
  final DateTime? estimatedDate;

  const NextStagePreview({
    super.key,
    required this.title,
    this.description,
    this.estimatedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.forward, color: Colors.grey, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Coming Up Next',
                style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (description != null) ...[
            const SizedBox(height: 8),
            Text(
              description!,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (estimatedDate != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.timer_outlined, color: AppTheme.primaryBlue, size: 14),
                const SizedBox(width: 6),
                Text(
                  'Estimated: ${estimatedDate!.day}/${estimatedDate!.month}/${estimatedDate!.year}',
                  style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
