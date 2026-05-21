import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/core/config/app_config.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:particles_flutter/particles_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:moharek_app/l10n/app_localizations.dart';
import 'package:moharek_app/shared/services/haptic_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String? _selectedGoal;

  Future<void> _completeOnboarding() async {
    if (_selectedGoal == null) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryGreen),
      ),
    );

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('profiles')
            .update({
              'onboarding_completed': true,
              'client_goal': _selectedGoal,
            })
            .eq('id', user.id);
      }

      if (mounted) {
        Navigator.pop(context); // close dialog
        ref.invalidate(profileProvider);
        ref.invalidate(currentProjectProvider);
        context.go(
          '/dashboard',
        ); // Go directly to dashboard instead of / (splash) to avoid another async check
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _nextPage() {
    if (_currentPage < 4) {
      HapticService.light();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Global Particles Background
          CircularParticle(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            particleColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
            numberOfParticles: 40,
            speedOfParticles: 0.5,
            maxParticleSize: 4,
            isRandomColor: false,
            randColorList: const [AppTheme.primaryGreen, AppTheme.primaryBlue],
            isRandSize: true,
            connectDots: false,
          ),

          SafeArea(
            child: PageView(
              controller: _pageController,
              physics:
                  const NeverScrollableScrollPhysics(), // user must use buttons to advance
              onPageChanged: (i) => setState(() => _currentPage = i),
              children: [
                _buildWelcomeStep(),
                _buildTeamStep(),
                _buildRoadmapStep(),
                _buildExpectationsStep(),
                _buildGoalStep(),
              ],
            ),
          ),

          // Progress Dots
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppTheme.primaryGreen
                        : Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeStep() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Image.asset(
            AppConfig.logoAsset,
            width: 120,
            errorBuilder: (c, e, s) => const Icon(
              Icons.rocket_launch,
              size: 80,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            l10n.welcomeTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.thrilledPartner,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                l10n.letsBegin,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildTeamStep() {
    final l10n = AppLocalizations.of(context)!;
    final projectAsync = ref.watch(currentProjectProvider);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Text(
            l10n.meetYourTeam,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.peopleWorkingForYou,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 16),
          ),
          const SizedBox(height: 48),

          projectAsync.when(
            data: (p) {
              final isAr = Localizations.localeOf(context).languageCode == 'ar';
              final amName = (isAr ? 'مدير النمو' : 'Growth Manager');
              final amRole = isAr ? 'مدير حسابك الشخصي' : 'Your Growth Manager';
              const String? amAvatar = null;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _teamCard(amName, amRole, Icons.person, avatarUrl: amAvatar),
                    _teamCard(
                      isAr ? 'فريق الدعم' : 'Support Team', 
                      isAr ? 'دعم فني 24/7' : '24/7 Tech Support', 
                      Icons.support_agent_outlined
                    ),
                    _teamCard(
                      isAr ? 'محرك الذكاء' : 'Moharek AI', 
                      isAr ? 'مساعدك الرقمي' : 'Digital Intelligence', 
                      Icons.auto_awesome_outlined
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
            error: (_, __) => const Text('Error loading team', style: TextStyle(color: Colors.red)),
          ),

          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: Text(
                l10n.next,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _teamCard(String name, String role, IconData icon, {String? avatarUrl}) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null ? Icon(icon, color: AppTheme.primaryGreen, size: 30) : null,
          ),
          const SizedBox(height: 20),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            role,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRoadmapStep() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            l10n.roadmapTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.structuredPlan,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 40),

          Expanded(
            child: ListView(
              children: [
                _timelineItem('Day 1', l10n.auditOnboarding, true),
                _timelineItem('Day 7', l10n.strategyDelivered, false),
                _timelineItem('Day 30', l10n.firstCampaign, false),
                _timelineItem('Day 60', l10n.optimizationReview, false),
                _timelineItem(
                  'Day 90',
                  l10n.quarterlyReport,
                  false,
                  isLast: true,
                ),
              ],
            ),
          ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                l10n.next,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _timelineItem(
    String day,
    String title,
    bool active, {
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: active
                    ? AppTheme.primaryGreen
                    : Colors.grey.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 50,
                color: active
                    ? AppTheme.primaryGreen.withValues(alpha: 0.5)
                    : Colors.white10,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day,
                  style: TextStyle(
                    color: active ? AppTheme.primaryGreen : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: active ? Colors.white : Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpectationsStep() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Text(
            l10n.whatToExpect,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),

          _expectationRow(Icons.bar_chart, l10n.trackResults),
          const SizedBox(height: 24),
          _expectationRow(Icons.check_circle_outline, l10n.approveContent),
          const SizedBox(height: 24),
          _expectationRow(Icons.chat_bubble_outline, l10n.talkGrowthManager),

          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                l10n.almostDone,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _expectationRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalStep() {
    final l10n = AppLocalizations.of(context)!;
    final goals = [
      l10n.increaseSales,
      l10n.improvePresence,
      l10n.launchProduct,
      l10n.rebrand,
    ];

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          Text(
            l10n.tellUsGoal,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.goalQuestion,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),

          ...goals.map(
            (goal) => GestureDetector(
              onTap: () {
                HapticService.light();
                setState(() => _selectedGoal = goal);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _selectedGoal == goal
                      ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                      : AppTheme.cardColor,
                  border: Border.all(
                    color: _selectedGoal == goal
                        ? AppTheme.primaryGreen
                        : Colors.white10,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: _selectedGoal == goal ? [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 0,
                    )
                  ] : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        goal,
                        style: TextStyle(
                          color: _selectedGoal == goal
                              ? AppTheme.primaryGreen
                              : Colors.white,
                          fontSize: 16,
                          fontWeight: _selectedGoal == goal ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (_selectedGoal == goal)
                      const Icon(
                        Icons.check_circle,
                        color: AppTheme.primaryGreen,
                      ),
                  ],
                ),
              ),
            ),
          ),

          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedGoal == null ? null : _completeOnboarding,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                l10n.finishEnterDashboard,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}
