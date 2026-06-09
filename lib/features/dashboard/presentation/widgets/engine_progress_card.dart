import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/core/utils/arabic_formatter.dart';
import 'package:moharek_app/core/config/app_config.dart';
import 'package:moharek_app/shared/models/engine_progress.dart';
import 'package:moharek_app/features/strategy/presentation/screens/strategy_screen.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';
import 'package:moharek_app/shared/services/data_providers.dart';

class EngineProgressCard extends ConsumerStatefulWidget {
  final List<EngineProgress> engineProgressList;
  final bool isAr;
  final String userRole;
  final String projectId;

  const EngineProgressCard({
    super.key,
    required this.engineProgressList,
    required this.isAr,
    required this.userRole,
    required this.projectId,
  });

  @override
  ConsumerState<EngineProgressCard> createState() => _EngineProgressCardState();
}

class _EngineProgressCardState extends ConsumerState<EngineProgressCard> {
  String? _expandedEngine;
  bool _isUpdating = false;

  final Map<String, List<String>> _subItemsAr = {
    // Moharek
    'seo': ['SEO التقني', 'SEO داخل الصفحة', 'الكلمات المفتاحية', 'المدونة'],
    'content': ['مقالات', 'صفحات الخدمات', 'فيديوهات قصيرة', 'محتوى يدعم البحث'],
    'ai_visibility': ['الظهور في ChatGPT', 'Gemini', 'Perplexity', 'تحسين إجابات الذكاء'],
    'trust': ['التقييمات', 'Google Business', 'السمعة', 'الدلائل'],
    'conversion': ['تحسين صفحات الهبوط', 'CTA', 'تتبع WhatsApp', 'نماذج الليدز'],
    // Rabhan
    'store': ['هوية المتجر', 'تصميم واجهة المستخدم', 'سرعة التصفح', 'تجربة الدفع Checkout'],
    'product': ['صور المنتجات', 'كتابة الوصف الإقناعي', 'التسعير والهامش', 'حزم المنتجات Bundles'],
    'ads': ['حملات Meta', 'حملات Google', 'إعلانات TikTok', 'إعلانات Snapchat'],
    'sales_page': ['هيكلة صفحة الهبوط', 'العروض الخاصة', 'عناصر الإقناع الاجتماعي', 'سلاسة الطلب السريع'],
    'operations': ['شركات الشحن', 'بوابات الدفع', 'إدارة المخزون', 'خدمة العملاء'],
    'analytics': ['تتبع السلة المهجورة', 'بكسل التتبع Pixel', 'معدل LTV للعملاء', 'تقارير أداء المنتجات'],
  };

