import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BriefField {
  final String key;
  final String label;
  final String type; // 'text', 'bool', or 'dropdown'
  final List<String>? options;
  BriefField(this.key, this.label, this.type, {this.options});
}

final briefProjectDetailFutureProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, projectId) async {
  final client = ref.watch(supabaseClientProvider);
  final response = await client.from('projects').select().eq('id', projectId).maybeSingle();
  return response ?? {};
});

class BriefTab extends ConsumerStatefulWidget {
  final String pid;
  const BriefTab({super.key, required this.pid});

  @override
  ConsumerState<BriefTab> createState() => _BriefTabState();
}

class _BriefTabState extends ConsumerState<BriefTab> {
  final TextEditingController _notesController = TextEditingController();
  bool _isSavingNotes = false;
  bool _isSavingBrief = false;
  bool _isEditingBrief = false;
  Map<String, dynamic> _briefData = {};

  // ── Sections matching the official CSV template ──────────────────────────
  final Map<String, List<BriefField>> _sections = {
    'المنصة والتواصل': [
      BriefField('platform_mail',        'إيميل المنصة (Platform Email)',   'text'),
      BriefField('platform_password',    'كلمة المرور (Password)',          'text'),
      BriefField('best_contact_time',    'الوقت المناسب للتواصل',           'text'),
      BriefField('employment_type',      'شغال في دوام ولا عمل حر؟',       'dropdown', options: [
        'موظف بدوام كامل',
        'عمل حر',
        'رائد أعمال / صاحب عمل',
        'غير ذلك',
      ]),
      BriefField('business_structure',   'مؤسسة يملكها شخص أو شركة؟',     'dropdown', options: [
        'مؤسسة فردية',
        'شركة',
        'شراكة',
        'غير ذلك',
      ]),
      BriefField('investment_timeline',  'مدة الاستثمار المتوقعة للحصول على نتائج', 'dropdown', options: [
        'أقل من ٣ أشهر',
        'من ٣ إلى ٦ أشهر',
        'من ٦ إلى ١٢ شهر',
        'أكثر من سنة',
      ]),
      BriefField('store_age',            'تاريخ بدء المتجر أو مدة تواجده', 'text'),
      BriefField('has_offline_store',    'في مكان على أرض الواقع ولا لا؟', 'text'),
      BriefField('store_market_stage',   'شايف متجرك في أي مرحلة أو وضع من السوق؟', 'dropdown', options: [
        'مرحلة البداية',
        'مرحلة النمو',
        'مرحلة النضج',
      ]),
    ],
    'التحليل والأهداف': [
      BriefField('current_future_goals',   'أهداف المتجر في الفترة الحالية والفترة القادمة', 'text'),
      BriefField('target_age_group',       'أكثر فئة عمرية بتتفاعل معنا',                   'multiselect', options: [
        '١٣-١٧',
        '١٨-٢٤',
        '٢٥-٣٤',
        '٣٥-٤٤',
        '٤٥-٥٤',
        '٥٥+',
        'جميع الفئات العمرية',
      ]),
      BriefField('best_selling_products',  'أكثر المنتجات مبيعاً للمتجر أو المكان على أرض الواقع', 'text'),
      BriefField('competitors',            'شايف مين المنافسين لنشاطك؟',                     'text'),
      BriefField('competitive_advantage',  'ايه الميزة التنافسية اللي عندك وشايف إنك متميز بيها عن منافسينك؟', 'text'),
    ],
    'الحسابات الإعلانية والتسويق': [
      BriefField('has_ad_snapchat',         'حساب إعلاني سناب شات؟',  'bool'),
      BriefField('has_ad_meta',             'حساب إعلاني ميتا؟',       'bool'),
      BriefField('has_ad_google',           'حساب إعلاني جوجل؟',       'bool'),
      BriefField('has_ad_tiktok',           'حساب إعلاني تيك توك؟',    'bool'),
      BriefField('past_campaigns_details',  'هل يوجد حملات إعلانية سابقة؟ على أي منصة؟ مردودها كان مرضي؟', 'text'),
      BriefField('past_marketing_agency',   'هل تم التعامل مع شركة تسويق من قبل؟',            'text'),
      BriefField('past_seo',                'هل تم عمل سيو للموقع من قبل؟',                   'text'),
      BriefField('ad_budget',               'الميزانية المتاحة للحملات الإعلانية',             'text'),
    ],
    'المنتجات والشحن': [
      BriefField('shipping_service_details', 'خدمة الشحن: أقصى قيمة؟ أقصى مدة؟ أقصى منطقة بتوصل شحن لها؟', 'text'),
      BriefField('past_shipping_problems',   'هل في مشاكل في الشحن تواجه العميل قبل كدا؟', 'text'),
      BriefField('shipping_companies',       'اذكر شركات الشحن المتعاقد معها',              'text'),
      BriefField('product_source',           'أنت مالك المنتج ومستورده؟ ولا دروب شيبنج؟',  'dropdown', options: [
        'مالك ومستورد',
        'دروب شيبنج',
        'كلاهما',
      ]),
      BriefField('inventory_quantities',     'كميات المنتجات المتاحة والمنتجات المتاح منها كميات كبيرة والكميات قد إيه؟', 'text'),
      BriefField('pricing_vs_competitors',   'رنج السعر بالنسبة للمنافسين / وطريقة التسعير', 'text'),
      BriefField('profit_margin_range',      'هامش الربح يتراوح من كام لكام %؟',            'text'),
      BriefField('minimum_roas',             'أفضل (ROAS) علشان يكون في مكسب؟',             'text'),
      BriefField('product_photos_link',      'أرسلنا صور للمنتجات لو متاحة بجودة عالية (رابط أو مرفق)', 'text'),
      BriefField('brand_identity_link',      'في هوية خاصة بالمتجر؟ لو متاح أرسلها لنا (رابط)', 'text'),
    ],
    'الموقع ونظام الدفع': [
      BriefField('payment_mada',          'مدى؟',                   'bool'),
      BriefField('payment_visa',          'فيزا؟',                   'bool'),
      BriefField('payment_mastercard',    'ماستر كارد؟',             'bool'),
      BriefField('payment_applepay',      'أبل باي؟',               'bool'),
      BriefField('payment_stcpay',        'STC Pay؟',               'bool'),
      BriefField('payment_tabby',         'تابي (Tabby)؟',          'bool'),
      BriefField('payment_tamara',        'تمارا (Tamara)؟',        'bool'),
      BriefField('payment_cod',           'الدفع عند الاستلام؟',    'bool'),
      BriefField('payment_bank_transfer', 'تحويل بنكي؟',            'bool'),
      BriefField('active_discount_code',  'هل يوجد كود خصم فعال؟', 'text'),
      BriefField('past_technical_issues', 'هل يوجد أي مشاكل تقنية بالمتجر قابلتك قبل كده؟ / أو العملاء اشتكوا من أي مشاكل؟', 'text'),
    ],
    'الربط والتكاملات': [
      BriefField('integration_gsc',     'جوجل سيرش كونسل (Google Search Console)؟', 'bool'),
      BriefField('integration_gtm',     'تاج مانجر (Google Tag Manager)؟',           'bool'),
      BriefField('integration_ga4',     'أنالتكس (Google Analytics / GA4)؟',         'bool'),
      BriefField('integration_yandex',  'ياندكس (Yandex Metrica)؟',                  'bool'),
      BriefField('integration_clarity', 'كلارتي (Microsoft Clarity)؟',               'bool'),
      BriefField('integration_gmc',     'جوجل ميرشنت (Google Merchant Center)؟',     'bool'),
      BriefField('integration_gmb',     'جوجل ماي بيزنس (Google My Business)؟',      'bool'),
    ],
    'السلات المتروكة والولاء': [
      BriefField('abandoned_cart_cartat',   'كيفية التعامل مع السلات المتروكة - كارتات؟',  'bool'),
      BriefField('abandoned_cart_carezone', 'كيفية التعامل مع السلات المتروكة - كيرزون؟', 'bool'),
      BriefField('has_loyalty_program',     'هل متاح برنامج ولاء للعملاء؟',               'text'),
    ],
    'اكسيس وملاحظات إضافية': [
      BriefField('additional_notes',    'ملاحظات إضافية',                                        'text'),
    ],
  };

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveAccountNotes() async {
    setState(() => _isSavingNotes = true);
    _briefData['account_notes'] = _notesController.text;
    try {
      await Supabase.instance.client
          .from('projects')
          .update({'client_brief': _briefData})
          .eq('id', widget.pid);
      ref.invalidate(briefProjectDetailFutureProvider(widget.pid));
      ref.invalidate(adminProjectDetailStream(widget.pid));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ ملاحظات الأكونت بنجاح ✅')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الحفظ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingNotes = false);
    }
  }

