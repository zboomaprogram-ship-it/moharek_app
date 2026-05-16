import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Providers ────────────────────────────────────────────────────────────────

final adminProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return null;
  return await client.from('profiles').select().eq('id', userId).maybeSingle();
});

// ── Admin Settings Screen ─────────────────────────────────────────────────────

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(adminProfileProvider);
    final supabase = ref.watch(supabaseClientProvider);
    final user = supabase.auth.currentUser;
    final isMobile = MediaQuery.of(context).size.width < 1000;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'الإعدادات',
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 24 : 32,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'إدارة إعدادات النظام والملف الشخصي',
              style: TextStyle(
                color: const Color(0xFF64748B),
                fontSize: isMobile ? 12 : 14,
              ),
            ),
            const SizedBox(height: 32),

            // ── Admin Profile ────────────────────────────────────────
            _sectionTitle('ملفك الشخصي'),
            const SizedBox(height: 12),
            profileAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              ),
              error: (e, _) => Text(
                'Error: $e',
                style: const TextStyle(color: Colors.red),
              ),
              data: (profile) => _AdminProfileCard(
                profile: profile,
                user: user,
                isMobile: isMobile,
              ),
            ),

            const SizedBox(height: 32),

            // ── Client Management ────────────────────────────────────
            _sectionTitle('إدارة العملاء'),
            const SizedBox(height: 12),
            _ClientPasswordCard(),

            const SizedBox(height: 32),

            // ── Danger Zone ──────────────────────────────────────────
            _sectionTitle('الخروج', color: Colors.redAccent),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withAlpha(40)),
              ),
              child: isMobile
                  ? Column(
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.logout, color: Colors.redAccent, size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'تسجيل الخروج من لوحة الإدارة',
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              await Supabase.instance.client.auth.signOut();
                              if (context.mounted) context.go('/login');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('خروج'),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'تسجيل الخروج من لوحة الإدارة',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            await Supabase.instance.client.auth.signOut();
                            if (context.mounted) context.go('/login');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          child: const Text('خروج'),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, {Color color = Colors.white}) {
    return Text(title,
      style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold));
  }
}

// ── Admin Profile Card ────────────────────────────────────────────────────────

class _AdminProfileCard extends ConsumerStatefulWidget {
  final Map<String, dynamic>? profile;
  final User? user;
  final bool isMobile;
  const _AdminProfileCard({required this.profile, required this.user, required this.isMobile});

  @override
  ConsumerState<_AdminProfileCard> createState() => _AdminProfileCardState();
}

class _AdminProfileCardState extends ConsumerState<_AdminProfileCard> {
  late final TextEditingController _nameCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile?['full_name'] as String? ?? '');
  }

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
      ref.invalidate(adminProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ الملف الشخصي ✅'), backgroundColor: AppTheme.primaryGreen),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: widget.isMobile ? 24 : 28,
                backgroundColor: AppTheme.primaryGreen.withAlpha(40),
                child: Text(
                  (_nameCtrl.text.isNotEmpty ? _nameCtrl.text[0] : 'A').toUpperCase(),
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: widget.isMobile ? 18 : 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('الاسم', style: TextStyle(color: Colors.grey, fontSize: 11)),
                    TextField(
                      controller: _nameCtrl,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: widget.isMobile ? 14 : 15,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.user?.email ?? '',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.black,
              ),
              child: _saving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text('حفظ التغييرات'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Client Password Reset Card ────────────────────────────────────────────────

class _ClientPasswordCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ClientPasswordCard> createState() => _ClientPasswordCardState();
}

class _ClientPasswordCardState extends ConsumerState<_ClientPasswordCard> {
  String? _selectedProjectId;
  final _newPasswordCtrl = TextEditingController();
  bool _sending = false;
  bool _obscure = true;
  String? _lastGeneratedPassword;

  @override
  void dispose() {
    _newPasswordCtrl.dispose();
    super.dispose();
  }

  String _generatePassword() {
    const chars = 'ABCDEFGHJKMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
    final rand = DateTime.now().millisecondsSinceEpoch;
    return List.generate(10, (i) => chars[(rand + i * 13) % chars.length]).join();
  }

  Future<void> _resetPassword() async {
    if (_selectedProjectId == null || _newPasswordCtrl.text.length < 8) return;
    setState(() => _sending = true);

    try {
      final actions = ref.read(adminActionsProvider);
      
      // Get client name for logging
      final projects = ref.read(allProjectsProvider).value ?? [];
      final project = projects.firstWhere((p) => p['id'] == _selectedProjectId);
      final profile = project['profiles'] as Map<String, dynamic>?;
      final name = profile?['company_name'] ?? profile?['full_name'] ?? 'Client';
      final clientId = project['client_id'] as String;

      await actions.resetClientPassword({
        'clientId': clientId,
        'newPassword': _newPasswordCtrl.text.trim(),
        'clientName': name,
      });

      setState(() => _lastGeneratedPassword = _newPasswordCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تغيير كلمة المرور ✅'), backgroundColor: AppTheme.primaryGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(allProjectsProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lock_reset, color: AppTheme.primaryBlue, size: 20),
              SizedBox(width: 10),
              Text('تغيير كلمة مرور عميل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),

          // Client selector
          projectsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('خطأ في تحميل العملاء', style: TextStyle(color: Colors.red)),
            data: (projects) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: const Color(0xFF1A2235), borderRadius: BorderRadius.circular(12)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedProjectId,
                  hint: const Text('اختر عميلاً', style: TextStyle(color: Colors.grey)),
                  dropdownColor: AppTheme.cardColor,
                  isExpanded: true,
                  items: projects.map((p) {
                    final pr = p['profiles'] as Map<String, dynamic>?;
                    final name = pr?['company_name'] as String? ?? pr?['full_name'] as String? ?? 'Client';
                    return DropdownMenuItem(
                      value: p['id'] as String,
                      child: Text(name, style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedProjectId = val),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Password field with generate button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newPasswordCtrl,
                  obscureText: _obscure,
                  style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    hintText: 'كلمة المرور الجديدة',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF1A2235),
                    border: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12))),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 18),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Auto-generate button
              Tooltip(
                message: 'توليد كلمة مرور',
                child: IconButton(
                  onPressed: () {
                    final pwd = _generatePassword();
                    _newPasswordCtrl.text = pwd;
                    setState(() => _obscure = false);
                  },
                  icon: const Icon(Icons.auto_fix_high, color: AppTheme.primaryGreen),
                ),
              ),
            ],
          ),

          // Show & copy last generated password
          if (_lastGeneratedPassword != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryGreen.withAlpha(40)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: AppTheme.primaryGreen, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'كلمة المرور الجديدة: $_lastGeneratedPassword',
                      style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: AppTheme.primaryGreen, size: 16),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _lastGeneratedPassword!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم النسخ'), duration: Duration(seconds: 1)),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_sending || _selectedProjectId == null || _newPasswordCtrl.text.length < 8)
                  ? null
                  : _resetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _sending
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('تغيير كلمة المرور'),
            ),
          ),
        ],
      ),
    );
  }
}
