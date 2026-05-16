import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/l10n/app_localizations.dart';
import 'package:moharek_app/shared/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoading = false;

  Future<void> _updateLanguage(String lang) async {
    setState(() => _isLoading = true);
    try {
      final client = ref.read(supabaseClientProvider);
      await client
          .from('profiles')
          .update({'preferred_language': lang})
          .eq('id', client.auth.currentUser!.id);
      ref.invalidate(profileProvider);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePreference(
    String key,
    bool value,
    Map<String, dynamic> current,
  ) async {
    final updated = Map<String, dynamic>.from(current);
    updated[key] = value;

    final client = ref.read(supabaseClientProvider);
    await client
        .from('profiles')
        .update({'notification_preferences': updated})
        .eq('id', client.auth.currentUser!.id);
    ref.invalidate(profileProvider);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
        error: (e, _) => Center(child: Text(l10n.errorOccurred(e.toString()))),
        data: (profile) {
          if (profile == null) return const SizedBox.shrink();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildSectionHeader(l10n.language),
              const SizedBox(height: 12),
              _buildLanguageTile(
                l10n.english,
                'en',
                profile.preferredLanguage == 'en',
              ),
              _buildLanguageTile(
                l10n.arabic,
                'ar',
                profile.preferredLanguage == 'ar',
              ),

              const SizedBox(height: 32),
              _buildSectionHeader(l10n.notifications),
              const SizedBox(height: 12),
              _buildToggleTile(
                l10n.monthlyReports,
                'reports',
                profile.notificationPreferences['reports'] ?? true,
                profile.notificationPreferences,
              ),
              _buildToggleTile(
                l10n.taskUpdates,
                'tasks',
                profile.notificationPreferences['tasks'] ?? true,
                profile.notificationPreferences,
              ),
              _buildToggleTile(
                l10n.chatMessages,
                'messages',
                profile.notificationPreferences['messages'] ?? true,
                profile.notificationPreferences,
              ),
              _buildToggleTile(
                l10n.milestonesWins,
                'milestones',
                profile.notificationPreferences['milestones'] ?? true,
                profile.notificationPreferences,
              ),

              const SizedBox(height: 48),
              Center(
                child: TextButton(
                  onPressed: () async {
                    // 1. Invalidate first
                    ref.invalidate(profileProvider);
                    ref.invalidate(currentProjectProvider);
                    ref.invalidate(tasksProvider);
                    ref.invalidate(meetingsProvider);
                    ref.invalidate(invoicesProvider);

                    await NotificationService.logout();
                    try {
                      await Supabase.instance.client.auth.signOut();
                    } catch (e) {
                      // Continue with local logout
                    }

                    if (context.mounted) context.go('/login');
                  },
                  child: Text(
                    l10n.logout,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.primaryGreen,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    );
  }

  Widget _buildLanguageTile(String label, String code, bool isSelected) {
    return ListTile(
      onTap: () => _updateLanguage(code),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppTheme.primaryGreen)
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildToggleTile(
    String label,
    String key,
    bool value,
    Map<String, dynamic> prefs,
  ) {
    return SwitchListTile(
      value: value,
      onChanged: (val) => _updatePreference(key, val, prefs),
      title: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ),
      activeColor: AppTheme.primaryGreen,
      contentPadding: EdgeInsets.zero,
    );
  }
}
