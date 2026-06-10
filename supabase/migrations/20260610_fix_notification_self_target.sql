-- ─────────────────────────────────────────────────────────────────────────────
-- FIX: Prevent self-notifications for chat messages
-- ─────────────────────────────────────────────────────────────────────────────
-- This migration recreates public.on_message_inserted() to include a guard
-- check ensuring that users never receive in-app notifications for messages
-- they sent themselves.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.on_message_inserted()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  target_user_id    UUID;
  project_client_id UUID;
  project_am_id     UUID;
  sender_name       TEXT;
  display_body_ar   TEXT;
  display_body_en   TEXT;
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

  -- Prevent notifying oneself
  IF target_user_id = NEW.sender_id THEN
    RETURN NEW;
  END IF;

  IF target_user_id IS NULL THEN RETURN NEW; END IF;

  -- Get sender display name
  SELECT COALESCE(full_name, 'فريق ربحان')
  INTO sender_name
  FROM public.profiles
  WHERE id = NEW.sender_id;

  -- Build safe body text for notifications (avoiding null propagation on image, file, voice types)
  display_body_ar := COALESCE(sender_name, 'فريقك') || ': ' || COALESCE(
    LEFT(NEW.content, 100),
    CASE 
      WHEN NEW.message_type = 'image' THEN '📷 أرسل صورة'
      WHEN NEW.message_type = 'voice' THEN '🎤 أرسل رسالة صوتية'
      WHEN NEW.message_type = 'file' THEN '📎 أرسل ملفاً'
      ELSE 'رسالة جديدة'
    END
  );

  display_body_en := COALESCE(sender_name, 'Your team') || ': ' || COALESCE(
    LEFT(NEW.content, 100),
    CASE 
      WHEN NEW.message_type = 'image' THEN '📷 sent a photo'
      WHEN NEW.message_type = 'voice' THEN '🎤 sent a voice message'
      WHEN NEW.message_type = 'file' THEN '📎 sent a file'
      ELSE 'new message'
    END
  );

  -- Insert in-app notification row.
  -- The Database Webhook on notifications table fires send-notification
  -- Edge Function automatically.
  INSERT INTO public.notifications (
    user_id,
    type,
    title_ar,
    title_en,
    body_ar,
    body_en,
    is_read,
    metadata,
    created_at
  ) VALUES (
    target_user_id,
    'chat_message',
    '💬 رسالة جديدة',
    '💬 New Message',
    display_body_ar,
    display_body_en,
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
