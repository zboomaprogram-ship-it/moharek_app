import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/features/am/data/am_providers.dart';

class AmApprovalsScreen extends ConsumerWidget {
  const AmApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approvals = ref.watch(amGlobalApprovalsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الموافقات المعلقة',
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const Text(
              'متابعة الطلبات التي تنتظر موافقة العملاء عبر كافة المشاريع',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
            const SizedBox(height: 32),

            Expanded(
              child: approvals.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (list) {
                  if (list.isEmpty) {
                    return _buildEmptyState();
                  }
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) => _ApprovalCard(approval: list[index]),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pending_actions_outlined, size: 64, color: const Color(0xFF334155)),
          const SizedBox(height: 16),
          const Text(
            'لا توجد طلبات موافقة معلقة',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  final Map<String, dynamic> approval;
  const _ApprovalCard({required this.approval});

  @override
  Widget build(BuildContext context) {
    final project = approval['projects'] as Map<String, dynamic>;
    final status = approval['status'] as String? ?? 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.pending_actions, color: Colors.orange, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  approval['title'] ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.business, size: 14, color: AppTheme.primaryGreen),
                    const SizedBox(width: 6),
                    Text(
                      project['name'] ?? '',
                      style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'بانتظار العميل',
                  style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 12, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Text(
                    'طلب في: ${approval['created_at'].toString().split('T')[0]}',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
