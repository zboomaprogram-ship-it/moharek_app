-- ================================================================
-- FINAL FIX: Remove pg_net dependency from all triggers
-- Use Supabase Database Webhooks instead (no extensions needed)
-- Run this in Supabase SQL Editor
-- ================================================================

-- ── 1. on_message_inserted: ONLY inserts a notifications row ────
-- The Supabase Database Webhook on the notifications table will then
-- call the send-notification Edge Function automatically.
-- No net.http_post() needed here at all.

CREATE OR REPLACE FUNCTION public.on_message_inserted()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  target_user_id    UUID;
  project_client_id UUID;
  project_am_id     UUID;
  sender_name       TEXT;
BEGIN
  -- Skip system messages
  IF NEW.message_type = 'system' THEN RETURN NEW; END IF;

  -- Get the project's client and AM for this chat channel
  SELECT p.client_id, p.account_manager_id
  INTO project_client_id, project_am_id
  FROM public.chat_channels c
  JOIN public.projects p ON c.project_id = p.id
  WHERE c.id = NEW.channel_id;

  -- Determine recipient (notify the OTHER party)
  IF NEW.sender_id = project_client_id THEN
    target_user_id := project_am_id;
  ELSE
    target_user_id := project_client_id;
  END IF;

  IF target_user_id IS NULL THEN RETURN NEW; END IF;

  -- Get sender display name
  SELECT COALESCE(full_name, 'فريق ربحان')
  INTO sender_name
  FROM public.profiles
  WHERE id = NEW.sender_id;

  -- Insert in-app notification row.
  -- The Database Webhook on notifications table fires send-notification
  -- Edge Function automatically — no pg_net needed.
  INSERT INTO public.notifications (
    user_id,
    type,
    title_ar,
    title_en,
    body_ar,
    body_en,
    is_read,
    data,
    created_at
  ) VALUES (
    target_user_id,
    'chat_message',
    '💬 رسالة جديدة',
    '💬 New Message',
    COALESCE(sender_name, 'فريقك') || ': ' || LEFT(NEW.content, 100),
    COALESCE(sender_name, 'Your team') || ': ' || LEFT(NEW.content, 100),
    false,
    jsonb_build_object(
      'sender_id',  NEW.sender_id,
      'channel_id', NEW.channel_id,
      'message_id', NEW.id,
      'table',      'messages',
      'record',     row_to_json(NEW)
    ),
    now()
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_on_message_inserted ON public.messages;
CREATE TRIGGER trigger_on_message_inserted
  AFTER INSERT ON public.messages
  FOR EACH ROW EXECUTE FUNCTION public.on_message_inserted();

-- ── 2. on_notification_inserted: REMOVED net.http_post() ─────────
-- The Database Webhook replaces this entirely.
-- This trigger now just returns NEW (a no-op, kept for clean drops).
CREATE OR REPLACE FUNCTION public.on_notification_inserted()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  -- Nothing to do here — the Supabase Database Webhook on this table
  -- automatically calls the send-notification Edge Function.
  RETURN NEW;
END;
$$;

-- Keep the trigger in place (webhook fires independently of it)
DROP TRIGGER IF EXISTS trigger_notification_inserted ON public.notifications;
CREATE TRIGGER trigger_notification_inserted
  AFTER INSERT ON public.notifications
  FOR EACH ROW EXECUTE FUNCTION public.on_notification_inserted();

-- ── 3. Drop old broken net.http triggers if they still exist ─────
DROP TRIGGER IF EXISTS trigger_notification_inserted ON public.notifications;
DROP TRIGGER IF EXISTS on_call_signal_created ON public.call_signals;
DROP TRIGGER IF EXISTS trigger_call_signal_created ON public.call_signals;
DROP TRIGGER IF EXISTS trigger_call_signal_created_v2 ON public.call_signals;

-- Recreate trigger_notification_inserted (dropped above)
CREATE TRIGGER trigger_notification_inserted
  AFTER INSERT ON public.notifications
  FOR EACH ROW EXECUTE FUNCTION public.on_notification_inserted();

-- ── 4. Verify triggers are in place ──────────────────────────────
SELECT
  trigger_name,
  event_object_table AS table_name,
  action_timing,
  event_manipulation AS event
FROM information_schema.triggers
WHERE trigger_schema = 'public'
  AND trigger_name IN (
    'trigger_on_message_inserted',
    'trigger_notification_inserted'
  )
ORDER BY event_object_table;
-- Expected: 2 rows
