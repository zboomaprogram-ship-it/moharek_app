import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moharek_app/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/shared/models/profile.dart';
import 'package:moharek_app/shared/services/notification_service.dart';
import 'package:moharek_app/features/profile/presentation/screens/settings_screen.dart';
import 'package:moharek_app/features/profile/presentation/screens/team_management_screen.dart';
import 'package:moharek_app/shared/widgets/fade_in_slide.dart';
import 'dart:ui';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF080B12),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
        error: (err, _) =>
            Center(child: Text(l10n.errorOccurred(err.toString()))),
        data: (profile) => CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(context, ref, profile, l10n),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 100),
                child: Column(
                  children: [
                    _buildStatsRow(ref),
                    const SizedBox(height: 40),
                    _buildSectionHeader(l10n.accountSettings),
                    const SizedBox(height: 16),
                    _buildSettingsGroup([
                      _buildPremiumItem(
                        l10n.personalInfo,
                        Icons.person_outline,
                        AppTheme.primaryGreen,
                        () => context.push('/profile/edit'),
                      ),
                      _buildPremiumItem(
                        l10n.companyProfile,
                        Icons.business_outlined,
                        AppTheme.primaryBlue,
                        () => context.push('/profile/company'),
                      ),
                      _buildPremiumItem(
                        l10n.localeName == 'ar'
                            ? 'إدارة الفريق'
                            : 'Team Management',
                        Icons.people_outline,
                        Colors.orangeAccent,
                        () => context.push('/profile/team'),
                      ),
                      _buildPremiumItem(
                        l10n.billingInvoices,
                        Icons.account_balance_wallet_outlined,
                        Colors.purpleAccent,
                        () => context.go('/dashboard/billing'),
                      ),
                      _buildPremiumItem(
                        l10n.appSettingsNotifications,
                        Icons.settings_suggest_outlined,
                        Colors.tealAccent,
                        () => context.push('/profile/settings'),
                      ),
                    ]),
                    const SizedBox(height: 40),
                    _buildDangerZone(context, l10n),
                    const SizedBox(height: 48),
                    Text(
                      l10n.version('1.0.2'),
                      style: const TextStyle(
                        color: Color(0xFF334155),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(
    BuildContext context,
    WidgetRef ref,
    Profile? profile,
    AppLocalizations l10n,
  ) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: const Color(0xFF0F172A),
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.white,
          size: 20,
        ),
        onPressed: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            context.go('/dashboard');
          }
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.redAccent),
          onPressed: () => _showLogoutDialog(context, ref, l10n),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background Gradient/Image
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1E293B), Color(0xFF080B12)],
                ),
              ),
            ),
            // Abstract decorative circles
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryGreen.withValues(alpha: 0.05),
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                FadeInSlide(
                  duration: const Duration(milliseconds: 600),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: const Color(0xFF1E293B),
                          backgroundImage: profile?.avatarUrl != null
                              ? NetworkImage(profile!.avatarUrl!)
                              : null,
                          child: profile?.avatarUrl == null
                              ? Text(
                                  profile?.fullName.isNotEmpty == true
                                      ? profile!.fullName[0].toUpperCase()
                                      : (profile?.email?.isNotEmpty == true
                                          ? profile!.email![0].toUpperCase()
                                          : '?'),
                                  style: const TextStyle(
                                    color: AppTheme.primaryGreen,
                                    fontSize: 40,
                                    fontWeight: FontWeight.w900,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FadeInSlide(
                  duration: const Duration(milliseconds: 700),
                  child: Text(
                    (profile?.fullName != null && profile!.fullName.isNotEmpty) 
                        ? profile.fullName 
                        : (profile?.email ?? l10n.unknownUser),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                FadeInSlide(
                  duration: const Duration(milliseconds: 800),
                  child: Text(
                    profile?.role == 'admin' 
                      ? (l10n.localeName == 'ar' ? 'مدير النظام' : 'Administrator')
                      : (profile?.role == 'am'
                          ? (l10n.localeName == 'ar' ? 'مدير حسابات' : 'Account Manager')
                          : (profile?.companyName ?? l10n.noCompany)),
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(WidgetRef ref) {
    final tasks = ref.watch(tasksProvider).value ?? [];
    final activeTasks = tasks.where((t) => t.status != 'completed').length;
    final project = ref.watch(currentProjectProvider).value;
    final results = ref.watch(resultsProvider).value ?? [];

    // Calculate growth from latest 2 results if available
    String growth = '0%';
    if (results.length >= 2) {
      final latest = results.first.metricValue;
      final previous = results[1].metricValue;
      if (previous > 0) {
        final diff = ((latest - previous) / previous * 100).toInt();
        growth = '${diff > 0 ? '+' : ''}$diff%';
      }
    } else if (results.isNotEmpty) {
      growth = '+${(results.first.metricValue % 100).toInt()}%';
    }

    final level = project?.subscriptionTier?.toUpperCase() ?? 'FREE';

    return FadeInSlide(
      duration: const Duration(milliseconds: 900),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 400;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildStatCard(
                'المهام النشطة',
                activeTasks.toString(),
                Icons.task_alt,
                Colors.orangeAccent,
                width: isSmall ? constraints.maxWidth : (constraints.maxWidth - 24) / 3,
              ),
              _buildStatCard(
                'المستوى',
                level,
                Icons.workspace_premium,
                Colors.amber,
                width: isSmall ? constraints.maxWidth : (constraints.maxWidth - 24) / 3,
              ),
              _buildStatCard(
                'النمو',
                growth,
                Icons.trending_up,
                AppTheme.primaryGreen,
                width: isSmall ? constraints.maxWidth : (constraints.maxWidth - 24) / 3,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return FadeInSlide(
      duration: const Duration(milliseconds: 1000),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> items) {
    return FadeInSlide(
      duration: const Duration(milliseconds: 1100),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(children: items),
      ),
    );
  }

  Widget _buildPremiumItem(
    String title,
    IconData icon,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF334155),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context, AppLocalizations l10n) {
    return FadeInSlide(
      duration: const Duration(milliseconds: 1200),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
                SizedBox(width: 10),
                Text(
                  'منطقة الخطر',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showDeleteDialog(context, l10n),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                foregroundColor: Colors.redAccent,
                elevation: 0,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'حذف الحساب نهائياً',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l10n.signOut, style: const TextStyle(color: Colors.white)),
        content: Text(
          l10n.signOutConfirm,
          style: const TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      // 1. Invalidate providers FIRST while the widget is still definitely active
      ref.invalidate(profileProvider);
      ref.invalidate(currentProjectProvider);
      ref.invalidate(tasksProvider);
      ref.invalidate(meetingsProvider);
      ref.invalidate(invoicesProvider);

      // 2. Perform async logout
      await NotificationService.logout();
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (e) {
        // Ignore network errors
      }
      
      // 3. Navigate away
      if (context.mounted) context.go('/login');
    }
  }

  void _showDeleteDialog(BuildContext context, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          l10n.deleteAccount,
          style: const TextStyle(color: Colors.redAccent),
        ),
        content: Text(
          l10n.deleteAccountConfirm,
          style: const TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      try {
        await Supabase.instance.client.rpc('delete_self');
        await Supabase.instance.client.auth.signOut();
        if (context.mounted) context.go('/login');
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
