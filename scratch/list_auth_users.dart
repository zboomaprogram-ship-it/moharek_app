import 'package:supabase/supabase.dart';

void main() async {
  final serviceClient = SupabaseClient(
    'https://typbaddqqhpeppzpbbhj.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5cGJhZGRxcWhwZXBwenBiYmhqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3ODE1MTgxMSwiZXhwIjoyMDkzNzI3ODExfQ.rkFLhelMXjVLb44Wf9vY6RRM-priol6f1Y-K72sn87U',
  );

  print('Listing auth users...');
  try {
    final List<User> users = await serviceClient.auth.admin.listUsers();
    for (var u in users) {
      final profile = await serviceClient.from('profiles').select().eq('id', u.id).maybeSingle();
      print('Auth User: id=${u.id}, email=${u.email}, role=${profile?['role']}, name=${profile?['full_name']}');
    }
  } catch (e) {
    print('Failed: $e');
  }
}
