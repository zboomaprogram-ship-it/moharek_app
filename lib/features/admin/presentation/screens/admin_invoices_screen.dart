import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';
import 'package:moharek_app/shared/services/data_providers.dart';

// ── Providers ─────────────────────────────────────────────────────

final allInvoicesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final data = await client
      .from('invoices')
      .select('*, projects(name, profiles!projects_client_id_fkey(full_name, company_name))')
      .order('created_at', ascending: false);
  return (data as List).cast<Map<String, dynamic>>();
});



// ── Admin Invoices Screen ─────────────────────────────────────────

class AdminInvoicesScreen extends ConsumerWidget {
  const AdminInvoicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(allInvoicesProvider);
    final isMobile = MediaQuery.of(context).size.width < 1000;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            if (isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الفواتير',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'إدارة الفواتير والتحصيلات المالية لجميع المشاريع',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showCreateInvoiceSheet(context, ref),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('فاتورة جديدة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الفواتير',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'إدارة الفواتير والتحصيلات المالية لجميع المشاريع',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateInvoiceSheet(context, ref),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('فاتورة جديدة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 32),

            Expanded(
              child: invoicesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                ),
                error: (err, _) => Center(
                  child: Text(
                    'Error: $err',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                data: (invoices) {
                  if (invoices.isEmpty) {
                    return _buildEmptyState();
                  }

                  // Summary stats
                  final totalPending =
                      invoices.where((i) => i['status'] == 'pending').length;
                  final totalPaid =
                      invoices.where((i) => i['status'] == 'paid').length;
                  final totalAmount = invoices.fold<double>(0, (sum, i) {
                    final amt = (i['amount'] as num?)?.toDouble() ?? 0;
                    return sum + (i['status'] == 'pending' ? amt : 0);
                  });

                  // Group by batch
                  final batched = <String, List<Map<String, dynamic>>>{};
                  final unbatched = <Map<String, dynamic>>[];
                  for (final inv in invoices) {
                    final bg = inv['batch_group'] as String?;
                    if (bg != null && bg.isNotEmpty) {
                      batched.putIfAbsent(bg, () => []).add(inv);
                    } else {
                      unbatched.add(inv);
                    }
                  }

                  return RefreshIndicator(
                    color: AppTheme.primaryGreen,
                    onRefresh: () async => ref.invalidate(allInvoicesProvider),
                    child: ListView(
                      children: [
                        if (isMobile)
                          Column(
                            children: [
                              _buildStat('قيد الانتظار', '$totalPending', Colors.orange, true),
                              const SizedBox(height: 12),
                              _buildStat('مدفوعة', '$totalPaid', AppTheme.primaryGreen, true),
                              const SizedBox(height: 12),
                              _buildStat('مستحقة', 'SAR ${totalAmount.toStringAsFixed(0)}', AppTheme.primaryBlue, true),
                            ],
                          )
                        else
                          Row(
                            children: [
                              _buildStat('قيد الانتظار', '$totalPending', Colors.orange, false),
                              const SizedBox(width: 12),
                              _buildStat('مدفوعة', '$totalPaid', AppTheme.primaryGreen, false),
                              const SizedBox(width: 12),
                              _buildStat('مستحقة', 'SAR ${totalAmount.toStringAsFixed(0)}', AppTheme.primaryBlue, false),
                            ],
                          ),
                        const SizedBox(height: 24),

                        // Batched invoices
                        ...batched.entries.map(
                          (entry) => _buildBatchGroup(
                            context,
                            ref,
                            entry.key,
                            entry.value,
                            isMobile,
                          ),
                        ),

                        // Unbatched invoices
                        ...unbatched.map(
                          (inv) => _buildInvoiceCard(
                            context,
                            ref,
                            inv,
                            isMobile,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, color: Colors.grey, size: 64),
          SizedBox(height: 16),
          Text('لا توجد فواتير حالياً', style: TextStyle(color: Colors.grey, fontSize: 16)),
          SizedBox(height: 8),
          Text('اضغط على "فاتورة جديدة" لإنشاء فاتورة لعميل', style: TextStyle(color: Colors.white38, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color, bool isMobile) {
    final content = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );

    if (isMobile) {
      return SizedBox(width: double.infinity, child: content);
    }
    return Expanded(child: content);
  }

  Widget _buildBatchGroup(BuildContext context, WidgetRef ref, String batchName, List<Map<String, dynamic>> invoices, bool isMobile) {
    final total = invoices.fold<double>(0, (sum, i) => sum + ((i['amount'] as num?)?.toDouble() ?? 0));
    final paid = invoices.fold<double>(0, (sum, i) => sum + ((i['partial_amount'] as num?)?.toDouble() ?? 0));
    final allPaid = invoices.every((i) => i['status'] == 'paid');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: allPaid ? AppTheme.primaryGreen.withValues(alpha: 0.3) : Colors.white10),
      ),
      child: Theme(
        data: ThemeData.dark().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Row(
            children: [
              const Icon(Icons.layers, color: AppTheme.primaryBlue, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  batchName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Text('${invoices.length} فواتير', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                const Spacer(),
                Text(
                  'SAR ${paid.toStringAsFixed(0)} / ${total.toStringAsFixed(0)}',
                  style: TextStyle(color: allPaid ? AppTheme.primaryGreen : Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          children: invoices.map((inv) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildInvoiceCard(context, ref, inv, isMobile, inBatch: true),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(BuildContext context, WidgetRef ref, Map<String, dynamic> invoice, bool isMobile, {bool inBatch = false}) {
    final project = invoice['projects'] as Map<String, dynamic>?;
    final profile = project?['profiles'] as Map<String, dynamic>?;
    final clientName = profile?['company_name'] as String? ?? profile?['full_name'] as String? ?? 'غير معروف';
    final status = invoice['status'] as String? ?? 'pending';
    final amount = (invoice['amount'] as num?)?.toDouble() ?? 0;
    final currency = invoice['currency'] as String? ?? 'SAR';
    final dueDate = invoice['due_date'] as String?;
    final desc = invoice['description'] as String? ?? '';

    Color statusColor;
    switch (status) {
      case 'paid': statusColor = AppTheme.primaryGreen; break;
      case 'overdue': statusColor = Colors.redAccent; break;
      case 'cancelled': statusColor = Colors.grey; break;
      default: statusColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: inBatch ? AppTheme.background : AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: status == 'overdue' ? Colors.redAccent.withValues(alpha: 0.4) : Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!inBatch)
                      Text(
                        clientName,
                        style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 11, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (!inBatch) const SizedBox(height: 4),
                    Text(
                      '$currency ${amount.toStringAsFixed(0)}',
                      style: TextStyle(color: Colors.white, fontSize: isMobile ? 16 : 20, fontWeight: FontWeight.bold),
                    ),
                    if (desc.isNotEmpty)
                      Text(
                        desc,
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (dueDate != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.grey, size: 12),
                const SizedBox(width: 6),
                Text('تاريخ الاستحقاق: ${dueDate.split('T')[0]}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (status == 'pending' || status == 'overdue')
                ElevatedButton.icon(
                  onPressed: () => _updateStatus(ref, invoice['id'] as String, 'paid'),
                  icon: const Icon(Icons.check, size: 12),
                  label: const Text('سداد', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              if (status == 'pending') ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _updateStatus(ref, invoice['id'] as String, 'overdue'),
                  icon: const Icon(Icons.warning_amber_outlined, size: 12, color: Colors.redAccent),
                  label: const Text('متأخرة', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
              const SizedBox(width: 8),
              IconButton(
                onPressed: () async {
                  final actions = ref.read(adminActionsProvider);
                  await actions.deleteInvoice(invoice['id'] as String);
                  ref.invalidate(allInvoicesProvider);
                },
                icon: const Icon(Icons.delete_outline, color: Colors.white24, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(WidgetRef ref, String invoiceId, String status) async {
    final actions = ref.read(adminActionsProvider);
    await actions.updateInvoiceStatus(invoiceId, status);
    ref.invalidate(allInvoicesProvider);
  }

  void _showCreateInvoiceSheet(BuildContext context, WidgetRef ref) {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final batchCtrl = TextEditingController();
    String? selectedProjectId;
    DateTime? dueDate;
    String currency = 'SAR';
    int installments = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Create Invoice', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // Client selector
              Consumer(builder: (ctx, ref, _) {
                final projectsAsync = ref.watch(allProjectsProvider);
                return projectsAsync.when(
                  data: (projects) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: const Color(0xFF1A2235), borderRadius: BorderRadius.circular(12)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedProjectId,
                        hint: const Text('Select Client', style: TextStyle(color: Colors.grey)),
                        dropdownColor: AppTheme.cardColor, isExpanded: true,
                        items: projects.map((p) {
                          final pr = p['profiles'] as Map<String, dynamic>?;
                          final name = pr?['company_name'] as String? ?? pr?['full_name'] as String? ?? 'Client';
                          return DropdownMenuItem(value: p['id'] as String, child: Text(name, style: const TextStyle(color: Colors.white)));
                        }).toList(),
                        onChanged: (val) => setModalState(() => selectedProjectId = val),
                      ),
                    ),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Error loading clients', style: TextStyle(color: Colors.red)),
                );
              }),
              const SizedBox(height: 12),

              // Description
              TextField(controller: descCtrl, style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Description (e.g. SEO retainer - Jan)', hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                  filled: true, fillColor: Color(0xFF1A2235), border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12))))),
              const SizedBox(height: 12),

              // Currency + Amount
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12), width: 100,
                  decoration: BoxDecoration(color: const Color(0xFF1A2235), borderRadius: BorderRadius.circular(12)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: currency, dropdownColor: AppTheme.cardColor,
                      items: ['AED', 'USD', 'EUR', 'SAR'].map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: Colors.white, fontSize: 14)))).toList(),
                      onChanged: (val) => setModalState(() => currency = val!),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: amountCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Total Amount', hintStyle: TextStyle(color: Colors.grey),
                    filled: true, fillColor: Color(0xFF1A2235), border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12)))))),
              ]),
              const SizedBox(height: 12),

              // Batch group
              TextField(controller: batchCtrl, style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Batch name (optional — groups invoices)', hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                  filled: true, fillColor: Color(0xFF1A2235), border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12))))),
              const SizedBox(height: 12),

              // Installments
              Row(children: [
                const Text('Installments:', style: TextStyle(color: Colors.grey)),
                const Spacer(),
                IconButton(onPressed: () { if (installments > 1) setModalState(() => installments--); }, icon: const Icon(Icons.remove_circle_outline, color: Colors.grey)),
                Text('$installments', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                IconButton(onPressed: () => setModalState(() => installments++), icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryGreen)),
              ]),
              if (installments > 1)
                Text('Each installment: ${currency} ${((double.tryParse(amountCtrl.text) ?? 0) / installments).toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 12),

              // Due date
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(context: ctx, initialDate: DateTime.now().add(const Duration(days: 14)),
                    firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 730)));
                  if (picked != null) setModalState(() => dueDate = picked);
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(dueDate != null ? 'Due: ${dueDate!.day}/${dueDate!.month}/${dueDate!.year}' : 'Set Due Date'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white70, side: const BorderSide(color: Colors.white24)),
              ),
              const SizedBox(height: 24),

              // Create
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: () async {
                  if (selectedProjectId == null || amountCtrl.text.isEmpty) return;
                  final client = ref.read(supabaseClientProvider);
                  final totalAmount = double.tryParse(amountCtrl.text) ?? 0;
                  final batchName = batchCtrl.text.trim().isNotEmpty ? batchCtrl.text.trim()
                      : (installments > 1 ? 'Batch-${DateTime.now().millisecondsSinceEpoch}' : null);

                  final inserts = <Map<String, dynamic>>[];
                  final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
                  for (int i = 0; i < installments; i++) {
                    final installAmount = totalAmount / installments;
                    final installDue = dueDate != null ? dueDate!.add(Duration(days: 30 * i)) : null;
                    inserts.add({
                      'project_id': selectedProjectId,
                      'invoice_number': 'INV-$timestamp-${i + 1}',
                      'amount': installAmount,
                      'currency': currency,
                      'due_date': installDue?.toIso8601String(),
                      'status': 'pending',
                      'batch_group': batchName,
                      'description': installments > 1
                          ? '${descCtrl.text.trim()} (${i + 1}/$installments)'
                          : descCtrl.text.trim(),
                    });
                  }
                  final actions = ref.read(adminActionsProvider);
                  await actions.createInvoices(inserts);
                  ref.invalidate(allInvoicesProvider);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(installments > 1 ? '$installments installments created ✅' : 'Invoice created ✅'), backgroundColor: AppTheme.primaryGreen),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14)),
                child: Text(installments > 1 ? 'Create $installments Installments' : 'Create Invoice', style: const TextStyle(fontWeight: FontWeight.bold)),
              )),
            ]),
          ),
        ),
      ),
    );
  }
}
