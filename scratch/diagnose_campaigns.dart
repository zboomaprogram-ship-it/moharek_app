import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://typbaddqqhpeppzpbbhj.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5cGJhZGRxcWhwZXBwenBiYmhqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3ODE1MTgxMSwiZXhwIjoyMDkzNzI3ODExfQ.rkFLhelMXjVLb44Wf9vY6RRM-priol6f1Y-K72sn87U',
  );

  print('=== DIAGNOSING CAMPAIGNS TABLES ===');
  
  print('1. Checking if "campaigns" table exists and selecting rows...');
  try {
    final campaigns = await client.from('campaigns').select();
    print('✅ Campaigns count: ${campaigns.length}');
    for (var c in campaigns.take(2)) {
      print('   Campaign: $c');
    }
  } catch (e) {
    print('❌ Failed to select from campaigns: $e');
  }

  print('\n2. Checking if "campaign_results" table exists and selecting rows...');
  try {
    final results = await client.from('campaign_results').select();
    print('✅ Campaign Results count: ${results.length}');
    for (var r in results.take(2)) {
      print('   Result: $r');
    }
  } catch (e) {
    print('❌ Failed to select from campaign_results: $e');
  }
}