  final Map<String, List<String>> _subItemsEn = {
    // Moharek
    'seo': ['Technical SEO', 'On-Page SEO', 'Keywords Strategy', 'Blog'],
    'content': ['Articles', 'Service Pages', 'Short Videos', 'Search Content'],
    'ai_visibility': ['ChatGPT Presence', 'Gemini Presence', 'Perplexity', 'AI Optimization'],
    'trust': ['Reviews', 'Google Business', 'Reputation', 'Directories'],
    'conversion': ['Landing Page Opt', 'CTA Strategy', 'WhatsApp Tracking', 'Lead Forms'],
    // Rabhan
    'store': ['Brand Identity', 'UI/UX Design', 'Page Speed', 'Checkout UX'],
    'product': ['Product Images', 'Copywriting Description', 'Pricing & Margin', 'Product Bundles'],
    'ads': ['Meta Campaigns', 'Google Ads', 'TikTok Ads', 'Snapchat Ads'],
    'sales_page': ['Landing Page Structure', 'Special Offers', 'Social Proof', 'Express Checkout Flow'],
    'operations': ['Shipping Carriers', 'Payment Gateways', 'Inventory Management', 'Customer Support'],
    'analytics': ['Abandoned Cart Tracking', 'Tracking Pixels', 'Customer LTV', 'Product Analytics Reports'],
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
            _buildEngineItem(widget.isAr ? 'المتجر' : 'Store', 'store', AppTheme.primaryGreen),
            _buildEngineItem(widget.isAr ? 'المنتجات' : 'Product', 'product', Colors.purpleAccent),
            _buildEngineItem(widget.isAr ? 'الإعلانات' : 'Ads', 'ads', AppTheme.primaryBlue),
            _buildEngineItem(widget.isAr ? 'صفحات البيع' : 'Sales Page', 'sales_page', Colors.amber),
            _buildEngineItem(widget.isAr ? 'العمليات' : 'Operations', 'operations', Colors.orangeAccent),
            _buildEngineItem(widget.isAr ? 'التحليلات' : 'Analytics', 'analytics', Colors.pinkAccent),
          ] else ...[
            _buildEngineItem('SEO', 'seo', AppTheme.primaryGreen),
            _buildEngineItem(widget.isAr ? 'المحتوى' : 'Content', 'content', Colors.purpleAccent),
            _buildEngineItem(widget.isAr ? 'الظهور AI' : 'AI Visibility', 'ai_visibility', AppTheme.primaryBlue),
            _buildEngineItem(widget.isAr ? 'الثقة والتقييمات' : 'Trust Engine', 'trust', Colors.amber),
            _buildEngineItem(widget.isAr ? 'تحسين التحويل' : 'Conversion', 'conversion', Colors.pinkAccent),
          ],
        ],
      ),
    );
  }

  Widget _buildEngineItem(String label, String key, Color color) {
    final isExpanded = _expandedEngine == key;
    
    // Find matching EngineProgress model from list
    final engine = widget.engineProgressList.firstWhere(
      (e) => e.engine == key,
      orElse: () => EngineProgress(
        id: '',
        projectId: widget.projectId,
        engine: key,
        progressPercent: 0,
        updatedAt: DateTime.now(),
      ),
    );

    // Decode checked steps
    List<String> checkedSteps = [];
    if (engine.statusNotes != null && engine.statusNotes!.isNotEmpty) {
      try {
        final decoded = jsonDecode(engine.statusNotes!);
        if (decoded is List) {
          checkedSteps = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    final steps = StrategyScreen.engineSteps[key] ?? [];
    final totalSteps = steps.length;
    
    // Calculate progress based on checklist
    final double value = totalSteps > 0 ? (checkedSteps.length / totalSteps) : 0.0;
    final progressPercent = (value * 100).toInt();

    final isEditable = widget.userRole == 'admin' || widget.userRole == 'account_manager';

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
                        '${ArabicFormatter.number(progressPercent, isAr: widget.isAr)}%',
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
              if (isExpanded) ...[
                const SizedBox(height: 16),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 12),
                if (_isUpdating)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: LinearProgressIndicator(color: AppTheme.primaryGreen, minHeight: 2),
                  ),
                if (steps.isNotEmpty)
                  Column(
                    children: steps.map((step) {
                      final enText = step['en']!;
                      final arText = step['ar']!;
                      final displayText = widget.isAr ? arText : enText;
                      final isChecked = checkedSteps.contains(enText);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            if (isEditable)
                              Checkbox(
                                value: isChecked,
                                activeColor: color,
                                checkColor: Colors.black,
                                side: const BorderSide(color: Colors.white30),
                                onChanged: _isUpdating
                                    ? null
                                    : (val) async {
                                        setState(() {
                                          _isUpdating = true;
                                        });

                                        final newChecked = List<String>.from(checkedSteps);
                                        if (val == true) {
                                          newChecked.add(enText);
                                        } else {
                                          newChecked.remove(enText);
                                        }

                                        final newPercent = ((newChecked.length / totalSteps) * 100).toInt();
                                        final client = Supabase.instance.client;

                                        try {
                                          if (engine.id.isNotEmpty) {
                                            await client.from('engine_progress').update({
                                              'progress_percent': newPercent,
                                              'status_notes': jsonEncode(newChecked),
                                              'updated_at': DateTime.now().toIso8601String(),
                                            }).eq('id', engine.id);
                                          } else {
                                            await client.from('engine_progress').insert({
                                              'project_id': widget.projectId,
                                              'engine': key,
                                              'progress_percent': newPercent,
                                              'status_notes': jsonEncode(newChecked),
                                              'updated_at': DateTime.now().toIso8601String(),
                                            });
                                          }

                                          // Sync main growth engine health if action provider exists
                                          try {
                                            final actions = ref.read(adminActionsProvider);
                                            await actions.updateEngineProgress({
                                              'project_id': widget.projectId,
                                              'engine': key,
                                              'progress_percent': newPercent,
                                            });
                                          } catch (_) {}

                                          ref.invalidate(engineProgressListProvider);
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.redAccent),
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
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                child: Icon(
                                  isChecked ? Icons.check_box : Icons.check_box_outline_blank,
                                  color: isChecked ? color : Colors.white30,
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
                  )
                else ...[
                  // Fallback to static chips if steps list is empty
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ((widget.isAr ? _subItemsAr[key] : _subItemsEn[key]) ?? []).map((item) => Container(
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
