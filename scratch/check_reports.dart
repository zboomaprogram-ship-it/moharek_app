import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final apikey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5cGJhZGRxcWhwZXBwenBiYmhqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3ODE1MTgxMSwiZXhwIjoyMDkzNzI3ODExfQ.rkFLhelMXjVLb44Wf9vY6RRM-priol6f1Y-K72sn87U';
  final url = 'https://typbaddqqhpeppzpbbhj.supabase.co/rest/v1/';

  print('Fetching OpenAPI spec to list RPC paths...');
  try {
    final resp = await http.get(Uri.parse(url), headers: {
      'apikey': apikey,
    });
    
    if (resp.statusCode != 200) {
      print('HTTP Error: ${resp.statusCode}');
      return;
    }

    final spec = jsonDecode(resp.body);
    final paths = spec['paths'] as Map<String, dynamic>;
    
    print('Available RPC paths:');
    for (var path in paths.keys) {
      if (path.startsWith('/rpc/')) {
        print('  - $path');
      }
    }
  } catch (e) {
    print('Failed: $e');
  }
}
