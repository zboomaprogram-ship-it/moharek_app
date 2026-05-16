import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/shared/models/approval.dart';
import 'package:moharek_app/l10n/app_localizations.dart';
import 'package:moharek_app/shared/widgets/empty_state.dart';
import 'package:moharek_app/shared/services/haptic_service.dart';
import 'package:moharek_app/shared/widgets/shimmer_placeholders.dart';
import 'package:moharek_app/features/approvals/presentation/screens/approval_detail_screen.dart';

class ApprovalsScreen extends ConsumerWidget {
  const ApprovalsScreen({super.key});

  Future<void> _updateStatus(
    WidgetRef ref,
    String id,
    String status, {
    String? notes,
  }) async {
    final client = ref.read(supabaseClientProvider);
    await client
        .from('approvals')
        .update({
          'status': status,
          'client_notes': notes,
          'responded_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);

    // Refresh the list
    ref.invalidate(approvalsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approvalsAsync = ref.watch(approvalsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.waitingApproval)),
      body: approvalsAsync.when(
        loading: () => const ShimmerList(itemCount: 4, itemHeight: 120),
        error: (err, _) => Center(child: Text(AppLocalizations.of(context)!.errorOccurred(err.toString()))),
        data: (approvals) {
          if (approvals.isEmpty) {
            return EmptyState.approvals(context);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: approvals.length,
            itemBuilder: (context, index) {
              final approval = approvals[index];
              return _buildApprovalCard(context, ref, approval);
            },
          );
        },
      ),
    );
  }

  Widget _buildApprovalCard(
    BuildContext context,
    WidgetRef ref,
    ApprovalRequest approval,
  ) {
    final isPending = approval.status == 'pending';
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ApprovalDetailScreen(approval: approval),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPending
                ? AppTheme.primaryBlue.withValues(alpha: 0.3)
                : Colors.white10,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  approval.approvalType.toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.primaryBlue,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusBadge(approval.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              approval.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              approval.description,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),
            if (isPending)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showFeedbackDialog(
                        context,
                        ref,
                        approval,
                        'needs_edit',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                      ),
                      child: Text(l10n.requestChanges),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        HapticService.medium();
                        _updateStatus(ref, approval.id, 'approved');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.black,
                      ),
                      child: Text(l10n.approve),
                    ),
                  ),
                ],
              )
            else if (approval.status == 'approved')
              Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppTheme.primaryGreen,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.approved,
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  const Icon(Icons.edit_note, color: Colors.redAccent, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    approval.status == 'rejected' ? l10n.rejected : l10n.changesRequested,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'approved':
        color = AppTheme.primaryGreen;
        break;
      case 'changes_requested':
      case 'needs_edit':
        color = Colors.redAccent;
        break;
      default:
        color = AppTheme.primaryBlue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showFeedbackDialog(
    BuildContext context,
    WidgetRef ref,
    ApprovalRequest approval,
    String status,
  ) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: Text(AppLocalizations.of(context)!.feedback, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.describeChanges,
            hintStyle: const TextStyle(color: Colors.grey),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              _updateStatus(ref, approval.id, status, notes: controller.text);
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.send),
          ),
        ],
      ),
    );
  }
}
