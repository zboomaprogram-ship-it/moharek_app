import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://typbaddqqhpeppzpbbhj.supabase.co',
    'YOUR_SERVICE_ROLE_KEY' // I don't have it, but I can use the anon key if RLS allows
  );
  
  final res = await supabase.from('admin_logs').select().limit(5);
  print(res);
}
