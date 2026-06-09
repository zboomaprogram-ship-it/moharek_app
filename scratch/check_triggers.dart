import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://typbaddqqhpeppzpbbhj.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5cGJhZGRxcWhwZXBwenBiYmhqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3ODE1MTgxMSwiZXhwIjoyMDkzNzI3ODExfQ.rkFLhelMXjVLb44Wf9vY6RRM-priol6f1Y-K72sn87U',
  );

  print('=== TRIGGERS ON APPROVALS ===');
  try {
    final res = await client.rpc('check_table_triggers', params: {'p_table_name': 'approvals'});
    print(res);
  } catch (e) {
    // If rpc doesn't exist, try custom select using postgres system views
    try {
      final res = await client.from('pg_trigger').select();
      print('Direct pg_trigger access: $res');
    } catch (e2) {
      print('Error querying triggers directly: $e2');
    }
  }

  // Let's run a raw query using a helper if available, or fetch last notifications
  print('\n=== LAST 5 NOTIFICATIONS ===');
  try {
    final res = await client.from('notifications').select().order('created_at', ascending: false).limit(5);
    for (var r in res) {
      print('Notification: id=${r['id']}, title_ar=${r['title_ar']}, title_en=${r['title_en']}, body_ar=${r['body_ar']}');
    }
  } catch (e) {
    print('Error notifications: $e');
  }
}
