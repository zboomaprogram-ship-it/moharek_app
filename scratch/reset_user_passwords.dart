import 'package:supabase/supabase.dart';

void main() async {
  final serviceClient = SupabaseClient(
    'https://typbaddqqhpeppzpbbhj.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5cGJhZGRxcWhwZXBwenBiYmhqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3ODE1MTgxMSwiZXhwIjoyMDkzNzI3ODExfQ.rkFLhelMXjVLb44Wf9vY6RRM-priol6f1Y-K72sn87U',
  );

  final targetEmails = ['account1@gmail.com', 'test1@gmail.com'];
  print('Listing and resetting passwords for: $targetEmails');

  try {
    final List<User> users = await serviceClient.auth.admin.listUsers();
    for (var u in users) {
      if (u.email != null && targetEmails.contains(u.email!.toLowerCase())) {
        print('Updating password for user: ${u.email} (ID: ${u.id})...');
        await serviceClient.auth.admin.updateUserById(
          u.id,
          attributes: AdminUserAttributes(password: '12345678'),
        );
        print('Successfully updated password for ${u.email} to "12345678".');
      }
    }
  } catch (e) {
    print('Error during reset: $e');
  }
}
