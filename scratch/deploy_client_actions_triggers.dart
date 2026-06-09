import 'dart:io';

void main() async {
  print('=== DEPLOYMENT INSTRUCTIONS FOR CLIENT ACTIONS TRIGGERS ===');
  print('To enable automatic notifications when a client requests a task or schedules a meeting,');
  print('please copy and execute the SQL statements below in your Supabase SQL Editor:\n');

  final sqlFile = File('supabase/notify_admin_on_client_actions.sql');
  if (await sqlFile.exists()) {
    final sqlContent = await sqlFile.readAsString();
    print('------------------ COPY SQL BELOW ------------------');
    print(sqlContent);
    print('----------------------------------------------------');
    print('\n✅ Instructions:');
    print('1. Go to your Supabase Dashboard: https://supabase.com/dashboard');
    print('2. Open the SQL Editor.');
    print('3. Paste the SQL statements copied above and run them.');
  } else {
    print('❌ Error: supabase/notify_admin_on_client_actions.sql not found!');
  }
}
