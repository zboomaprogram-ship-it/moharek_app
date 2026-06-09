import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/shared/models/profile.dart';
import '../models/package_model.dart';

final packageProvider = FutureProvider.family<PackageModel?, String>((ref, projectId) async {
  final client = ref.watch(supabaseClientProvider);
  try {
    final data = await client
        .from('packages')
        .select()
        .eq('project_id', projectId)
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return data != null ? PackageModel.fromJson(data) : null;
  } catch (e) {
    // Fallback: Query without ordering to prevent crash if columns don't exist
    try {
      final data = await client
          .from('packages')
          .select()
          .eq('project_id', projectId)
          .limit(1)
          .maybeSingle();
      return data != null ? PackageModel.fromJson(data) : null;
    } catch (e2) {
      rethrow;
    }
  }
});

final accountManagerProvider = FutureProvider.family<Profile?, String>((ref, projectId) async {
  final client = ref.watch(supabaseClientProvider);
  final project = await client
      .from('projects')
      .select('account_manager_id')
      .eq('id', projectId)
      .single();
  final amId = project['account_manager_id'] as String?;
  if (amId == null) return null;
  
  final profileData = await client
      .from('profiles')
      .select()
      .eq('id', amId)
      .single();
  return Profile.fromJson(profileData);
});
