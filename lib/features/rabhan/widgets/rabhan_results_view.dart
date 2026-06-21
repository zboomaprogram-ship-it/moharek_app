import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:moharek_app/core/theme/rabhan_theme_constants.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/features/rabhan/providers/metrics_provider.dart';
import 'package:moharek_app/features/rabhan/providers/growth_provider.dart';
import 'package:moharek_app/features/rabhan/providers/ad_campaign_provider.dart';
import 'package:moharek_app/features/rabhan/models/growth_engine_model.dart';
import 'package:moharek_app/features/rabhan/models/ad_campaign.dart';

class RabhanResultsView extends ConsumerStatefulWidget {
  const RabhanResultsView({super.key});

  @override
  ConsumerState<RabhanResultsView> createState() => _RabhanResultsViewState();
}

class _RabhanResultsViewState extends ConsumerState<RabhanResultsView> with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(currentProjectProvider);
    final project = projectAsync.valueOrNull;
    final projectId = project?.id ?? '';
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    if (projectId.isEmpty) {
      return const Scaffold(
        backgroundColor: RabhanTheme.background,
        body: Center(
          child: Text('لا يوجد مشروع نشط حالياً', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1C),
      appBar: AppBar(
        title: Text(
          isAr ? 'تقارير الأداء والتحليلات' : 'Performance Reports & Analytics',
          style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0A0F1C),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: RabhanTheme.primaryGreen,
          labelColor: RabhanTheme.primaryGreen,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: isAr ? 'المتجر' : 'Store'),
            Tab(text: isAr ? 'الإعلانات' : 'Ads'),
            Tab(text: isAr ? 'المنتجات' : 'Products'),
            Tab(text: isAr ? 'التحليلات' : 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStoreTab(projectId, isAr),
          _buildAdsTab(projectId, isAr),
          _buildProductsTab(isAr),
          _buildAnalyticsTab(projectId, isAr),
        ],
      ),
    );
  }

  // ─── TAB 1: STORE ─────────────────────────────────────────────────────────
  Widget _buildStoreTab(String projectId, bool isAr) {
    final historyAsync = ref.watch(projectMetricsHistoryProvider(projectId));

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: RabhanTheme.primaryGreen)),
      error: (e, _) => Center(child: Text('خطأ في تحميل البيانات: $e', style: const TextStyle(color: Colors.red))),
      data: (metricsHistory) {
        final published = metricsHistory.where((m) => m['is_published'] == true).toList();
        
        if (published.isEmpty) {
          return Center(
            child: Text(
              isAr ? 'سيتم نشر التقارير والمؤشرات قريباً من قبل مدير الحساب' : 'Performance reports will be published soon.',
              style: const TextStyle(color: RabhanTheme.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          );
        }

        final sortedForChart = List<Map<String, dynamic>>.from(published)
          ..sort((a, b) => (a['period_end'] as String).compareTo(b['period_end'] as String));

        final latest = published.first;
        final currency = latest['currency'] ?? 'SAR';

        return RefreshIndicator(
          color: RabhanTheme.primaryGreen,
          onRefresh: () async {
            ref.invalidate(projectMetricsHistoryProvider(projectId));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildKpiCard(
                        title: isAr ? 'إجمالي المبيعات' : 'Total Sales',
                        value: '${latest['total_sales']} $currency',
                        subText: isAr ? 'آخر فترة مسجلة' : 'Latest period',
                        icon: Icons.monetization_on_outlined,
                        color: RabhanTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildKpiCard(
                        title: isAr ? 'العائد الإعلاني ROAS' : 'ROAS',
                        value: '${latest['roas']}x',
                        subText: isAr ? 'أداء الحملات الإعلانية' : 'Ads performance',
                        icon: Icons.trending_up,
                        color: RabhanTheme.gold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildKpiCard(
                        title: isAr ? 'الطلبات' : 'Orders',
                        value: '${latest['orders_count']}',
                        subText: isAr ? 'عمليات الشراء الناجحة' : 'Successful purchases',
                        icon: Icons.shopping_cart_outlined,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildKpiCard(
                        title: isAr ? 'معدل التحويل CR' : 'Conversion Rate',
                        value: '${((double.tryParse(latest['conversion_rate']?.toString() ?? '0') ?? 0.0) * 100).toStringAsFixed(2)}%',
                        subText: isAr ? 'نسبة الشراء للزوار' : 'Purchase to visitor ratio',
                        icon: Icons.percent,
                        color: Colors.purpleAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildCardWrapper(
                  title: isAr ? 'منحنى نمو المبيعات' : 'Sales Growth Trend',
                  subtitle: isAr ? 'تطور حجم مبيعات متجرك عبر الفترات المتعاقبة' : 'Development of your store sales',
                  child: SizedBox(
                    height: 200,
                    child: _buildLineChart(sortedForChart, currency),
                  ),
                ),
                const SizedBox(height: 20),
                _buildCardWrapper(
                  title: isAr ? 'صافي الأرباح مقابل الإنفاق الإعلاني' : 'Net Profit vs Spend',
                  subtitle: isAr ? 'كفاءة الصرف الإعلاني وتحقيق الأرباح الفعالة' : 'Ads spend efficiency vs profit',
                  child: SizedBox(
                    height: 200,
                    child: _buildBarChart(sortedForChart, currency),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isAr ? 'تفاصيل فترات الأداء السابقة' : 'Historical Performance Details',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...published.map((m) => _buildHistoryRow(m, currency, isAr)),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── TAB 2: ADS ───────────────────────────────────────────────────────────
  Widget _buildAdsTab(String projectId, bool isAr) {
    final adsAsync = ref.watch(adCampaignsProvider(projectId));

    return adsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: RabhanTheme.primaryGreen)),
      error: (e, _) => Center(child: Text('خطأ في تحميل الحملات: $e', style: const TextStyle(color: Colors.red))),
      data: (campaigns) {
        if (campaigns.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.campaign_outlined, color: RabhanTheme.textSecondary, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    isAr ? 'لا توجد حملات إعلانية نشطة حالياً' : 'No active campaigns right now.',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAr ? 'يقوم فريق العمل بإنشاء وإدارة حملاتك وسوف تظهر هنا فور إطلاقها.' : 'Our team is configuring your campaigns. They will appear here once launched.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: RabhanTheme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        // Compute summary metrics
        final totalBudget = campaigns.fold<double>(0, (sum, c) => sum + c.budget);
        final totalSpend = campaigns.fold<double>(0, (sum, c) => sum + c.spend);
        final totalClicks = campaigns.fold<int>(0, (sum, c) => sum + c.clicks);
        final totalImpressions = campaigns.fold<int>(0, (sum, c) => sum + c.impressions);
        final totalConversions = campaigns.fold<int>(0, (sum, c) => sum + c.conversions);
        final activeCampaignsCount = campaigns.where((c) => c.status == 'active').length;
        final avgRoas = activeCampaignsCount == 0 ? 0.0 : campaigns.where((c) => c.status == 'active').fold<double>(0, (sum, c) => sum + c.roas) / activeCampaignsCount;
        final currency = campaigns.first.currency;

        return RefreshIndicator(
          color: RabhanTheme.primaryGreen,
          onRefresh: () async {
            ref.invalidate(adCampaignsProvider(projectId));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary KPI list
                Row(
                  children: [
                    Expanded(
                      child: _buildKpiCard(
                        title: isAr ? 'الإنفاق الإجمالي' : 'Total Spend',
                        value: '${totalSpend.toStringAsFixed(1)} $currency',
                        subText: isAr ? 'الميزانية: ${totalBudget.toStringAsFixed(0)}' : 'Budget: ${totalBudget.toStringAsFixed(0)}',
                        icon: Icons.payments_outlined,
                        color: RabhanTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildKpiCard(
                        title: isAr ? 'متوسط العائد ROAS' : 'Average ROAS',
                        value: '${avgRoas.toStringAsFixed(2)}x',
                        subText: isAr ? 'للحملات النشطة' : 'Active campaigns',
                        icon: Icons.show_chart,
                        color: RabhanTheme.gold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildKpiCard(
                        title: isAr ? 'النقرات والتحويلات' : 'Clicks & Conversions',
                        value: '$totalConversions / $totalClicks',
                        subText: isAr ? 'مرات الظهور: ${totalImpressions}' : 'Impressions: ${totalImpressions}',
                        icon: Icons.ads_click,
                        color: Colors.cyanAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  isAr ? 'الحملات الإعلانية النشطة والتفاصيل' : 'Active Campaigns & Details',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...campaigns.map((c) => _buildCampaignItem(c, isAr)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCampaignItem(AdCampaign c, bool isAr) {
    final spendPct = c.budget == 0 ? 0.0 : c.spend / c.budget;
    final statusColor = c.status == 'active' ? RabhanTheme.primaryGreen 
                        : c.status == 'paused' ? RabhanTheme.gold
                        : Colors.grey;
    final statusText = isAr 
        ? (c.status == 'active' ? 'نشطة' : c.status == 'paused' ? 'متوقفة' : 'منتهية')
        : c.status.toUpperCase();

    final platformIcon = switch (c.platform.toLowerCase()) {
      'meta' || 'facebook' || 'instagram' => Icons.facebook,
      'google' || 'youtube' => Icons.g_mobiledata,
      'tiktok' => Icons.music_note,
      'snapchat' => Icons.snapchat,
      _ => Icons.campaign,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RabhanTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(platformIcon, color: RabhanTheme.primaryGreen, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  c.campaignName,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withAlpha(100), width: 0.5),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Spend Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isAr ? 'الإنفاق الإعلاني' : 'Ad Spend',
                style: const TextStyle(color: RabhanTheme.textSecondary, fontSize: 12),
              ),
              Text(
                '${c.spend} / ${c.budget} ${c.currency}',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: spendPct.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(RabhanTheme.primaryGreen),
            ),
          ),
          const SizedBox(height: 14),
          // Metrics Grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCampaignMiniMetric(isAr ? 'العائد ROAS' : 'ROAS', '${c.roas.toStringAsFixed(1)}x', RabhanTheme.gold),
              _buildCampaignMiniMetric(isAr ? 'النقرات' : 'Clicks', '${c.clicks}', Colors.white),
              _buildCampaignMiniMetric(isAr ? 'الظهور' : 'Impressions', '${c.impressions}', Colors.white),
              _buildCampaignMiniMetric(isAr ? 'التحويلات' : 'Conversions', '${c.conversions}', RabhanTheme.primaryGreen),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignMiniMetric(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(color: RabhanTheme.textSecondary, fontSize: 9)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ─── TAB 3: PRODUCTS ──────────────────────────────────────────────────────
  Widget _buildProductsTab(bool isAr) {
    final projectAsync = ref.watch(currentProjectProvider);
    final projectId = projectAsync.valueOrNull?.id ?? '';
    final metricsAsync = ref.watch(latestMetricsProvider(projectId));

    return metricsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: RabhanTheme.primaryGreen)),
      error: (_, __) => _buildProductsContent(isAr, null),
      data: (metrics) => _buildProductsContent(isAr, metrics),
    );
  }

  Widget _buildProductsContent(bool isAr, dynamic metrics) {
    // Build funnel from real data if available
    final clicks = (metrics?.clicks ?? 0) as int;
    final addToCart = (metrics?.addToCart ?? 0) as int;
    final orders = (metrics?.ordersCount ?? 0) as int;

    final hasRealFunnelData = clicks > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Funnel widget
          _buildCardWrapper(
            title: isAr ? 'قمع تحويل المنتجات العام' : 'Overall Product Funnel',
            subtitle: isAr ? 'كفاءة انتقال العملاء من المشاهدة للشراء' : 'Efficiency of customer journey to purchase',
            child: hasRealFunnelData
              ? Column(
                  children: [
                    _buildFunnelStage(
                      isAr ? 'زيارة صفحة المنتج' : 'Product Page Views',
                      _formatNumber(clicks),
                      1.0,
                      Colors.grey,
                    ),
                    if (addToCart > 0) _buildFunnelStage(
                      isAr ? 'الإضافة للسلة' : 'Add to Cart',
                      '${_formatNumber(addToCart)} (${(addToCart / clicks * 100).toStringAsFixed(1)}%)',
                      addToCart / clicks,
                      RabhanTheme.gold,
                    ),
                    if (orders > 0) _buildFunnelStage(
                      isAr ? 'إتمام الشراء' : 'Purchase',
                      '${_formatNumber(orders)} (${(orders / clicks * 100).toStringAsFixed(1)}%)',
                      orders / clicks,
                      RabhanTheme.primaryGreen,
                    ),
                  ],
                )
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      isAr ? 'أدخل بيانات المبيعات في تقرير الأداء لعرض قمع التحويل' : 'Enter sales data in the performance report to view the conversion funnel',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: RabhanTheme.textSecondary, fontSize: 13),
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  Widget _buildFunnelStage(String label, String value, double percent, Color barColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
              Text(value, style: TextStyle(color: barColor, fontSize: 14, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(10),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(50),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  flex: (percent * 100).toInt(),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        colors: [barColor.withAlpha(200), barColor],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: barColor.withAlpha(50),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 100 - (percent * 100).toInt(),
                  child: const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductMetricCol(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: RabhanTheme.textSecondary, fontSize: 10)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildAnalyticsTab(String projectId, bool isAr) {
    final metricsAsync = ref.watch(latestMetricsProvider(projectId));
    final enginesAsync = ref.watch(growthEnginesProvider(projectId));
    final summaryAsync = ref.watch(projectWeeklySummaryProvider(projectId));

    return RefreshIndicator(
      color: RabhanTheme.primaryGreen,
      onRefresh: () async {
        ref.invalidate(latestMetricsProvider(projectId));
        ref.invalidate(growthEnginesProvider(projectId));
        ref.invalidate(projectWeeklySummaryProvider(projectId));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── AI SUMMARY CARD (PHASE 4) ─────────────────────────────────
            summaryAsync.when(
              data: (summary) {
                if (summary == null || summary.isEmpty) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: RabhanTheme.primaryGreen.withAlpha(50)),
                    boxShadow: [
                      BoxShadow(
                        color: RabhanTheme.primaryGreen.withAlpha(10),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: RabhanTheme.primaryGreen, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            isAr ? 'ملخص الأداء الأسبوعي (AI)' : 'Weekly AI Insight Summary',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        summary,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Center(child: CircularProgressIndicator(color: RabhanTheme.primaryGreen)),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // ── SECTION 1: Real Ecom KPIs ─────────────────────────────
            metricsAsync.when(
              loading: () => const LinearProgressIndicator(color: RabhanTheme.primaryGreen),
              error: (_, __) => const SizedBox.shrink(),
              data: (metrics) {
                if (metrics == null) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: RabhanTheme.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withAlpha(10)),
                    ),
                    child: Text(
                      isAr
                          ? 'لم يتم نشر تقرير أداء حتى الآن. سيتم إضافة مؤشراتك من قبل مدير الحساب.'
                          : 'No performance report published yet. Your AM will add your metrics soon.',
                      style: const TextStyle(color: RabhanTheme.textSecondary, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final currency = 'SAR';
                final crPct = (metrics.conversionRate * 100).toStringAsFixed(2);
                final periodLabel = '${metrics.periodStart.day}/${metrics.periodStart.month} — ${metrics.periodEnd.day}/${metrics.periodEnd.month}';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isAr ? 'مؤشرات الأداء — آخر فترة' : 'Performance KPIs — Latest Period',
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        Text(periodLabel, style: const TextStyle(color: RabhanTheme.textSecondary, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildKpiCard(
                            title: isAr ? 'إجمالي المبيعات' : 'Total Sales',
                            value: '${metrics.totalSales.toStringAsFixed(0)} $currency',
                            subText: isAr
                                ? '${metrics.salesDeltaPercent >= 0 ? '+' : ''}${metrics.salesDeltaPercent.toStringAsFixed(1)}% عن السابق'
                                : '${metrics.salesDeltaPercent >= 0 ? '+' : ''}${metrics.salesDeltaPercent.toStringAsFixed(1)}% vs prev',
                            icon: Icons.monetization_on_outlined,
                            color: RabhanTheme.primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildKpiCard(
                            title: isAr ? 'العائد الإعلاني ROAS' : 'ROAS',
                            value: '${metrics.roas.toStringAsFixed(1)}x',
                            subText: isAr
                                ? '${metrics.roasDeltaPercent >= 0 ? '+' : ''}${metrics.roasDeltaPercent.toStringAsFixed(1)}% عن السابق'
                                : '${metrics.roasDeltaPercent >= 0 ? '+' : ''}${metrics.roasDeltaPercent.toStringAsFixed(1)}% vs prev',
                            icon: Icons.trending_up,
                            color: RabhanTheme.gold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildKpiCard(
                            title: isAr ? 'الإنفاق الإعلاني' : 'Ad Spend',
                            value: '${metrics.adSpend.toStringAsFixed(0)} $currency',
                            subText: isAr ? 'صافي الأرباح: ${metrics.netProfit.toStringAsFixed(0)}' : 'Net profit: ${metrics.netProfit.toStringAsFixed(0)}',
                            icon: Icons.payments_outlined,
                            color: Colors.redAccent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildKpiCard(
                            title: isAr ? 'معدل التحويل CR' : 'Conversion Rate',
                            value: '$crPct%',
                            subText: isAr ? '${metrics.ordersCount} طلب / ${metrics.clicks} زيارة' : '${metrics.ordersCount} orders / ${metrics.clicks} visits',
                            icon: Icons.percent,
                            color: Colors.purpleAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Funnel Mini Summary
                    _buildCardWrapper(
                      title: isAr ? 'قمع التحويل' : 'Conversion Funnel',
                      subtitle: isAr ? 'من الظهور حتى إتمام الشراء' : 'From impressions to purchase',
                      child: Column(
                        children: [
                          if (metrics.impressions > 0) _buildFunnelStage(
                            isAr ? 'الظهور (Impressions)' : 'Impressions',
                            _formatNumber(metrics.impressions), 1.0, Colors.grey,
                          ),
                          if (metrics.clicks > 0) _buildFunnelStage(
                            isAr ? 'زيارات المنتج (Clicks)' : 'Product Page Visits',
                            _formatNumber(metrics.clicks),
                            metrics.impressions > 0 ? metrics.clicks / metrics.impressions : 1.0,
                            Colors.blueAccent,
                          ),
                          if (metrics.addToCart > 0) _buildFunnelStage(
                            isAr ? 'الإضافة للسلة' : 'Add to Cart',
                            '${_formatNumber(metrics.addToCart)} (${metrics.clicks > 0 ? (metrics.addToCart / metrics.clicks * 100).toStringAsFixed(1) : 0}%)',
                            metrics.clicks > 0 ? metrics.addToCart / metrics.clicks : 0,
                            RabhanTheme.gold,
                          ),
                          if (metrics.ordersCount > 0) _buildFunnelStage(
                            isAr ? 'إتمام الشراء (Orders)' : 'Purchase (Orders)',
                            '${_formatNumber(metrics.ordersCount)} (${metrics.clicks > 0 ? (metrics.ordersCount / metrics.clicks * 100).toStringAsFixed(1) : 0}%)',
                            metrics.clicks > 0 ? metrics.ordersCount / metrics.clicks : 0,
                            RabhanTheme.primaryGreen,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),

            // ── SECTION 2: Growth Engine Health ───────────────────────
            Text(
              isAr ? 'تحليل صحة محركات النمو' : 'Growth Engine Health Analysis',
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            enginesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: RabhanTheme.primaryGreen)),
              error: (e, _) => Text('خطأ: $e', style: const TextStyle(color: RabhanTheme.error)),
              data: (engines) {
                final requiredTypes = ['store', 'product', 'ads', 'sales_page', 'operations', 'analytics'];
                final engineMap = {for (var e in engines) e.engineType: e};

                final allEngines = requiredTypes.map((type) => engineMap[type] ??
                    GrowthEngineModel(engineType: type, status: 'pending', healthScore: 0)).toList();

                final totalScore = allEngines.fold(0, (sum, e) => sum + e.healthScore);
                final avgScore = allEngines.isNotEmpty ? (totalScore / allEngines.length).round() : 0;
                final overallColor = avgScore > 80 ? RabhanTheme.primaryGreen : avgScore > 50 ? RabhanTheme.gold : RabhanTheme.error;

                return Column(
                  children: [
                    // Overall score ring
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: RabhanTheme.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: overallColor.withAlpha(40), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 70,
                                height: 70,
                                child: CircularProgressIndicator(
                                  value: avgScore / 100,
                                  strokeWidth: 7,
                                  backgroundColor: Colors.white.withAlpha(15),
                                  valueColor: AlwaysStoppedAnimation<Color>(overallColor),
                                ),
                              ),
                              Text('$avgScore%', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAr ? 'مؤشر جاهزية النمو الكلي' : 'Overall Growth Readiness',
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getOverallAssessment(avgScore, isAr),
                                  style: TextStyle(color: overallColor, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...allEngines.map((e) => _buildEngineCard(e, isAr)),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }


  String _getOverallAssessment(int score, bool isAr) {
    if (score >= 85) {
      return isAr ? 'ممتاز! متجرك مهيأ تماماً وقابل للتوسع والنمو السريع 🚀' : 'Excellent! Store is growth ready 🚀';
    }
    if (score >= 60) {
      return isAr ? 'جيد. هناك بعض الجوانب بحاجة للتحسين لضمان كفاءة التوسع 📈' : 'Good. Some optimization needed 📈';
    }
    return isAr ? 'تنبيه: محركات المتجر تعاني من ثغرات تعطل أداء نمو المبيعات ⚠️' : 'Warning: Action required on key engines ⚠️';
  }

  Widget _buildEngineCard(GrowthEngineModel engine, bool isAr) {
    final statusColor = switch (engine.status) {
      'active'     => RabhanTheme.primaryGreen,
      'optimizing' => RabhanTheme.gold,
      'critical'   => RabhanTheme.error,
      _            => Colors.blueAccent,
    };

    final statusLabel = isAr 
        ? switch (engine.status) {
            'active'     => 'نشط وفعال',
            'optimizing' => 'جاري تحسينه',
            'critical'   => 'يحتاج تدخل',
            _            => 'قيد الانتظار',
          }
        : engine.status.toUpperCase();

    final icon = switch (engine.engineType) {
      'store'      => Icons.storefront_outlined,
      'product'    => Icons.shopping_bag_outlined,
      'ads'        => Icons.campaign_outlined,
      'sales_page' => Icons.layers_outlined,
      'operations' => Icons.settings_input_component_outlined,
      _            => Icons.bar_chart_outlined,
    };

    final desc = isAr 
        ? switch (engine.engineType) {
            'store'      => 'تحسين سرعة التصفح، تجربة العميل وثقة الشراء بالمتجر.',
            'product'    => 'تحليل ربحية المنتجات، تسعيرها، ومعدلات الطلب عليها.',
            'ads'        => 'أداء الحملات الإعلانية المدفوعة وكفاءة الاستهداف والعائد.',
            'sales_page' => 'كفاءة صفحات الهبوط، العروض الترويجية وخطوات الدفع السلسة.',
            'operations' => 'سرعة تنفيذ الطلبات، الدعم الفني، وربط الخدمات اللوجستية.',
            _            => 'تقارير المبيعات، تصنيف العملاء، وتحليلات سلات الشراء المهجورة.',
          }
        : switch (engine.engineType) {
            'store'      => 'Optimize store browsing speed, CX, and purchase trust.',
            'product'    => 'Analyze product profitability, pricing, and demands.',
            'ads'        => 'Performance and target efficiency of paid ads.',
            'sales_page' => 'LPs efficiency, conversion boosters, and seamless checkout.',
            'operations' => 'Fulfillment speed, support ticketing, and shipping sync.',
            _            => 'Sales reporting, customer profiling, and cart recovery.',
          };

    final arabicName = isAr ? engine.arabicName : engine.engineType.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RabhanTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  value: engine.healthScore / 100,
                  strokeWidth: 4,
                  backgroundColor: Colors.white.withAlpha(15),
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
              Text(
                '${engine.healthScore}',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      arabicName,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(35),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withAlpha(100), width: 0.5),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: const TextStyle(color: RabhanTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────
  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subText,
    required IconData icon,
    required Color color,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withAlpha(50), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(20),
                blurRadius: 20,
                spreadRadius: -5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title, 
                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FittedBox(
                child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    subText.contains('-') ? Icons.trending_down : Icons.trending_up, 
                    color: subText.contains('-') ? Colors.redAccent : RabhanTheme.primaryGreen, 
                    size: 14
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      subText, 
                      style: TextStyle(color: subText.contains('-') ? Colors.redAccent : RabhanTheme.primaryGreen, fontSize: 11, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardWrapper({required String title, required String subtitle, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(12),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withAlpha(20), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 24),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart(List<Map<String, dynamic>> data, String currency) {
    if (data.isEmpty) return const SizedBox.shrink();
    final spots = data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['total_sales'] as num).toDouble())).toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.4,
            color: RabhanTheme.primaryGreen,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  RabhanTheme.primaryGreen.withAlpha(100),
                  RabhanTheme.primaryGreen.withAlpha(0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            shadow: Shadow(
              color: RabhanTheme.primaryGreen.withAlpha(100),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> data, String currency) {
    if (data.isEmpty) return const SizedBox.shrink();

    final barGroups = data.asMap().entries.map((e) {
      final idx = e.key;
      final val = e.value;
      final profit = (val['net_profit'] as num).toDouble();
      final spend = (val['ad_spend'] as num).toDouble();

      return BarChartGroupData(
        x: idx,
        barRods: [
          BarChartRodData(
            toY: profit, 
            gradient: LinearGradient(colors: [RabhanTheme.primaryGreen.withAlpha(200), RabhanTheme.primaryGreen]), 
            width: 12, 
            borderRadius: BorderRadius.circular(4)
          ),
          BarChartRodData(
            toY: spend, 
            gradient: LinearGradient(colors: [RabhanTheme.gold.withAlpha(200), RabhanTheme.gold]), 
            width: 12, 
            borderRadius: BorderRadius.circular(4)
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }

  Widget _buildHistoryRow(Map<String, dynamic> m, String currency, bool isAr) {
    final start = DateTime.parse(m['period_start'].toString());
    final end = DateTime.parse(m['period_end'].toString());
    final rangeStr = '${start.day}/${start.month} - ${end.day}/${end.month}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAr ? 'فترة الأداء' : 'Performance Period',
                style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(rangeStr, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${m['total_sales']} $currency',
                style: const TextStyle(color: RabhanTheme.primaryGreen, fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                'ROAS: ${m['roas']}x',
                style: const TextStyle(color: RabhanTheme.gold, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
