import 'package:flutter/material.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/core/utils/arabic_formatter.dart';
import 'package:moharek_app/core/config/app_config.dart';

class EngineProgressCard extends StatefulWidget {
  final Map<String, double> progress;
  final bool isAr;

  const EngineProgressCard({
    super.key,
    required this.progress,
    required this.isAr,
  });

  @override
  State<EngineProgressCard> createState() => _EngineProgressCardState();
}

class _EngineProgressCardState extends State<EngineProgressCard> {
  String? _expandedEngine;

  final Map<String, List<String>> _subItemsAr = {
    // Moharek
    'SEO': ['SEO التقني', 'SEO داخل الصفحة', 'الكلمات المفتاحية', 'المدونة'],
    'Content': ['مقالات', 'صفحات الخدمات', 'فيديوهات قصيرة', 'محتوى يدعم البحث'],
    'AI Visibility': ['الظهور في ChatGPT', 'Gemini', 'Perplexity', 'تحسين إجابات الذكاء'],
    'Trust Engine': ['التقييمات', 'Google Business', 'السمعة', 'الدلائل'],
    'Conversion': ['تحسين صفحات الهبوط', 'CTA', 'تتبع WhatsApp', 'نماذج الليدز'],
    // Rabhan
    'Store': ['هوية المتجر', 'تصميم واجهة المستخدم', 'سرعة التصفح', 'تجربة الدفع Checkout'],
    'Product': ['صور المنتجات', 'كتابة الوصف الإقناعي', 'التسعير والهامش', 'حزم المنتجات Bundles'],
    'Ads': ['حملات Meta', 'حملات Google', 'إعلانات TikTok', 'إعلانات Snapchat'],
    'Sales Page': ['هيكلة صفحة الهبوط', 'العروض الخاصة', 'عناصر الإقناع الاجتماعي', 'سلاسة الطلب السريع'],
    'Operations': ['شركات الشحن', 'بوابات الدفع', 'إدارة المخزون', 'خدمة العملاء'],
    'Analytics': ['تتبع السلة المهجورة', 'بكسل التتبع Pixel', 'معدل LTV للعملاء', 'تقارير أداء المنتجات'],
  };

  final Map<String, List<String>> _subItemsEn = {
    // Moharek
    'SEO': ['Technical SEO', 'On-Page SEO', 'Keywords Strategy', 'Blog'],
    'Content': ['Articles', 'Service Pages', 'Short Videos', 'Search Content'],
    'AI Visibility': ['ChatGPT Presence', 'Gemini Presence', 'Perplexity', 'AI Optimization'],
    'Trust Engine': ['Reviews', 'Google Business', 'Reputation', 'Directories'],
    'Conversion': ['Landing Page Opt', 'CTA Strategy', 'WhatsApp Tracking', 'Lead Forms'],
    // Rabhan
    'Store': ['Brand Identity', 'UI/UX Design', 'Page Speed', 'Checkout UX'],
    'Product': ['Product Images', 'Copywriting Description', 'Pricing & Margin', 'Product Bundles'],
    'Ads': ['Meta Campaigns', 'Google Ads', 'TikTok Ads', 'Snapchat Ads'],
    'Sales Page': ['Landing Page Structure', 'Special Offers', 'Social Proof', 'Express Checkout Flow'],
    'Operations': ['Shipping Carriers', 'Payment Gateways', 'Inventory Management', 'Customer Support'],
    'Analytics': ['Abandoned Cart Tracking', 'Tracking Pixels', 'Customer LTV', 'Product Analytics Reports'],
  };

  @override
  Widget build(BuildContext context) {
    final isRabhan = AppConfig.flavorName == 'rabhan';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isRabhan
                ? (widget.isAr ? 'محركات النمو الستة' : 'The 6 Growth Engines')
                : (widget.isAr ? 'أنظمة النمو الخمسة' : 'The 5 Growth Engines'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          if (isRabhan) ...[
            _buildEngineItem(widget.isAr ? 'المتجر' : 'Store', 'Store', widget.progress['store'] ?? 0.0, AppTheme.primaryGreen),
            _buildEngineItem(widget.isAr ? 'المنتجات' : 'Product', 'Product', widget.progress['product'] ?? 0.0, Colors.purpleAccent),
            _buildEngineItem(widget.isAr ? 'الإعلانات' : 'Ads', 'Ads', widget.progress['ads'] ?? 0.0, AppTheme.primaryBlue),
            _buildEngineItem(widget.isAr ? 'صفحات البيع' : 'Sales Page', 'Sales Page', widget.progress['sales_page'] ?? 0.0, Colors.amber),
            _buildEngineItem(widget.isAr ? 'العمليات' : 'Operations', 'Operations', widget.progress['operations'] ?? 0.0, Colors.orangeAccent),
            _buildEngineItem(widget.isAr ? 'التحليلات' : 'Analytics', 'Analytics', widget.progress['analytics'] ?? 0.0, Colors.pinkAccent),
          ] else ...[
            _buildEngineItem('SEO', 'SEO', widget.progress['seo'] ?? 0.0, AppTheme.primaryGreen),
            _buildEngineItem(widget.isAr ? 'المحتوى' : 'Content', 'Content', widget.progress['content'] ?? 0.0, Colors.purpleAccent),
            _buildEngineItem(widget.isAr ? 'الظهور AI' : 'AI Visibility', 'AI Visibility', widget.progress['ai_visibility'] ?? 0.0, AppTheme.primaryBlue),
            _buildEngineItem(widget.isAr ? 'الثقة والتقييمات' : 'Trust Engine', 'Trust Engine', widget.progress['trust'] ?? 0.0, Colors.amber),
            _buildEngineItem(widget.isAr ? 'تحسين التحويل' : 'Conversion', 'Conversion', widget.progress['conversion'] ?? 0.0, Colors.pinkAccent),
          ],
        ],
      ),
    );
  }

  Widget _buildEngineItem(String label, String key, double value, Color color) {
    final isExpanded = _expandedEngine == key;
    final subItems = widget.isAr ? _subItemsAr[key] : _subItemsEn[key];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            _expandedEngine = isExpanded ? null : key;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isExpanded ? color.withValues(alpha: 0.05) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isExpanded ? color.withValues(alpha: 0.2) : Colors.transparent,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isExpanded ? color : Colors.white70,
                      fontSize: 14,
                      fontWeight: isExpanded ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '${ArabicFormatter.number((value * 100).toInt(), isAr: widget.isAr)}%',
                        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: Colors.white24,
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildProgressBar(value, color),
              if (isExpanded && subItems != null) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: subItems.map((item) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item,
                      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500),
                    ),
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(double value, Color color) {
    return Stack(
      children: [
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: value),
          duration: const Duration(milliseconds: 1500),
          curve: Curves.easeOutCubic,
          builder: (context, val, child) {
            return FractionallySizedBox(
              alignment: widget.isAr ? Alignment.centerRight : Alignment.centerLeft,
              widthFactor: val.clamp(0.0, 1.0),
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 4,
                      spreadRadius: 0,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
