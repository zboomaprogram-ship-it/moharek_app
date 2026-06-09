-- =========================================================================
-- TRIGGER AND NOTIFICATION AUTO-SETUP FOR CLIENT & AM ACTIONS
-- Run this in your Supabase SQL Editor to enable notifications for all actions
-- =========================================================================

-- 1. Notify AM/Admins when a client responds to an approval
CREATE OR REPLACE FUNCTION public.notify_approval_response()
RETURNS TRIGGER AS $$
DECLARE
  p_client_id UUID;
  p_am_id     UUID;
  p_name      TEXT;
BEGIN
  IF NEW.status != 'pending' AND OLD.status = 'pending' THEN
    SELECT client_id, account_manager_id, name
    INTO p_client_id, p_am_id, p_name
    FROM public.projects
    WHERE id = NEW.project_id;

    -- Notify AM
    IF p_am_id IS NOT NULL THEN
      INSERT INTO public.notifications (user_id, title_ar, title_en, body_ar, body_en, type, link_path, metadata)
      VALUES (
        p_am_id,
        '✅ رد على طلب موافقة',
        '✅ Approval Response Received',
        'قام العميل بالرد على طلب الموافقة: ' || NEW.title || ' (' || NEW.status || ')',
        'Client responded to approval: ' || NEW.title || ' (' || NEW.status || ')',
        'approval',
        '/am/approvals',
        jsonb_build_object('project_id', NEW.project_id, 'approval_id', NEW.id, 'status', NEW.status)
      );
    END IF;

    -- Notify admins
    INSERT INTO public.notifications (user_id, title_ar, title_en, body_ar, body_en, type, link_path, metadata)
    SELECT id, 
           '✅ رد على طلب موافقة (' || p_name || ')',
           '✅ Approval Response (' || p_name || ')',
           'قام العميل بالرد على طلب الموافقة: ' || NEW.title || ' (' || NEW.status || ')',
           'Client responded to approval: ' || NEW.title || ' (' || NEW.status || ')',
           'approval',
           '/admin/clients/' || NEW.project_id,
           jsonb_build_object('project_id', NEW.project_id, 'approval_id', NEW.id, 'status', NEW.status)
    FROM public.profiles
    WHERE role = 'admin' AND id != COALESCE(p_am_id, '00000000-0000-0000-0000-000000000000'::uuid);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_notify_approval_response ON public.approvals;
CREATE TRIGGER tr_notify_approval_response
  AFTER UPDATE OF status ON public.approvals
  FOR EACH ROW EXECUTE FUNCTION public.notify_approval_response();


-- 2. Notify AM/Admins when a client creates a support ticket
CREATE OR REPLACE FUNCTION public.notify_new_ticket()
RETURNS TRIGGER AS $$
DECLARE
  p_am_id     UUID;
  p_name      TEXT;
BEGIN
  SELECT account_manager_id, name
  INTO p_am_id, p_name
  FROM public.projects
  WHERE id = NEW.project_id;

  -- Notify AM
  IF p_am_id IS NOT NULL THEN
    INSERT INTO public.notifications (user_id, title_ar, title_en, body_ar, body_en, type, link_path, metadata)
    VALUES (
      p_am_id,
      '🎫 تذكرة دعم جديدة',
      '🎫 New Support Ticket',
      'تم إنشاء تذكرة دعم فني جديدة بعنوان: ' || NEW.title,
      'A new support ticket was opened: ' || NEW.title,
      'support_ticket',
      '/am/clients',
      jsonb_build_object('project_id', NEW.project_id, 'ticket_id', NEW.id)
    );
  END IF;

  -- Notify admins
  INSERT INTO public.notifications (user_id, title_ar, title_en, body_ar, body_en, type, link_path, metadata)
  SELECT id,
         '🎫 تذكرة دعم جديدة (' || p_name || ')',
         '🎫 New Support Ticket (' || p_name || ')',
         'تم إنشاء تذكرة دعم فني جديدة بعنوان: ' || NEW.title,
         'A new support ticket was opened: ' || NEW.title,
         'support_ticket',
         '/admin/support',
         jsonb_build_object('project_id', NEW.project_id, 'ticket_id', NEW.id)
  FROM public.profiles
  WHERE role = 'admin' AND id != COALESCE(p_am_id, '00000000-0000-0000-0000-000000000000'::uuid);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_notify_new_ticket ON public.support_tickets;
