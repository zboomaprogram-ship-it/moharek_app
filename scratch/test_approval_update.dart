import 'package:supabase/supabase.dart';

void main() async {
  final serviceClient = SupabaseClient(
    'https://typbaddqqhpeppzpbbhj.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5cGJhZGRxcWhwZXBwenBiYmhqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3ODE1MTgxMSwiZXhwIjoyMDkzNzI3ODExfQ.rkFLhelMXjVLb44Wf9vY6RRM-priol6f1Y-K72sn87U',
  );

  print('Fetching approvals...');
  try {
    final approvals = await serviceClient.from('approvals').select().limit(5);
    print('Fetched ${approvals.length} approvals:');
    for (var app in approvals) {
      print('  Approval: id=${app['id']}, title=${app['title']}, status=${app['status']}');
    }

    if (approvals.isNotEmpty) {
      final targetId = approvals.first['id'];
      final originalStatus = approvals.first['status'];
      print('\nAttempting to update approval ID: $targetId status to approved (original: $originalStatus)...');

      final stopwatch = Stopwatch()..start();
      final response = await serviceClient
          .from('approvals')
          .update({
            'status': 'approved',
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', targetId)
          .select();

      stopwatch.stop();
      print('Update query completed in ${stopwatch.elapsedMilliseconds}ms.');
      print('Response: $response');

      // Revert status
      print('\nReverting approval ID: $targetId status to $originalStatus...');
      await serviceClient
          .from('approvals')
          .update({
            'status': originalStatus,
            'responded_at': null,
          })
          .eq('id', targetId);
      print('Revert completed.');
    } else {
      print('No approvals found to test.');
    }
  } catch (e) {
    print('Error during test: $e');
  }
}
