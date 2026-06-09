import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/core/config/app_config.dart';
import 'package:file_picker/file_picker.dart';
import 'package:moharek_app/shared/services/wordpress_upload_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:moharek_app/features/notifications/data/notifications_provider.dart';

class ResultsTab extends ConsumerWidget {
  final String pid;
  const ResultsTab({super.key, required this.pid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.markProjectNotificationsAsRead(pid, 'metrics');
      ref.invalidate(notificationsProvider);
    });

    final resultsAsync = ref.watch(projectResultsProvider(pid));
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_metric_$pid',
        backgroundColor: AppTheme.primaryGreen,
        onPressed: () => _showEditResult(context, ref, null),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: resultsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
        data: (results) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. Performance Snapshots Control Panel
              PerformanceSnapshotsControl(pid: pid, results: results),
              const SizedBox(height: 24),

              // 2. Section Header for History
              Text(
                isAr ? 'سجل النتائج والقياسات' : 'Results History Log',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // 3. Historical Logs List
              if (results.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      isAr ? 'لا توجد نتائج تاريخية مسجلة بعد' : 'No historical results logged yet',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...results.map((r) => _buildResultRow(context, ref, r)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResultRow(BuildContext context, WidgetRef ref, Map<String, dynamic> r) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        (r['result_type'] ?? 'general').toString().toUpperCase(),
                        style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(r['metric_label'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${r['metric_value']} ${r['metric_unit'] ?? ''}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                if (r['file_url'] != null && r['file_url'].toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final uri = Uri.tryParse(r['file_url'].toString());
                      if (uri != null) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.attach_file, color: AppTheme.primaryGreen, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          isAr ? 'عرض المرفق / لقطة الشاشة' : 'View Attachment / Screenshot',
                          style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 12, decoration: TextDecoration.underline),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryGreen, size: 18),
            onPressed: () => _showEditResult(context, ref, r),
            tooltip: isAr ? 'تعديل' : 'Edit',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
            onPressed: () => _confirmDelete(context, ref, r),
            tooltip: isAr ? 'حذف' : 'Delete',
          ),
        ],
      ),
    );
  }

  void _showEditResult(BuildContext context, WidgetRef ref, Map<String, dynamic>? r) {
    final isEditing = r != null;
    final isRabhan = AppConfig.flavorName == 'rabhan';
    final labelCtrl = TextEditingController(text: r?['metric_label'] ?? '');
    final valCtrl = TextEditingController(text: r?['metric_value']?.toString() ?? '');
    final unitCtrl = TextEditingController(text: r?['metric_unit'] ?? '');
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    
    final types = isRabhan
        ? ['store', 'product', 'ads', 'sales_page', 'operations', 'analytics', 'general']
        : ['seo', 'ads', 'ai_visibility', 'trust_engine', 'conversion', 'leads', 'general'];

    String selectedType = r?['result_type'] ?? (isRabhan ? 'store' : 'seo');
    if (!types.contains(selectedType)) {
      selectedType = isRabhan ? 'store' : 'seo';
    }
    bool saving = false;

    String? selectedFileUrl = r?['file_url'];
    String? pickedFileName;
    PlatformFile? pickedFile;
    bool uploadingFile = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isEditing 
                ? (isAr ? 'تعديل النتيجة' : 'Edit Result') 
                : (isAr ? 'تسجيل نتيجة' : 'Add Result'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedType,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1E293B),
                      items: types.map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.toUpperCase(), style: const TextStyle(color: Colors.white)),
                      )).toList(),
                      onChanged: (v) => setState(() => selectedType = v!),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _field(labelCtrl, isAr ? 'اسم المقياس (مثال: زيارات SEO)' : 'Metric label', Icons.label_outline),
                const SizedBox(height: 12),
                _field(valCtrl, isAr ? 'القيمة' : 'Value', Icons.numbers, type: TextInputType.number),
                const SizedBox(height: 12),
                _field(unitCtrl, isAr ? 'الوحدة (مثال: %, زيارة)' : 'Unit', Icons.straighten),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        pickedFileName ?? (selectedFileUrl != null ? (isAr ? 'مرفق موجود' : 'Attachment exists') : (isAr ? 'لا يوجد ملف' : 'No attachment')),
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (uploadingFile)
                      const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGreen))
                    else
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
                        onPressed: () async {
                          final result = await FilePicker.pickFiles(withData: true);
                          if (result != null) {
                            setState(() {
                              pickedFile = result.files.first;
                              pickedFileName = pickedFile!.name;
                            });
                          }
                        },
                        icon: const Icon(Icons.image_outlined, size: 16),
                        label: Text(isAr ? 'إرفاق ملف' : 'Attach File'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isAr ? 'إلغاء' : 'Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.black),
              onPressed: saving ? null : () async {
                if (labelCtrl.text.trim().isEmpty || valCtrl.text.trim().isEmpty) return;
                setState(() => saving = true);
                try {
                  String? fileUrl = selectedFileUrl;
                  if (pickedFile != null) {
                    setState(() => uploadingFile = true);
                    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${pickedFile!.name}';
                    if (pickedFile!.bytes != null) {
                      fileUrl = await WordPressUploadService.uploadBytes(pickedFile!.bytes!, fileName);
                    } else if (pickedFile!.path != null) {
                      fileUrl = await WordPressUploadService.uploadFile(pickedFile!.path!, fileName);
                    }
                  }

                  final actions = ref.read(adminActionsProvider);
                  if (isEditing) {
                    await actions.updateResult(r['id'], {
                      'result_type': selectedType,
                      'metric_label': labelCtrl.text.trim(),
                      'metric_value': double.tryParse(valCtrl.text),
                      'metric_unit': unitCtrl.text.trim(),
                      'file_url': fileUrl,
                    });
                    ref.invalidate(projectResultsProvider(pid));
                  } else {
                    await actions.createResult({
                      'project_id': pid,
                      'result_type': selectedType,
                      'metric_name': labelCtrl.text.trim().toLowerCase().replaceAll(' ', '_'),
                      'metric_label': labelCtrl.text.trim(),
                      'metric_value': double.tryParse(valCtrl.text),
                      'metric_unit': unitCtrl.text.trim(),
                      'recorded_at': DateTime.now().toIso8601String(),
                      'file_url': fileUrl,
                    });
                    ref.invalidate(projectResultsProvider(pid));
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                } finally {
                  if (ctx.mounted) setState(() => saving = false);
                }
              },
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : Text(
                      isEditing 
                          ? (isAr ? 'حفظ' : 'Save') 
                          : (isAr ? 'تسجيل' : 'Add'), 
                      style: const TextStyle(fontWeight: FontWeight.bold)
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Map<String, dynamic> r) async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(isAr ? 'حذف النتيجة' : 'Delete Result', style: const TextStyle(color: Colors.white)),
        content: Text(
          isAr ? 'حذف "${r['metric_label']}"؟' : 'Delete "${r['metric_label']}"?', 
          style: const TextStyle(color: Color(0xFF94A3B8))
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(isAr ? 'إلغاء' : 'Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isAr ? 'حذف' : 'Delete', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(adminActionsProvider).deleteResult(r['id'], r['metric_label'] ?? '');
      ref.invalidate(projectResultsProvider(pid));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'تم الحذف ✅' : 'Deleted successfully ✅'), 
            backgroundColor: AppTheme.primaryGreen
          )
        );
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon, {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF64748B)),
        prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 18),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        border: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(10))),
      ),
    );
  }
}

