import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/features/rabhan/providers/metrics_provider.dart';
import 'package:moharek_app/shared/services/data_providers.dart';

class RabhanMetricsTab extends ConsumerWidget {
  final String pid;
  const RabhanMetricsTab({super.key, required this.pid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(projectMetricsHistoryProvider(pid));

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_metrics_$pid',
        backgroundColor: AppTheme.primaryGreen,
        onPressed: () => _showEditMetrics(context, ref, null),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
        error: (e, _) => Center(child: Text('خطأ: $e', style: const TextStyle(color: Colors.red))),
        data: (metrics) {
          if (metrics.isEmpty) {
            return const Center(child: Text('لا توجد تقارير أداء مسجلة', style: TextStyle(color: Colors.grey)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: metrics.length,
            itemBuilder: (context, index) {
              final m = metrics[index];
              final isPub = m['is_published'] == true;
              final start = m['period_start']?.toString() ?? '';
              final end = m['period_end']?.toString() ?? '';

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
                                  color: isPub ? AppTheme.primaryGreen.withValues(alpha: 0.1) : Colors.white10,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isPub ? 'منشور' : 'مسودة',
                                  style: TextStyle(color: isPub ? AppTheme.primaryGreen : Colors.grey, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('$start إلى $end', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _metricValue('مبيعات', '${m['total_sales']} ${m['currency'] ?? 'SAR'}'),
                              const SizedBox(width: 24),
                              _metricValue('الطلبات', '${m['orders_count']}'),
                              const SizedBox(width: 24),
                              _metricValue('ROAS', '${m['roas']}x'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryGreen, size: 18),
                      onPressed: () => _showEditMetrics(context, ref, m),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                      onPressed: () => _confirmDelete(context, ref, m),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _metricValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  void _showEditMetrics(BuildContext context, WidgetRef ref, Map<String, dynamic>? m) {
    final isEditing = m != null;
    final salesCtrl = TextEditingController(text: m?['total_sales']?.toString() ?? '');
    final prevSalesCtrl = TextEditingController(text: m?['prev_sales']?.toString() ?? '');
    final ordersCtrl = TextEditingController(text: m?['orders_count']?.toString() ?? '');
    final prevOrdersCtrl = TextEditingController(text: m?['prev_orders']?.toString() ?? '');
    final roasCtrl = TextEditingController(text: m?['roas']?.toString() ?? '');
    final prevRoasCtrl = TextEditingController(text: m?['prev_roas']?.toString() ?? '');
    final convCtrl = TextEditingController(text: m?['conversion_rate']?.toString() ?? '');
    final prevConvCtrl = TextEditingController(text: m?['prev_conversion_rate']?.toString() ?? '');
    final profitCtrl = TextEditingController(text: m?['net_profit']?.toString() ?? '');
    final spendCtrl = TextEditingController(text: m?['ad_spend']?.toString() ?? '');
    final impressionsCtrl = TextEditingController(text: m?['impressions']?.toString() ?? '');
    final clicksCtrl = TextEditingController(text: m?['clicks']?.toString() ?? '');
    
    DateTime start = m?['period_start'] != null ? DateTime.parse(m!['period_start']) : DateTime.now().subtract(const Duration(days: 30));
    DateTime end = m?['period_end'] != null ? DateTime.parse(m!['period_end']) : DateTime.now();
    bool isPub = m?['is_published'] ?? true;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isEditing ? 'تعديل تقرير الأداء' : 'تسجيل تقرير أداء جديد',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('الفترة الزمنية', style: TextStyle(color: Colors.grey, fontSize: 11)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final p = await showDatePicker(context: context, initialDate: start, firstDate: DateTime(2020), lastDate: DateTime(2030));
                          if (p != null) setState(() => start = p);
                        },
                        child: Text('من: ${start.toString().split(' ')[0]}', style: const TextStyle(fontSize: 11)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final p = await showDatePicker(context: context, initialDate: end, firstDate: DateTime(2020), lastDate: DateTime(2030));
                          if (p != null) setState(() => end = p);
                        },
                        child: Text('إلى: ${end.toString().split(' ')[0]}', style: const TextStyle(fontSize: 11)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _field(salesCtrl, 'المبيعات الحالية', TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: _field(prevSalesCtrl, 'المبيعات السابقة', TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _field(ordersCtrl, 'الطلبات الحالية', TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: _field(prevOrdersCtrl, 'الطلبات السابقة', TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _field(roasCtrl, 'ROAS الحالي', TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: _field(prevRoasCtrl, 'ROAS السابق', TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _field(convCtrl, 'معدل التحويل الحالي (مثال: 0.025)', TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: _field(prevConvCtrl, 'معدل التحويل السابق', TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _field(profitCtrl, 'صافي الأرباح', TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: _field(spendCtrl, 'ميزانية الإعلانات', TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _field(impressionsCtrl, 'الظهور (Impressions)', TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: _field(clicksCtrl, 'النقرات (Clicks)', TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('نشر التقرير للعميل فوراً', style: TextStyle(color: Colors.white, fontSize: 13)),
                  value: isPub,
                  onChanged: (val) => setState(() => isPub = val),
                  activeColor: AppTheme.primaryGreen,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.black),
              onPressed: saving ? null : () async {
                setState(() => saving = true);
                try {
                  final client = ref.read(supabaseClientProvider);
                  final payload = {
                    'project_id': pid,
                    'period_start': start.toString().split(' ')[0],
                    'period_end': end.toString().split(' ')[0],
                    'total_sales': double.tryParse(salesCtrl.text) ?? 0.0,
                    'prev_sales': double.tryParse(prevSalesCtrl.text) ?? 0.0,
                    'orders_count': int.tryParse(ordersCtrl.text) ?? 0,
                    'prev_orders': int.tryParse(prevOrdersCtrl.text) ?? 0,
                    'roas': double.tryParse(roasCtrl.text) ?? 0.0,
                    'prev_roas': double.tryParse(prevRoasCtrl.text) ?? 0.0,
                    'conversion_rate': double.tryParse(convCtrl.text) ?? 0.0,
                    'prev_conversion_rate': double.tryParse(prevConvCtrl.text) ?? 0.0,
                    'net_profit': double.tryParse(profitCtrl.text) ?? 0.0,
                    'ad_spend': double.tryParse(spendCtrl.text) ?? 0.0,
                    'impressions': int.tryParse(impressionsCtrl.text) ?? 0,
                    'clicks': int.tryParse(clicksCtrl.text) ?? 0,
                    'is_published': isPub,
                    'published_at': isPub ? DateTime.now().toIso8601String() : null,
                  };

                  if (isEditing) {
                    await client.from('ecom_metrics').update(payload).eq('id', m['id']);
                  } else {
                    await client.from('ecom_metrics').insert(payload);
                  }

                  ref.invalidate(projectMetricsHistoryProvider(pid));
                  ref.invalidate(latestMetricsProvider(pid));
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
                } finally {
                  if (ctx.mounted) setState(() => saving = false);
                }
              },
              child: const Text('حفظ', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Map<String, dynamic> m) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('حذف التقرير', style: TextStyle(color: Colors.white)),
        content: const Text('هل أنت متأكد من حذف هذا التقرير نهائياً؟', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final client = ref.read(supabaseClientProvider);
      await client.from('ecom_metrics').delete().eq('id', m['id']);
      ref.invalidate(projectMetricsHistoryProvider(pid));
      ref.invalidate(latestMetricsProvider(pid));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف بنجاح ✅'), backgroundColor: AppTheme.primaryGreen));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.redAccent));
      }
    }
  }

  Widget _field(TextEditingController ctrl, String hint, TextInputType type) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 11),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(8))),
      ),
    );
  }
}
