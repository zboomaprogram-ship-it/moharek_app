import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';

class AdminLogsScreen extends ConsumerWidget {
  const AdminLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(adminLogsProvider);
    final isMobile = MediaQuery.of(context).size.width < 1000;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'سجل العمليات الإدارية',
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 24 : 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'متابعة كافة التغييرات الحساسة التي قام بها فريق العمل',
              style: TextStyle(
                color: const Color(0xFF64748B),
                fontSize: isMobile ? 12 : 14,
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF334155), width: 1),
                ),
                child: logs.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (list) {
                    if (list.isEmpty) {
                      return const Center(
                        child: Text(
                          'لا توجد سجلات حالياً',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      );
                    }
                    return _buildLogsTable(list, isMobile);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsTable(List<Map<String, dynamic>> list, bool isMobile) {
    return ListView.separated(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      itemCount: list.length,
      separatorBuilder: (_, __) =>
          const Divider(color: Color(0xFF1E293B), height: 1),
      itemBuilder: (context, i) {
        final log = list[i];
        final profile = log['profiles'] as Map<String, dynamic>?;
        final name = profile?['full_name'] ?? 'النظام';
        final action = log['action'] ?? 'عملية';
        final details = log['details'] ?? '—';
        final time = log['created_at'].toString().split('T')[0];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildActionIcon(action),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isMobile)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                time,
                                style: const TextStyle(
                                  color: Color(0xFF475569),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildActionBadge(action),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildActionBadge(action),
                          const Spacer(),
                          Text(
                            time,
                            style: const TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Text(
                      details,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionIcon(String action) {
    IconData icon = Icons.info_outline;
    Color color = Colors.blue;

    if (action.contains('delete')) {
      icon = Icons.delete_outline;
      color = Colors.redAccent;
    } else if (action.contains('create')) {
      icon = Icons.add_circle_outline;
      color = Colors.greenAccent;
    } else if (action.contains('update')) {
      icon = Icons.edit_outlined;
      color = Colors.orangeAccent;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildActionBadge(String action) {
    String label = action;
    Color color = Colors.blue;

    if (action.contains('delete')) {
      label = 'حذف';
      color = Colors.redAccent;
    } else if (action.contains('create')) {
      label = 'إنشاء';
      color = Colors.greenAccent;
    } else if (action.contains('update')) {
      label = 'تحديث';
      color = Colors.orangeAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