// ── DEDICATED CONTROL FOR MAIN PERFORMANCE METRICS ──
class PerformanceSnapshotsControl extends ConsumerStatefulWidget {
  final String pid;
  final List<Map<String, dynamic>> results;
  const PerformanceSnapshotsControl({super.key, required this.pid, required this.results});

  @override
  ConsumerState<PerformanceSnapshotsControl> createState() => _PerformanceSnapshotsControlState();
}

class _PerformanceSnapshotsControlState extends ConsumerState<PerformanceSnapshotsControl> {
  final _trafficCtrl = TextEditingController();
  final _spendCtrl = TextEditingController();
  final _keywordCtrl = TextEditingController();

  PlatformFile? _trafficFile;
  PlatformFile? _spendFile;
  PlatformFile? _keywordFile;

  bool _isSavingTraffic = false;
  bool _isSavingSpend = false;
  bool _isSavingKeyword = false;

  @override
  void dispose() {
    _trafficCtrl.dispose();
    _spendCtrl.dispose();
    _keywordCtrl.dispose();
    super.dispose();
  }

  String _getLatestValue(String type, String name) {
    final matches = widget.results.where((r) {
      final isTypeMatch = (r['result_type'] ?? '').toString().toLowerCase() == type.toLowerCase();
      if (!isTypeMatch) return false;

      final metricNameLower = (r['metric_name'] ?? '').toString().toLowerCase();
      final metricLabelLower = (r['metric_label'] ?? '').toString().toLowerCase();

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
    }).toList();

    if (matches.isEmpty) return '—';
    final val = matches.first['metric_value'];
    final unit = matches.first['metric_unit'] ?? '';
    return '$val $unit';
  }

