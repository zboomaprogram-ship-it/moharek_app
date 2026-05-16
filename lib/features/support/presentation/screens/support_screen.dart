import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/shared/models/support.dart';
import 'package:moharek_app/l10n/app_localizations.dart';
import 'package:moharek_app/shared/widgets/shimmer_placeholders.dart';
import 'package:moharek_app/features/support/presentation/widgets/new_ticket_sheet.dart';
import 'package:go_router/go_router.dart';

class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(ticketsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.supportHub)),
      body: ticketsAsync.when(
        loading: () => const ShimmerList(itemCount: 4, itemHeight: 100),
        error: (err, _) => Center(child: Text(l10n.errorOccurred(err.toString()))),
        data: (tickets) {
          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              children: [
                if (tickets.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.history_outlined, color: Colors.grey, size: 20),
                        const SizedBox(width: 8),
                        Text(l10n.myTickets, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = tickets[index];
                      return InkWell(
                        onTap: () => context.push('/profile/support/${ticket.id}'),
                        child: _buildTicketCard(context, ticket, l10n),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
                if (tickets.isEmpty) ...[
                  const SizedBox(height: 40),
                  const Icon(Icons.support_agent_outlined, color: Colors.white10, size: 80),
                  const SizedBox(height: 24),
                  Text(l10n.howCanWeHelp, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      l10n.supportDescription,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
                _buildFAQSection(context, l10n),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewTicketSheet(context, ref),
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Icons.add_comment, color: Colors.black),
        label: Text(l10n.newTicket, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }


  Widget _buildFAQSection(BuildContext context, AppLocalizations l10n) {
    final faqs = [
      (
        q: 'كيف يمكنني متابعة نتائج SEO؟',
        a: 'يمكنك متابعة كافة النتائج من خلال تبويب "النتائج" في القائمة السفلية، حيث نعرض لك ترتيب الكلمات وحجم الزيارات.',
        cat: 'SEO'
      ),
      (
        q: 'متى يتم إصدار الفاتورة الشهرية؟',
        a: 'يتم إصدار الفاتورة في الأول من كل شهر ميلادي، وتصلك تنبيهات فور صدورها.',
        cat: 'Billing'
      ),
      (
        q: 'كيف أطلب تعديلاً على محتوى تم نشره؟',
        a: 'اضغط على زر "تذكرة جديدة" واختر نوع "تعديل محتوى" وسيقوم فريقنا بمراجعة طلبك فوراً.',
        cat: 'Content'
      ),
      (
        q: 'هل يمكنني إضافة أعضاء آخرين من فريقي؟',
        a: 'نعم، يمكننا إضافة أعضاء إضافيين بصلاحيات مختلفة. تواصل مع مدير حسابك لتفعيل ذلك.',
        cat: 'Account'
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              const Icon(Icons.quiz_outlined, color: AppTheme.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'الأسئلة الشائعة',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: faqs.length,
          itemBuilder: (context, index) {
            final faq = faqs[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      faq.cat,
                      style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    faq.q,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                      child: Text(
                        faq.a,
                        style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.6),
                      ),
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

  Widget _buildTicketCard(BuildContext context, SupportTicket ticket, AppLocalizations l10n) {
    final color = _getStatusColor(ticket.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ticket.status.toUpperCase(),
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '${ticket.createdAt.day}/${ticket.createdAt.month}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            ticket.title,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            ticket.description,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open': return AppTheme.primaryBlue;
      case 'resolved': return AppTheme.primaryGreen;
      case 'closed': return Colors.white24;
      default: return Colors.orange;
    }
  }

  void _showNewTicketSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const NewSupportTicketBottomSheet(),
    );
  }
}
