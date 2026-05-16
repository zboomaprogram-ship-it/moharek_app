import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/shared/models/financials.dart';
import 'package:moharek_app/l10n/app_localizations.dart';
import 'package:moharek_app/shared/widgets/shimmer_placeholders.dart';
import 'package:url_launcher/url_launcher.dart';

class BillingScreen extends ConsumerWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(currentProjectProvider);
    final invoicesAsync = ref.watch(invoicesProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.billingAndPayments)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            projectAsync.when(
              data: (project) => project != null 
                ? _buildCurrentPlanCard(project, l10n)
                : const SizedBox(),
              loading: () => const ShimmerCard(height: 180),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 32),
            Text(l10n.paymentHistory, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            invoicesAsync.when(
              data: (invoices) => invoices.isEmpty
                ? _buildNoInvoices(l10n)
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: invoices.length,
                    itemBuilder: (ctx, i) => _buildInvoiceTile(context, invoices[i], l10n),
                  ),
              loading: () => const ShimmerList(itemCount: 3, itemHeight: 80),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: Center(child: Text(l10n.errorOccurred(err.toString()))),
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPlanCard(dynamic project, AppLocalizations l10n) {
    // Assuming project has tier and renewal info
    final tier = project.subscriptionTier ?? 'Growth Plan';
    final renewal = project.nextRenewalDate != null 
      ? '${project.nextRenewalDate!.day}/${project.nextRenewalDate!.month}/${project.nextRenewalDate!.year}'
      : 'Auto-renewing monthly';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryGreen.withValues(alpha: 0.2), AppTheme.primaryBlue.withValues(alpha: 0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.currentPlan, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(tier, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
              const Icon(Icons.star, color: AppTheme.primaryGreen, size: 32),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: AppTheme.primaryGreen, size: 14),
              const SizedBox(width: 8),
              Text(
                '${l10n.nextRenewal}: $renewal',
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceTile(BuildContext context, Invoice invoice, AppLocalizations l10n) {
    final isUnpaid = invoice.status == 'unpaid';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isUnpaid ? Colors.orangeAccent.withValues(alpha: 0.2) : Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isUnpaid ? Colors.orange : AppTheme.primaryGreen).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isUnpaid ? Icons.pending_outlined : Icons.check_circle_outlined,
              color: isUnpaid ? Colors.orange : AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(invoice.invoiceNumber, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(
                  '${invoice.amount} ${invoice.currency} • ${invoice.createdAt.day}/${invoice.createdAt.month}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          if (isUnpaid && invoice.paymentLink != null)
            ElevatedButton(
              onPressed: () => _launchPayment(invoice.paymentLink!),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(l10n.payNow, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            )
          else
            Text(
              invoice.status.toUpperCase(),
              style: TextStyle(
                color: isUnpaid ? Colors.orange : AppTheme.primaryGreen,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoInvoices(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.receipt_long_outlined, color: Colors.white10, size: 64),
            const SizedBox(height: 16),
            Text(l10n.noInvoicesYet, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Future<void> _launchPayment(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
