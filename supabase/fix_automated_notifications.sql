-- Fix Automated Notifications (Two-Way System)
-- This script ensures both Clients and Account Managers receive notifications.

-- 1. Function for Chat Messages
CREATE OR REPLACE FUNCTION on_message_inserted()
RETURNS TRIGGER AS $$
DECLARE
  target_user_id UUID;
  project_client_id UUID;
  project_am_id UUID;
  service_role_key TEXT := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5cGJhZGRxcWhwZXBwenBiYmhqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3ODE1MTgxMSwiZXhwIjoyMDkzNzI3ODExfQ.rkFLhelMXjVLb44Wf9vY6RRM-priol6f1Y-K72sn87U';
  function_url TEXT := 'https://typbaddqqhpeppzpbbhj.supabase.co/functions/v1/send-notification';
BEGIN
  -- Get the project details for this channel
  SELECT p.client_id, p.account_manager_id 
  INTO project_client_id, project_am_id
  FROM public.chat_channels c
  JOIN public.projects p ON c.project_id = p.id
  WHERE c.id = NEW.channel_id;

  -- Determine who to notify
  -- If sender is the client, notify the AM
  IF NEW.sender_id = project_client_id THEN
    target_user_id := project_am_id;
  -- If sender is NOT the client (Admin/AM), notify the client
  ELSE
    target_user_id := project_client_id;
  END IF;

  -- Send notification if we have a target
  IF target_user_id IS NOT NULL THEN
    PERFORM
      net.http_post(
        url := function_url,
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || service_role_key
        ),
        body := jsonb_build_object(
          'table', 'messages',
          'record', row_to_json(NEW),
          'target_user_id', target_user_id
        )
      );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_message_inserted ON public.messages;
CREATE TRIGGER trigger_message_inserted
  AFTER INSERT ON public.messages
  FOR EACH ROW
  EXECUTE FUNCTION on_message_inserted();


-- 2. Function for Activity Feed (Tasks, Results, Reports)
CREATE OR REPLACE FUNCTION on_activity_feed_inserted()
RETURNS TRIGGER AS $$
DECLARE
  target_client_id UUID;
  service_role_key TEXT := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5cGJhZGRxcWhwZXBwenBiYmhqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3ODE1MTgxMSwiZXhwIjoyMDkzNzI3ODExfQ.rkFLhelMXjVLb44Wf9vY6RRM-priol6f1Y-K72sn87U';
  function_url TEXT := 'https://typbaddqqhpeppzpbbhj.supabase.co/functions/v1/send-notification';
BEGIN
  -- Resolve client ID from project
  SELECT p.client_id INTO target_client_id
  FROM public.projects p
  WHERE p.id = NEW.project_id;

  -- Notify the client when an action is taken by someone else
  IF target_client_id IS NOT NULL AND (NEW.actor_id IS NULL OR NEW.actor_id != target_client_id) THEN
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
          'target_user_id', target_client_id
        )
      );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_activity_feed_inserted ON public.activity_feed;
CREATE TRIGGER trigger_activity_feed_inserted
  AFTER INSERT ON public.activity_feed
  FOR EACH ROW
  EXECUTE FUNCTION on_activity_feed_inserted();
