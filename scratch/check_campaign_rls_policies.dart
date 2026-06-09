import 'package:supabase/supabase.dart';

void main() async {
  final serviceClient = SupabaseClient(
    'https://typbaddqqhpeppzpbbhj.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5cGJhZGRxcWhwZXBwenBiYmhqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3ODE1MTgxMSwiZXhwIjoyMDkzNzI3ODExfQ.rkFLhelMXjVLb44Wf9vY6RRM-priol6f1Y-K72sn87U',
  );

  print('Querying pg_policies for campaigns and campaign_results...');
  try {
    final res = await serviceClient.from('pg_policies').select().or('tablename.eq.campaigns,tablename.eq.campaign_results');
    for (var r in res) {
      print('Policy: table=${r['tablename']}, name=${r['policyname']}, cmd=${r['cmd']}, qual=${r['qual']}, with_check=${r['with_check']}');
    }
  } catch (e) {
    print('Failed: $e');
  }
}
