-- ---------------------------------------------------------------
-- 1. Setup notification trigger on insert to public.notifications
-- ---------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.on_notification_inserted()
RETURNS TRIGGER AS $$
DECLARE
  anon_key TEXT := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB5emhlcXd5cG9hYXpwbXBnaXVxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkxODUwMzEsImV4cCI6MjA5NDc2MTAzMX0.ZRM1H-5ZR01UwL5KXG0O9vFomc6ZOiMg8r-yNLvvMiw';
  fn_url TEXT := 'https://pyzheqwypoaazpmpgiuq.supabase.co/functions/v1/send-notification';
BEGIN
  PERFORM net.http_post(
    url     := fn_url,
    headers := jsonb_build_object(
      'Content-Type',  'application/json',
      'Authorization', 'Bearer ' || anon_key
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
  EXECUTE FUNCTION public.on_notification_inserted();

-- ---------------------------------------------------------------
-- 2. Setup message trigger on insert to public.messages (chat messages)
-- ---------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.on_message_inserted()
RETURNS TRIGGER AS $$
DECLARE
  target_user_id UUID;
  project_client_id UUID;
  project_am_id UUID;
  anon_key TEXT := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB5emhlcXd5cG9hYXpwbXBnaXVxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkxODUwMzEsImV4cCI6MjA5NDc2MTAzMX0.ZRM1H-5ZR01UwL5KXG0O9vFomc6ZOiMg8r-yNLvvMiw';
  fn_url TEXT := 'https://pyzheqwypoaazpmpgiuq.supabase.co/functions/v1/send-notification';
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
        url := fn_url,
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || anon_key
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
  EXECUTE FUNCTION public.on_message_inserted();

-- ---------------------------------------------------------------
-- 3. Setup activity feed trigger on insert to public.activity_feed
-- ---------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.on_activity_feed_inserted()
RETURNS TRIGGER AS $$
DECLARE
  target_client_id UUID;
  anon_key TEXT := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB5emhlcXd5cG9hYXpwbXBnaXVxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkxODUwMzEsImV4cCI6MjA5NDc2MTAzMX0.ZRM1H-5ZR01UwL5KXG0O9vFomc6ZOiMg8r-yNLvvMiw';
  fn_url TEXT := 'https://pyzheqwypoaazpmpgiuq.supabase.co/functions/v1/send-notification';
BEGIN
  -- Resolve client ID from project
  SELECT p.client_id INTO target_client_id
  FROM public.projects p
  WHERE p.id = NEW.project_id;

  -- Notify the client when an action is taken by someone else
  IF target_client_id IS NOT NULL AND (NEW.actor_id IS NULL OR NEW.actor_id != target_client_id) THEN
    PERFORM
      net.http_post(
        url := fn_url,
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || anon_key
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
  EXECUTE FUNCTION public.on_activity_feed_inserted();

-- ---------------------------------------------------------------
-- 4. Setup call signal trigger on insert to public.call_signals
-- ---------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.on_call_signal_created_v2()
RETURNS TRIGGER AS $$
DECLARE
  anon_key TEXT := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB5emhlcXd5cG9hYXpwbXBnaXVxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkxODUwMzEsImV4cCI6MjA5NDc2MTAzMX0.ZRM1H-5ZR01UwL5KXG0O9vFomc6ZOiMg8r-yNLvvMiw';
  fn_url TEXT := 'https://pyzheqwypoaazpmpgiuq.supabase.co/functions/v1/send-notification';
  project_row RECORD;
  callee_id UUID;
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
        'Authorization', 'Bearer ' || anon_key
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

DROP TRIGGER IF EXISTS trigger_call_signal_created_v2 ON public.call_signals;
CREATE TRIGGER trigger_call_signal_created_v2
  AFTER INSERT ON public.call_signals
  FOR EACH ROW
  EXECUTE FUNCTION public.on_call_signal_created_v2();
