import 'package:flutter/material.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'dart:math' as math;
import 'package:moharek_app/l10n/app_localizations.dart';

class HealthScoreGauge extends StatelessWidget {
  final int score;

  const HealthScoreGauge({
    super.key,
    required this.score,
  });

  Color _getScoreColor() {
    if (score < 40) return Colors.redAccent;
    if (score < 70) return Colors.orangeAccent;
    return AppTheme.primaryGreen;
  }

  String _getScoreLabel(AppLocalizations l10n) {
    if (score < 40) return l10n.needsAttention;
    if (score < 70) return l10n.steady;
    return l10n.thriving;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = _getScoreColor();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              children: [
                CustomPaint(
                  size: const Size(80, 80),
                  painter: _GaugePainter(
                    score: score.toDouble(),
                    color: color,
                    backgroundColor: Colors.white10,
                  ),
                ),
                Center(
                  child: Text(
                    '$score',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.projectHealth,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getScoreLabel(l10n),
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.healthScoreDisclaimer,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double score;
  final Color color;
  final Color backgroundColor;

  _GaugePainter({
    required this.score,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2);
    const strokeWidth = 8.0;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75, // Start angle
      math.pi * 1.5, // Sweep angle (270 degrees)
      false,
      bgPaint,
    );

    // Foreground arc
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (score / 100) * (math.pi * 1.5);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
