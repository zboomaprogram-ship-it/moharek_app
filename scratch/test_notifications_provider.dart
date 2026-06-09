import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://typbaddqqhpeppzpbbhj.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5cGJhZGRxcWhwZXBwenBiYmhqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3ODE1MTgxMSwiZXhwIjoyMDkzNzI3ODExfQ.rkFLhelMXjVLb44Wf9vY6RRM-priol6f1Y-K72sn87U',
  );

  print('=== ALL UNREAD NOTIFICATIONS ===');
  try {
    final res = await client
        .from('notifications')
        .select()
        .eq('is_read', false);
    
    print('Total unread notifications: ${res.length}');
    for (var row in res) {
      print('User: ${row['user_id']}, Type: ${row['type']}, Title: ${row['title_ar']}, Metadata: ${row['metadata']}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
