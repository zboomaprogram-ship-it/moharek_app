import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://typbaddqqhpeppzpbbhj.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5cGJhZGRxcWhwZXBwenBiYmhqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3ODE1MTgxMSwiZXhwIjoyMDkzNzI3ODExfQ.rkFLhelMXjVLb44Wf9vY6RRM-priol6f1Y-K72sn87U',
  );

  final clientId = 'fceb23fa-b2a3-42e7-80da-ca9ef5319547';

  print('1. Checking profile details in Supabase for user $clientId...');
  try {
    final profile = await supabase
        .from('profiles')
        .select('full_name, role, preferred_language, onesignal_player_id')
        .eq('id', clientId)
        .maybeSingle();

    if (profile == null) {
      print('   Profile NOT found for user $clientId');
      return;
    }

    print('   Name: ${profile['full_name']}');
    print('   Role: ${profile['role']}');
    print('   Language: ${profile['preferred_language']}');
    print('   OneSignal Player ID: ${profile['onesignal_player_id']}');

    print('2. Triggering send-notification Edge Function manually...');
    final functionUrl = 'https://typbaddqqhpeppzpbbhj.supabase.co/functions/v1/send-notification';
    final serviceRole = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5cGJhZGRxcWhwZXBwenBiYmhqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3ODE1MTgxMSwiZXhwIjoyMDkzNzI3ODExfQ.rkFLhelMXjVLb44Wf9vY6RRM-priol6f1Y-K72sn87U';

    final payload = {
      'target_user_id': clientId,
      'table': 'notifications',
      'record': {
        'id': 'test-notification-id',
        'user_id': clientId,
        'title_ar': '🔔 اختبار فوري للإشعارات',
        'title_en': '🔔 Instant Notification Test',
        'body_ar': 'هذا اختبار فوري لإرسال الإشعارات عبر الخادم.',
        'body_en': 'This is an instant push notification test.',
        'type': 'task',
        'is_read': false,
      }
    };

    final resp = await http.post(
      Uri.parse(functionUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $serviceRole',
      },
      body: jsonEncode(payload),
    );

    print('   Response Status: ${resp.statusCode}');
    print('   Response Body: ${resp.body}');

  } catch (e) {
    print('Error: $e');
  }
}
