import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://typbaddqqhpeppzpbbhj.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5cGJhZGRxcWhwZXBwenBiYmhqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3ODE1MTgxMSwiZXhwIjoyMDkzNzI3ODExfQ.rkFLhelMXjVLb44Wf9vY6RRM-priol6f1Y-K72sn87U',
  );

  final targetUser = 'd0d09797-35b9-4f70-a649-469b1a0e1c36';
  final emulatorFcmToken = 'dR8wcjC8T9aGgjHXwVUsZQ:APA91bEPyUvDnhtnHPBGYxu6RlKhNbXd5D3DfsfMZga4qW19xf5QOgETiPYNlZXjLzEUngA7nZdIQUWx1_XFCm59fOyvnd5TbVPmZMpKN9VpuVUlNhkvW50';

  print('Updating FCM token for user $targetUser to emulator token...');
  try {
    final res = await client
        .from('profiles')
        .update({'fcm_token': emulatorFcmToken})
        .eq('id', targetUser)
        .select();
    
    print('Update response: $res');
  } catch (e) {
    print('Error: $e');
  }
}
