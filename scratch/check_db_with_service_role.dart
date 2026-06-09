import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://typbaddqqhpeppzpbbhj.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5cGJhZGRxcWhwZXBwenBiYmhqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3ODE1MTgxMSwiZXhwIjoyMDkzNzI3ODExfQ.rkFLhelMXjVLb44Wf9vY6RRM-priol6f1Y-K72sn87U',
  );

  print('Listing notifications...');
  try {
    final res = await client.from('notifications').select().order('created_at', ascending: false);
    for (var r in res) {
      print('Notification: id=${r['id']}, user_id=${r['user_id']}, title_ar=${r['title_ar']}, body_ar=${r['body_ar']}, type=${r['type']}, is_read=${r['is_read']}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
