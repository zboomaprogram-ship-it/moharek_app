import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/l10n/app_localizations.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/features/dashboard/presentation/widgets/health_score_gauge.dart';
import 'package:moharek_app/features/dashboard/presentation/widgets/whats_new_banner.dart';
import 'package:moharek_app/features/dashboard/presentation/widgets/milestones_feed.dart';
import 'package:moharek_app/shared/widgets/milestone_overlay.dart';
import 'package:moharek_app/shared/widgets/skeleton_loader.dart';
import 'package:moharek_app/shared/services/haptic_service.dart';
import 'package:moharek_app/shared/models/milestone.dart';
import 'package:moharek_app/features/dashboard/presentation/widgets/nps_survey_bottom_sheet.dart';
import 'package:moharek_app/features/dashboard/presentation/widgets/growth_update_player.dart';
import 'package:moharek_app/features/dashboard/presentation/widgets/engine_progress_card.dart';
import 'package:moharek_app/shared/widgets/fade_in_slide.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:moharek_app/core/utils/arabic_formatter.dart';
import 'package:moharek_app/core/config/app_config.dart';
import 'package:moharek_app/features/rabhan/widgets/ecom_kpi_section.dart';
import 'package:moharek_app/features/rabhan/widgets/sales_trend_chart.dart';
import 'package:moharek_app/features/rabhan/widgets/journey_mini_progress.dart';
import 'package:moharek_app/features/admin/presentation/widgets/manage_client/brief_tab.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _hasUpdatedLastSeen = false;
  bool _hasShownCelebration = false;

  void _updateLastSeen() {
    if (_hasUpdatedLastSeen) return;
    _hasUpdatedLastSeen = true;
    try {
      Supabase.instance.client.rpc('update_last_seen').ignore();
      _checkNpsSurvey();
    } catch (_) {}
  }

  Future<void> _checkNpsSurvey() async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      final isDue = await client.rpc(
        'is_nps_due',
        params: {'p_client_id': userId},
      );

      if (isDue == true && mounted) {
        // Find project id
        final project = ref.read(currentProjectProvider).value;
        if (project == null) return;

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => NPSSurveyBottomSheet(
            onSubmit: (score, comment) async {
              await client.from('satisfaction_surveys').insert({
                'project_id': project.id,
                'client_id': userId,
                'score': score,
                'comment': comment,
              });
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.thankYouFeedback,
                    ),
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                );
              }
            },
          ),
        );
      }
    } catch (e) {
      debugPrint('Error checking NPS: $e');
    }
  }

  Future<void> _markMilestonesSeen(List<Milestone> milestones) async {
    if (milestones.isEmpty) return;
    try {
      final ids = milestones.map((m) => m.id).toList();
      await Supabase.instance.client.rpc(
        'mark_milestones_as_seen',
        params: {'p_milestone_ids': ids},
      );
    } catch (e) {
      debugPrint('Error marking milestones seen: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final projectAsync = ref.watch(currentProjectProvider);
    final tasksAsync = ref.watch(tasksProvider);
    final approvalsAsync = ref.watch(approvalsProvider);
    final activityAsync = ref.watch(clientActivityFeedProvider);
    final contractsAsync = ref.watch(contractsProvider);
    final resultsAsync = ref.watch(resultsProvider);
    final journeyAsync = ref.watch(journeyStagesProvider);
    final milestonesAsync = ref.watch(milestonesProvider);
    final engineProgressAsync = ref.watch(engineProgressListProvider);
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final Map<String, double> engineProgressMap = {};
    if (engineProgressAsync.hasValue) {
      for (var ep in engineProgressAsync.value!) {
        engineProgressMap[ep.engine] = ep.progressPercent / 100.0;
      }
    }

    return Stack(
      children: [
        Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              color: AppTheme.primaryGreen,
              onRefresh: () async {
                HapticService.light();
                try {
                  ref.invalidate(profileProvider);
                  ref.invalidate(currentProjectProvider);
                  ref.invalidate(tasksProvider);
                  ref.invalidate(approvalsProvider);
                  ref.invalidate(clientActivityFeedProvider);
                  ref.invalidate(contractsProvider);
                  ref.invalidate(resultsProvider);
                  ref.invalidate(milestonesProvider);
                  ref.invalidate(engineProgressListProvider);

                  await ref.read(profileProvider.future);
                  await ref.read(currentProjectProvider.future);
                } catch (e) {
                  debugPrint('Refresh Error: $e');
                }
              },
              child: profileAsync.when(
                loading: () => const DashboardSkeleton(),
                error: (err, stack) => Center(
                  child: Text(
                    l10n.errorOccurred(err.toString()),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                data: (profile) {
                  final displayName =
                      (profile?.fullName != null &&
                          profile!.fullName.isNotEmpty)
                      ? profile.fullName
                      : (profile?.email ?? l10n.unknownUser);

                  final String? displaySubtitle =
                      profile?.clientGoal ??
                      projectAsync.value?.projectGoal ??
                      (profile?.role == 'admin'
                          ? (l10n.localeName == 'ar'
                                ? 'مدير النظام'
                                : 'Administrator')
                          : (profile?.role == 'account_manager'
                                ? (l10n.localeName == 'ar'
                                      ? 'مدير حسابات'
                                      : 'Account Manager')
                                : null));
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
                        child: FadeInSlide(
                          delay: const Duration(milliseconds: 100),
                          child: _buildHeader(
                            displayName,
                            displaySubtitle,
                            l10n,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                        // Brief completion reminder card
                        if (projectAsync.hasValue &&
                            projectAsync.value != null) ...[
                          (() {
                            final project = projectAsync.value!;
                            final userRole = profileAsync.valueOrNull?.role;
                            final isClient = userRole == 'client' || userRole == null;
                            final filled = _countFilledBriefFields(
                              project.clientBrief,
                            );
                            const total = 21;
                            if (filled < total) {
                              return FadeInSlide(
                                delay: const Duration(milliseconds: 150),
                                child: _buildBriefReminder(
                                  context,
                                  filled,
                                  total,
                                  l10n,
                                  isAr,
                                  isClient,
                                  project.id,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          })(),
                        ],

                        // WhatsNew & Contract alerts — not relevant for Rabhan e-commerce clients
                        if (AppConfig.flavorName != 'rabhan') ...[
                          if (profile?.lastSeenAt != null)
                            FadeInSlide(
                              delay: const Duration(milliseconds: 200),
                              child: WhatsNewBanner(
                                updates: _calculateWhatsNew(
                                  profile!.lastSeenAt!,
                                  activityAsync.asData?.value ?? [],
                                  isAr,
                                ),
                              ),
                            ),

                          // Pending contract alert
                          if (contractsAsync.hasValue) ...[
                            if (contractsAsync.value!
                                .where((c) => c.status == 'pending')
                                .isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: FadeInSlide(
                                  delay: const Duration(milliseconds: 250),
                                  child: _buildContractAlert(context, l10n),
                                ),
                              ),
                          ],
                        ],

                        // Approvals Alert
                        if (approvalsAsync.hasValue) ...[
                          if (approvalsAsync.value!
                              .where((a) => a.status == 'pending')
                              .isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: FadeInSlide(
                                delay: const Duration(milliseconds: 300),
                                child: _buildApprovalsAlert(
                                  context,
                                  approvalsAsync.value!
                                      .where((a) => a.status == 'pending')
                                      .length,
                                  l10n,
                                ),
                              ),
                            ),
                        ],

                        // Ecom KPI Section for Rabhan
                        if (AppConfig.flavorName == 'rabhan' &&
                            projectAsync.valueOrNull != null) ...[
                          FadeInSlide(
                            delay: const Duration(milliseconds: 325),
                            child: EcomKpiSection(
                              projectId: projectAsync.valueOrNull!.id,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeInSlide(
                            delay: const Duration(milliseconds: 328),
                            child: SalesTrendChart(
                              projectId: projectAsync.valueOrNull!.id,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeInSlide(
                            delay: const Duration(milliseconds: 330),
                            child: Card(
                              margin: EdgeInsets.zero,
                              color: AppTheme.cardColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: Colors.white10),
                              ),
                              child: InkWell(
                                onTap: () {
                                  context.push('/dashboard/analytics');
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryGreen
                                              .withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.analytics_outlined,
                                          color: AppTheme.primaryGreen,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              isAr
                                                  ? 'تقارير الأداء والتحليلات'
                                                  : 'Performance Reports & Analytics',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              isAr
                                                  ? 'تفقد مبيعات المتجر، أداء الحملات الإعلانية ومؤشرات النمو.'
                                                  : 'Check store sales, campaign performance, and growth metrics.',
                                              style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right,
                                        color: Colors.white54,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeInSlide(
                            delay: const Duration(milliseconds: 332),
                            child: JourneyMiniProgress(
                              projectId: projectAsync.valueOrNull!.id,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        projectAsync.when(
                          data: (project) {
                            _updateLastSeen(); // Update after data loads
                            final isDesktop =
                                MediaQuery.of(context).size.width >= 1000;
                            return Column(
                              children: [
                                if (project?.voiceUpdateUrl != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 24),
                                    child: FadeInSlide(
                                      delay: const Duration(milliseconds: 350),
                                      child: GrowthUpdatePlayer(
                                        url: project!.voiceUpdateUrl!,
                                        date:
                                            project.voiceUpdateAt ??
                                            project.createdAt,
                                      ),
                                    ),
                                  ),
                                // GrowthCard & HealthScoreGauge — not for Rabhan (uses EcomKpiSection instead)
                                if (AppConfig.flavorName != 'rabhan') ...[
                                  if (isDesktop)
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: FadeInSlide(
                                            delay: const Duration(
                                              milliseconds: 400,
                                            ),
                                            child: _buildGrowthCard(
                                              context,
                                              _translateStage(
                                                project?.currentStage ??
                                                    'Audit',
                                                l10n,
                                              ),
                                              journeyAsync,
                                              l10n,
                                              isAr,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 24),
                                        Expanded(
                                          flex: 1,
                                          child: FadeInSlide(
                                            delay: const Duration(
                                              milliseconds: 450,
                                            ),
                                            child: HealthScoreGauge(
                                              score: _calculateHealthScore(
                                                journeyAsync,
                                                tasksAsync.asData?.value ?? [],
                                                approvalsAsync.asData?.value ??
                                                    [],
                                                engineProgressMap,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  else ...[
                                    FadeInSlide(
                                      delay: const Duration(milliseconds: 400),
                                      child: _buildGrowthCard(
                                        context,
                                        _translateStage(
                                          project?.currentStage ?? 'Audit',
                                          l10n,
                                        ),
                                        journeyAsync,
                                        l10n,
                                        isAr,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    FadeInSlide(
                                      delay: const Duration(milliseconds: 450),
                                      child: HealthScoreGauge(
                                        score: _calculateHealthScore(
                                          journeyAsync,
                                          tasksAsync.asData?.value ?? [],
                                          approvalsAsync.asData?.value ?? [],
                                          engineProgressMap,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 24),
                                ],
                              ],
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),

                        // Journey Stages — inline on home (disabled for Rabhan since it has a dedicated mini progress tracker)
                        if (AppConfig.flavorName != 'rabhan') ...[
                          journeyAsync.when(
                            data: (stages) {
                              if (stages.isEmpty) {
                                return FadeInSlide(
                                  delay: const Duration(milliseconds: 525),
                                  child: _buildEmptyJourneyPlaceholder(
                                    l10n,
                                    isAr,
                                  ),
                                );
                              }
                              return FadeInSlide(
                                delay: const Duration(milliseconds: 525),
                                child: _buildJourneySection(stages, l10n, isAr),
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Milestones Feed — not relevant for Rabhan e-commerce clients
                        if (AppConfig.flavorName != 'rabhan')
                          milestonesAsync.when(
                            data: (milestones) => Column(
                              children: [
                                FadeInSlide(
                                  delay: const Duration(milliseconds: 500),
                                  child: MilestonesFeed(milestones: milestones),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),

                        if (AppConfig.flavorName != 'rabhan') ...[
                          FadeInSlide(
                            delay: const Duration(milliseconds: 550),
                            child: _buildStatsRow(
                              tasks: tasksAsync.asData?.value ?? [],
                              results: resultsAsync.asData?.value ?? [],
                              l10n: l10n,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        FadeInSlide(
                          delay: const Duration(milliseconds: 600),
                          child: AppConfig.flavorName == 'rabhan'
                              ? _buildRabhanQuickActions(context, isAr)
                              : _buildQuickActions(context, l10n),
                        ),
                        const SizedBox(height: 24),
                        if (AppConfig.flavorName != 'rabhan') ...[
                          FadeInSlide(
                            delay: const Duration(milliseconds: 650),
                            child: _buildPerformanceSection(
                              resultsAsync.asData?.value ?? [],
                              l10n,
                              profileAsync.valueOrNull?.role == 'admin' ||
                                  profileAsync.valueOrNull?.role ==
                                      'account_manager',
                            ),
                          ),
                          const SizedBox(height: 24),
                          FadeInSlide(
                            delay: const Duration(milliseconds: 675),
                            child: engineProgressAsync.when(
                              data: (progress) => EngineProgressCard(
                                engineProgressList: progress,
                                isAr: isAr,
                                userRole:
                                    profileAsync.valueOrNull?.role ?? 'client',
                                projectId: projectAsync.valueOrNull?.id ?? '',
                              ),
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            );
                },
              ),
            ),
          ),
        ),

        // Celebration Overlay
        if (!_hasShownCelebration)
          milestonesAsync.when(
            data: (milestones) {
              final unread = milestones.where((m) => !m.seenByClient).toList();
              if (unread.isEmpty) return const SizedBox.shrink();

              return MilestoneOverlay(
                milestones: unread,
                onDismiss: () {
                  setState(() => _hasShownCelebration = true);
                  _markMilestonesSeen(unread);
                },
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
      ],
    );
  }

  int _countFilledBriefFields(Map<String, dynamic>? brief) {
    if (brief == null) return 0;
    final coreFields = [
      'platform_mail',
      'platform_password',
      'best_contact_time',
      'employment_type',
      'business_structure',
      'investment_timeline',
      'store_age',
      'has_offline_store',
      'store_market_stage',
      'current_future_goals',
      'target_age_group',
      'best_selling_products',
      'competitors',
      'competitive_advantage',
      'past_campaigns_details',
      'past_marketing_agency',
      'past_seo',
      'ad_budget',
      'shipping_service_details',
      'pricing_vs_competitors',
      'profit_margin_range',
    ];
    int filled = 0;
    for (final field in coreFields) {
      final val = brief[field];
      if (val != null) {
        if (val is String && val.trim().isNotEmpty) {
          filled++;
        } else if (val is bool) {
          filled++;
        } else if (val is List && val.isNotEmpty) {
          filled++;
        } else if (val is Map && val.isNotEmpty) {
          filled++;
        }
      }
    }
    return filled;
  }

  Widget _buildBriefReminder(
    BuildContext context,
    int filledCount,
    int totalCount,
    AppLocalizations l10n,
    bool isAr,
    bool isClient,
    String projectId,
  ) {
    final double percentage = (filledCount / totalCount).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGreen.withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticService.light();
            if (isClient) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    backgroundColor: AppTheme.background,
                    appBar: AppBar(
                      title: const Text('عرض بريف المشروع'),
                      backgroundColor: AppTheme.cardColor,
                    ),
                    body: BriefTab(pid: projectId),
                  ),
                ),
              );
            } else {
              context.push('/onboarding?edit=true');
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    color: AppTheme.primaryGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isClient
                            ? (isAr ? 'بريف المشروع' : 'Project Brief')
                            : (isAr ? 'أكمل معلومات مشروعك' : 'Complete Your Project Brief'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isClient
                            ? (isAr ? 'تصفح معلومات وتفاصيل مشروعك الحالية.' : 'Review your project details and information.')
                            : (isAr ? 'يرجى إكمال الحقول المتبقية لتحسين أداء متجرك.' : 'Please fill the remaining fields to optimize your store.'),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percentage,
                                minHeight: 6,
                                backgroundColor: Colors.white10,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryGreen,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            isAr
                                ? 'تم إكمال $filledCount/$totalCount'
                                : '$filledCount/$totalCount filled',
                            style: const TextStyle(
                              color: AppTheme.primaryGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isAr ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
                  color: Colors.white60,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String name, String? goal, AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    String greeting = l10n.goodEvening;
    if (hour < 12) {
      greeting = l10n.goodMorning;
    } else if (hour < 17) {
      greeting = l10n.goodAfternoon;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            HapticService.light();
            Scaffold.of(context).openDrawer();
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.menu, color: Colors.white),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (goal != null && goal.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    l10n.focusedOn(goal),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _buildNotificationButton(context, ref),
        const SizedBox(width: 12),
        _buildAIButton(context),
        const SizedBox(width: 12),
        InkWell(
          onTap: () {
            HapticService.light();
            context.push('/profile');
          },
          borderRadius: BorderRadius.circular(24),
          child: const CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.cardColor,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationButton(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        HapticService.light();
        context.push('/dashboard/notifications');
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.notifications_outlined, color: Colors.white),
      ),
    );
  }

  Widget _buildAIButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticService.medium();
        context.push('/dashboard/ai-assistant');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome,
              color: AppTheme.primaryGreen,
              size: 16,
            ),
            const SizedBox(width: 6),
            const Text(
              'مساعد النمو',
              style: TextStyle(
                color: AppTheme.primaryGreen,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalsAlert(
    BuildContext context,
    int count,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withValues(alpha: 0.2),
            AppTheme.primaryBlue.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.pending_actions, color: AppTheme.primaryBlue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.itemNeedsApproval(count),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  l10n.pendingApprovals,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              HapticService.light();
              context.push('/dashboard/approvals');
            },
            child: Text(
              l10n.approve,
              style: const TextStyle(color: AppTheme.primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthCard(
    BuildContext context,
    String stage,
    AsyncValue journeyAsync,
    AppLocalizations l10n,
    bool isAr,
  ) {
    // Calculate progress from journey stages
    double progress = 0.0;
    if (journeyAsync.hasValue) {
      final stages = journeyAsync.value as List;
      if (stages.isNotEmpty) {
        final completed = stages.where((s) => s.status == 'completed').length;
        final inProgress = stages
            .where((s) => s.status == 'in_progress')
            .length;
        progress = (completed + inProgress * 0.5) / stages.length;
      }
    }
    final progressPercent = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.projectGrowth,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.currentStage(stage.toUpperCase()),
                  style: const TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        HapticService.light();
                        context.push('/journey');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen.withValues(
                          alpha: 0.1,
                        ),
                        foregroundColor: AppTheme.primaryGreen,
                        elevation: 0,
                      ),
                      child: Text(l10n.viewJourney),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        HapticService.light();
                        context.push('/dashboard/growth-story');
                      },
                      child: Text(
                        isAr ? 'قصة النمو' : 'Growth Story',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 80,
            width: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryGreen,
                  ),
                ),
                Text(
                  '${ArabicFormatter.number(progressPercent, isAr: isAr)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow({
    required List tasks,
    required List results,
    required AppLocalizations l10n,
  }) {
    final completedTasks = tasks.where((t) => t.status == 'completed').length;
    final inProgressTasks = tasks
        .where((t) => t.status == 'in_progress')
        .length;
    final keywordMetric = results
        .where(
          (r) =>
              r.resultType == 'seo' &&
              (r.metricName.toLowerCase().contains('keyword') ||
                  (r.metricLabel ?? '').toLowerCase().contains('keyword') ||
                  (r.metricLabel ?? '').contains('الكلمات') ||
                  (r.metricLabel ?? '').contains('الكلمة')),
        )
        .toList();
    final keywordsValue = keywordMetric.isNotEmpty
        ? keywordMetric.first.metricValue
        : 0.0;

    return Row(
      children: [
        _buildStatItem(
          l10n.completed,
          completedTasks.toDouble(),
          Icons.check_circle_outline,
          false,
        ),
        const SizedBox(width: 12),
        _buildStatItem(
          l10n.inProgress,
          inProgressTasks.toDouble(),
          Icons.pending_outlined,
          false,
        ),
        const SizedBox(width: 12),
        _buildStatItem(
          l10n.keywords,
          keywordsValue,
          Icons.trending_up,
          keywordMetric.isEmpty,
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    double value,
    IconData icon,
    bool isPlaceholder,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryBlue, size: 20),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: isPlaceholder
                  ? const Text(
                      '—',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : Text(
                      ArabicFormatter.number(
                        value.toInt(),
                        isAr:
                            Localizations.localeOf(context).languageCode ==
                            'ar',
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateHealthScore(
    AsyncValue journeyAsync,
    List tasks,
    List approvals,
    Map<String, double> engineProgress,
  ) {
    double score = 40.0; // Base score

    if (journeyAsync.hasValue) {
      final stages = journeyAsync.value as List;
      if (stages.isNotEmpty) {
        final completed = stages.where((s) => s.status == 'completed').length;
        score += (completed / stages.length) * 15; // Up to 15 points
      }
    }

    if (tasks.isNotEmpty) {
      final completed = tasks.where((t) => t.status == 'completed').length;
      score += (completed / tasks.length) * 15; // Up to 15 points
    }

    if (approvals.isNotEmpty) {
      final approved = approvals.where((a) => a.status == 'approved').length;
      score += (approved / approvals.length) * 10; // Up to 10 points
    }

    // Add Engine progress (up to 20 points)
    if (engineProgress.isNotEmpty) {
      double totalEngineProgress = 0;
      engineProgress.forEach((_, val) => totalEngineProgress += val);
      score += (totalEngineProgress / 5) * 20;
    }

    return score.clamp(0.0, 100.0).toInt();
  }

  List<String> _calculateWhatsNew(
    DateTime lastSeen,
    List<Map<String, dynamic>> activities,
    bool isAr,
  ) {
    return activities
        .where((a) => DateTime.parse(a['created_at']).isAfter(lastSeen))
        .map((a) => (isAr ? a['action_ar'] : a['action_en']) as String)
        .toList();
  }

  Widget _buildPerformanceSection(
    List results,
    AppLocalizations l10n,
    bool isEditable,
  ) {
    // Find the latest value for each metric type from the results
    String _getMetricValue(String type, String name) {
      final matches = results.where((r) {
        final isTypeMatch = r.resultType.toLowerCase() == type.toLowerCase();
        if (!isTypeMatch) return false;

        final metricNameLower = r.metricName.toLowerCase();
        final metricLabelLower = (r.metricLabel ?? '').toLowerCase();

        if (name == 'traffic') {
          return metricNameLower.contains('traffic') ||
              metricNameLower.contains('organic') ||
              metricLabelLower.contains('traffic') ||
              metricLabelLower.contains('الزيارات') ||
              metricLabelLower.contains('الزيارة') ||
              metricLabelLower.contains('زيارة') ||
              metricLabelLower.contains('زوار');
        }
        if (name == 'spend') {
          return metricNameLower.contains('spend') ||
              metricNameLower.contains('cost') ||
              metricLabelLower.contains('spend') ||
              metricLabelLower.contains('الإنفاق') ||
              metricLabelLower.contains('الانفاق') ||
              metricLabelLower.contains('صرف') ||
              metricLabelLower.contains('ميزانية') ||
              metricLabelLower.contains('ميزانيه');
        }
        if (name == 'keyword') {
          return metricNameLower.contains('keyword') ||
              metricLabelLower.contains('keyword') ||
              metricLabelLower.contains('الكلمات') ||
              metricLabelLower.contains('الكلمة') ||
              metricLabelLower.contains('كلمات') ||
              metricLabelLower.contains('كلمة');
        }
        return metricNameLower.contains(name.toLowerCase());
      });
      if (matches.isEmpty) return '—';
      return matches.first.metricValue.toStringAsFixed(0);
    }

    final traffic = _getMetricValue('seo', 'traffic');
    final spend = _getMetricValue('ads', 'spend');
    final keywords = _getMetricValue('seo', 'keyword');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.performanceSnapshots,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildPerformanceCard(
                title: l10n.organicTraffic,
                trend: traffic,
                icon: Icons.show_chart,
                onEdit: isEditable
                    ? () => _showEditMetricDialog(
                        context,
                        'seo',
                        'traffic',
                        l10n.organicTraffic,
                        traffic,
                      )
                    : null,
              ),
              _buildPerformanceCard(
                title: l10n.adSpend,
                trend: spend.isNotEmpty && spend != '—' ? 'SAR $spend' : '—',
                icon: Icons.monetization_on_outlined,
                onEdit: isEditable
                    ? () => _showEditMetricDialog(
                        context,
                        'ads',
                        'spend',
                        l10n.adSpend,
                        spend,
                      )
                    : null,
              ),
              _buildPerformanceCard(
                title: l10n.keywords,
                trend: keywords,
                icon: Icons.bar_chart,
                onEdit: isEditable
                    ? () => _showEditMetricDialog(
                        context,
                        'seo',
                        'keyword',
                        l10n.keywords,
                        keywords,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditMetricDialog(
    BuildContext context,
    String type,
    String name,
    String title,
    String currentValue,
  ) {
    final controller = TextEditingController(
      text: currentValue == '—' ? '' : currentValue,
    );
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            Localizations.localeOf(context).languageCode == 'ar'
                ? 'تعديل $title'
                : 'Edit $title',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Localizations.localeOf(context).languageCode == 'ar'
                    ? 'أدخل القيمة الجديدة لـ $title:'
                    : 'Enter new value for $title:',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Color(0xFF0F172A),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                Localizations.localeOf(context).languageCode == 'ar'
                    ? 'إلغاء'
                    : 'Cancel',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.black,
              ),
              onPressed: saving
                  ? null
                  : () async {
                      final val = double.tryParse(controller.text);
                      if (val == null) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text(
                              Localizations.localeOf(context).languageCode ==
                                      'ar'
                                  ? 'الرجاء إدخال رقم صحيح'
                                  : 'Please enter a valid number',
                            ),
                          ),
                        );
                        return;
                      }

                      setState(() => saving = true);

                      try {
                        final project = ref.read(currentProjectProvider).value;
                        if (project != null) {
                          await Supabase.instance.client
                              .from('results')
                              .insert({
                                'project_id': project.id,
                                'result_type': type,
                                'metric_name': name,
                                'metric_value': val,
                                'recorded_at': DateTime.now().toIso8601String(),
                              });
                          ref.invalidate(resultsProvider);
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('Error saving: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        if (ctx.mounted) setState(() => saving = false);
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : Text(
                      Localizations.localeOf(context).languageCode == 'ar'
                          ? 'حفظ'
                          : 'Save',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCard({
    required String title,
    required String trend,
    required IconData icon,
    VoidCallback? onEdit,
  }) {
    return Container(
      width: 140,
      margin: const EdgeInsetsDirectional.only(end: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(icon, color: AppTheme.primaryGreen, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                GestureDetector(
                  onTap: onEdit,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.0),
                    child: Icon(
                      Icons.edit,
                      color: AppTheme.primaryGreen,
                      size: 14,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            trend,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractAlert(BuildContext context, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () => context.push('/dashboard/contracts'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.withValues(alpha: 0.2),
              Colors.orange.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.description_outlined, color: Colors.orange),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.contractAwaitingSignature,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    l10n.tapToReview,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildRabhanQuickActions(BuildContext context, bool isAr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAr ? 'الوصول السريع' : 'Quick Access',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildQuickAction(
              context,
              Icons.chat_bubble_outline,
              isAr ? 'المحادثة' : 'Chat',
              '/chat',
            ),
            _buildQuickAction(
              context,
              Icons.analytics_outlined,
              isAr ? 'الأداء' : 'Analytics',
              '/dashboard/analytics',
            ),
            _buildQuickAction(
              context,
              Icons.rocket_launch_outlined,
              isAr ? 'الاستراتيجية' : 'Strategy',
              '/strategy',
            ),
            _buildQuickAction(
              context,
              Icons.task_outlined,
              isAr ? 'المهام' : 'Tasks',
              '/tasks',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.quickActions,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildQuickAction(
              context,
              Icons.task_outlined,
              l10n.tasksTab,
              '/tasks',
            ),
            _buildQuickAction(
              context,
              Icons.chat_bubble_outline,
              l10n.chatTab,
              '/chat',
            ),
            _buildQuickAction(
              context,
              Icons.analytics_outlined,
              l10n.resultsTab,
              '/results',
            ),
            _buildQuickAction(
              context,
              Icons.description_outlined,
              l10n.contracts,
              '/dashboard/contracts',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    IconData icon,
    String label,
    String route,
  ) {
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticService.light();
          context.push(route);
        },
        child: Container(
          margin: const EdgeInsetsDirectional.only(end: 8),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.primaryBlue, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyJourneyPlaceholder(AppLocalizations l10n, bool isAr) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.map_outlined,
            color: Colors.white.withValues(alpha: 0.2),
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            isAr
                ? 'خارطة التطوير قيد التجهيز'
                : 'Growth Roadmap is being prepared',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isAr
                ? 'يقوم فريقنا حالياً بوضع خطة النمو الخاصة بمشروعك'
                : 'Our team is currently defining the growth stages for your project',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneySection(List stages, AppLocalizations l10n, bool isAr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isAr ? 'خارطة التطوير' : 'Growth Roadmap',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/journey'),
              child: Text(
                isAr ? 'عرض الكل' : 'View all',
                style: const TextStyle(
                  color: AppTheme.primaryGreen,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: stages.length,
            itemBuilder: (context, index) {
              final stage = stages[index];
              final name = (stage.stageName ?? '').toString().replaceAll(
                '_',
                ' ',
              );
              final status = (stage.status ?? 'not_started').toString();
              final isCompleted = status == 'completed';
              final isInProgress = status == 'in_progress';
              Color stageColor = Colors.grey;
              if (isCompleted) stageColor = AppTheme.primaryGreen;
              if (isInProgress) stageColor = AppTheme.primaryBlue;

              return Container(
                width: 110,
                margin: const EdgeInsetsDirectional.only(end: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isInProgress
                        ? AppTheme.primaryBlue.withValues(alpha: 0.5)
                        : Colors.white10,
                    width: isInProgress ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      isCompleted
                          ? Icons.check_circle
                          : isInProgress
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: stageColor,
                      size: 18,
                    ),
                    Text(
                      name,
                      style: TextStyle(
                        color: isInProgress ? Colors.white : Colors.grey,
                        fontSize: 11,
                        fontWeight: isInProgress
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: stageColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isCompleted
                            ? (isAr ? 'مكتمل' : 'Done')
                            : isInProgress
                            ? (isAr ? 'جارٍ' : 'Active')
                            : (isAr ? 'مجدول' : 'Planned'),
                        style: TextStyle(
                          color: stageColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _translateStage(String stage, AppLocalizations l10n) {
    switch (stage.toLowerCase()) {
      case 'audit':
        return l10n.audit;
      case 'strategy':
        return l10n.strategy;
      case 'setup':
        return l10n.setup;
      case 'execution':
        return l10n.execution;
      case 'optimization':
        return l10n.optimization;
      case 'results':
        return l10n.results;
      default:
        return stage;
    }
  }
}
