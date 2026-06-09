-- ── 1. Notify AM/Admins when a client requests a task ──

CREATE OR REPLACE FUNCTION public.notify_admin_on_new_client_task()
RETURNS TRIGGER AS $$
DECLARE
  p_am_id     UUID;
  p_name      TEXT;
BEGIN
  IF NEW.is_client_request = true THEN
    SELECT account_manager_id, name
    INTO p_am_id, p_name
    FROM public.projects
    WHERE id = NEW.project_id;

    -- Notify AM
    IF p_am_id IS NOT NULL THEN
      INSERT INTO public.notifications (user_id, type, title_ar, title_en, body_ar, body_en, is_read, metadata)
      VALUES (
        p_am_id,
        'task',
        '📋 طلب مهمة جديدة من العميل',
        '📋 New Task Request from Client',
        'طلب العميل مهمة جديدة: ' || COALESCE(NEW.title, 'بدون عنوان'),
        'Client requested a new task: ' || COALESCE(NEW.title, 'Untitled'),
        false,
        jsonb_build_object('project_id', NEW.project_id, 'task_id', NEW.id)
      );
    END IF;

    -- Notify admins
    INSERT INTO public.notifications (user_id, type, title_ar, title_en, body_ar, body_en, is_read, metadata)
    SELECT id,
           'task',
           '📋 طلب مهمة جديدة (' || COALESCE(p_name, 'العميل') || ')',
           '📋 New Task Request (' || COALESCE(p_name, 'Client') || ')',
           'طلب العميل مهمة جديدة: ' || COALESCE(NEW.title, 'بدون عنوان'),
           'Client requested a new task: ' || COALESCE(NEW.title, 'Untitled'),
           false,
           jsonb_build_object('project_id', NEW.project_id, 'task_id', NEW.id)
    FROM public.profiles
    WHERE role = 'admin' AND id != COALESCE(p_am_id, '00000000-0000-0000-0000-000000000000'::uuid);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_notify_admin_on_new_client_task ON public.tasks;
CREATE TRIGGER tr_notify_admin_on_new_client_task
  AFTER INSERT ON public.tasks
  FOR EACH ROW EXECUTE FUNCTION public.notify_admin_on_new_client_task();


-- ── 2. Notify AM/Admins when a client schedules/requests a meeting ──

CREATE OR REPLACE FUNCTION public.notify_admin_on_new_meeting()
RETURNS TRIGGER AS $$
DECLARE
  p_am_id     UUID;
  p_name      TEXT;
  is_client   BOOLEAN;
BEGIN
  -- Check if the creator is indeed a client
  SELECT (role = 'client') INTO is_client
  FROM public.profiles
  WHERE id = auth.uid();

  IF is_client = true THEN
    SELECT account_manager_id, name
    INTO p_am_id, p_name
    FROM public.projects
    WHERE id = NEW.project_id;

    -- Notify AM
    IF p_am_id IS NOT NULL THEN
      INSERT INTO public.notifications (user_id, type, title_ar, title_en, body_ar, body_en, is_read, metadata)
      VALUES (
        p_am_id,
        'meeting',
        '📅 طلب اجتماع جديد من العميل',
        '📅 New Meeting Request from Client',
        'طلب العميل اجتماعاً جديداً: ' || COALESCE(NEW.title, 'بدون عنوان'),
        'Client requested a new meeting: ' || COALESCE(NEW.title, 'Untitled'),
        false,
        jsonb_build_object('project_id', NEW.project_id, 'meeting_id', NEW.id)
      );
    END IF;

    -- Notify admins
    INSERT INTO public.notifications (user_id, type, title_ar, title_en, body_ar, body_en, is_read, metadata)
    SELECT id,
           'meeting',
           '📅 طلب اجتماع جديد (' || COALESCE(p_name, 'العميل') || ')',
           '📅 New Meeting Request (' || COALESCE(p_name, 'Client') || ')',
           'طلب العميل اجتماعاً جديداً: ' || COALESCE(NEW.title, 'بدون عنوان'),
           'Client requested a new meeting: ' || COALESCE(NEW.title, 'Untitled'),
           false,
           jsonb_build_object('project_id', NEW.project_id, 'meeting_id', NEW.id)
    FROM public.profiles
    WHERE role = 'admin' AND id != COALESCE(p_am_id, '00000000-0000-0000-0000-000000000000'::uuid);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_notify_admin_on_new_meeting ON public.meetings;
CREATE TRIGGER tr_notify_admin_on_new_meeting
  AFTER INSERT ON public.meetings
  FOR EACH ROW EXECUTE FUNCTION public.notify_admin_on_new_meeting();
