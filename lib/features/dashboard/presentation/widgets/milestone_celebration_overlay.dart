import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/shared/models/milestone.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/shared/services/haptic_service.dart';

class MilestoneCelebrationOverlay extends ConsumerStatefulWidget {
  const MilestoneCelebrationOverlay({super.key});

  @override
  ConsumerState<MilestoneCelebrationOverlay> createState() => _MilestoneCelebrationOverlayState();
}

class _MilestoneCelebrationOverlayState extends ConsumerState<MilestoneCelebrationOverlay> {
  late ConfettiController _confettiController;
  final List<String> _shownMilestoneIds = [];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(milestonesProvider, (previous, next) {
      if (next.hasValue) {
        final newMilestones = next.value!.where((m) => !m.seenByClient && !_shownMilestoneIds.contains(m.id)).toList();
        if (newMilestones.isNotEmpty) {
          _showCelebration(newMilestones.first);
        }
      }
    });

    return Stack(
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2,
            maxBlastForce: 5,
            minBlastForce: 2,
            emissionFrequency: 0.05,
            numberOfParticles: 50,
            gravity: 0.05,
            colors: const [
              AppTheme.primaryGreen,
              AppTheme.primaryBlue,
              Colors.purpleAccent,
              Colors.amber,
              Colors.pinkAccent,
            ],
          ),
        ),
      ],
    );
  }

  void _showCelebration(Milestone milestone) {
    _shownMilestoneIds.add(milestone.id);
    _confettiController.play();
    HapticService.heavy();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 80),
            const SizedBox(height: 24),
            const Text(
              'NEW WIN UNLOCKED!',
              style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),
            Text(
              milestone.title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              milestone.description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  _confettiController.stop();
                  
                  // Mark as seen in database
                  final client = ref.read(supabaseClientProvider);
                  await client.from('milestones').update({'seen_by_client': true}).eq('id', milestone.id);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('LET\'S GO!', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
