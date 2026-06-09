import 'package:supabase/supabase.dart';

void main() async {
  final serviceClient = SupabaseClient(
    'https://typbaddqqhpeppzpbbhj.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5cGJhZGRxcWhwZXBwenBiYmhqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3ODE1MTgxMSwiZXhwIjoyMDkzNzI3ODExfQ.rkFLhelMXjVLb44Wf9vY6RRM-priol6f1Y-K72sn87U',
  );

  final projectId = 'f5890577-97fc-4a1d-ad47-b7ba0a305f5e'; // جلومي
  final clientId = 'fceb23fa-b2a3-42e7-80da-ca9ef5319547';

  print('1. Inserting a test task for project $projectId to see if client notification is triggered...');
  try {
    final taskResp = await serviceClient.from('tasks').insert({
      'project_id': projectId,
      'title': 'Test Trigger Task',
      'description': 'Testing auto-trigger for client notifications',
      'status': 'todo',
      'priority': 'Medium',
      'category': 'Testing',
    }).select().single();

    final taskId = taskResp['id'];
    print('   Successfully inserted task with ID: $taskId');

    print('2. Waiting 2 seconds for trigger to execute...');
    await Future.delayed(const Duration(seconds: 2));

    print('3. Querying notifications table for user $clientId...');
    final notifications = await serviceClient
        .from('notifications')
        .select()
        .eq('user_id', clientId)
        .order('created_at', ascending: false)
        .limit(5);

    bool triggerFired = false;
    for (var notif in notifications) {
      print('   Notification found: id=${notif['id']}, title_ar="${notif['title_ar']}", body_ar="${notif['body_ar']}"');
      if (notif['body_ar'] != null && notif['body_ar'].contains('Test Trigger Task')) {
        triggerFired = true;
      }
    }

    if (triggerFired) {
      print('🎉 SUCCESS: The client task notification trigger is installed and fired correctly! 🎉');
    } else {
      print('❌ FAILURE: No notification was triggered for the client. The triggers might not be installed. ❌');
    }

    print('4. Cleaning up test task and notifications...');
    await serviceClient.from('tasks').delete().eq('id', taskId);
    print('   Test task deleted.');
    
    // Also delete any test notification generated
    await serviceClient.from('notifications').delete().eq('user_id', clientId).like('body_ar', '%Test Trigger Task%');
    print('   Test notification cleaned up.');

  } catch (e) {
    print('Error executing trigger test: $e');
  }
}
