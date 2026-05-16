import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';


class AdminTeamScreen extends ConsumerWidget {
  const AdminTeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final team = ref.watch(teamListProvider);
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isMobile) ...[
              const Text('فريق العمل', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('إدارة مديري الحسابات وأعضاء الفريق', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 12)),
                  onPressed: () => _showInviteDialog(context, ref),
                  icon: const Icon(Icons.person_add_outlined, size: 18),
                  label: const Text('دعوة عضو جديد', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ] else
              Row(
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('فريق العمل', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                      Text('إدارة مديري الحسابات وأعضاء الفريق الفني', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                    onPressed: () => _showInviteDialog(context, ref),
                    icon: const Icon(Icons.person_add_outlined, size: 20),
                    label: const Text('دعوة عضو جديد', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            const SizedBox(height: 24),

            // Team List Container
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF334155), width: 1),
                ),
                child: team.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (list) => ListView.separated(
                    padding: EdgeInsets.all(isMobile ? 12 : 24),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(color: Color(0xFF334155), height: 1),
                    itemBuilder: (context, index) => _TeamMemberTile(member: list[index]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInviteDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'account_manager';
    List<String> selectedProjectIds = [];
    bool loading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text(
            'إضافة عضو فريق جديد',
            style: TextStyle(color: Colors.white),
          ),
          content: Consumer(
            builder: (context, ref, child) {
              final projectsAsync = ref.watch(allProjectsProvider);
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildField(
                      nameController,
                      'الاسم الكامل',
                      Icons.person_outline,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      emailController,
                      'البريد الإلكتروني',
                      Icons.email_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      passwordController,
                      'كلمة المرور',
                      Icons.lock_outline,
                      obscure: true,
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      dropdownColor: const Color(0xFF0F172A),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'الدور الوظيفي',
                        labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'account_manager',
                          child: Text('مدير حسابات (Account)'),
                        ),
                        DropdownMenuItem(
                          value: 'seo_team',
                          child: Text('خبير سيو (SEO)'),
                        ),
                        DropdownMenuItem(
                          value: 'ads_team',
                          child: Text('خبير إعلانات (Ads)'),
                        ),
                        DropdownMenuItem(
                          value: 'tech_team',
                          child: Text('مطور تقني (Tech)'),
                        ),
                        DropdownMenuItem(
                          value: 'admin',
                          child: Text('مدير نظام (Admin)'),
                        ),
                      ],
                      onChanged: (v) => setState(() => selectedRole = v!),
                    ),
                    if (selectedRole == 'account_manager') ...[
                      const SizedBox(height: 24),
                      const Text(
                        'تعيين عملاء لمدير الحسابات:',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      projectsAsync.when(
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (e, _) => Text(
                          'Error: $e',
                          style: const TextStyle(color: Colors.red),
                        ),
                        data: (projects) => Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: projects.map((p) {
                              final isSelected = selectedProjectIds.contains(
                                p['id'],
                              );
                              return CheckboxListTile(
                                value: isSelected,
                                title: Text(
                                  p['name'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                onChanged: (v) {
                                  setState(() {
                                    if (v == true)
                                      selectedProjectIds.add(p['id']);
                                    else
                                      selectedProjectIds.remove(p['id']);
                                  });
                                },
                                activeColor: AppTheme.primaryGreen,
                                checkColor: Colors.black,
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'إلغاء',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: loading
                  ? null
                  : () async {
                      if (nameController.text.isEmpty ||
                          emailController.text.isEmpty ||
                          passwordController.text.isEmpty)
                        return;

                      setState(() => loading = true);
                      try {
                        await ref
                            .read(adminActionsProvider)
                            .createTeamMember({
                              'email': emailController.text.trim(),
                              'password': passwordController.text,
                              'fullName': nameController.text.trim(),
                              'role': selectedRole,
                              'projectIds': selectedRole == 'account_manager'
                                  ? selectedProjectIds
                                  : null,
                            });
                        ref.invalidate(teamListProvider);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'تم إنشاء الحساب وتعيين الأدوار بنجاح ✅',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        String errorMessage = 'خطأ: $e';
                        if (e.toString().contains('already been registered')) {
                          errorMessage =
                              'عذراً، هذا البريد الإلكتروني مسجل مسبقاً';
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(errorMessage),
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
                  : const Text('إنشاء الحساب'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool obscure = false,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
        prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _TeamMemberTile extends ConsumerWidget {
  final Map<String, dynamic> member;
  const _TeamMemberTile({required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = member['is_active'] ?? true;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
            child: Text(
              member['full_name']?[0] ?? '?',
              style: const TextStyle(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member['full_name'] ?? 'بدون اسم',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getRoleLabel(member['role']),
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isActive ? 'نشط' : 'معطل',
              style: TextStyle(
                color: isActive ? AppTheme.primaryGreen : Colors.red,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 24),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
            color: const Color(0xFF0F172A),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _showEditUserDialog(context, ref, member);
                  break;
                case 'assignments':
                  _showEditAssignmentsDialog(context, ref, member);
                  break;
                case 'toggle':
                  ref.read(adminActionsProvider).toggleUserStatus(member['id'], !isActive).then((_) {
                    ref.invalidate(teamListProvider);
                  });
                  break;
                case 'view':
                  context.push('/admin/team/${member['id']}');
                  break;
                case 'delete':
                  _showDeleteConfirm(context, ref, member);
                  break;
              }
            },
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              const PopupMenuItem(
                value: 'edit',
                child: Text('تعديل البيانات', style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem(
                value: 'assignments',
                child: Text('تعديل التعيينات', style: TextStyle(color: Colors.white)),
              ),
              PopupMenuItem(
                value: 'toggle',
                child: Text(
                  isActive ? 'تعطيل الحساب' : 'تفعيل الحساب',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const PopupMenuItem(
                value: 'view',
                child: Text('عرض التفاصيل', style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Text('حذف الحساب نهائياً', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditAssignmentsDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> member,
  ) {
    if (member['role'] != 'account_manager') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('التعديل متاح فقط لمديري الحسابات')),
      );
      return;
    }

    List<String> selectedProjectIds = [];
    bool loading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text(
            'تعديل تعيينات: ${member['full_name']}',
            style: const TextStyle(color: Colors.white),
          ),
          content: Consumer(
            builder: (context, ref, _) {
              final projectsAsync = ref.watch(allProjectsProvider);
              return projectsAsync.when(
                data: (projects) {
                  // Pre-fill selected projects on first load
                  if (selectedProjectIds.isEmpty) {
                    selectedProjectIds = projects
                        .where((p) => p['account_manager_id'] == member['id'])
                        .map((p) => p['id'] as String)
                        .toList();
                  }

                  return SizedBox(
                    width: 400,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'اختر العملاء المراد تعيينهم لهذا المدير:',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 300),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: projects.length,
                            itemBuilder: (context, i) {
                              final p = projects[i];
                              final isSelected = selectedProjectIds.contains(
                                p['id'],
                              );
                              return CheckboxListTile(
                                value: isSelected,
                                title: Text(
                                  p['name'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  p['profiles']?['company_name'] ?? '',
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 12,
                                  ),
                                ),
                                onChanged: (v) {
                                  setState(() {
                                    if (v == true)
                                      selectedProjectIds.add(p['id']);
                                    else
                                      selectedProjectIds.remove(p['id']);
                                  });
                                },
                                activeColor: AppTheme.primaryGreen,
                                checkColor: Colors.black,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text(
                  'Error: $e',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'إلغاء',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.black,
              ),
              onPressed: loading
                  ? null
                  : () async {
                      setState(() => loading = true);
                      try {
                        await ref
                            .read(adminActionsProvider)
                            .updateAmProjects(member['id'], selectedProjectIds);
                        ref.invalidate(allProjectsProvider);
                        ref.invalidate(teamListProvider);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم تحديث التعيينات بنجاح'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('خطأ: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                      } finally {
                        if (context.mounted) setState(() => loading = false);
                      }
                    },
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('حفظ التغييرات'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> member,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white)),
        content: Text(
          'هل أنت متأكد من حذف حساب ${member['full_name']}؟ لا يمكن التراجع عن هذا الإجراء وسيتم حذف جميع بيانات الدخول.',
          style: const TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'إلغاء',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              try {
                await ref
                    .read(adminActionsProvider)
                    .deleteTeamMember(member['id'], member['full_name'] ?? '');
                ref.invalidate(teamListProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حذف الحساب بنجاح')),
                  );
                }
              } catch (e) {
                if (context.mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('خطأ: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
              }
            },
            child: const Text('حذف نهائياً'),
          ),
        ],
      ),
    );
  }

  String _getRoleLabel(String? role) {
    switch (role) {
      case 'admin':
        return 'مدير النظام';
      case 'account_manager':
        return 'مدير حسابات';
      case 'seo_team':
        return 'خبير سيو';
      case 'ads_team':
        return 'خبير إعلانات';
      case 'tech_team':
        return 'مطور تقني';
      default:
        return role ?? 'عضو';
    }
  }

  void _showEditUserDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> member,
  ) {
    final nameController = TextEditingController(text: member['full_name']);
    String selectedRole = member['role'] ?? 'tech_team';
    bool loading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('تعديل بيانات العضو', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'الاسم الكامل',
                  labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                dropdownColor: const Color(0xFF0F172A),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'الدور الوظيفي',
                  filled: true,
                  fillColor: Color(0xFF0F172A),
                ),
                items: const [
                  DropdownMenuItem(value: 'account_manager', child: Text('مدير حسابات')),
                  DropdownMenuItem(value: 'seo_team', child: Text('خبير سيو')),
                  DropdownMenuItem(value: 'ads_team', child: Text('خبير إعلانات')),
                  DropdownMenuItem(value: 'tech_team', child: Text('مطور تقني')),
                  DropdownMenuItem(value: 'admin', child: Text('مدير نظام')),
                ],
                onChanged: (v) => setState(() => selectedRole = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.black),
              onPressed: loading ? null : () async {
                setState(() => loading = true);
                try {
                  await ref.read(adminActionsProvider).updateUser({
                    'userId': member['id'],
                    'full_name': nameController.text.trim(),
                    'role': selectedRole,
                  });
                  ref.invalidate(teamListProvider);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم تحديث البيانات بنجاح ✅')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
                    );
                  }
                } finally {
                  if (context.mounted) setState(() => loading = false);
                }
              },
              child: loading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                : const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}

