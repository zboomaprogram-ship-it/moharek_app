import 'package:supabase/supabase.dart';

void main() async {
  final serviceClient = SupabaseClient(
    'https://typbaddqqhpeppzpbbhj.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5cGJhZGRxcWhwZXBwenBiYmhqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3ODE1MTgxMSwiZXhwIjoyMDkzNzI3ODExfQ.rkFLhelMXjVLb44Wf9vY6RRM-priol6f1Y-K72sn87U',
  );

  final adminId = '184b0976-0b4a-4324-a34e-e1a4f725b9c1';
  final clientId = '0af0c12e-0e1c-4637-b1f8-ee42370fd3b1';

  print('Resetting admin password for testing...');
  await serviceClient.auth.admin.updateUserById(
    adminId,
    attributes: AdminUserAttributes(password: 'testpass123'),
  );

  print('Signing in as admin...');
  final adminClient = SupabaseClient(
    'https://typbaddqqhpeppzpbbhj.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5cGJhZGRxcWhwZXBwenBiYmhqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgxNTE4MTEsImV4cCI6MjA5MzcyNzgxMX0.nxk43GEdtyEUYvmT6K6uj4MPJVXRFb80uEA_mE9NGJI',
  );

  final authResp = await adminClient.auth.signInWithPassword(
    email: 'account1@gmail.com',
    password: 'testpass123',
  );
  print('Admin user ID signed in: ${authResp.user?.id}');

  print('Inserting notification as admin...');
  try {
    final response = await adminClient.from('notifications').insert({
      'user_id': clientId,
      'title_ar': 'تنبيه تجريبي من لوحة التحكم',
      'title_en': 'Test alert from dashboard',
      'body_ar': 'هذا تنبيه تم إرساله من لوحة التحكم للإدارة.',
      'body_en': 'This is a test notification from the admin panel.',
      'type': 'task',
      'is_read': false,
    }).select();
    print('SUCCESS! Inserted notification: $response');
  } catch (e) {
    print('FAILED to insert notification: $e');
  }
}
