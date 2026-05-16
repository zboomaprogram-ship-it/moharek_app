import 'package:flutter/material.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/l10n/app_localizations.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 60, color: AppTheme.primaryGreen.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 32),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    foregroundColor: AppTheme.primaryGreen,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(actionLabel!, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget reports(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EmptyState(
      icon: Icons.analytics_outlined,
      title: l10n.reportsEmptyTitle,
      message: l10n.reportsEmptyMsg,
    );
  }
  
  static Widget tasks(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EmptyState(
      icon: Icons.task_alt,
      title: l10n.tasksEmptyTitle,
      message: l10n.tasksEmptyMsg,
    );
  }
  
  static Widget approvals(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EmptyState(
      icon: Icons.verified_user_outlined,
      title: l10n.approvalsEmptyTitle,
      message: l10n.approvalsEmptyMsg,
    );
  }
  
  static Widget generic(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EmptyState(
      icon: Icons.inbox_outlined,
      title: l10n.genericEmptyTitle,
      message: l10n.genericEmptyMsg,
    );
  }

  static Widget meetings(BuildContext context) {
    return const EmptyState(
      icon: Icons.videocam_outlined,
      title: 'No Meetings',
      message: 'You have no upcoming or past meetings scheduled.',
    );
  }

  static Widget files(BuildContext context) {
    return const EmptyState(
      icon: Icons.folder_open_outlined,
      title: 'No Files',
      message: 'Brand guidelines, plans, and assets will appear here.',
    );
  }

  static Widget campaigns(BuildContext context) {
    return const EmptyState(
      icon: Icons.campaign_outlined,
      title: 'No Campaigns',
      message: 'Your active and past growth campaigns will appear here.',
    );
  }
}
