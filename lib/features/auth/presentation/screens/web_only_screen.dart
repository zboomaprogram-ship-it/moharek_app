import 'package:flutter/material.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/shared/services/data_providers.dart';

/// Shown on mobile when an admin user logs in.
/// The admin panel is only accessible via the web.
class WebOnlyScreen extends ConsumerWidget {
  const WebOnlyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.desktop_windows_outlined,
                  size: 64,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'Admin Panel',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'The Moharek Admin Console is only available on the web. Please open it from your computer.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // Web URL card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link, color: AppTheme.primaryGreen, size: 18),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'moharek-admin.web.app',
                        style: TextStyle(
                          color: AppTheme.primaryGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.open_in_new, color: Colors.grey, size: 18),
                      onPressed: () => launchUrl(
                        Uri.parse('https://moharek-admin.web.app'),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Sign out button
              OutlinedButton.icon(
                onPressed: () async {
                  try {
                    await Supabase.instance.client.auth.signOut();
                  } catch (e) {
                    // Ignore network error and proceed with local cleanup
                  }
                  
                  // Clear all caches
                  ref.invalidate(profileProvider);
                  ref.invalidate(currentProjectProvider);
                  ref.invalidate(tasksProvider);
                  ref.invalidate(meetingsProvider);
                  ref.invalidate(invoicesProvider);
                  
                  if (context.mounted) context.go('/login');
                },
                icon: const Icon(Icons.logout, size: 16),
                label: const Text('Sign Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey,
                  side: const BorderSide(color: Colors.white24),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
