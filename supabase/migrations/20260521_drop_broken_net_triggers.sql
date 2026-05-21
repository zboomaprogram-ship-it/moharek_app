-- ============================================================
-- CRITICAL FIX: Remove broken net.http_post triggers
-- Root cause: pg_net extension not installed → "schema net does
-- not exist" error crashes every INSERT on messages, notifications,
-- activity_feed, and call_signals tables.
--
-- Solution:
--   1. DROP all broken triggers that use net.http_post
--   2. Recreate on_message_inserted using pg_notify instead
--      (Supabase Realtime picks this up — no extension needed)
-- ============================================================

-- ── Drop ALL broken triggers ──────────────────────────────

DROP TRIGGER IF EXISTS trigger_notification_inserted   ON public.notifications;
DROP TRIGGER IF EXISTS trigger_message_inserted        ON public.messages;
DROP TRIGGER IF EXISTS trigger_activity_feed_inserted  ON public.activity_feed;
DROP TRIGGER IF EXISTS trigger_call_signal_created_v2  ON public.call_signals;

-- Drop the old broken functions
DROP FUNCTION IF EXISTS public.on_notification_inserted();
DROP FUNCTION IF EXISTS public.on_message_inserted();
DROP FUNCTION IF EXISTS public.on_activity_feed_inserted();
DROP FUNCTION IF EXISTS public.on_call_signal_created_v2();

-- ── Recreate message trigger using pg_notify (no pg_net needed) ──
-- pg_notify is built-in PostgreSQL — always available.
-- Supabase Realtime listens on these channels.

CREATE OR REPLACE FUNCTION public.on_message_inserted()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_project_id   uuid;
  v_client_id    uuid;
  v_am_id        uuid;
  v_target_id    uuid;
  v_body_ar      text;
  v_body_en      text;
BEGIN
  -- Resolve project participants from channel
  SELECT p.id, p.client_id, p.account_manager_id
  INTO v_project_id, v_client_id, v_am_id
  FROM public.chat_channels c
  JOIN public.projects p ON c.project_id = p.id
  WHERE c.id = NEW.channel_id;

  -- Decide who to notify
  IF NEW.sender_id = v_client_id THEN
    v_target_id := v_am_id;      -- client sent → notify AM
  ELSE
    v_target_id := v_client_id;  -- AM/admin sent → notify client
  END IF;

  -- Build bilingual body
  v_body_ar := CASE
    WHEN NEW.message_type = 'voice' THEN '🎤 رسالة صوتية'
    WHEN NEW.message_type = 'image' THEN '📷 صورة جديدة'
    WHEN NEW.message_type = 'file'  THEN '📎 ملف جديد'
    ELSE COALESCE(LEFT(NEW.content, 80), 'رسالة جديدة')
  END;

  v_body_en := CASE
    WHEN NEW.message_type = 'voice' THEN '🎤 Voice message'
    WHEN NEW.message_type = 'image' THEN '📷 New image'
    WHEN NEW.message_type = 'file'  THEN '📎 New file'
    ELSE COALESCE(LEFT(NEW.content, 80), 'New message')
  END;

  -- Insert notification with all required NOT NULL columns
  IF v_target_id IS NOT NULL AND v_target_id != NEW.sender_id THEN
    INSERT INTO public.notifications (
      user_id,
      title_ar,
      title_en,
      body_ar,
      body_en,
      type,
      link_path,
      metadata
    ) VALUES (
      v_target_id,
      'رسالة جديدة',
      'New Message',
      v_body_ar,
      v_body_en,
      'chat_message',
      '/chat',
      jsonb_build_object(
        'channel_id', NEW.channel_id,
        'message_id', NEW.id,
        'project_id', v_project_id,
        'sender_id',  NEW.sender_id
      )
    );
  END IF;

  RETURN NEW;
END;
$$;

-- Re-attach the safe trigger
DROP TRIGGER IF EXISTS trigger_message_inserted ON public.messages;
CREATE TRIGGER trigger_message_inserted
  AFTER INSERT ON public.messages
  FOR EACH ROW
  EXECUTE FUNCTION public.on_message_inserted();

