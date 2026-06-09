import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://typbaddqqhpeppzpbbhj.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5cGJhZGRxcWhwZXBwenBiYmhqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3ODE1MTgxMSwiZXhwIjoyMDkzNzI3ODExfQ.rkFLhelMXjVLb44Wf9vY6RRM-priol6f1Y-K72sn87U',
  );

  final amUserId = '184b0976-0b4a-4324-a34e-e1a4f725b9c1';
  try {
    final res = await client
        .from('projects')
        .select('id, name, client_id, profiles(full_name, company_name)')
        .eq('account_manager_id', amUserId);
    
    for (var r in res) {
      print('Project: id=${r['id']}, name=${r['name']}, profile=${r['profiles']}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