CREATE TRIGGER tr_notify_new_ticket
  AFTER INSERT ON public.support_tickets
  FOR EACH ROW EXECUTE FUNCTION public.notify_new_ticket();


-- 3. Notify AM/Admins when a client replies to a support ticket
CREATE OR REPLACE FUNCTION public.notify_ticket_reply()
RETURNS TRIGGER AS $$
DECLARE
  p_id      UUID;
  c_id      UUID;
  p_am_id   UUID;
  p_name    TEXT;
  t_title   TEXT;
  is_team   BOOLEAN;
BEGIN
  SELECT project_id, title INTO p_id, t_title FROM public.support_tickets WHERE id = NEW.ticket_id;
  SELECT client_id, account_manager_id, name INTO c_id, p_am_id, p_name FROM public.projects WHERE id = p_id;
  
  SELECT (team_role IS NOT NULL OR role IN ('admin', 'account_manager')) 
  INTO is_team 
  FROM public.profiles 
  WHERE id = NEW.sender_id;

  IF is_team THEN
    -- Notify client
    INSERT INTO public.notifications (user_id, title_ar, title_en, body_ar, body_en, type, link_path, metadata)
    VALUES (
      c_id,
      'رد جديد على التذكرة',
      'New Ticket Reply',
      'رد فريق الدعم على: ' || t_title,
      'Support team replied to: ' || t_title,
      'ticket',
      '/profile/support/' || NEW.ticket_id,
      jsonb_build_object('ticket_id', NEW.ticket_id)
    );
  ELSE
    -- Notify AM
    IF p_am_id IS NOT NULL THEN
      INSERT INTO public.notifications (user_id, title_ar, title_en, body_ar, body_en, type, link_path, metadata)
      VALUES (
        p_am_id,
        '💬 رد على تذكرة الدعم',
        '💬 Support Ticket Reply',
        'رد العميل على التذكرة: ' || t_title,
        'Client replied to ticket: ' || t_title,
        'ticket',
        '/am/clients',
        jsonb_build_object('ticket_id', NEW.ticket_id)
      );
    END IF;

    -- Notify admins
    INSERT INTO public.notifications (user_id, title_ar, title_en, body_ar, body_en, type, link_path, metadata)
    SELECT id,
           '💬 رد على تذكرة (' || p_name || ')',
           '💬 Ticket Reply (' || p_name || ')',
           'رد العميل على التذكرة: ' || t_title,
           'Client replied to ticket: ' || t_title,
           'ticket',
           '/admin/support',
           jsonb_build_object('ticket_id', NEW.ticket_id)
    FROM public.profiles
    WHERE role = 'admin' AND id != COALESCE(p_am_id, '00000000-0000-0000-0000-000000000000'::uuid);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_notify_ticket_reply ON public.support_ticket_messages;
CREATE TRIGGER tr_notify_ticket_reply
  AFTER INSERT ON public.support_ticket_messages
  FOR EACH ROW EXECUTE FUNCTION public.notify_ticket_reply();


-- 4. Automatically fire send-notification edge function on ANY new notification insert via pg_net
-- This guarantees push notifications are sent without requiring manual dashboard webhook configurations.
CREATE EXTENSION IF NOT EXISTS "pg_net";

CREATE OR REPLACE FUNCTION public.on_notification_inserted_send_push()
RETURNS TRIGGER AS $$
DECLARE
  service_role_key TEXT := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5cGJhZGRxcWhwZXBwenBiYmhqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3ODE1MTgxMSwiZXhwIjoyMDkzNzI3ODExfQ.rkFLhelMXjVLb44Wf9vY6RRM-priol6f1Y-K72sn87U';
  function_url TEXT := 'https://typbaddqqhpeppzpbbhj.supabase.co/functions/v1/send-notification';
BEGIN
  PERFORM
    net.http_post(
      url := function_url,
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || service_role_key
      ),
      body := jsonb_build_object(
        'table', 'notifications',
        'record', row_to_json(NEW)
      )
    );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_notification_inserted_push ON public.notifications;
CREATE TRIGGER trigger_notification_inserted_push
  AFTER INSERT ON public.notifications
  FOR EACH ROW EXECUTE FUNCTION public.on_notification_inserted_send_push();
