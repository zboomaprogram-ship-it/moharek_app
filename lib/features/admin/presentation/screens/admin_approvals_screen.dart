import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';
import 'package:moharek_app/shared/services/data_providers.dart';

// ── Providers ─────────────────────────────────────────────────────

final allApprovalsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final data = await client
      .from('approvals')
      .select('*, projects(profiles!projects_client_id_fkey(full_name, company_name))')
      .order('created_at', ascending: false);
  return (data as List).cast<Map<String, dynamic>>();
});

// ── Admin Approvals Screen ────────────────────────────────────────

class AdminApprovalsScreen extends ConsumerWidget {
  const AdminApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approvalsAsync = ref.watch(allApprovalsProvider);
    final isMobile = MediaQuery.of(context).size.width < 1000;

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
                    'طلبات الاعتماد',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'إدارة الموافقات والطلبات المرسلة للعملاء',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showCreateApprovalSheet(context, ref),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('طلب جديد'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'طلبات الاعتماد',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'إدارة الموافقات والطلبات المرسلة للعملاء',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateApprovalSheet(context, ref),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('طلب جديد'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 32),
            Expanded(
              child: approvalsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                ),
                error: (err, _) => Center(
                  child: Text(
                    'Error: $err',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                data: (approvals) {
                  if (approvals.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    color: AppTheme.primaryGreen,
                    onRefresh: () async => ref.invalidate(allApprovalsProvider),
                    child: ListView.builder(
                      itemCount: approvals.length,
                      itemBuilder: (context, index) => _buildApprovalCard(
                        context,
                        ref,
                        approvals[index],
                        isMobile,
                      ),
                    ),
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pending_actions_outlined, color: Color(0xFF334155), size: 64),
          SizedBox(height: 16),
          Text('لا توجد طلبات حالياً', style: TextStyle(color: Color(0xFF64748B), fontSize: 16)),
          SizedBox(height: 8),
          Text('اضغط على "طلب جديد" لإرسال طلب اعتماد لعميل', style: TextStyle(color: Color(0xFF475569), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildApprovalCard(BuildContext context, WidgetRef ref, Map<String, dynamic> approval, bool isMobile) {
    final project = approval['projects'] as Map<String, dynamic>?;
    final profile = project?['profiles'] as Map<String, dynamic>?;
    final clientName = profile?['company_name'] as String? ?? profile?['full_name'] as String? ?? 'غير معروف';
    final status = approval['status'] as String? ?? 'pending';

    Color statusColor;
    String statusText;
    switch (status) {
      case 'approved':
        statusColor = AppTheme.primaryGreen;
        statusText = 'معتمد';
        break;
      case 'changes_requested':
        statusColor = Colors.redAccent;
        statusText = 'ملاحظات';
        break;
      default:
        statusColor = AppTheme.primaryBlue;
        statusText = 'قيد الانتظار';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: status == 'pending' ? AppTheme.primaryBlue.withValues(alpha: 0.2) : const Color(0xFF334155),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(clientName, style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _translateType(approval['approval_type'] as String? ?? 'general'),
                  style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            approval['title'] as String? ?? 'بدون عنوان',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 14 : 16,
            ),
          ),
          if ((approval['description'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              approval['description'] as String,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if ((approval['client_notes'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.feedback_outlined, color: Colors.orange, size: 16),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ملاحظات العميل:', style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          approval['client_notes'] as String,
                          style: const TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () async {
                  final actions = ref.read(adminActionsProvider);
                  await actions.deleteApproval(approval['id'], approval['title'] ?? 'Approval');
                  ref.invalidate(allApprovalsProvider);
                },
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                label: const Text('حذف', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _translateType(String type) {
    switch (type) {
      case 'content_calendar': return 'خطة محتوى';
      case 'design': return 'تصميم';
      case 'ad_copy': return 'نص إعلاني';
      case 'landing_page': return 'صفحة هبوط';
      case 'budget': return 'ميزانية';
      case 'campaign': return 'حمية إعلانية';
      case 'monthly_strategy': return 'استراتيجية شهرية';
      default: return 'عام';
    }
  }

  void _showCreateApprovalSheet(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final notesController = TextEditingController();
    String selectedType = 'content_calendar';
    String? selectedProjectId;

    final approvalTypes = [
      'content_calendar', 'design', 'ad_copy',
      'landing_page', 'budget', 'campaign', 'monthly_strategy',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('إرسال طلب اعتماد جديد', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('اختر العميل:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                const SizedBox(height: 8),
                Consumer(
                  builder: (context, ref, _) {
                    final projectsAsync = ref.watch(allProjectsProvider);
                    return projectsAsync.when(
                      data: (projects) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedProjectId,
                            hint: const Text('اختر المشروع', style: TextStyle(color: Color(0xFF64748B))),
                            dropdownColor: const Color(0xFF1E293B),
                            isExpanded: true,
                            items: projects.map((p) {
                              final profile = p['profiles'] as Map<String, dynamic>?;
                              final name = profile?['company_name'] as String? ?? 'عميل';
                              return DropdownMenuItem(value: p['id'] as String, child: Text(name, style: const TextStyle(color: Colors.white)));
                            }).toList(),
                            onChanged: (val) => setModalState(() => selectedProjectId = val),
                          ),
                        ),
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Text('Error loading clients', style: TextStyle(color: Colors.red)),
                    );
                  },
                ),
                const SizedBox(height: 16),

                const Text('نوع الاعتماد:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedType,
                      dropdownColor: const Color(0xFF1E293B),
                      isExpanded: true,
                      items: approvalTypes.map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(_translateType(t), style: const TextStyle(color: Colors.white, fontSize: 13)),
                      )).toList(),
                      onChanged: (val) => setModalState(() => selectedType = val!),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                _buildField(titleController, 'عنوان الطلب', Icons.title),
                const SizedBox(height: 12),
                _buildField(descController, 'وصف التفاصيل', Icons.description_outlined, maxLines: 3),
                const SizedBox(height: 12),
                _buildField(notesController, 'ملاحظات للفريق (تظهر للعميل)', Icons.note_outlined, maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedProjectId == null || titleController.text.isEmpty) return;
                final actions = ref.read(adminActionsProvider);
                await actions.createApproval({
                  'project_id': selectedProjectId,
                  'title': titleController.text.trim(),
                  'description': descController.text.trim(),
                  'approval_type': selectedType,
                  'team_notes': notesController.text.trim(),
                  'status': 'pending',
                });
                ref.invalidate(allApprovalsProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم إرسال طلب الاعتماد بنجاح ✅'), backgroundColor: AppTheme.primaryGreen),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('إرسال للعميل', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF64748B)),
        prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        border: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12))),
      ),
    );
  }
}
