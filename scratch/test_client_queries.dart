import 'package:supabase/supabase.dart';

void main() async {
  final serviceClient = SupabaseClient(
    'https://typbaddqqhpeppzpbbhj.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5cGJhZGRxcWhwZXBwenBiYmhqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3ODE1MTgxMSwiZXhwIjoyMDkzNzI3ODExfQ.rkFLhelMXjVLb44Wf9vY6RRM-priol6f1Y-K72sn87U',
  );

  final client = SupabaseClient(
    'https://typbaddqqhpeppzpbbhj.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5cGJhZGRxcWhwZXBwenBiYmhqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgxNTE4MTEsImV4cCI6MjA5MzcyNzgxMX0.nxk43GEdtyEUYvmT6K6uj4MPJVXRFb80uEA_mE9NGJI',
  );

  final clientEmail = 'test@gmail.com';
  final tempPassword = 'password123';

  print('1. Resetting password for $clientEmail to "$tempPassword" using service role admin API...');
  try {
    final List<User> users = await serviceClient.auth.admin.listUsers();
    User? targetUser;
    for (var u in users) {
      if (u.email != null && u.email!.toLowerCase() == clientEmail) {
        targetUser = u;
      }
    }

    if (targetUser == null) {
      print('❌ Error: Client user $clientEmail not found!');
      return;
    }

    await serviceClient.auth.admin.updateUserById(
      targetUser.id,
      attributes: AdminUserAttributes(password: tempPassword),
    );
    print('✅ Password reset successful.');

    print('\n2. Signing in as client user $clientEmail using anon key...');
    final authRes = await client.auth.signInWithPassword(
      email: clientEmail,
      password: tempPassword,
    );
    print('✅ Sign in successful. User ID: ${authRes.user?.id}');

    print('\n3. Querying "campaigns" table as client...');
    try {
      final campaigns = await client.from('campaigns').select();
      print('✅ Campaigns count: ${campaigns.length}');
      for (var c in campaigns) {
        print('   - Campaign: id=${c['id']}, name=${c['name']}');
      }
    } catch (e) {
      print('❌ Campaigns query failed: $e');
    }

    print('\n4. Querying "campaign_results" table as client...');
    try {
      final results = await client.from('campaign_results').select();
      print('✅ Campaign Results count: ${results.length}');
      for (var r in results) {
        print('   - Result: id=${r['id']}, campaign_id=${r['campaign_id']}, label=${r['metric_label']}');
      }
    } catch (e) {
      print('❌ Campaign Results query failed: $e');
    }

  } catch (e) {
    print('General Error: $e');
  }
}
