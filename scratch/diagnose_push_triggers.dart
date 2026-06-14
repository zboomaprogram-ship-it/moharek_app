import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://typbaddqqhpeppzpbbhj.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5cGJhZGRxcWhwZXBwenBiYmhqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3ODE1MTgxMSwiZXhwIjoyMDkzNzI3ODExfQ.rkFLhelMXjVLb44Wf9vY6RRM-priol6f1Y-K72sn87U',
  );

  print('=== DIAGNOSING PROFILE FOR d0d09797-35b9-4f70-a649-469b1a0e1c36 ===');
  try {
    final res = await client.from('profiles').select().eq('id', 'd0d09797-35b9-4f70-a649-469b1a0e1c36').maybeSingle();
    if (res != null) {
      print('Name: ${res['full_name']}');
      print('Email: ${res['email']}');
      print('OneSignal Player ID: ${res['onesignal_player_id']}');
      print('FCM Token: ${res['fcm_token']}');
      print('APNS VOIP Token: ${res['apns_voip_token']}');
    } else {
      print('Profile not found.');
    }
  } catch (e) {
    print('Error profiles: $e');
  }

  print('\n=== LAST 3 CALL SIGNALS ===');
  try {
    final res = await client.from('call_signals').select().order('created_at', ascending: false).limit(3);
    for (var r in res) {
      print('Call Signal: id=${r['id']}, project_id=${r['project_id']}, status=${r['status']}, caller_id=${r['caller_id']}, caller_name=${r['caller_name']}, created_at=${r['created_at']}');
    }
  } catch (e) {
    print('Error call_signals: $e');
  }

  print('\n=== LAST 3 NOTIFICATIONS ===');
  try {
    final res = await client.from('notifications').select().order('created_at', ascending: false).limit(3);
    for (var r in res) {
      print('Notification: id=${r['id']}, user_id=${r['user_id']}, type=${r['type']}, title_ar=${r['title_ar']}, body_ar=${r['body_ar']}');
    }
  } catch (e) {
    print('Error notifications: $e');
  }
}
