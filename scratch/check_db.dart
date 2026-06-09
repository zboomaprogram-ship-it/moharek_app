import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://typbaddqqhpeppzpbbhj.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5cGJhZGRxcWhwZXBwenBiYmhqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgxNTE4MTEsImV4cCI6MjA5MzcyNzgxMX0.nxk43GEdtyEUYvmT6K6uj4MPJVXRFb80uEA_mE9NGJI',
  );

  print('Listing all tables/rows counts...');
  for (var table in ['profiles', 'projects', 'tasks', 'results', 'engine_progress']) {
    try {
      final res = await client.from(table).select();
      print('Table "$table" has ${res.length} rows');
      if (res.isNotEmpty && table == 'profiles') {
        for (var row in res) {
          print('  Profile: id=${row['id']}, email=${row['email']}, role=${row['role']}, name=${row['full_name']}');
        }
      }
      if (res.isNotEmpty && table == 'projects') {
        for (var row in res) {
          print('  Project: id=${row['id']}, name=${row['name']}, client_id=${row['client_id']}, am=${row['account_manager_id']}');
        }
      }
    } catch (e) {
      print('Error on "$table": $e');
    }
  }
}
