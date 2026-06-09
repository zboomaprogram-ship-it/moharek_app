import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://typbaddqqhpeppzpbbhj.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5cGJhZGRxcWhwZXBwenBiYmhqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgxNTE4MTEsImV4cCI6MjA5MzcyNzgxMX0.nxk43GEdtyEUYvmT6K6uj4MPJVXRFb80uEA_mE9NGJI',
  );

  print('Checking projects table for client_brief...');
  try {
    final response = await client.from('projects').select('client_brief').limit(1);
    print('Projects column client_brief exists! Data: $response');
  } catch (e) {
    print('Projects column client_brief does NOT exist or query failed: $e');
  }

  print('\nChecking tasks table for start_date...');
  try {
    final response = await client.from('tasks').select('start_date').limit(1);
    print('Tasks column start_date exists! Data: $response');
  } catch (e) {
    print('Tasks column start_date does NOT exist or query failed: $e');
  }
}
