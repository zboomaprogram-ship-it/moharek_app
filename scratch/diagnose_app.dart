import 'package:supabase/supabase.dart';

void main() async {
  final serviceClient = SupabaseClient(
    'https://typbaddqqhpeppzpbbhj.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5cGJhZGRxcWhwZXBwenBiYmhqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3ODE1MTgxMSwiZXhwIjoyMDkzNzI3ODExfQ.rkFLhelMXjVLb44Wf9vY6RRM-priol6f1Y-K72sn87U',
  );

  print('=== DIAGNOSING DB USERS & ROLES ===');
  try {
    final profiles = await serviceClient.from('profiles').select();
    print('Total profiles: ${profiles.length}');
    for (var p in profiles) {
      print('  User: id=${p['id']}, email=${p['email']}, role=${p['role']}, name=${p['full_name']}');
    }
  } catch (e) {
    print('Failed to fetch profiles: $e');
  }

  print('\n=== DIAGNOSING PROJECTS ===');
  try {
    final projects = await serviceClient.from('projects').select();
    print('Total projects: ${projects.length}');
    for (var p in projects) {
      print('  Project: id=${p['id']}, name=${p['name']}, client_id=${p['client_id']}, am=${p['account_manager_id']}, brief_empty=${p['client_brief'] == null}');
    }
  } catch (e) {
    print('Failed to fetch projects: $e');
  }

  print('\n=== DIAGNOSING RLS POLICIES ===');
  try {
    // We can run raw SQL using a RPC if we have one, or check pg_policies via service client if allowed
    final policies = await serviceClient.rpc('get_policies');
    print('Policies: $policies');
  } catch (e) {
    // If get_policies RPC doesn't exist, we can use a query on pg_policies via select/raw or create a helper sql. Let's see if we can do it via a simple select if views are exposed
    try {
      final policies = await serviceClient.from('pg_policies').select();
      print('pg_policies: $policies');
    } catch (_) {
      print('Could not query pg_policies directly. This is expected if it is not exposed.');
    }
  }

  print('\n=== CHECKING SUPABASE REALTIME PUBLICATION ===');
  try {
    // We can query pg_publication_tables if exposed, otherwise check using custom sql or we can just apply our setup sql to be 100% sure.
  } catch (e) {
    print('Error: $e');
  }
}
