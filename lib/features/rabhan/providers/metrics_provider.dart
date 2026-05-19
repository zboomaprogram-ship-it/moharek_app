import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import '../models/ecom_metrics.dart';

final latestMetricsProvider = FutureProvider.family<EcomMetrics?, String>((ref, projectId) async {
  final client = ref.watch(supabaseClientProvider);
  final response = await client.rpc('get_latest_metrics', params: {'p_project_id': projectId});
  if (response == null || (response as List).isEmpty) return null;
  return EcomMetrics.fromJson(response.first as Map<String, dynamic>);
});

final projectMetricsHistoryProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, projectId) async {
  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('ecom_metrics')
      .select()
      .eq('project_id', projectId)
      .order('period_end', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});
