import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/features/am/data/am_providers.dart';

class AmClientsScreen extends ConsumerWidget {
  const AmClientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clients = ref.watch(amClientsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'عملائي',
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const Text(
              'قائمة المشاريع المسندة إليك للمتابعة والإدارة',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
            const SizedBox(height: 32),
            
            Expanded(
              child: clients.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (list) {
                  if (list.isEmpty) {
                    return _buildEmptyState();
                  }
                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 400,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      mainAxisExtent: 220,
                    ),
                    itemCount: list.length,
                    itemBuilder: (context, index) => _ClientCard(project: list[index]),
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
          Icon(Icons.business_center_outlined, size: 64, color: const Color(0xFF334155)),
          const SizedBox(height: 16),
          const Text(
            'لا يوجد عملاء مسندون إليك حالياً',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  final Map<String, dynamic> project;
  const _ClientCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final profile = project['profiles'];
    final clientName = profile['company_name'] ?? profile['full_name'] ?? 'عميل';
    final health = (project['health_score'] ?? 0).toDouble();

    return InkWell(
      onTap: () => context.go('/am/clients/${project['id']}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF334155), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  child: const Icon(Icons.business, color: AppTheme.primaryGreen, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    clientName,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusBadge(project['status']),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('مؤشر الصحة', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                Text('${health.toStringAsFixed(0)}%', style: TextStyle(color: _getHealthColor(health), fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: health / 100,
                backgroundColor: const Color(0xFF0F172A),
                valueColor: AlwaysStoppedAnimation(_getHealthColor(health)),
                minHeight: 6,
              ),
            ),
            const Spacer(),
            const Divider(color: Color(0xFF334155), height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.list_alt_rounded, color: Color(0xFF64748B), size: 16),
                    const SizedBox(width: 8),
                    const Text('المهام المعلقة', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        '${(project['tasks'] as List?)?.where((t) => t['status'] != 'completed').length ?? 0}',
                        style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF64748B), size: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    final isActive = status == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primaryGreen.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isActive ? 'نشط' : 'قيد الانتظار',
        style: TextStyle(color: isActive ? AppTheme.primaryGreen : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _getHealthColor(double score) {
    if (score >= 70) return AppTheme.primaryGreen;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }
}
