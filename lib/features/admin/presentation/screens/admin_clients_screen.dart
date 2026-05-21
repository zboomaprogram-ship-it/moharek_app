import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moharek_app/core/config/app_config.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';
import 'package:moharek_app/shared/services/data_providers.dart';

class AdminClientsScreen extends ConsumerWidget {
  const AdminClientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    final projectsAsync = ref.watch(allProjectsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'إدارة العملاء',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'متابعة كافة مشاريع العملاء والنشاط الحالي',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => _showCreateClientDialog(context, ref),
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text(
                        'إضافة عميل جديد',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إدارة العملاء',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'متابعة كافة مشاريع العملاء والنشاط الحالي',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () => _showCreateClientDialog(context, ref),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text(
                      'إضافة عميل جديد',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 32),

            Expanded(
              child: projectsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryGreen,
                  ),
                ),
                error: (e, _) => Center(
                  child: Text(
                    'Error: $e',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                data: (projects) {
                  if (projects.isEmpty) {
                    return const Center(
                      child: Text(
                        'لا يوجد عملاء حالياً',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    );
                  }

                  if (isMobile) {
                    return _buildClientCards(context, projects);
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF334155),
                        width: 1,
                      ),
                    ),
                    child: _buildClientTable(context, projects),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientCards(
    BuildContext context,
    List<Map<String, dynamic>> projects,
  ) {
    return ListView.separated(
      itemCount: projects.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final p = projects[index];
        final client = p['profiles'] as Map<String, dynamic>?;
        final name = client?['full_name'] ?? '—';
        final company = client?['company_name'] ?? '—';
        final health = (p['health_score'] ?? 0).toDouble();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF334155), width: 1),
          ),
          child: InkWell(
            onTap: () => context.go('/admin/clients/${p['id']}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.primaryBlue.withValues(
                        alpha: 0.1,
                      ),
                      child: Text(
                        name.isNotEmpty ? name[0] : '?',
                        style: const TextStyle(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            company,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFF334155), height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildStageBadge(p['current_stage']),
                        if (AppConfig.flavorName == 'rabhan') ...[
                          const SizedBox(width: 8),
                          _buildPackageBadge(p),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        if (AppConfig.flavorName == 'rabhan') ...[
                          const Icon(
                            Icons.show_chart,
                            color: Color(0xFF64748B),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          _buildRoasText(p),
                          const SizedBox(width: 12),
                        ],
                        const Icon(
                          Icons.favorite,
                          color: Color(0xFF64748B),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${health.toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: _getHealthColor(health),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildClientTable(
    BuildContext context,
    List<Map<String, dynamic>> projects,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFF0F172A)),
          dataRowMaxHeight: 80,
          horizontalMargin: 24,
          columns: [
            const DataColumn(
              label: Text(
                'العميل',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const DataColumn(
              label: Text(
                'الشركة',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (AppConfig.flavorName == 'rabhan') ...const [
              const DataColumn(
                label: Text(
                  'الباقة',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const DataColumn(
                label: Text(
                  'ROAS',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            const DataColumn(
              label: Text(
                'المرحلة',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const DataColumn(
              label: Text(
                'مؤشر الصحة',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const DataColumn(
              label: Text(
                'الإجراءات',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          rows: projects.map((p) {
            final client = p['profiles'] as Map<String, dynamic>?;
            final name = client?['full_name'] ?? '—';
            final company = client?['company_name'] ?? '—';
            final health = (p['health_score'] ?? 0).toDouble();

            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppTheme.primaryBlue.withValues(
                            alpha: 0.1,
                          ),
                          child: Text(
                            name.isNotEmpty ? name[0] : '?',
                            style: const TextStyle(
                              color: AppTheme.primaryBlue,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Text(
                    company,
                    style: const TextStyle(color: Color(0xFF94A3B8)),
                  ),
                ),
                if (AppConfig.flavorName == 'rabhan') ...[
                  DataCell(_buildPackageBadge(p)),
                  DataCell(_buildRoasText(p)),
                ],
                DataCell(_buildStageBadge(p['current_stage'])),
                DataCell(
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: FractionallySizedBox(
                          alignment: AlignmentDirectional.centerStart,
                          widthFactor: health / 100,
                          child: Container(
                            decoration: BoxDecoration(
                              color: _getHealthColor(health),
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: [
                                BoxShadow(
                                  color: _getHealthColor(
                                    health,
                                  ).withValues(alpha: 0.4),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${health.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: _getHealthColor(health),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppTheme.primaryGreen,
                      size: 16,
                    ),
                    onPressed: () => context.go('/admin/clients/${p['id']}'),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStageBadge(String? stage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Text(
        (stage ?? 'audit').toUpperCase(),
        style: const TextStyle(
          color: AppTheme.primaryGreen,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPackageBadge(Map<String, dynamic> project) {
    final packages = project['packages'] as List<dynamic>? ?? [];
    if (packages.isEmpty)
      return const Text('—', style: TextStyle(color: Color(0xFF94A3B8)));

    final pkg = packages.first as Map<String, dynamic>;
    final tier = pkg['tier'] as String? ?? 'basic';

    Color color;
    String label;
    switch (tier.toLowerCase()) {
      case 'startup':
      case 'basic':
        color = const Color(0xFF2196F3);
        label = 'انطلاق';
        break;
      case 'growth':
      case 'pro':
        color = AppTheme.primaryGreen;
        label = 'نمو';
        break;
      case 'scale':
      case 'enterprise':
        color = const Color(0xFFD4A017); // Gold
        label = 'توسع';
        break;
      default:
        color = Colors.grey;
        label = tier;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRoasText(Map<String, dynamic> project) {
    final metricsList = project['ecom_metrics'] as List<dynamic>? ?? [];
    if (metricsList.isEmpty)
      return const Text('—', style: TextStyle(color: Color(0xFF94A3B8)));

    final metrics = metricsList.first as Map<String, dynamic>;
    final roas = metrics['roas'] ?? 0;

    return Text(
      '${roas}x',
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
    );
  }

  Color _getHealthColor(double score) {
    if (score >= 70) return AppTheme.primaryGreen;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  void _showCreateClientDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    final projectCtrl = TextEditingController();
    String? selectedAmId;
    bool loading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'إضافة عميل جديد',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildInput(nameCtrl, 'الاسم الكامل', Icons.person_outline),
                  const SizedBox(height: 16),
                  _buildInput(
                    emailCtrl,
                    'البريد الإلكتروني',
                    Icons.email_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildInput(
                    passCtrl,
                    'كلمة المرور',
                    Icons.lock_outline,
                    obscure: true,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'تعيين مدير حساب (اختياري):',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Consumer(
                    builder: (context, ref, _) {
                      final amsAsync = ref.watch(allAmsProvider);
                      return amsAsync.when(
                        data: (ams) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedAmId,
                              hint: const Text(
                                'اختر مدير حساب',
                                style: TextStyle(color: Color(0xFF64748B)),
                              ),
                              dropdownColor: const Color(0xFF1E293B),
                              isExpanded: true,
                              items: ams
                                  .map(
                                    (am) => DropdownMenuItem(
                                      value: am['id'] as String,
                                      child: Text(
                                        am['full_name'] ?? 'AM',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => selectedAmId = val),
                            ),
                          ),
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const Text('Error loading AMs'),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildInput(
                    companyCtrl,
                    'اسم الشركة',
                    Icons.business_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildInput(
                    projectCtrl,
                    'اسم المشروع',
                    Icons.rocket_launch_outlined,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: loading ? null : () => Navigator.pop(context),
              child: const Text(
                'إلغاء',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: loading
                  ? null
                  : () async {
                      final email = emailCtrl.text.trim();
                      final password = passCtrl.text.trim();
                      final fullName = nameCtrl.text.trim();
                      final companyName = companyCtrl.text.trim();
                      final projectName = projectCtrl.text.trim();

                      if (email.isEmpty ||
                          password.isEmpty ||
                          fullName.isEmpty ||
                          companyName.isEmpty ||
                          projectName.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('جميع الحقول مطلوبة'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setState(() => loading = true);
                      try {
                        final actions = ref.read(adminActionsProvider);
                        await actions.createClient({
                          'email': email,
                          'password': password,
                          'full_name': fullName,
                          'company_name': companyName,
                          'project_name': projectName,
                          'account_manager_id': selectedAmId,
                        });

                        ref.invalidate(allProjectsProvider);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم إنشاء حساب العميل بنجاح ✅'),
                              backgroundColor: AppTheme.primaryGreen,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('خطأ: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        if (context.mounted) setState(() => loading = false);
                      }
                    },
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text(
                      'إنشاء الحساب',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    bool obscure = false,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1),
        ),
      ),
    );
  }
}
