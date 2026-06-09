import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://typbaddqqhpeppzpbbhj.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5cGJhZGRxcWhwZXBwenBiYmhqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgxNTE4MTEsImV4cCI6MjA5MzcyNzgxMX0.nxk43GEdtyEUYvmT6K6uj4MPJVXRFb80uEA_mE9NGJI',
  );

  print('Checking packages table...');
  try {
    final response = await client.from('packages').select().limit(1);
    print('Packages response: $response');
  } catch (e) {
    print('Failed to query packages: $e');
  }

  print('Running relation query (projects joining packages)...');
  try {
    final response = await client.from('projects').select('id, name, packages(*)').limit(1);
    print('Relation query success: $response');
  } catch (e) {
    print('Relation query failed: $e');
  }
}
