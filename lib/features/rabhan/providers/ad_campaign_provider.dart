import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import '../models/ad_campaign.dart';

final adCampaignsProvider = FutureProvider.family<List<AdCampaign>, String>((ref, projectId) async {
  final client = ref.watch(supabaseClientProvider);
  if (projectId.isEmpty) return [];

  final response = await client
      .from('ad_campaigns')
      .select()
      .eq('project_id', projectId)
      .order('created_at', ascending: false);

  final List<dynamic> data = response as List<dynamic>;
  return data.map((json) => AdCampaign.fromJson(json as Map<String, dynamic>)).toList();
});
