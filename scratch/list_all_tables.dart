import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://typbaddqqhpeppzpbbhj.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5cGJhZGRxcWhwZXBwenBiYmhqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgxNTE4MTEsImV4cCI6MjA5MzcyNzgxMX0.nxk43GEdtyEUYvmT6K6uj4MPJVXRFb80uEA_mE9NGJI',
  );

  print('Listing tables...');
  try {
    // We can query the information_schema via a RPC or using PostgREST if it allows it.
    // Let's try to query some standard tables to see which ones are there.
    final tables = ['profiles', 'projects', 'tasks', 'results', 'engine_progress', 'approvals', 'journey_stages', 'reports', 'invoices', 'contracts', 'files', 'meetings', 'support_tickets', 'activity_feed', 'packages', 'ecom_metrics'];
    for (var table in tables) {
      try {
        await client.from(table).select().limit(1);
        print('✅ Table "$table" exists');
      } catch (e) {
        print('❌ Table "$table" does NOT exist: $e');
      }
    }
  } catch (e) {
    print('Error listing tables: $e');
  }
}
