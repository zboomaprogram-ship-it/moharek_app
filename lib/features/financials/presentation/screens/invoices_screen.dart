import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/l10n/app_localizations.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/shared/models/financials.dart';
import 'package:moharek_app/shared/utils/file_helper.dart';

class InvoicesScreen extends ConsumerWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(invoicesProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.invoices),
      ),
      body: invoicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
        error: (err, _) => Center(child: Text(l10n.errorOccurred(err.toString()))),
        data: (invoices) {
          if (invoices.isEmpty) {
            return Center(child: Text(l10n.noInvoicesFound, style: const TextStyle(color: Colors.grey)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: invoices.length,
            itemBuilder: (context, index) {
              final invoice = invoices[index];
              return _buildInvoiceCard(context, invoice, l10n);
            },
          );
        },
      ),
    );
  }

  Widget _buildInvoiceCard(BuildContext context, Invoice invoice, AppLocalizations l10n) {
    final isUnpaid = invoice.status == 'unpaid' || invoice.status == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isUnpaid ? Colors.redAccent.withValues(alpha: 0.3) : Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.invoiceLabel,
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              _buildStatusBadge(invoice.status, l10n),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.amountDue, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(
                    '${invoice.amount} ${invoice.currency}',
                    style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (invoice.dueDate != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(l10n.dueDate, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(
                      '${invoice.dueDate!.day}/${invoice.dueDate!.month}/${invoice.dueDate!.year}',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
            ],
          ),
          if (invoice.status != 'paid') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => invoice.paymentLink != null ? _launchURL(context, invoice.paymentLink!) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(l10n.payNow, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, AppLocalizations l10n) {
    Color color;
    String label;
    
    switch (status.toLowerCase()) {
      case 'paid':
        color = AppTheme.primaryGreen;
        label = l10n.paid;
        break;
      case 'unpaid':
        color = Colors.red;
        label = l10n.unpaid;
        break;
      case 'pending':
        color = Colors.orange;
        label = l10n.pending;
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _launchURL(BuildContext context, String url) async {
    await openFileInApp(context, url, 'Payment');
  }
}