  String? _getLatestFileUrl(String type, String name) {
    final matches = widget.results.where((r) {
      final isTypeMatch = (r['result_type'] ?? '').toString().toLowerCase() == type.toLowerCase();
      if (!isTypeMatch) return false;

      final metricNameLower = (r['metric_name'] ?? '').toString().toLowerCase();
      final metricLabelLower = (r['metric_label'] ?? '').toString().toLowerCase();

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
    }).toList();

    if (matches.isEmpty) return null;
    return matches.first['file_url']?.toString();
  }

  Future<void> _updateMetric({
    required String metricType,
    required String metricName,
    required String metricLabel,
    required String metricUnit,
    required String valueText,
    required PlatformFile? pickedFile,
    required String? existingFileUrl,
    required Function(bool) setSaving,
  }) async {
    final value = double.tryParse(valueText.trim());
    if (value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال رقم صحيح / Please enter a valid number'), 
          backgroundColor: Colors.red
        ),
      );
      return;
    }

    setSaving(true);
    try {
      String? fileUrl = existingFileUrl;
      if (pickedFile != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
        if (pickedFile.bytes != null) {
          fileUrl = await WordPressUploadService.uploadBytes(pickedFile.bytes!, fileName);
        } else if (pickedFile.path != null) {
          fileUrl = await WordPressUploadService.uploadFile(pickedFile.path!, fileName);
        }
      }

      await ref.read(adminActionsProvider).createResult({
        'project_id': widget.pid,
        'result_type': metricType,
        'metric_name': metricName,
        'metric_label': metricLabel,
        'metric_value': value,
        'metric_unit': metricUnit,
        'recorded_at': DateTime.now().toIso8601String(),
        'file_url': fileUrl,
      });

      // Clear the local inputs on success
      if (metricName == 'traffic') {
        _trafficCtrl.clear();
        setState(() => _trafficFile = null);
      } else if (metricName == 'spend') {
        _spendCtrl.clear();
        setState(() => _spendFile = null);
      } else if (metricName == 'keyword') {
        _keywordCtrl.clear();
        setState(() => _keywordFile = null);
      }

      ref.invalidate(projectResultsProvider(widget.pid));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث لقطة الأداء بنجاح ✅'), backgroundColor: AppTheme.primaryGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء التحديث: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setSaving(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final latestTraffic = _getLatestValue('seo', 'traffic');
    final latestTrafficFile = _getLatestFileUrl('seo', 'traffic');

    final latestSpend = _getLatestValue('ads', 'spend');
    final latestSpendFile = _getLatestFileUrl('ads', 'spend');

    final latestKeyword = _getLatestValue('seo', 'keyword');
    final latestKeywordFile = _getLatestFileUrl('seo', 'keyword');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, color: AppTheme.primaryGreen, size: 22),
              const SizedBox(width: 8),
              Text(
                isAr ? 'لقطات الأداء (الرئيسية في التطبيق)' : 'Performance Snapshots (App Home Cards)',
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 24),

          // 1. Organic Traffic
          _buildMetricRow(
            titleAr: 'الزيارات الطبيعية (Organic Traffic)',
            titleEn: 'Organic Traffic',
            icon: Icons.show_chart,
            color: AppTheme.primaryGreen,
            currentValue: latestTraffic,
            currentFileUrl: latestTrafficFile,
            controller: _trafficCtrl,
            pickedFile: _trafficFile,
            onPickFile: () async {
              final result = await FilePicker.pickFiles(withData: true);
              if (result != null) {
                setState(() => _trafficFile = result.files.first);
              }
            },
            isSaving: _isSavingTraffic,
            onUpdate: () => _updateMetric(
              metricType: 'seo',
              metricName: 'traffic',
              metricLabel: isAr ? 'الزيارات الطبيعية' : 'Organic Traffic',
              metricUnit: isAr ? 'زيارة' : 'Visits',
              valueText: _trafficCtrl.text,
              pickedFile: _trafficFile,
              existingFileUrl: latestTrafficFile,
              setSaving: (v) => setState(() => _isSavingTraffic = v),
            ),
          ),

          // 2. Ad Spend
          _buildMetricRow(
            titleAr: 'الإنفاق الإعلاني (Ad Spend)',
            titleEn: 'Ad Spend',
            icon: Icons.monetization_on_outlined,
            color: AppTheme.primaryBlue,
            currentValue: latestSpend,
            currentFileUrl: latestSpendFile,
            controller: _spendCtrl,
            pickedFile: _spendFile,
            onPickFile: () async {
              final result = await FilePicker.pickFiles(withData: true);
              if (result != null) {
                setState(() => _spendFile = result.files.first);
              }
            },
            isSaving: _isSavingSpend,
            onUpdate: () => _updateMetric(
              metricType: 'ads',
              metricName: 'spend',
              metricLabel: isAr ? 'الإنفاق الإعلاني' : 'Ad Spend',
              metricUnit: 'SAR',
              valueText: _spendCtrl.text,
              pickedFile: _spendFile,
              existingFileUrl: latestSpendFile,
              setSaving: (v) => setState(() => _isSavingSpend = v),
            ),
          ),

          // 3. Keywords
          _buildMetricRow(
            titleAr: 'الكلمات المفتاحية (Keywords)',
            titleEn: 'Keywords',
            icon: Icons.bar_chart,
            color: Colors.orange,
            currentValue: latestKeyword,
            currentFileUrl: latestKeywordFile,
            controller: _keywordCtrl,
            pickedFile: _keywordFile,
            onPickFile: () async {
              final result = await FilePicker.pickFiles(withData: true);
              if (result != null) {
                setState(() => _keywordFile = result.files.first);
              }
            },
            isSaving: _isSavingKeyword,
            onUpdate: () => _updateMetric(
              metricType: 'seo',
              metricName: 'keyword',
              metricLabel: isAr ? 'الكلمات المفتاحية' : 'Keywords',
              metricUnit: isAr ? 'كلمة' : 'Keywords',
              valueText: _keywordCtrl.text,
              pickedFile: _keywordFile,
              existingFileUrl: latestKeywordFile,
              setSaving: (v) => setState(() => _isSavingKeyword = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow({
    required String titleAr,
    required String titleEn,
    required IconData icon,
    required Color color,
    required String currentValue,
    required String? currentFileUrl,
    required TextEditingController controller,
    required PlatformFile? pickedFile,
    required VoidCallback onPickFile,
    required bool isSaving,
    required VoidCallback onUpdate,
  }) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAr ? titleAr : titleEn,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${isAr ? 'الحالي' : 'Current'}: $currentValue',
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              if (currentFileUrl != null && currentFileUrl.isNotEmpty) ...[
                const SizedBox(width: 6),
                IconButton(
                  icon: Icon(Icons.image_outlined, color: color, size: 16),
                  visualDensity: VisualDensity.compact,
                  tooltip: isAr ? 'عرض لقطة الشاشة' : 'View Screenshot',
                  onPressed: () async {
                    final uri = Uri.tryParse(currentFileUrl);
                    if (uri != null) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: isAr ? 'القيمة الجديدة' : 'New value',
                      hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 38,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: onPickFile,
                  icon: Icon(
                    pickedFile != null ? Icons.check_circle_outline : Icons.attach_file,
                    size: 14,
                    color: pickedFile != null ? AppTheme.primaryGreen : Colors.white70,
                  ),
                  label: Text(
                    pickedFile != null 
                        ? (pickedFile.name.length > 10 ? '${pickedFile.name.substring(0, 8)}...' : pickedFile.name)
                        : (isAr ? 'لقطة شاشة' : 'File'),
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 38,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: isSaving ? null : onUpdate,
                  child: isSaving
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : Text(
                          isAr ? 'تحديث' : 'Update',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
