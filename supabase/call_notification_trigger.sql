-- Enable HTTP extension (pg_net) if not already enabled
-- Note: You may need to enable this in your Supabase Dashboard: 
-- Database -> Extensions -> search for "pg_net" and click enable.
CREATE EXTENSION IF NOT EXISTS "pg_net";

-- Trigger to send push notification when a new call signal is created
-- This enables WhatsApp-style background call notifications

CREATE OR REPLACE FUNCTION on_call_signal_created()
RETURNS TRIGGER AS $$
DECLARE
  client_id UUID;
BEGIN
  -- 1. Identify the recipient (Callee)
  -- If the caller is an Admin/Team member, the recipient is the Client of the project.
  -- If the caller is the Client, the recipient is the Account Manager (Admin).
  
  -- For now, we prioritize notifying the Client when an Admin calls.
  SELECT p.client_id INTO client_id
  FROM public.projects p
  WHERE p.id = NEW.project_id;

  -- Only trigger for 'ringing' status
  IF NEW.status = 'ringing' AND client_id IS NOT NULL THEN
    -- Call the send-notification edge function using pg_net
    PERFORM
      net.http_post(
        url := 'https://typbaddqqhpeppzpbbhj.supabase.co/functions/v1/send-notification',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || 'YOUR_SERVICE_ROLE_KEY' -- Replace with your Service Role Key
        ),
        body := jsonb_build_object(
          'table', 'call_signals',
          'record', row_to_json(NEW),
          'client_id', client_id
        )
      );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger
DROP TRIGGER IF EXISTS trigger_call_signal_created ON call_signals;
CREATE TRIGGER trigger_call_signal_created
  AFTER INSERT ON call_signals
  FOR EACH ROW
  EXECUTE FUNCTION on_call_signal_created();
