import 'dart:convert';
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
import 'package:supabase_flutter/supabase_flutter.dart';

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
                    final profile = ref.watch(profileProvider).valueOrNull;
                    final userRole = profile?.role ?? 'client';
                    return Column(
                      children: [
                        GrowthEngineCard(
                          type: 'content',
                          label: isAr ? 'محرك المحتوى' : 'Content Engine',
                          engines: engines,
                          icon: Icons.edit_note,
                          color: Colors.orange,
                          project: project,
                          userRole: userRole,
                        ),
                        GrowthEngineCard(
                          type: 'seo',
                          label: isAr ? 'محرك SEO' : 'SEO Engine',
                          engines: engines,
                          icon: Icons.search,
                          color: Colors.blue,
                          project: project,
                          userRole: userRole,
                        ),
                        GrowthEngineCard(
                          type: 'ai_visibility',
                          label: isAr ? 'محرك الظهور في AI' : 'AI Visibility Engine',
                          engines: engines,
                          icon: Icons.smart_toy,
                          color: Colors.purple,
                          project: project,
                          userRole: userRole,
                        ),
                        GrowthEngineCard(
                          type: 'trust',
                          label: isAr ? 'محرك الثقة' : 'Trust Engine',
                          engines: engines,
                          icon: Icons.star_outline,
                          color: Colors.amber,
                          project: project,
                          userRole: userRole,
                        ),
                        GrowthEngineCard(
                          type: 'conversion',
                          label: isAr ? 'محرك التحويل' : 'Conversion Engine',
                          engines: engines,
                          icon: Icons.shopping_cart_outlined,
                          color: Colors.green,
                          project: project,
                          userRole: userRole,
                        ),
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

  // Growth engine steps mapped by type, containing both English and Arabic translations.
  // The English text is used as the database key to track checked items consistently.
  static const Map<String, List<Map<String, String>>> engineSteps = {
    'content': [
      {
        'en': 'Keyword Research: Target primary, secondary & LSI keywords.',
        'ar': 'البحث عن الكلمات المفتاحية: استهداف الكلمات الأساسية والثانوية وLSI.'
      },
      {
        'en': 'Optimize On-Page Elements: Title, Meta Description, H1–H6, URL.',
        'ar': 'تحسين العناصر داخل الصفحة: العناوين، الأوصاف التعريفية، وسوم H1-H6، والروابط.'
      },
      {
        'en': 'Content Quality: Original, in-depth, useful, and intent-focused content.',
        'ar': 'جودة المحتوى: محتوى أصلي، متعمق، مفيد وموجه لنية بحث المستخدم.'
      },
      {
        'en': 'Semantic SEO: Add related terms & entities (Entity SEO / Knowledge Graph).',
        'ar': 'سيو دلالي (Semantic SEO): إضافة مصطلحات وكيانات ذات صلة (Entity SEO).'
      },
      {
        'en': 'Readability: Short paragraphs, bullet points, scannable structure.',
        'ar': 'سهولة القراءة: فقرات قصيرة، نقاط تعداد، وهيكل سهل التصفح.'
      },
      {
        'en': 'Media Optimization: Compress images, use descriptive filenames & Alt Text.',
        'ar': 'تحسين الوسائط: ضغط الصور، استخدام أسماء ملفات وصفية ونصوص بديلة (Alt Text).'
      },
      {
        'en': 'Internal Linking: Link relevant pages with keyword-rich anchor text.',
        'ar': 'الربط الداخلي: ربط الصفحات ذات الصلة بنصوص مرساة غنية بالكلمات المفتاحية.'
      },
      {
        'en': 'Content Freshness: Update content regularly to maintain rankings.',
        'ar': 'تحديث المحتوى: تحديث المحتوى بانتظام للحفاظ على التصنيفات.'
      },
    ],
    'seo': [
      {
        'en': 'Technical Audit: Fix crawl errors, redirects, and broken links.',
        'ar': 'التدقيق التقني: إصلاح أخطاء الزحف، التوجيهات، والروابط المعطلة.'
      },
      {
        'en': 'URL Structure: Clean, short, keyword-optimized, canonicalized URLs.',
        'ar': 'بنية الروابط: روابط نظيفة، قصيرة، محسنة للكلمات المفتاحية، ومحددة أساسياً (Canonical).'
      },
      {
        'en': 'Site Speed: Optimize Core Web Vitals (LCP, INP, CLS) and page speed.',
        'ar': 'سرعة الموقع: تحسين مؤشرات أداء الويب الأساسية (Core Web Vitals) وسرعة الصفحة.'
      },
      {
        'en': 'Mobile Optimization: Ensure mobile-first design & responsiveness.',
        'ar': 'التوافق مع الجوال: ضمان تصميم مستجيب ومتوافق مع الجوال أولاً.'
      },
      {
        'en': 'Robots.txt & Sitemap.xml: Submit and keep updated in Google Search Console.',
        'ar': 'ملفات Robots.txt و Sitemap.xml: تقديمها وتحديثها في Google Search Console.'
      },
      {
        'en': 'Structured Data (Schema): Implement relevant schema markup.',
        'ar': 'البيانات المنظمة (Schema): تطبيق ترميز المخطط المناسب.'
      },
      {
        'en': 'Indexation: Check index coverage and fix indexing issues.',
        'ar': 'الفهرسة: التحقق من تغطية الفهرسة وإصلاح مشاكل الفهرسة.'
      },
      {
        'en': 'Monitoring: Track performance in Google Search Console.',
        'ar': 'المراقبة: تتبع الأداء والظهور في Google Search Console.'
      },
    ],
    'ai_visibility': [
      {
        'en': 'Create High-Quality, E-E-A-T Driven Content: Experience, Expertise, Authoritativeness, Trust.',
        'ar': 'إنشاء محتوى عالي الجودة يدعم E-E-A-T: الخبرة، التخصص، الموثوقية، والمصداقية.'
      },
      {
        'en': 'FAQ & Q&A Optimization: Answer user questions clearly and concisely.',
        'ar': 'تحسين الأسئلة الشائعة: الإجابة على أسئلة المستخدمين بوضوح واختصار.'
      },
      {
        'en': 'Content Structure: Use headings, bullets, and tables for AI readability.',
        'ar': 'بنية المحتوى: استخدام العناوين والنقاط والجداول لتسهيل القراءة على نماذج الذكاء الاصطناعي.'
      },
      {
        'en': 'Mentions & Citations: Get mentioned on reputable sites and platforms.',
        'ar': 'الإشارات والاستشهادات: الحصول على إشارات في مواقع ومنصات موثوقة.'
      },
      {
        'en': 'Optimize for AI Overviews: Provide clear, direct, and factual answers.',
        'ar': 'تحسين لنتائج بحث الذكاء الاصطناعي: تقديم إجابات واضحة ومباشرة وحقيقية.'
      },
      {
        'en': 'Monitor Brand Presence: Track visibility in AI responses and platforms (ChatGPT, Gemini, Perplexity).',
        'ar': 'مراقبة حضور العلامة التجارية: تتبع الظهور في إجابات الذكاء الاصطناعي (ChatGPT, Gemini, Perplexity).'
      },
    ],
    'trust': [
      {
        'en': 'Secure Website: Enable HTTPS with a valid SSL certificate.',
        'ar': 'أمان الموقع: تفعيل بروتوكول HTTPS مع شهادة SSL صالحة.'
      },
      {
        'en': 'Trust Signals: Add About Us, Contact, Privacy Policy, and Terms pages.',
        'ar': 'إشارات الثقة: إضافة صفحات من نحن، اتصل بنا، سياسة الخصوصية، والشروط والأحكام.'
      },
      {
        'en': 'Reviews & Ratings: Showcase customer reviews, testimonials & ratings.',
        'ar': 'المراجعات والتقييمات: عرض مراجعات العملاء وتوصياتهم وتقييماتهم.'
      },
      {
        'en': 'Author & Publisher Info: Add author bios and company credentials.',
        'ar': 'معلومات الكاتب والناشر: إضافة سيرة ذاتية للمؤلفين ومستندات اعتماد الشركة.'
      },
      {
        'en': 'Transparent Policies: Clear return, shipping, and refund policies.',
        'ar': 'سياسات شفافة: سياسات واضحة للاسترجاع، الشحن، واسترداد الأموال.'
      },
      {
        'en': 'Security & Compliance: Ensure GDPR/CCPA compliance and data protection.',
        'ar': 'الأمن والامتثال: ضمان الامتثال لمعايير GDPR/CCPA وحماية البيانات.'
      },
    ],
    'conversion': [
      {
        'en': 'Landing Page Optimization: Clear value proposition and strong CTA.',
        'ar': 'تحسين صفحات الهبوط: عرض قيمة واضح ودعوة قوية لاتخاذ إجراء (CTA).'
      },
      {
        'en': 'Product Pages: Unique descriptions, high-quality images, specs, and FAQs.',
        'ar': 'صفحات المنتجات: أوصاف فريدة، صور عالية الجودة، المواصفات، والأسئلة الشائعة.'
      },
      {
        'en': 'User Experience (UX): Easy navigation, search, filters, and site structure.',
        'ar': 'تجربة المستخدم (UX): سهولة التنقل، البحث، الفلاتر، وهيكل الموقع.'
      },
      {
        'en': 'Add-to-Cart & Checkout: Simplify steps and reduce friction.',
        'ar': 'الإضافة للسلة وإتمام الشراء: تبسيط الخطوات وتقليل نقاط الاحتكاك.'
      },
      {
        'en': 'Offer Optimization: Discounts, bundles, upsells, and free shipping thresholds.',
        'ar': 'تحسين العروض: خصومات، حزم منتجات، صفقات بديلة، وحدود الشحن المجاني.'
      },
      {
        'en': 'A/B Testing: Test headlines, CTAs, layouts, and offers.',
        'ar': 'اختبارات A/B: اختبار العناوين، دعوات اتخاذ الإجراء، التنسيقات، والعروض.'
      },
      {
        'en': 'Analytics & Tracking: Implement GA4, conversion tracking, and event tracking.',
        'ar': 'التحليلات والتتبع: إعداد GA4، تتبع التحويلات، وتتبع الأحداث.'
      },
    ],
  };
}

class GrowthEngineCard extends StatefulWidget {
  final String type;
  final String label;
  final List<EngineProgress> engines;
  final IconData icon;
  final Color color;
  final Project project;
  final String userRole;

  const GrowthEngineCard({
    super.key,
    required this.type,
    required this.label,
    required this.engines,
    required this.icon,
    required this.color,
    required this.project,
    required this.userRole,
  });

  @override
  State<GrowthEngineCard> createState() => _GrowthEngineCardState();
}

class _GrowthEngineCardState extends State<GrowthEngineCard> {
  bool _isExpanded = false;
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    
    final engine = widget.engines.firstWhere(
      (e) => e.engine == widget.type,
      orElse: () => EngineProgress(
        id: '',
        projectId: widget.project.id,
        engine: widget.type,
        progressPercent: 0,
        updatedAt: DateTime.now(),
      ),
    );

    // Decode checked steps from statusNotes
    List<String> checkedSteps = [];
    if (engine.statusNotes != null && engine.statusNotes!.isNotEmpty) {
      try {
        final decoded = jsonDecode(engine.statusNotes!);
        if (decoded is List) {
          checkedSteps = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        // Fallback for non-JSON content
      }
    }

    final steps = StrategyScreen.engineSteps[widget.type] ?? [];
    final totalSteps = steps.length;
    final progress = totalSteps > 0 ? checkedSteps.length / totalSteps : 0.0;
    final progressPercent = (progress * 100).toInt();

    final isEditable = widget.userRole == 'admin' || widget.userRole == 'am';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          // Header Row
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label,
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
                            valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$progressPercent%',
                        style: TextStyle(
                          color: widget.color,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: Colors.white30,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Collapsible Checklist Section
          if (_isExpanded) ...[
            const Divider(color: Colors.white10, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_isUpdating)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: LinearProgressIndicator(color: AppTheme.primaryGreen, minHeight: 2),
                    ),
                  ...steps.map((stepMap) {
                    final enText = stepMap['en']!;
                    final arText = stepMap['ar']!;
                    final displayText = isAr ? arText : enText;
                    final isChecked = checkedSteps.contains(enText);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          if (isEditable)
                            Checkbox(
                              value: isChecked,
                              activeColor: widget.color,
                              checkColor: Colors.black,
                              side: const BorderSide(color: Colors.white30),
                              onChanged: _isUpdating
                                  ? null
                                  : (value) async {
                                      setState(() {
                                        _isUpdating = true;
                                      });
                                      
                                      final newChecked = List<String>.from(checkedSteps);
                                      if (value == true) {
                                        newChecked.add(enText);
                                      } else {
                                        newChecked.remove(enText);
                                      }

                                      final newPercent = ((newChecked.length / totalSteps) * 100).toInt();

                                      try {
                                        final client = Supabase.instance.client;
                                        if (engine.id.isNotEmpty) {
                                          await client.from('engine_progress').update({
                                            'progress_percent': newPercent,
                                            'status_notes': jsonEncode(newChecked),
                                            'updated_at': DateTime.now().toIso8601String(),
                                          }).eq('id', engine.id);
                                        } else {
                                          await client.from('engine_progress').insert({
                                            'project_id': widget.project.id,
                                            'engine': widget.type,
                                            'progress_percent': newPercent,
                                            'status_notes': jsonEncode(newChecked),
                                            'updated_at': DateTime.now().toIso8601String(),
                                          });
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Failed to update progress: $e')),
                                          );
                                        }
                                      } finally {
                                        if (mounted) {
                                          setState(() {
                                            _isUpdating = false;
                                          });
                                        }
                                      }
                                    },
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Icon(
                                isChecked ? Icons.check_box : Icons.check_box_outline_blank,
                                color: isChecked ? widget.color : Colors.white30,
                                size: 20,
                              ),
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              displayText,
                              style: TextStyle(
                                color: isChecked ? Colors.white70 : Colors.white,
                                fontSize: 13,
                                decoration: isChecked ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

