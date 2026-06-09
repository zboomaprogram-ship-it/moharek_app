import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';

class AdminAmDetailScreen extends ConsumerWidget {
  final String amId;
  const AdminAmDetailScreen({super.key, required this.amId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(amDetailProvider(amId));
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('تفاصيل أداء مدير الحساب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          final profile = data['profile'] as Map<String, dynamic>;
          final projects = data['projects'] as List;
          final avgHealth = data['avg_health'] as double;
          final tasksCreated = data['tasks_created'] as int? ?? 0;
          final tasksCompleted = data['tasks_completed'] as int? ?? 0;
          final reportsCount = data['reports_count'] as int? ?? 0;
          final approvalsCount = data['approvals_count'] as int? ?? 0;
          final approvalsPending = data['approvals_pending'] as int? ?? 0;
          final meetingsCount = data['meetings_count'] as int? ?? 0;
          final performanceHistory = data['performance_history'] as List<dynamic>? ?? [];

          final taskCompletionRate = tasksCreated > 0 ? (tasksCompleted / tasksCreated) * 100 : 0.0;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header Card
                _buildProfileHeader(profile, avgHealth),
                const SizedBox(height: 32),

                // Live Performance KPI Dashboard Title
                const Text(
                  'مؤشرات الأداء الحالية (مباشر)',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Grid of KPI Cards
                GridView.count(
                  crossAxisCount: isMobile ? 1 : 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isMobile ? 2.5 : 1.3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildKpiCard(
                      icon: Icons.business_outlined,
                      title: 'المشاريع المسندة',
                      value: '${projects.length}',
                      subtitle: 'متوسط مؤشر الصحة: ${avgHealth.toStringAsFixed(0)}%',
                      color: AppTheme.primaryGreen,
                    ),
                    _buildKpiCard(
                      icon: Icons.checklist_outlined,
                      title: 'معدل إنجاز المهام',
                      value: '${taskCompletionRate.toStringAsFixed(0)}%',
                      subtitle: '$tasksCompleted من $tasksCreated مهام منجزة',
                      color: Colors.blueAccent,
                    ),
                    _buildKpiCard(
                      icon: Icons.rate_review_outlined,
                      title: 'موافقات العملاء',
                      value: '$approvalsCount',
                      subtitle: '$approvalsPending موافقات قيد الانتظار',
                      color: Colors.orangeAccent,
                    ),
                    _buildKpiCard(
                      icon: Icons.analytics_outlined,
                      title: 'التقارير والاجتماعات',
                      value: '$reportsCount / $meetingsCount',
                      subtitle: 'تقارير مرفوعة / اجتماعات مجدولة',
                      color: Colors.purpleAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Monthly Performance Reports History
                const Text(
                  'تقارير الأداء الشهرية الموثقة',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildPerformanceHistoryTable(performanceHistory, isMobile),
                const SizedBox(height: 32),

                const Text(
                  'المشاريع المسندة حالياً',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Projects List
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF334155), width: 1),
                  ),
                  child: projects.isEmpty 
                    ? const Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Center(child: Text('لا توجد مشاريع مسندة حالياً', style: TextStyle(color: Color(0xFF64748B)))),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: projects.length,
                        separatorBuilder: (_, __) => const Divider(color: Color(0xFF334155), height: 1),
                        itemBuilder: (context, index) => _ProjectTile(project: projects[index]),
                      ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> profile, double avgHealth) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF334155), width: 1),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E293B),
            AppTheme.primaryGreen.withValues(alpha: 0.05),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2), width: 2),
            ),
            child: CircleAvatar(
              radius: 46,
              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
              child: Text(
                profile['full_name']?[0] ?? '?', 
                style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 36, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile['full_name'] ?? 'بدون اسم',
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                ),
                Text(
                  profile['email'] ?? '',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildStatChip('متوسط الصحة', '${avgHealth.toStringAsFixed(0)}%', AppTheme.primaryGreen),
                    const SizedBox(width: 12),
                    _buildStatChip('الحالة', profile['is_active'] ?? true ? 'نشط' : 'معطل', Colors.blue),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceHistoryTable(List<dynamic> history, bool isMobile) {
    if (history.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: const Center(
          child: Text(
            'لا توجد تقارير أداء تاريخية مسجلة بعد لهذا المدير. سيتم إدراج التقارير الشهرية تلقائياً.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (isMobile) {
      // Mobile friendly cards list instead of Table
      return Column(
        children: history.map((h) {
          final monthStr = h['period_month']?.toString() ?? '';
          final parts = monthStr.split('-');
          final displayMonth = parts.length >= 2 ? '${parts[1]} / ${parts[0]}' : monthStr;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('التقرير الشهري: $displayMonth', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('رضا العملاء: ${h['client_satisfaction_avg'] ?? '—'} ⭐', style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 12)),
                  ],
                ),
                const Divider(color: Colors.white10, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _mobileStatCol('العملاء النشطين', '${h['active_clients'] ?? 0} / ${h['total_clients'] ?? 0}'),
                    _mobileStatCol('متوسط الصحة', '${(h['avg_client_health_score'] ?? 0.0).toStringAsFixed(0)}%'),
                    _mobileStatCol('المهام المنجزة', '${h['tasks_completed'] ?? 0} / ${h['tasks_created'] ?? 0}'),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(const Color(0xFF0F172A)),
          dataRowColor: MaterialStateProperty.all(const Color(0xFF1E293B)),
          columns: const [
            DataColumn(label: Text('الشهر', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('إجمالي العملاء', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('العملاء النشطين', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('متوسط الصحة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('المهام المنجزة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('تقارير مرفوعة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('موافقات منشأة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('رضا العملاء', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ],
          rows: history.map((h) {
            final monthStr = h['period_month']?.toString() ?? '';
            final parts = monthStr.split('-');
            final displayMonth = parts.length >= 2 ? '${parts[1]} / ${parts[0]}' : monthStr;

            return DataRow(
              cells: [
                DataCell(Text(displayMonth, style: const TextStyle(color: Colors.white))),
                DataCell(Text('${h['total_clients'] ?? 0}', style: const TextStyle(color: Colors.white))),
                DataCell(Text('${h['active_clients'] ?? 0}', style: const TextStyle(color: Colors.white))),
                DataCell(Text('${(h['avg_client_health_score'] ?? 0.0).toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white))),
                DataCell(Text('${h['tasks_completed'] ?? 0} / ${h['tasks_created'] ?? 0}', style: const TextStyle(color: Colors.white))),
                DataCell(Text('${h['reports_uploaded'] ?? 0}', style: const TextStyle(color: Colors.white))),
                DataCell(Text('${h['approvals_created'] ?? 0}', style: const TextStyle(color: Colors.white))),
                DataCell(Text('${h['client_satisfaction_avg'] ?? '—'} ⭐', style: const TextStyle(color: Colors.white))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _mobileStatCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _ProjectTile extends StatelessWidget {
  final Map<String, dynamic> project;
  const _ProjectTile({required this.project});

  @override
  Widget build(BuildContext context) {
    final health = (project['health_score'] ?? 0).toDouble();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.folder_shared_outlined, color: AppTheme.primaryGreen, size: 24),
      ),
      title: Text(
        project['name'] ?? 'مشروع بدون اسم',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          'تاريخ الإسناد: ${project['created_at'].toString().split('T')[0]}',
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHealthIndicator(health),
          const SizedBox(width: 16),
          const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF475569), size: 14),
        ],
      ),
      onTap: () => context.go('/admin/clients/${project['id']}'),
    );
  }

  Widget _buildHealthIndicator(double health) {
    Color color = health >= 70 ? AppTheme.primaryGreen : health >= 40 ? Colors.orange : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${health.toStringAsFixed(0)}%',
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900),
      ),
    );
  }
}
