-- Universal Activity Notification Trigger
-- This script bridges the activity_feed table to OneSignal Push Notifications

-- 1. Ensure pg_net extension is enabled
CREATE EXTENSION IF NOT EXISTS "pg_net";

-- 2. Create the notification function
CREATE OR REPLACE FUNCTION on_activity_feed_inserted()
RETURNS TRIGGER AS $$
DECLARE
  client_id UUID;
  service_role_key TEXT := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5cGJhZGRxcWhwZXBwenBiYmhqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3ODE1MTgxMSwiZXhwIjoyMDkzNzI3ODExfQ.rkFLhelMXjVLb44Wf9vY6RRM-priol6f1Y-K72sn87U'; -- IMPORTANT: Must be replaced during deployment
  function_url TEXT := 'https://typbaddqqhpeppzpbbhj.supabase.co/functions/v1/send-notification';
BEGIN
  -- Get the client ID for the project
  SELECT p.client_id INTO client_id
  FROM public.projects p
  WHERE p.id = NEW.project_id;

  -- Only notify if the actor is NOT the client (prevent self-notifications)
  -- and if the client exists
  IF client_id IS NOT NULL AND (NEW.actor_id IS NULL OR NEW.actor_id != client_id) THEN
    PERFORM
      net.http_post(
        url := function_url,
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || service_role_key
        ),
        body := jsonb_build_object(
          'table', 'activity_feed',
          'record', row_to_json(NEW),
          'client_id', client_id
        )
      );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Create the trigger
DROP TRIGGER IF EXISTS trigger_activity_feed_inserted ON public.activity_feed;
CREATE TRIGGER trigger_activity_feed_inserted
  AFTER INSERT ON public.activity_feed
  FOR EACH ROW
  EXECUTE FUNCTION on_activity_feed_inserted();

-- 4. Enable Realtime for activity_feed (if not already)
-- This ensures the mobile app UI updates instantly without polling
ALTER publication supabase_realtime ADD TABLE activity_feed;
