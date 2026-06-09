import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/features/notifications/data/notifications_provider.dart';

class BillingTab extends ConsumerWidget {
  final String pid;
  const BillingTab({super.key, required this.pid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.markProjectNotificationsAsRead(pid, 'invoice');
      ref.invalidate(notificationsProvider);
    });

    final invoicesAsync = ref.watch(projectInvoicesProvider(pid));
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_invoice_$pid',
        backgroundColor: Colors.amber,
        onPressed: () => _showCreateInvoice(context, ref),
        child: const Icon(Icons.add_card, color: Colors.black),
      ),
      body: invoicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (invoices) {
          if (invoices.isEmpty) {
            return const Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.receipt_long_outlined, color: Colors.grey, size: 48),
                SizedBox(height: 16),
                Text('لا توجد فواتير', style: TextStyle(color: Colors.grey)),
              ]),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: invoices.length,
            itemBuilder: (context, index) => _buildCard(context, ref, invoices[index]),
          );
        },
      ),
    );
  }

  Widget _buildCard(BuildContext context, WidgetRef ref, Map<String, dynamic> inv) {
    final status = inv['status'] as String? ?? 'pending';
    final amount = (inv['amount'] as num?)?.toDouble() ?? 0.0;
    final existingLink = inv['payment_link'] as String?;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (status == 'paid' ? AppTheme.primaryGreen : Colors.amber).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                status == 'paid' ? Icons.check_circle_outline : Icons.pending_outlined,
                color: status == 'paid' ? AppTheme.primaryGreen : Colors.amber,
              ),
            ),
            title: Text('فاتورة #${inv['id'].toString().substring(0, 8)}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text('${(inv['created_at'] as String).split('T')[0]} • ${inv['currency'] ?? 'SAR'}',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$amount', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(status.toUpperCase(), style: TextStyle(
                      color: status == 'paid' ? AppTheme.primaryGreen : Colors.amber,
                      fontSize: 10, fontWeight: FontWeight.bold,
                    )),
                  ],
                ),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  color: const Color(0xFF1E293B),
                  icon: const Icon(Icons.more_vert, color: Colors.white54),
                  onSelected: (value) async {
                    if (value == 'delete') {
                      await _confirmDelete(context, ref, inv);
                    } else {
                      await _updateStatus(context, ref, inv, value);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'pending', child: Text('معلق', style: TextStyle(color: Colors.white))),
                    const PopupMenuItem(value: 'paid', child: Text('مدفوع', style: TextStyle(color: Colors.white))),
                    const PopupMenuItem(value: 'void', child: Text('ملغي', style: TextStyle(color: Colors.white))),
                    const PopupMenuItem(value: 'refunded', child: Text('مسترجع', style: TextStyle(color: Colors.white))),
                    const PopupMenuDivider(),
                    const PopupMenuItem(value: 'delete', child: Text('حذف', style: TextStyle(color: Colors.redAccent))),
                  ],
                ),
              ],
            ),
          ),
          // ── Payment Link Row ────────────────────────────────────────
          if (existingLink != null && existingLink.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.link, size: 12, color: AppTheme.primaryGreen),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      existingLink,
                      style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showSendPaymentLinkDialog(context, ref, inv),
              icon: const Icon(Icons.send_to_mobile, size: 15),
              label: Text(
                existingLink != null && existingLink.isNotEmpty
                    ? 'إعادة إرسال رابط الدفع'
                    : 'إرسال رابط الدفع',
                style: const TextStyle(fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.amber,
                side: const BorderSide(color: Colors.amber, width: 1),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, Map<String, dynamic> inv, String status) async {
    try {
      await ref.read(adminActionsProvider).updateInvoiceStatus(inv['id'], status);
      ref.invalidate(projectInvoicesProvider(pid));
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التحديث ✅'), backgroundColor: AppTheme.primaryGreen));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Map<String, dynamic> inv) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('حذف الفاتورة', style: TextStyle(color: Colors.white)),
        content: const Text('هل تريد حذف هذه الفاتورة نهائياً؟', style: TextStyle(color: Color(0xFF94A3B8))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(supabaseClientProvider).from('invoices').delete().eq('id', inv['id']);
      ref.invalidate(projectInvoicesProvider(pid));
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف ✅'), backgroundColor: AppTheme.primaryGreen));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
    }
  }

  void _showCreateInvoice(BuildContext context, WidgetRef ref) {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final linkCtrl = TextEditingController();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 24, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('إنشاء فاتورة', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _field(amountCtrl, 'المبلغ', Icons.attach_money, type: TextInputType.number),
              const SizedBox(height: 12),
              _field(descCtrl, 'الوصف (مثال: اشتراك شهري)', Icons.description, maxLines: 2),
              const SizedBox(height: 12),
              _field(linkCtrl, 'رابط الدفع (اختياري)', Icons.link),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                  onPressed: saving ? null : () async {
                    if (amountCtrl.text.isEmpty) return;
                    setState(() => saving = true);
                    try {
                      await ref.read(adminActionsProvider).createInvoices([{
                        'project_id': pid,
                        'amount': double.tryParse(amountCtrl.text),
                        'currency': 'SAR',
                        'status': 'pending',
                        'description': descCtrl.text.trim(),
                        if (linkCtrl.text.trim().isNotEmpty)
                          'payment_link': linkCtrl.text.trim(),
                      }]);
                      ref.invalidate(projectInvoicesProvider(pid));
                      if (ctx.mounted) Navigator.pop(ctx);
                    } catch (e) {
                      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
                    } finally {
                      if (ctx.mounted) setState(() => saving = false);
                    }
                  },
                  child: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Text('إنشاء', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSendPaymentLinkDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> inv) {
    final linkCtrl = TextEditingController(text: inv['payment_link'] as String? ?? '');
    bool sending = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.send_to_mobile, color: Colors.amber, size: 22),
              SizedBox(width: 10),
              Text('إرسال رابط الدفع', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'المبلغ: ${inv['currency'] ?? 'SAR'} ${inv['amount'] ?? 0}',
                style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text('رابط الدفع:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              const SizedBox(height: 8),
              TextField(
                controller: linkCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  hintText: 'https://payment.example.com/...',
                  hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  prefixIcon: const Icon(Icons.link, color: Colors.amber, size: 18),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'سيتم إرسال الرابط للعميل عبر المحادثة وإشعار فوري.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton.icon(
              onPressed: sending ? null : () async {
                final link = linkCtrl.text.trim();
                if (link.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('أدخل رابط الدفع أولاً'), backgroundColor: Colors.orange),
                  );
                  return;
                }
                setState(() => sending = true);
                try {
                  await ref.read(adminActionsProvider).sendPaymentLink(
                    invoiceId: inv['id'] as String,
                    projectId: pid,
                    paymentLink: link,
                    description: inv['description'] as String?,
                    amount: (inv['amount'] as num?)?.toDouble(),
                    currency: inv['currency'] as String? ?? 'SAR',
                  );
                  ref.invalidate(projectInvoicesProvider(pid));
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ تم إرسال رابط الدفع للعميل'),
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
                    );
                  }
                } finally {
                  if (ctx.mounted) setState(() => sending = false);
                }
              },
              icon: sending
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.send, size: 16),
              label: const Text('إرسال', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon, {TextInputType type = TextInputType.text, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF64748B)),
        prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 18),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12))),
      ),
    );
  }
}


