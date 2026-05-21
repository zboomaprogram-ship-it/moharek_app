import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/shared/models/journey_stage.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/shared/models/engine_progress.dart';
import 'package:moharek_app/shared/models/project.dart';
import 'package:moharek_app/l10n/app_localizations.dart';
import 'package:moharek_app/core/config/app_config.dart';
import 'package:moharek_app/features/rabhan/screens/rabhan_strategy_screen.dart';

class StrategyScreen extends ConsumerWidget {
  const StrategyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Rabhan flavor has its own dedicated e-commerce strategy screen
    if (AppConfig.flavorName == 'rabhan') {
      return const RabhanStrategyScreen();
    }

    final projectAsync = ref.watch(currentProjectProvider);
    final enginesAsync = ref.watch(engineProgressListProvider);
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'الاستراتيجية' : 'Strategy'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: projectAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (project) {
          if (project == null)
            return const Center(child: Text('No project found'));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGoalCard(project, isAr),
                const SizedBox(height: 24),
                _buildInfoGrid(project, isAr),
                const SizedBox(height: 32),
                Text(
                  isAr ? 'خارطة الطريق (90 يوماً)' : '90-Day Roadmap',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ref
                    .watch(journeyStagesProvider)
                    .when(
                      loading: () => const LinearProgressIndicator(
                        color: AppTheme.primaryGreen,
                      ),
                      error: (err, _) => Text('Error: $err'),
                      data: (stages) {
                        if (stages.isEmpty)
                          return Text(
                            isAr
                                ? 'لم يتم تحديد مراحل بعد'
                                : 'No stages defined yet',
                            style: const TextStyle(color: Colors.white38),
                          );
                        return Column(
                          children: stages
                              .map((s) => _buildJourneyItem(s, isAr))
                              .toList(),
                        );
                      },
                    ),
                const SizedBox(height: 32),
                Text(
                  isAr ? 'محركات النمو الخمسة' : '5 Growth Engines',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                enginesAsync.when(
                  loading: () => const LinearProgressIndicator(
                    color: AppTheme.primaryGreen,
                  ),
                  error: (err, _) => Text('Error: $err'),
                  data: (engines) {
                    return Column(
                      children: [
                        _buildEngineCard('content', isAr ? 'محرك المحتوى' : 'Content Engine', engines, Icons.edit_note, Colors.orange),
                        _buildEngineCard('seo', isAr ? 'محرك SEO' : 'SEO Engine', engines, Icons.search, Colors.blue),
                        _buildEngineCard('ai_visibility', isAr ? 'محرك الظهور في AI' : 'AI Visibility Engine', engines, Icons.smart_toy, Colors.purple),
                        _buildEngineCard('trust', isAr ? 'محرك الثقة' : 'Trust Engine', engines, Icons.star_outline, Colors.amber),
                        _buildEngineCard('conversion', isAr ? 'محرك التحويل' : 'Conversion Engine', engines, Icons.shopping_cart_outlined, Colors.green),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildJourneyItem(JourneyStage stage, bool isAr) {
    final bool isCompleted = stage.status == 'completed';
    final bool isInProgress = stage.status == 'in_progress';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppTheme.primaryGreen
                    : (isInProgress ? AppTheme.primaryBlue : Colors.white10),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white10),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 10, color: Colors.black)
                  : null,
            ),
            Container(width: 2, height: 40, color: Colors.white10),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getStageLabel(stage.stageName, isAr),
                style: TextStyle(
                  color: isCompleted
                      ? Colors.white
                      : (isInProgress ? AppTheme.primaryBlue : Colors.white38),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (stage.stageDescription != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    stage.stageDescription!,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _getStageLabel(String name, bool isAr) {
    switch (name) {
      case 'audit':
        return isAr ? 'التدقيق والتحليل' : 'Audit & Analysis';
      case 'strategy':
        return isAr ? 'بناء الاستراتيجية' : 'Strategy Building';
      case 'setup':
        return isAr ? 'التجهيز والربط' : 'Technical Setup';
      case 'execution':
        return isAr ? 'التنفيذ والتشغيل' : 'Execution';
      case 'optimization':
        return isAr ? 'التحسين المستمر' : 'Optimization';
      case 'results':
        return isAr ? 'النتائج والنمو' : 'Results & Growth';
      default:
        return name;
    }
  }

  Widget _buildGoalCard(Project project, bool isAr) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryBlue, Color(0xFF1A237E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rocket_launch, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text(
                isAr ? 'هدف المشروع' : 'Project Goal',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            project.projectGoal ??
                (isAr ? 'لم يتم تحديد هدف بعد' : 'No goal defined yet'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(Project project, bool isAr) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSmallInfoCard(
                isAr ? 'السوق المستهدف' : 'Target Market',
                project.targetMarket ?? '-',
                Icons.public,
                Colors.teal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSmallInfoCard(
                isAr ? 'الجمهور المستهدف' : 'Target Audience',
                project.targetAudience ?? '-',
                Icons.groups,
                Colors.indigo,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildCompetitorsCard(
          isAr ? 'المنافسون' : 'Competitors',
          project.competitors ?? [],
          Icons.compare_arrows,
          Colors.redAccent,
          isAr,
        ),
      ],
    );
  }

  Widget _buildSmallInfoCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCompetitorsCard(
    String label,
    List<String> competitors,
    IconData icon,
    Color color,
    bool isAr,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (competitors.isEmpty)
            Text(
              isAr ? 'لم يتم تحديد منافسين' : 'No competitors listed',
              style: const TextStyle(color: Colors.white38, fontSize: 14),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: competitors
                  .map(
                    (c) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        c,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEngineCard(
    String type,
    String label,
    List<EngineProgress> engines,
    IconData icon,
    Color color,
  ) {
    final engine = engines.firstWhere(
      (e) => e.engine == type,
      orElse: () => EngineProgress(
        id: '',
        projectId: '',
        engine: type,
        progressPercent: 0,
        updatedAt: DateTime.now(),
      ),
    );
    final progress = engine.progressPercent / 100.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
