import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/shared/models/approval.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/shared/widgets/pdf_viewer_screen.dart';
import 'package:moharek_app/shared/widgets/image_viewer_screen.dart';
import 'package:moharek_app/shared/services/haptic_service.dart';
import 'package:moharek_app/shared/utils/file_helper.dart';
import 'package:moharek_app/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class ApprovalDetailScreen extends ConsumerWidget {
  final ApprovalRequest approval;

  const ApprovalDetailScreen({super.key, required this.approval});

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    String status, {
    String? notes,
  }) async {
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
    );

    try {
      final client = ref.read(supabaseClientProvider);
      await client
          .from('approvals')
          .update({
            'status': status,
            'client_notes': notes,
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', approval.id);

      ref.invalidate(approvalsProvider);
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog
        Navigator.of(context).pop(); // Close detail screen
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء حفظ الموافقة: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isPending = approval.status == 'pending';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.approvalDetail),
        actions: [
          if (approval.fileUrl != null)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () {
                // TODO: Share link
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 32),
            _buildInfoSection(l10n.description, approval.description),
            if (approval.teamNotes != null) ...[
              const SizedBox(height: 24),
              _buildInfoSection(l10n.teamNotes, approval.teamNotes!, isAccent: true),
            ],
            if (approval.clientNotes != null) ...[
              const SizedBox(height: 24),
              _buildInfoSection(l10n.yourFeedback, approval.clientNotes!),
            ],
            const SizedBox(height: 32),
            if (approval.fileUrl != null) _buildFileCard(context, l10n),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: isPending ? _buildBottomActions(context, ref, l10n) : null,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            approval.approvalType.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.primaryBlue,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          approval.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sent on ${_formatDate(approval.createdAt)}',
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildInfoSection(String title, String content, {bool isAccent = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: isAccent ? AppTheme.primaryBlue : Colors.grey,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isAccent ? AppTheme.primaryBlue.withValues(alpha: 0.05) : AppTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isAccent ? AppTheme.primaryBlue.withValues(alpha: 0.2) : Colors.white10),
          ),
          child: Text(
            content,
            style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildFileCard(BuildContext context, AppLocalizations l10n) {
    final fileUrl = approval.fileUrl!;
    final lowerUrl = fileUrl.toLowerCase();
    final isImage = lowerUrl.endsWith('.png') || 
                    lowerUrl.endsWith('.jpg') || 
                    lowerUrl.endsWith('.jpeg') ||
                    lowerUrl.endsWith('.gif') ||
                    lowerUrl.endsWith('.webp');
    final isPdf = lowerUrl.endsWith('.pdf');

    return GestureDetector(
      onTap: () => openFileInApp(context, fileUrl, approval.title),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isImage ? Icons.image_outlined : (isPdf ? Icons.picture_as_pdf_outlined : Icons.insert_drive_file_outlined),
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isImage ? l10n.viewDesign : l10n.viewDocument,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const Text('Tap to open full preview', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showFeedbackDialog(context, ref, 'needs_edit'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(l10n.requestChanges),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  HapticService.medium();
                  _updateStatus(context, ref, 'approved');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(l10n.approve, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context, WidgetRef ref, String status) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: Text(AppLocalizations.of(context)!.feedback, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          maxLines: 4,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.describeChanges,
            hintStyle: const TextStyle(color: Colors.grey),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              _updateStatus(context, ref, status, notes: controller.text);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.black),
            child: Text(AppLocalizations.of(context)!.send),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
