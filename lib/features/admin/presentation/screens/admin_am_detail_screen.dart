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

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('تفاصيل مدير الحساب', style: TextStyle(color: Colors.white)),
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          final profile = data['profile'] as Map<String, dynamic>;
          final projects = data['projects'] as List;
          final avgHealth = data['avg_health'] as double;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header Card
                _buildProfileHeader(profile, avgHealth),
                const SizedBox(height: 32),

                const Text(
                  'المشاريع المسندة',
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
                        child: Center(child: Text('لا توجد مشاريع مسندة', style: TextStyle(color: Color(0xFF64748B)))),
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
