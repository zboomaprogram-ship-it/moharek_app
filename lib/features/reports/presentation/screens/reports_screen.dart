import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/shared/models/report.dart';
import 'package:moharek_app/features/reports/presentation/screens/report_viewer_screen.dart';
import 'package:moharek_app/l10n/app_localizations.dart';
import 'package:moharek_app/shared/widgets/empty_state.dart';
import 'package:moharek_app/shared/widgets/pdf_viewer_screen.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(reportsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.reportsTitle)),
      body: reportsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
        error: (err, _) => Center(
          child: Text(
            AppLocalizations.of(context)!.errorOccurred(err.toString()),
          ),
        ),
        data: (reports) {
          if (reports.isEmpty) {
            return EmptyState.reports(context);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              return _buildReportCard(context, reports, index);
            },
          );
        },
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context,
    List<ProjectReport> reports,
    int index,
  ) {
    final report = reports[index];
    final periodStr = report.periodStart != null && report.periodEnd != null
        ? '${report.periodStart!.month}/${report.periodStart!.day} - ${report.periodEnd!.month}/${report.periodEnd!.day}'
        : AppLocalizations.of(context)!.monthlyReport;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  report.reportType.toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.primaryBlue,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                AppLocalizations.of(context)!.ready,
                style: const TextStyle(
                  color: AppTheme.primaryGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            report.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            periodStr,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReportViewerScreen(
                          reports: reports,
                          initialIndex: index,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: Text(AppLocalizations.of(context)!.growthStory),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (report.fileUrl.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PdfViewerScreen(
                            url: report.fileUrl,
                            title: report.title,
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.remove_red_eye, size: 18),
                  label: Text(AppLocalizations.of(context)!.downloadPdf),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    foregroundColor: AppTheme.primaryGreen,
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
