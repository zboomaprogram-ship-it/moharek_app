import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';

class ClientInfoTab extends ConsumerStatefulWidget {
  final String pid;
  final bool isAdmin;

  const ClientInfoTab({
    super.key,
    required this.pid,
    this.isAdmin = false,
  });

  @override
  ConsumerState<ClientInfoTab> createState() => _ClientInfoTabState();
}

class _ClientInfoTabState extends ConsumerState<ClientInfoTab> {
  bool _passwordVisible = false;
  bool _isEditing = false;

  // Edit controllers
  final _nameCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _projectNameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _companyCtrl.dispose();
    _projectNameCtrl.dispose();
    super.dispose();
  }

  void _populateControllers(Map<String, dynamic> data) {
    final profile = data['profiles'] as Map<String, dynamic>? ?? {};
    _nameCtrl.text = profile['full_name'] ?? '';
    _companyCtrl.text = profile['company_name'] ?? '';
    _projectNameCtrl.text = data['name'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(clientDetailProvider(widget.pid));
    final isMobile = MediaQuery.of(context).size.width < 800;

    return detailAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
      data: (data) {
        if (data.isEmpty) {
          return const Center(child: Text('Client not found', style: TextStyle(color: Colors.grey)));
        }

        final profile = data['profiles'] as Map<String, dynamic>? ?? {};
        final clientId = profile['id'] as String? ?? '';
        final fullName = profile['full_name'] as String? ?? '—';
        final email = profile['email'] as String? ?? '—';
        final companyName = profile['company_name'] as String? ?? '—';
        final isActive = profile['is_active'] as bool? ?? true;
        final createdAt = profile['created_at'] as String?;
        final avatarUrl = profile['avatar_url'] as String?;

        final projectName = data['name'] as String? ?? '—';
        final stage = data['current_stage'] as String? ?? 'audit';
        final healthScore = (data['health_score'] ?? 0).toDouble();

        // Populate controllers if not editing yet
        if (!_isEditing) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_isEditing) {
              _nameCtrl.text = fullName == '—' ? '' : fullName;
              _companyCtrl.text = companyName == '—' ? '' : companyName;
              _projectNameCtrl.text = projectName == '—' ? '' : projectName;
            }
          });
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────
                Row(
                  children: [
                    _buildAvatar(avatarUrl, fullName, isActive),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          _buildStatusBadge(isActive),
                        ],
                      ),
                    ),
                    if (widget.isAdmin)
                      TextButton.icon(
                        onPressed: () {
                          if (_isEditing) {
                            _saveChanges(context, clientId, data);
                          } else {
                            _populateControllers(data);
                            setState(() => _isEditing = true);
                          }
                        },
                        icon: Icon(_isEditing ? Icons.save_outlined : Icons.edit_outlined, size: 16),
                        label: Text(_isEditing ? 'Save' : 'Edit'),
                        style: TextButton.styleFrom(
                          foregroundColor: _isEditing ? AppTheme.primaryGreen : Colors.white70,
                        ),
                      ),
                    if (_isEditing)
                      TextButton(
                        onPressed: () => setState(() => _isEditing = false),
                        child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                      ),
                  ],
                ),

                const SizedBox(height: 32),

                // ── Profile Info Card ────────────────────────────────
                _buildSectionCard(
                  title: 'Client Information',
                  icon: Icons.person_outline,
                  children: [
                    _buildInfoRow(
                      label: 'Full Name',
                      value: fullName,
                      controller: _nameCtrl,
                      isEditing: _isEditing && widget.isAdmin,
                    ),
                    _buildInfoRow(
                      label: 'Email',
                      value: email,
                      controller: null,
                      isEditing: false,
                      trailing: IconButton(
                        icon: const Icon(Icons.copy, size: 16, color: Color(0xFF64748B)),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: email));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Email copied'), backgroundColor: AppTheme.primaryGreen, duration: Duration(seconds: 1)),
                          );
                        },
                      ),
                    ),
                    _buildInfoRow(
                      label: 'Company',
                      value: companyName,
                      controller: _companyCtrl,
                      isEditing: _isEditing && widget.isAdmin,
                    ),
                    if (createdAt != null)
                      _buildInfoRow(
                        label: 'Member Since',
                        value: _formatDate(createdAt),
                        controller: null,
                        isEditing: false,
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Project Info Card ────────────────────────────────
                _buildSectionCard(
                  title: 'Project Details',
                  icon: Icons.rocket_launch_outlined,
                  children: [
                    _buildInfoRow(
                      label: 'Project Name',
                      value: projectName,
                      controller: _projectNameCtrl,
                      isEditing: _isEditing && widget.isAdmin,
                    ),
                    _buildInfoRow(
                      label: 'Stage',
                      value: stage.toUpperCase(),
                      controller: null,
                      isEditing: false,
                      valueWidget: _buildStageBadge(stage),
                    ),
                    _buildInfoRow(
                      label: 'Health Score',
                      value: '${healthScore.toStringAsFixed(0)}%',
                      controller: null,
                      isEditing: false,
                      valueWidget: _buildHealthBar(healthScore),
                    ),
                  ],
                ),

                // ── Security Card (Admin Only) ────────────────────────
                if (widget.isAdmin) ...[
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    title: 'Security',
                    icon: Icons.lock_outline,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 130,
                              child: Text('Password', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                            ),
                            Expanded(
                              child: Text(
                                _passwordVisible ? '(stored securely — use Reset to change)' : '●●●●●●●●●●●●',
                                style: TextStyle(
                                  color: _passwordVisible ? Colors.grey : Colors.white,
                                  fontSize: 14,
                                  letterSpacing: _passwordVisible ? 0 : 4,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _passwordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                size: 18,
                                color: const Color(0xFF64748B),
                              ),
                              onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Color(0xFF1E293B)),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Reset Password', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                            OutlinedButton.icon(
                              onPressed: () => _showResetPasswordDialog(context, clientId, fullName),
                              icon: const Icon(Icons.refresh, size: 14),
                              label: const Text('Reset'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orange,
                                side: const BorderSide(color: Colors.orange),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // ── Danger Zone (Admin Only) ──────────────────────────
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    title: 'Danger Zone',
                    icon: Icons.warning_amber_outlined,
                    accentColor: Colors.redAccent,
                    children: [
                      // Block / Unblock
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isActive ? 'Block User' : 'Unblock User',
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  isActive
                                      ? 'Prevent this user from accessing the app'
                                      : 'Restore access for this user',
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _toggleBlock(context, clientId, fullName, isActive),
                              icon: Icon(isActive ? Icons.block : Icons.check_circle_outline, size: 16),
                              label: Text(isActive ? 'Block' : 'Unblock'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isActive ? Colors.orange.withValues(alpha: 0.15) : AppTheme.primaryGreen.withValues(alpha: 0.15),
                                foregroundColor: isActive ? Colors.orange : AppTheme.primaryGreen,
                                side: BorderSide(color: isActive ? Colors.orange : AppTheme.primaryGreen),
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Color(0xFF2D1B1B)),
                      // Delete Project
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Delete Project', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                Text('Permanently delete this project and all data', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _deleteProject(context, projectName),
                              icon: const Icon(Icons.delete_outline, size: 16),
                              label: const Text('Delete Project'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.withValues(alpha: 0.1),
                                foregroundColor: Colors.redAccent,
                                side: const BorderSide(color: Colors.redAccent),
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Color(0xFF2D1B1B)),
                      // Delete User Account
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Delete User Account', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                Text('Permanently delete the user account from auth', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _deleteUserAccount(context, clientId, fullName),
                              icon: const Icon(Icons.person_remove_outlined, size: 16),
                              label: const Text('Delete Account'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.withValues(alpha: 0.2),
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Helper Widgets ───────────────────────────────────────────────────

  Widget _buildAvatar(String? avatarUrl, String name, bool isActive) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: isActive ? AppTheme.primaryGreen : Colors.orange, width: 2),
          ),
          child: CircleAvatar(
            radius: 36,
            backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'C',
                    style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 24, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
        ),
        Positioned(
          bottom: 2,
          right: 2,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AppTheme.primaryGreen : Colors.orange,
              border: const Border.fromBorderSide(BorderSide(color: Color(0xFF0F172A), width: 2)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: (isActive ? AppTheme.primaryGreen : Colors.orange).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (isActive ? AppTheme.primaryGreen : Colors.orange).withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isActive ? Icons.check_circle_outline : Icons.block_outlined, size: 12, color: isActive ? AppTheme.primaryGreen : Colors.orange),
          const SizedBox(width: 4),
          Text(
            isActive ? 'Active' : 'Blocked',
            style: TextStyle(color: isActive ? AppTheme.primaryGreen : Colors.orange, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color accentColor = AppTheme.primaryGreen,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 18),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF334155), height: 1),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required TextEditingController? controller,
    required bool isEditing,
    Widget? valueWidget,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          ),
          Expanded(
            child: isEditing && controller != null
                ? TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.primaryGreen),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                    ),
                  )
                : valueWidget ??
                    Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildStageBadge(String stage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
      ),
      child: Text(stage.toUpperCase(), style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    );
  }

  Widget _buildHealthBar(double health) {
    final color = health >= 70 ? AppTheme.primaryGreen : health >= 40 ? Colors.orange : Colors.red;
    return Row(
      children: [
        SizedBox(
          width: 100,
          height: 6,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: health / 100,
              backgroundColor: const Color(0xFF0F172A),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('${health.toStringAsFixed(0)}%', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  // ── Actions ──────────────────────────────────────────────────────────

  Future<void> _saveChanges(BuildContext context, String clientId, Map<String, dynamic> data) async {
    try {
      final actions = ref.read(adminActionsProvider);
      await actions.updateClientProfile(
        userId: clientId,
        projectId: widget.pid,
        fullName: _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : null,
        companyName: _companyCtrl.text.trim().isNotEmpty ? _companyCtrl.text.trim() : null,
        projectName: _projectNameCtrl.text.trim().isNotEmpty ? _projectNameCtrl.text.trim() : null,
      );
      ref.invalidate(clientDetailProvider(widget.pid));
      if (context.mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Client info updated ✅'), backgroundColor: AppTheme.primaryGreen),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showResetPasswordDialog(BuildContext context, String clientId, String clientName) {
    final passCtrl = TextEditingController();
    bool loading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Reset Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Setting new password for: $clientName', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: passCtrl,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'New Password',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.black),
              onPressed: loading
                  ? null
                  : () async {
                      if (passCtrl.text.trim().length < 6) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Password must be at least 6 characters'), backgroundColor: Colors.red),
                        );
                        return;
                      }
                      setDialogState(() => loading = true);
                      try {
                        final actions = ref.read(adminActionsProvider);
                        await actions.resetClientPassword({'clientId': clientId, 'clientName': clientName, 'newPassword': passCtrl.text.trim()});
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password reset successfully ✅'), backgroundColor: AppTheme.primaryGreen),
                          );
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                        }
                      } finally {
                        if (ctx.mounted) setDialogState(() => loading = false);
                      }
                    },
              child: loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleBlock(BuildContext context, String clientId, String name, bool isActive) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(isActive ? 'Block User' : 'Unblock User', style: const TextStyle(color: Colors.white)),
        content: Text(
          isActive
              ? 'Are you sure you want to block $name? They will not be able to log in.'
              : 'Are you sure you want to restore access for $name?',
          style: const TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: isActive ? Colors.orange : AppTheme.primaryGreen, foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isActive ? 'Block' : 'Unblock'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        final actions = ref.read(adminActionsProvider);
        await actions.toggleUserStatus(clientId, !isActive);
        ref.invalidate(clientDetailProvider(widget.pid));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isActive ? 'User blocked successfully' : 'User unblocked successfully'),
              backgroundColor: isActive ? Colors.orange : AppTheme.primaryGreen,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  Future<void> _deleteProject(BuildContext context, String projectName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Project', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to permanently delete "$projectName"? This cannot be undone.',
          style: const TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Project'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final actions = ref.read(adminActionsProvider);
        await actions.deleteProject(widget.pid, projectName);
        ref.invalidate(allProjectsProvider);
        ref.invalidate(adminOverviewProvider);
        if (context.mounted) {
          final location = GoRouterState.of(context).matchedLocation;
          if (location.startsWith('/am')) {
            context.go('/am/clients');
          } else {
            context.go('/admin/clients');
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  Future<void> _deleteUserAccount(BuildContext context, String clientId, String name) async {
    // Require typing "DELETE" to confirm
    final confirmCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Delete User Account', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '⚠️ This will permanently delete $name\'s account from authentication. The project and all data must be deleted separately.',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text('Type DELETE to confirm:', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 8),
              TextField(
                controller: confirmCtrl,
                style: const TextStyle(color: Colors.white),
                onChanged: (_) => setS(() {}),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.red)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: confirmCtrl.text == 'DELETE' ? () => Navigator.pop(ctx, true) : null,
              child: const Text('Delete Account'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final actions = ref.read(adminActionsProvider);
        await actions.deleteUserAccount(clientId, name);
        ref.invalidate(allProjectsProvider);
        ref.invalidate(adminOverviewProvider);
        ref.invalidate(teamListProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User account deleted'), backgroundColor: Colors.red),
          );
          context.go('/admin/clients');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }
}
