import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://typbaddqqhpeppzpbbhj.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5cGJhZGRxcWhwZXBwenBiYmhqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgxNTE4MTEsImV4cCI6MjA5MzcyNzgxMX0.nxk43GEdtyEUYvmT6K6uj4MPJVXRFb80uEA_mE9NGJI',
  );

  print('Checking projects table details...');
  try {
    final res = await client.from('projects').select().limit(1);
    if (res.isNotEmpty) {
      print('First project fields: ${res.first.keys.toList()}');
      print('client_brief content: ${res.first['client_brief']}');
      print('client_brief type: ${res.first['client_brief'].runtimeType}');
    } else {
      print('No projects found');
    }
  } catch (e) {
    print('Error checking projects table: $e');
  }
}
