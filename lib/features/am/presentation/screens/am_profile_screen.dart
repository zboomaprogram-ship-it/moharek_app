import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';
import 'package:moharek_app/features/am/data/am_providers.dart';
import 'package:moharek_app/shared/widgets/fade_in_slide.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AmProfileScreen extends ConsumerStatefulWidget {
  const AmProfileScreen({super.key});

  @override
  ConsumerState<AmProfileScreen> createState() => _AmProfileScreenState();
}

class _AmProfileScreenState extends ConsumerState<AmProfileScreen> {
  late final TextEditingController _nameCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final actions = ref.read(adminActionsProvider);
      await actions.updateAdminProfile({'full_name': _nameCtrl.text.trim()});
      
      ref.invalidate(profileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ الملف الشخصي ✅'),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final user = Supabase.instance.client.auth.currentUser;
    final isMobile = MediaQuery.of(context).size.width < 1000;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (_nameCtrl.text.isEmpty && profile != null) {
            _nameCtrl.text = profile.fullName;
          }
          
          final content = [
            // Main Profile Card
            FadeInSlide(
              duration: const Duration(milliseconds: 400),
              child: _buildMainProfileCard(profile, user, isMobile),
            ),
            SizedBox(height: isMobile ? 24 : 0, width: isMobile ? 0 : 24),
            // Stats & Secondary Info
            if (isMobile)
              Column(
                children: [
                  FadeInSlide(
                    duration: const Duration(milliseconds: 500),
                    child: _buildStatsCard(ref),
                  ),
                  if (profile?.role == 'admin') ...[
                    const SizedBox(height: 24),
                    FadeInSlide(
                      duration: const Duration(milliseconds: 600),
                      child: _buildSecurityCard(),
                    ),
                  ],
                ],
              )
            else
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    FadeInSlide(
                      duration: const Duration(milliseconds: 500),
                      child: _buildStatsCard(ref),
                    ),
                    if (profile?.role == 'admin') ...[
                      const SizedBox(height: 24),
                      FadeInSlide(
                        duration: const Duration(milliseconds: 600),
                        child: _buildSecurityCard(),
                      ),
                    ],
                  ],
                ),
              ),
          ];

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إدارة الحساب',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 24 : 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'تخصيص ملفك الشخصي وإدارة إعدادات الوصول',
                  style: TextStyle(
                    color: const Color(0xFF64748B),
                    fontSize: isMobile ? 12 : 14,
                  ),
                ),
                const SizedBox(height: 40),
                
                if (isMobile)
                  Column(children: content)
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: content[0]),
                      content[1],
                      content[2],
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainProfileCard(profile, user, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : 40),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final useStack = constraints.maxWidth < 400;
              final headerContent = [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: isMobile ? 40 : 60,
                        backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.05),
                        child: Text(
                          _nameCtrl.text.isNotEmpty ? _nameCtrl.text[0] : '?',
                          style: TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: isMobile ? 32 : 48,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: AppTheme.primaryGreen, shape: BoxShape.circle),
                      child: const Icon(Icons.edit, size: 16, color: Colors.black),
                    ),
                  ],
                ),
                SizedBox(width: useStack ? 0 : 32, height: useStack ? 16 : 0),
                Column(
                  crossAxisAlignment: useStack ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'مدير حسابات معتمد',
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _nameCtrl.text,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 20 : 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                  ],
                ),
              ];

              return useStack
                  ? Column(children: headerContent)
                  : Row(children: headerContent);
            },
          ),
          const SizedBox(height: 48),
          const Divider(color: Color(0xFF334155), height: 1),
          const SizedBox(height: 48),
          _buildInput('الاسم الكامل', _nameCtrl, Icons.person_outline),
          const SizedBox(height: 24),
          _buildReadOnlyInput('البريد الإلكتروني الأساسي', user?.email ?? '', Icons.alternate_email_rounded),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: _saving ? null : _save,
              child: _saving 
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text('تحديث البيانات', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(WidgetRef ref) {
    final clients = ref.watch(amClientsProvider).value ?? [];
    final tasks = ref.watch(amGlobalTasksProvider).value ?? [];
    final reports = ref.watch(amGlobalReportsProvider).value ?? [];
    
    final openTasks = tasks.where((t) => t['status'] != 'completed').length;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          _buildStatRow('العملاء المسندين', clients.length.toString(), Icons.business_center_rounded, AppTheme.primaryBlue),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Color(0xFF334155))),
          _buildStatRow('المهام المفتوحة', openTasks.toString(), Icons.task_alt_rounded, AppTheme.primaryGreen),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Color(0xFF334155))),
          _buildStatRow('تقارير الشهر', reports.length.toString(), Icons.description_rounded, Colors.orangeAccent),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 16),
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
        const Spacer(),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSecurityCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryBlue.withValues(alpha: 0.1), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_outlined, color: AppTheme.primaryBlue, size: 20),
              SizedBox(width: 12),
              Text('الأمان والخصوصية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'حسابك محمي بواسطة نظام المصادقة الثنائي التابع لمحرك.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => _showChangePasswordDialog(),
            child: const Text('تغيير كلمة المرور', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool loading = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('تغيير كلمة المرور', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passCtrl,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور الجديدة',
                  labelStyle: TextStyle(color: Color(0xFF64748B)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmCtrl,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'تأكيد كلمة المرور',
                  labelStyle: TextStyle(color: Color(0xFF64748B)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: loading ? null : () async {
                if (passCtrl.text != confirmCtrl.text || passCtrl.text.length < 6) return;
                setModalState(() => loading = true);
                try {
                  await Supabase.instance.client.auth.updateUser(UserAttributes(password: passCtrl.text));
                  if (mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم تغيير كلمة المرور بنجاح ✅'), backgroundColor: AppTheme.primaryGreen),
                    );
                  }
                } finally {
                  setModalState(() => loading = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.black),
              child: loading ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Text('تغيير'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController ctrl, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 8),
          child: Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
            filled: true,
            fillColor: const Color(0xFF0F172A),
            contentPadding: const EdgeInsets.all(20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.transparent)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyInput(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 8),
          child: Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1E293B), width: 1),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF334155), size: 20),
              const SizedBox(width: 12),
              Text(value, style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}
