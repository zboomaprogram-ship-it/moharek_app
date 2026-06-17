import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:moharek_app/core/theme/rabhan_theme.dart';

class AdminAnalyticsControlScreen extends StatefulWidget {
  final String projectId;

  const AdminAnalyticsControlScreen({super.key, required this.projectId});

  @override
  State<AdminAnalyticsControlScreen> createState() => _AdminAnalyticsControlScreenState();
}

class _AdminAnalyticsControlScreenState extends State<AdminAnalyticsControlScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  // Metrics form controllers
  final _salesCtrl = TextEditingController();
  final _profitCtrl = TextEditingController();
  final _spendCtrl = TextEditingController();
  final _roasCtrl = TextEditingController();
  final _conversionCtrl = TextEditingController();

  // Narrative form controller
  final _summaryCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final metricRes = await _supabase
          .from('rabhan_metrics')
          .select()
          .eq('project_id', widget.projectId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      
      if (metricRes != null) {
        _salesCtrl.text = metricRes['sales']?.toString() ?? '0';
        _profitCtrl.text = metricRes['profit']?.toString() ?? '0';
        _spendCtrl.text = metricRes['ad_spend']?.toString() ?? '0';
        _roasCtrl.text = metricRes['roas']?.toString() ?? '0';
        _conversionCtrl.text = metricRes['conversion_rate']?.toString() ?? '0';
      }

      final summaryRes = await _supabase
          .from('rabhan_weekly_summaries')
          .select()
          .eq('project_id', widget.projectId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (summaryRes != null) {
        _summaryCtrl.text = summaryRes['summary_text'] ?? '';
      }
    } catch (e) {
      debugPrint('Error loading analytics control: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveMetrics() async {
    setState(() => _isLoading = true);
    try {
      await _supabase.from('rabhan_metrics').insert({
        'project_id': widget.projectId,
        'sales': double.tryParse(_salesCtrl.text) ?? 0,
        'profit': double.tryParse(_profitCtrl.text) ?? 0,
        'ad_spend': double.tryParse(_spendCtrl.text) ?? 0,
        'roas': double.tryParse(_roasCtrl.text) ?? 0,
        'conversion_rate': double.tryParse(_conversionCtrl.text) ?? 0,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Metrics saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSummary() async {
    setState(() => _isLoading = true);
    try {
      await _supabase.from('rabhan_weekly_summaries').insert({
        'project_id': widget.projectId,
        'summary_text': _summaryCtrl.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Weekly summary published!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics Control Center')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Update Live KPIs', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  _buildTextField(_salesCtrl, 'Total Sales (SAR)'),
                  _buildTextField(_profitCtrl, 'Net Profit (SAR)'),
                  _buildTextField(_spendCtrl, 'Ad Spend (SAR)'),
                  _buildTextField(_roasCtrl, 'ROAS'),
                  _buildTextField(_conversionCtrl, 'Conversion Rate (%)'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _saveMetrics,
                    child: const Text('Push Metrics to Client'),
                  ),
                  const Divider(height: 48),
                  Text('Weekly AI Summary Narrative', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Write the weekly report narrative in Arabic. The client will see this pinned at the top of their Analytics tab.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _summaryCtrl,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'e.g. هذا الأسبوع ارتفعت المبيعات بنسبة...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _saveSummary,
                    child: const Text('Publish Weekly Summary'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