  Future<void> _saveBriefData() async {
    setState(() => _isSavingBrief = true);
    try {
      await Supabase.instance.client
          .from('projects')
          .update({'client_brief': _briefData})
          .eq('id', widget.pid);
      ref.invalidate(briefProjectDetailFutureProvider(widget.pid));
      ref.invalidate(adminProjectDetailStream(widget.pid));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث بريف المشروع بنجاح ✅')),
        );
        setState(() => _isEditingBrief = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الحفظ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingBrief = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(briefProjectDetailFutureProvider(widget.pid));
    final profileAsync = ref.watch(profileProvider);
    final userRole = profileAsync.valueOrNull?.role;
    final isClient = userRole == 'client' || userRole == null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: projectAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (project) {
          if (project.isEmpty) {
            return const Center(child: Text('المشروع غير موجود'));
          }

          final briefRaw = project['client_brief'];
          if (_briefData.isEmpty) {
            if (briefRaw is Map) {
              _briefData = Map<String, dynamic>.from(briefRaw);
            } else if (briefRaw is String) {
              try {
                _briefData = Map<String, dynamic>.from(jsonDecode(briefRaw));
              } catch (_) {}
            }
            _notesController.text = _briefData['account_notes']?.toString() ?? '';
          }

          return Directionality(
            textDirection: TextDirection.rtl,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // ── Top action bar ─────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isEditingBrief ? 'تعديل البريف' : 'بريف المشروع',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        if (_isEditingBrief) ...[
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isEditingBrief = false;
                                _briefData.clear();
                              });
                            },
                            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _isSavingBrief ? null : _saveBriefData,
                            icon: _isSavingBrief
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                : const Icon(Icons.check, size: 16),
                            label: const Text('حفظ البريف'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.black,
                            ),
                          ),
                        ] else
                          ElevatedButton.icon(
                            onPressed: () => setState(() => _isEditingBrief = true),
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('تعديل البريف'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Account Manager / Admin Private Notes ───────────────
                if (!_isEditingBrief && !isClient)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ملاحظات الأكونت (خاصة - غير مرئية للعميل)',
                          style: TextStyle(color: AppTheme.primaryGreen, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _notesController,
                          maxLines: 4,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'أضف ملاحظات الأكونت الخاصة هنا...',
                            hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                            filled: true,
                            fillColor: Color(0xFF0F172A),
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _isSavingNotes ? null : _saveAccountNotes,
                            child: _isSavingNotes
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                : const Text('حفظ ملاحظات الأكونت', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Section Cards ───────────────────────────────────────
                ..._sections.entries.map((sec) => _buildSectionCard(
                      title: sec.key,
                      icon: _getIconForSection(sec.key),
                      color: _getColorForSection(sec.key),
                      fields: sec.value,
                    )),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Icon + Colour helpers (keyed by Arabic section name) ────────────────
  IconData _getIconForSection(String name) {
    if (name.contains('المنصة'))         return Icons.store_outlined;
    if (name.contains('التحليل'))        return Icons.rocket_launch_outlined;
    if (name.contains('الإعلانية'))      return Icons.campaign_outlined;
    if (name.contains('المنتجات'))       return Icons.inventory_2_outlined;
    if (name.contains('الموقع'))         return Icons.payments_outlined;
    if (name.contains('الربط'))          return Icons.analytics_outlined;
    if (name.contains('السلات'))         return Icons.shopping_cart_outlined;
    return Icons.notes_outlined;
  }

  Color _getColorForSection(String name) {
    if (name.contains('المنصة'))         return Colors.blue;
    if (name.contains('التحليل'))        return Colors.orange;
    if (name.contains('الإعلانية'))      return Colors.purple;
    if (name.contains('المنتجات'))       return Colors.teal;
    if (name.contains('الموقع'))         return Colors.green;
    if (name.contains('الربط'))          return Colors.indigo;
    if (name.contains('السلات'))         return Colors.pink;
    return Colors.blueGrey;
  }

  // ── Section Card Builder ─────────────────────────────────────────────────
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<BriefField> fields,
  }) {
    final fieldsToShow = <Widget>[];

    for (final field in fields) {
      final val = _briefData[field.key];
      final isBool = field.type == 'bool';
      final isDropdown = field.type == 'dropdown';

      if (_isEditingBrief) {
        if (isBool) {
          fieldsToShow.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      field.label,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  Switch(
                    value: val == true,
                    activeThumbColor: AppTheme.primaryGreen,
                    activeTrackColor: AppTheme.primaryGreen.withValues(alpha: 0.4),
                    onChanged: (newVal) => setState(() => _briefData[field.key] = newVal),
                  ),
                ],
              ),
            ),
          );
        } else if (isDropdown) {
          final dropdownOptions = List<String>.from(field.options ?? []);
          final valStr = val?.toString() ?? '';
          if (valStr.isNotEmpty && !dropdownOptions.contains(valStr)) {
            dropdownOptions.add(valStr);
          }
          fieldsToShow.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(field.label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: valStr.isNotEmpty && dropdownOptions.contains(valStr) ? valStr : null,
                    dropdownColor: AppTheme.cardColor,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Color(0xFF0F172A),
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: dropdownOptions.map((option) {
                      return DropdownMenuItem<String>(
                        value: option,
                        child: Text(option, textDirection: TextDirection.rtl),
                      );
                    }).toList(),
                    onChanged: (newVal) {
                      if (newVal != null) {
                        setState(() {
                          _briefData[field.key] = newVal;
                        });
                      }
                    },
                    hint: const Text('اختر من القائمة...', style: TextStyle(color: Colors.white30, fontSize: 13)),
                  ),
                ],
              ),
            ),
          );
        } else if (field.type == 'multiselect') {
          final options = List<String>.from(field.options ?? []);
          List<String> selectedItems = [];
          if (val is List) {
            selectedItems = List<String>.from(val);
          } else if (val is String && val.isNotEmpty) {
            selectedItems = val.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
          }
          fieldsToShow.add(
            Padding(
              key: ValueKey(field.key),
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(field.label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: options.map((option) {
                      final isSelected = selectedItems.contains(option);
                      return FilterChip(
                        label: Text(option),
                        selected: isSelected,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : Colors.white70,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        selectedColor: AppTheme.primaryGreen,
                        checkmarkColor: Colors.black,
                        backgroundColor: const Color(0xFF0F172A),
                        side: BorderSide(
                          color: isSelected ? AppTheme.primaryGreen : Colors.white10,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              selectedItems.add(option);
                            } else {
                              selectedItems.remove(option);
                            }
                            _briefData[field.key] = selectedItems;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        } else {
          fieldsToShow.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(field.label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  const SizedBox(height: 6),
                  TextFormField(
                    initialValue: val?.toString() ?? '',
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    maxLines: null,
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Color(0xFF0F172A),
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (newVal) => _briefData[field.key] = newVal,
                  ),
                ],
              ),
            ),
          );
        }
      } else {
        // View mode
        final isEmpty = val == null || (val is String && val.trim().isEmpty) || (val is List && val.isEmpty);
        String displayVal = isEmpty ? 'غير محدد' : '';
        if (!isEmpty) {
          if (isBool) {
            displayVal = val == true ? 'نعم ✅' : 'لا ❌';
          } else if (val is List) {
            displayVal = val.join('، ');
          } else {
            displayVal = val.toString();
          }
        }
        fieldsToShow.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(field.label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                const SizedBox(height: 4),
                SelectableText(
                  displayVal,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    color: isEmpty ? Colors.white24 : Colors.white,
                    fontSize: 13,
                    height: 1.4,
                    fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    if (fieldsToShow.isEmpty && title != 'اكسيس وملاحظات إضافية') {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 24),
          ...fieldsToShow,
          if (title == 'اكسيس وملاحظات إضافية') ...[
            if (fieldsToShow.isNotEmpty) const SizedBox(height: 12),
            _buildSocialMediaSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildSocialMediaSection() {
    final rawAccess = _briefData['social_media_access'];
    
    // Check if it's legacy string
    if (rawAccess is String && rawAccess.trim().isNotEmpty) {
      if (!_isEditingBrief) {
        // View mode for legacy string
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('اكسيس حسابات السوشيال ميديا', style: TextStyle(color: Colors.grey, fontSize: 11)),
            const SizedBox(height: 4),
            Text(
              rawAccess,
              textDirection: TextDirection.rtl,
              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
            ),
          ],
        );
      } else {
        // Edit mode with warning and migration button
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('اكسيس حسابات السوشيال ميديا', style: TextStyle(color: Colors.grey, fontSize: 11)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'تنبيه: لديك بيانات سوشيال ميديا بالنظام القديم:',
                          style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    rawAccess,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _briefData['social_media_access'] = <String, dynamic>{};
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    child: const Text('البدء بالتنسيق الجديد (سيتم مسح النص القديم)'),
                  ),
                ],
              ),
            ),
          ],
        );
      }
    }

    // Now handle Map format
    final Map<String, dynamic> accessMap = (rawAccess is Map) 
        ? Map<String, dynamic>.from(rawAccess) 
        : {};

    final platforms = [
      {'id': 'instagram', 'name': 'إنستغرام', 'icon': Icons.camera_alt_outlined, 'color': Colors.pink},
      {'id': 'snapchat', 'name': 'سناب شات', 'icon': Icons.snapchat_outlined, 'color': Colors.yellow},
      {'id': 'tiktok', 'name': 'تيك توك', 'icon': Icons.music_note_outlined, 'color': Colors.cyan},
      {'id': 'twitter', 'name': 'تويتر (X)', 'icon': Icons.close_outlined, 'color': Colors.white},
      {'id': 'youtube', 'name': 'يوتيوب', 'icon': Icons.play_circle_outline, 'color': Colors.red},
      {'id': 'facebook', 'name': 'فيسبوك', 'icon': Icons.facebook_outlined, 'color': Colors.blue},
      {'id': 'linkedin', 'name': 'لينكد إن', 'icon': Icons.work_outline, 'color': Colors.blueAccent},
    ];

    if (!_isEditingBrief) {
      // View mode
      bool hasData = false;
      for (final p in platforms) {
        final val = accessMap[p['id']];
        if (val != null) {
          if (val is Map) {
            final email = val['email']?.toString().trim() ?? '';
            final password = val['password']?.toString().trim() ?? '';
            if (email.isNotEmpty || password.isNotEmpty) {
              hasData = true;
              break;
            }
          } else if (val.toString().trim().isNotEmpty) {
            hasData = true;
            break;
          }
        }
      }

      if (!hasData) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('اكسيس حسابات السوشيال ميديا', style: TextStyle(color: Colors.grey, fontSize: 11)),
            const SizedBox(height: 4),
            const Text(
              'غير محدد',
              style: TextStyle(color: Colors.white24, fontSize: 13, fontStyle: FontStyle.italic),
            ),
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('اكسيس حسابات السوشيال ميديا', style: TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 8),
          ...platforms.where((p) {
            final val = accessMap[p['id']];
            if (val == null) return false;
            if (val is Map) {
              final email = val['email']?.toString().trim() ?? '';
              final password = val['password']?.toString().trim() ?? '';
              return email.isNotEmpty || password.isNotEmpty;
            }
            return val.toString().trim().isNotEmpty;
          }).map((p) {
            final id = p['id'] as String;
            final val = accessMap[id];
            
            String displayString = '';
            if (val is Map) {
              final email = val['email']?.toString() ?? '';
              final password = val['password']?.toString() ?? '';
              displayString = 'اسم المستخدم: $email | كلمة المرور: $password';
            } else {
              displayString = val?.toString() ?? '';
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Icon(p['icon'] as IconData, color: p['color'] as Color, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${p['name']}: ',
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: SelectableText(
                      displayString,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      );
    }

    // Edit mode
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'اكسيس حسابات السوشيال ميديا (اختر المنصات أولاً)',
          style: TextStyle(color: Colors.grey, fontSize: 11),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: platforms.map((p) {
            final id = p['id'] as String;
            final isSelected = accessMap.containsKey(id);
            return FilterChip(
              label: Text(p['name'] as String),
              selected: isSelected,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              selectedColor: AppTheme.primaryGreen,
              checkmarkColor: Colors.black,
              backgroundColor: const Color(0xFF0F172A),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    accessMap[id] = <String, dynamic>{'email': '', 'password': ''};
                  } else {
                    accessMap.remove(id);
                  }
                  _briefData['social_media_access'] = accessMap;
                });
              },
            );
          }).toList(),
        ),
        if (accessMap.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 16),
          ...platforms.where((p) => accessMap.containsKey(p['id'])).map((p) {
            final id = p['id'] as String;
            final dynamic rawCreds = accessMap[id];
            String email = '';
            String password = '';
            if (rawCreds is Map) {
              email = rawCreds['email']?.toString() ?? '';
              password = rawCreds['password']?.toString() ?? '';
            } else if (rawCreds is String) {
              email = rawCreds;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(p['icon'] as IconData, color: p['color'] as Color, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'بيانات دخول ${p['name']}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Username/Email Field
                  TextFormField(
                    key: ValueKey('${id}_email'),
                    initialValue: email,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'اسم المستخدم أو البريد الإلكتروني أو رابط الحساب الخاص بـ ${p['name']}',
                      hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (newVal) {
                      final currentMap = (accessMap[id] is Map)
                          ? Map<String, dynamic>.from(accessMap[id] as Map)
                          : <String, dynamic>{'password': password};
                      currentMap['email'] = newVal;
                      accessMap[id] = currentMap;
                      _briefData['social_media_access'] = accessMap;
                    },
                  ),
                  const SizedBox(height: 8),
                  // Password Field
                  TextFormField(
                    key: ValueKey('${id}_password'),
                    initialValue: password,
                    obscureText: true,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'كلمة المرور لـ ${p['name']}',
                      hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (newVal) {
                      final currentMap = (accessMap[id] is Map)
                          ? Map<String, dynamic>.from(accessMap[id] as Map)
                          : <String, dynamic>{'email': email};
                      currentMap['password'] = newVal;
                      accessMap[id] = currentMap;
                      _briefData['social_media_access'] = accessMap;
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}
