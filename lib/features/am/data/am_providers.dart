import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/shared/services/data_providers.dart';

final amClientsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final user = client.auth.currentUser;
  if (user == null) return [];

  final data = await client
      .from('projects')
      .select('*, profiles!projects_client_id_fkey(full_name, company_name, avatar_url), tasks(status), packages(*), ecom_metrics(*)')
      .eq('account_manager_id', user.id)
      .order('created_at', ascending: false);
  
  return List<Map<String, dynamic>>.from(data);
});

final amGlobalTasksProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final user = client.auth.currentUser;
  if (user == null) return [];

  // Get tasks for all projects assigned to this AM
  final data = await client
      .from('tasks')
      .select('*, projects!inner(id, name, account_manager_id)')
      .eq('projects.account_manager_id', user.id)
      .order('deadline', ascending: true);
  
  return List<Map<String, dynamic>>.from(data);
});

final amGlobalApprovalsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final user = client.auth.currentUser;
  if (user == null) return [];

  final data = await client
      .from('approvals')
      .select('*, projects!inner(id, name, account_manager_id)')
      .eq('projects.account_manager_id', user.id)
      .order('created_at', ascending: false);
  
  return List<Map<String, dynamic>>.from(data);
});

final amGlobalReportsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final user = client.auth.currentUser;
  if (user == null) return [];

  final data = await client
      .from('reports')
      .select('*, projects!inner(id, name, account_manager_id)')
      .eq('projects.account_manager_id', user.id)
      .order('created_at', ascending: false);
  
  return List<Map<String, dynamic>>.from(data);
});

final amNotificationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final user = client.auth.currentUser;
  if (user == null) return [];

  // Fetch activity for projects managed by this AM
  final data = await client
      .from('activity_feed')
      .select('*, projects!inner(name, account_manager_id)')
      .eq('projects.account_manager_id', user.id)
      .order('created_at', ascending: false)
      .limit(20);
  
  return List<Map<String, dynamic>>.from(data);
});

final amMeetingsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final user = client.auth.currentUser;
  if (user == null) return [];

  final data = await client
      .from('meetings')
      .select('*, projects!inner(name, account_manager_id)')
      .eq('projects.account_manager_id', user.id)
      .order('scheduled_at', ascending: true);
  
  return List<Map<String, dynamic>>.from(data);
});
