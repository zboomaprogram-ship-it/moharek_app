import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class OverviewTab extends ConsumerWidget {
  final String pid;
  const OverviewTab({super.key, required this.pid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(projectResultsProvider(pid));
    final reportsAsync = ref.watch(projectReportsProvider(pid));
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Recent Growth Results', () => _showAddMetric(context, ref)),
            const SizedBox(height: 16),
            resultsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (results) => _buildResultsGrid(results),
            ),
            const SizedBox(height: 40),
            _sectionHeader('Growth Reports (PDF)', () => _uploadReport(context, ref)),
            const SizedBox(height: 16),
            reportsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (reports) => _buildReportsList(context, ref, reports),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, VoidCallback onAdd) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        IconButton(
          onPressed: onAdd,
          icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryGreen),
        ),
      ],
    );
  }

  Widget _buildResultsGrid(List<Map<String, dynamic>> results) {
    if (results.isEmpty) return const Center(child: Text('No metrics logged yet', style: TextStyle(color: Colors.white24)));
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemCount: results.length > 4 ? 4 : results.length,
      itemBuilder: (context, index) {
        final r = results[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(r['metric_label'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 10)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '${r['metric_value']} ${r['metric_unit'] ?? ''}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Spacer(),
                  if (r['change_from_last'] != null)
                    Text(
                      '${r['change_from_last'] > 0 ? '+' : ''}${r['change_from_last']}%',
                      style: TextStyle(
                        color: r['change_from_last'] > 0 ? AppTheme.primaryGreen : Colors.redAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportsList(BuildContext context, WidgetRef ref, List<Map<String, dynamic>> reports) {
    if (reports.isEmpty) return const Center(child: Text('No reports uploaded yet', style: TextStyle(color: Colors.white24)));

    return Column(
      children: reports.map((r) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 20),
          title: Text(r['title'] ?? 'Report', style: const TextStyle(color: Colors.white, fontSize: 13)),
          subtitle: Text(r['period'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 11)),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white24, size: 18),
            onPressed: () async {
              final actions = ref.read(adminActionsProvider);
              await actions.deleteReport(r['id'], r['title'] ?? 'Report');
              ref.invalidate(projectReportsProvider(pid));
            },
          ),
        ),
      )).toList(),
    );
  }

  void _showAddMetric(BuildContext context, WidgetRef ref) {
    final labelCtrl = TextEditingController();
    final valCtrl = TextEditingController();
    final unitCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Log Growth Metric', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: labelCtrl, decoration: const InputDecoration(labelText: 'Metric Label (e.g. SEO Traffic)', labelStyle: TextStyle(color: Colors.grey))),
            TextField(controller: valCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Value', labelStyle: TextStyle(color: Colors.grey))),
            TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Unit (e.g. users)', labelStyle: TextStyle(color: Colors.grey))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (labelCtrl.text.isEmpty) return;
              final actions = ref.read(adminActionsProvider);
              await actions.createResult({
                'project_id': pid,
                'metric_label': labelCtrl.text.trim(),
                'metric_value': double.tryParse(valCtrl.text),
                'metric_unit': unitCtrl.text.trim(),
                'recorded_at': DateTime.now().toIso8601String(),
              });
              ref.invalidate(projectResultsProvider(pid));
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadReport(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf'], withData: kIsWeb);
    if (result == null) return;
    
    final file = result.files.first;
    final client = ref.read(supabaseClientProvider);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_report.pdf';

    try {
      if (kIsWeb && file.bytes != null) {
        await client.storage.from('reports').uploadBinary(fileName, file.bytes!);
      }
      final url = client.storage.from('reports').getPublicUrl(fileName);
      final actions = ref.read(adminActionsProvider);
      await actions.createReport({
        'project_id': pid,
        'title': file.name,
        'file_url': url,
        'report_type': 'monthly',
        'period': 'Current Month',
      });
      ref.invalidate(projectReportsProvider(pid));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }
}
