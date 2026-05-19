import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import '../models/growth_engine_model.dart';

final growthEnginesProvider = FutureProvider.family<List<GrowthEngineModel>, String>((ref, projectId) async {
  final client = ref.watch(supabaseClientProvider);
  if (projectId.isEmpty) return [];

  // Query using get_engine_health RPC helper
  final List<dynamic> data = await client.rpc(
    'get_engine_health',
    params: {'p_project_id': projectId},
  );

  return data.map((json) => GrowthEngineModel.fromJson(json)).toList();
});
