import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/shared/models/milestone.dart';
import 'package:animate_do/animate_do.dart';

class MilestoneOverlay extends StatefulWidget {
  final List<Milestone> milestones;
  final VoidCallback onDismiss;

  const MilestoneOverlay({
    super.key,
    required this.milestones,
    required this.onDismiss,
  });

  @override
  State<MilestoneOverlay> createState() => _MilestoneOverlayState();
}

class _MilestoneOverlayState extends State<MilestoneOverlay> {
  late ConfettiController _confettiController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentIndex < widget.milestones.length - 1) {
      setState(() {
        _currentIndex++;
        _confettiController.play();
      });
    } else {
      widget.onDismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    final milestone = widget.milestones[_currentIndex];
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final title = isAr ? milestone.titleAr : milestone.titleEn;
    final description = isAr ? milestone.descriptionAr : milestone.descriptionEn;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.9),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                AppTheme.primaryGreen,
                AppTheme.primaryBlue,
                Colors.yellow,
                Colors.orange,
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Trophy
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(seconds: 1),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                          border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.5), width: 2),
                        ),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          size: 100,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 48),
                
                // Localized Text
                FadeInUp(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: Text(
                    description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                
                // Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentIndex < widget.milestones.length - 1 
                        ? (isAr ? 'الإنجاز التالي' : 'Next Win') 
                        : (isAr ? 'رائع!' : 'Awesome!'),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                    ),
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
