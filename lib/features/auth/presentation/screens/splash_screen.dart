import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/shared/services/data_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    _controller.forward();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final client = ref.read(supabaseClientProvider);
    if (client.auth.currentSession != null) {
      try {
        // Fetch profile to check role
        final profile = await ref.read(profileProvider.future);
        final role = profile?.role;
        
        final isStaff = role == 'admin' ||
            role == 'account_manager' ||
            role == 'seo_team' ||
            role == 'ads_team' ||
            role == 'content_team' ||
            role == 'design_team' ||
            role == 'tech_team';

        if (isStaff) {
          if (role == 'admin') {
            context.go('/admin/overview');
          } else if (role == 'account_manager') {
            context.go('/am/clients');
          } else {
            // For other staff, default to admin clients for now or a general dashboard
            context.go('/admin/overview');
          }
        } else {
          // Check onboarding for clients
          if (profile?.onboardingCompleted == false) {
            context.go('/onboarding');
          } else {
            context.go('/dashboard');
          }
        }
      } catch (e) {
        debugPrint('Splash Error: $e');
        context.go('/login');
      }
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.rocket_launch,
                  size: 80,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'M O H A R E K',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'CLIENT PORTAL',
                style: TextStyle(
                  color: AppTheme.primaryGreen,
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 48),
              const SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
