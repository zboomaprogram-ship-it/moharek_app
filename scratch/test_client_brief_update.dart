import 'package:supabase/supabase.dart';

void main() async {
  final serviceClient = SupabaseClient(
    'https://typbaddqqhpeppzpbbhj.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5cGJhZGRxcWhwZXBwenBiYmhqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3ODE1MTgxMSwiZXhwIjoyMDkzNzI3ODExfQ.rkFLhelMXjVLb44Wf9vY6RRM-priol6f1Y-K72sn87U',
  );

  print('Listing auth users to find a client user...');
  try {
    final List<User> users = await serviceClient.auth.admin.listUsers();
    print('Found ${users.length} users in auth.users');

    User? clientUser;
    for (var u in users) {
      // Find a user who is a client in the profiles table
      final profile = await serviceClient.from('profiles').select().eq('id', u.id).maybeSingle();
      if (profile != null && profile['role'] == 'client') {
        clientUser = u;
        print('Selected client user: id=${u.id}, email=${u.email}, name=${profile['full_name']}');
        break;
      }
    }

    if (clientUser == null) {
      print('No client user found in database.');
      return;
    }

    // Reset password to 'testpass123'
    print('Updating password for testing...');
    await serviceClient.auth.admin.updateUserById(
      clientUser.id,
      attributes: AdminUserAttributes(password: 'testpass123'),
    );

    // Now sign in as the client using a clean client instance
    print('Signing in as the client user...');
    final clientInstance = SupabaseClient(
      'https://typbaddqqhpeppzpbbhj.supabase.co',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5cGJhZGRxcWhwZXBwenBiYmhqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgxNTE4MTEsImV4cCI6MjA5MzcyNzgxMX0.nxk43GEdtyEUYvmT6K6uj4MPJVXRFb80uEA_mE9NGJI',
    );

    final authResp = await clientInstance.auth.signInWithPassword(
      email: clientUser.email!,
      password: 'testpass123',
    );
    print('Successfully signed in! User ID: ${authResp.user?.id}');

    // Find the project for this client
    final project = await clientInstance.from('projects').select().eq('client_id', clientUser.id).maybeSingle();
    if (project == null) {
      print('No project found for client ${clientUser.id}');
      return;
    }
    print('Found project: id=${project['id']}, name=${project['name']}');

    // Try to update client_brief
    print('Attempting to update client_brief...');
    try {
      final mockBrief = {'test_key': 'test_value_${DateTime.now().millisecondsSinceEpoch}'};
      await clientInstance.from('projects').update({'client_brief': mockBrief}).eq('id', project['id']);
      print('SUCCESS! The client was able to update their project brief in the database. 🎉');
    } catch (updateError) {
      print('UPDATE FAILED: $updateError');
    }

  } catch (e) {
    print('Error during test: $e');
  }
}
