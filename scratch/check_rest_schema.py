import urllib.request
import json

url = "https://typbaddqqhpeppzpbbhj.supabase.co/rest/v1/"
# Service role key
service_key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5cGJhZGRxcWhwZXBwenBiYmhqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3ODE1MTgxMSwiZXhwIjoyMDkzNzI3ODExfQ.rkFLhelMXjVLb44Wf9vY6RRM-priol6f1Y-K72sn87U"

req = urllib.request.Request(
    url,
    headers={
        "apikey": service_key,
        "Authorization": f"Bearer {service_key}"
    }
)

try:
    with urllib.request.urlopen(req) as response:
        spec = json.loads(response.read().decode())
        
        # Check messages table definition
        messages_def = spec.get("definitions", {}).get("messages", {})
        properties = messages_def.get("properties", {})
        
        print("Columns exposed by PostgREST in 'messages' table:")
        for prop, details in properties.items():
            print(f" - {prop}: {details.get('type')} ({details.get('format', 'no format')})")
            
except Exception as e:
    print("Error:", e)
