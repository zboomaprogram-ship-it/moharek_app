-- ================================================================
-- notification_triggers_v2.sql
-- Fires send-notification edge function on every notification insert
-- Run this in your Supabase SQL Editor
-- ================================================================

-- Ensure pg_net extension is enabled
CREATE EXTENSION IF NOT EXISTS "pg_net";

-- ---------------------------------------------------------------
-- 1. Trigger: push on every in-app notification insert
-- ---------------------------------------------------------------
CREATE OR REPLACE FUNCTION on_notification_inserted()
RETURNS TRIGGER AS $$
DECLARE
  service_key TEXT := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5cGJhZGRxcWhwZXBwenBiYmhqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3ODE1MTgxMSwiZXhwIjoyMDkzNzI3ODExfQ.rkFLhelMXjVLb44Wf9vY6RRM-priol6f1Y-K72sn87U';
  fn_url TEXT := 'https://typbaddqqhpeppzpbbhj.supabase.co/functions/v1/send-notification';
BEGIN
  PERFORM net.http_post(
    url     := fn_url,
    headers := jsonb_build_object(
      'Content-Type',  'application/json',
      'Authorization', 'Bearer ' || service_key
    ),
    body := jsonb_build_object(
      'table',          'notifications',
      'record',         row_to_json(NEW),
      'target_user_id', NEW.user_id
    )
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_notification_inserted ON public.notifications;
CREATE TRIGGER trigger_notification_inserted
  AFTER INSERT ON public.notifications
  FOR EACH ROW
  EXECUTE FUNCTION on_notification_inserted();

-- ---------------------------------------------------------------
-- 2. Trigger: high-priority call push (bidirectional)
-- ---------------------------------------------------------------
CREATE OR REPLACE FUNCTION on_call_signal_created_v2()
RETURNS TRIGGER AS $$
DECLARE
  service_key  TEXT := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5cGJhZGRxcWhwZXBwenBiYmhqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3ODE1MTgxMSwiZXhwIjoyMDkzNzI3ODExfQ.rkFLhelMXjVLb44Wf9vY6RRM-priol6f1Y-K72sn87U';
  fn_url       TEXT := 'https://typbaddqqhpeppzpbbhj.supabase.co/functions/v1/send-notification';
  project_row  RECORD;
  callee_id    UUID;
BEGIN
  IF NEW.status != 'ringing' THEN RETURN NEW; END IF;

  -- Get project client and AM
  SELECT client_id, account_manager_id INTO project_row
  FROM public.projects
  WHERE id = NEW.project_id;

  -- Notify the OTHER party (whoever did NOT initiate the call)
  IF NEW.caller_id = project_row.client_id THEN
    callee_id := project_row.account_manager_id;
  ELSE
    callee_id := project_row.client_id;
  END IF;

  IF callee_id IS NOT NULL THEN
    PERFORM net.http_post(
      url     := fn_url,
      headers := jsonb_build_object(
        'Content-Type',  'application/json',
        'Authorization', 'Bearer ' || service_key
      ),
      body := jsonb_build_object(
        'table',          'call_signals',
        'record',         row_to_json(NEW),
        'target_user_id', callee_id
      )
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_call_signal_created ON public.call_signals;
DROP TRIGGER IF EXISTS trigger_call_signal_created_v2 ON public.call_signals;
CREATE TRIGGER trigger_call_signal_created_v2
  AFTER INSERT ON public.call_signals
  FOR EACH ROW
  EXECUTE FUNCTION on_call_signal_created_v2();

-- ---------------------------------------------------------------
-- 3. Index (ensure fast lookup on user_id + is_read)
-- ---------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread
  ON public.notifications(user_id, is_read);

-- ---------------------------------------------------------------
-- INSTRUCTIONS
-- ---------------------------------------------------------------
-- After running this SQL:
-- 1. Deploy the updated edge function:
--    supabase functions deploy send-notification
-- 2. Make sure these secrets are set in Supabase Dashboard > Edge Functions > Secrets:
--    ONESIGNAL_APP_ID     = 234d893b-ca81-493d-9afd-6a287a69b27e
--    ONESIGNAL_REST_API_KEY = <your REST API key from OneSignal dashboard>
--    SUPABASE_URL         = https://typbaddqqhpeppzpbbhj.supabase.co
--    SUPABASE_SERVICE_ROLE_KEY = <your service role key>
