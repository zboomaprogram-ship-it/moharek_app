import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:go_router/go_router.dart';

class AdminSupportScreen extends ConsumerWidget {
  const AdminSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(allTicketsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'مركز الدعم والمساعدة',
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const Text(
              'إدارة كافة طلبات الدعم الفني والاستفسارات من العملاء',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
            const SizedBox(height: 32),

            Expanded(
              child: ticketsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (tickets) {
                  if (tickets.isEmpty) {
                    return const Center(child: Text('لا توجد تذاكر دعم حالياً', style: TextStyle(color: Color(0xFF64748B))));
                  }
                  return _buildTicketsGrid(context, tickets);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketsGrid(BuildContext context, List<Map<String, dynamic>> tickets) {
    return ListView.builder(
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        final status = ticket['status'] ?? 'open';
        final priority = ticket['priority'] ?? 'normal';
        final color = _getStatusColor(status);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _getPriorityColor(priority).withValues(alpha: 0.1), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getPriorityColor(priority).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  priority == 'urgent' ? Icons.priority_high : Icons.support_agent,
                  color: _getPriorityColor(priority),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          ticket['title'] ?? 'بدون عنوان',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ticket['description'] ?? '',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: () => _openTicketDetail(context, ticket['id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  foregroundColor: AppTheme.primaryGreen,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Text('فتح المحادثة'),
              ),
              const SizedBox(width: 12),
              _buildStatusMenu(context, ticket),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusMenu(BuildContext context, Map<String, dynamic> ticket) {
    return Consumer(builder: (context, ref, child) {
      return PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
        onSelected: (val) async {
          final actions = ref.read(adminActionsProvider);
          await actions.updateTicketStatus(ticket['id'], val);
          ref.invalidate(allTicketsProvider);
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'open', child: Text('فتح التذكرة')),
          const PopupMenuItem(value: 'in_progress', child: Text('قيد المعالجة')),
          const PopupMenuItem(value: 'resolved', child: Text('تم الحل')),
          const PopupMenuItem(value: 'closed', child: Text('إغلاق')),
        ],
      );
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open': return AppTheme.primaryBlue;
      case 'in_progress': return Colors.orange;
      case 'resolved': return AppTheme.primaryGreen;
      default: return Colors.white24;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent': return Colors.redAccent;
      case 'important': return Colors.orangeAccent;
      default: return AppTheme.primaryBlue;
    }
  }

  void _openTicketDetail(BuildContext context, String ticketId) {
    // Navigate to a shared ticket detail view
    // For simplicity, we can reuse the client detail view if we make it generic
    // or create an admin-specific one.
    // For now, let's assume we have a route for it.
    context.push('/admin/support/$ticketId');
  }
}
