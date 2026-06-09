-- =========================================================================
-- SYSTEM-WIDE TRIGGER SETUP FOR ADMIN/AM TO CLIENT NOTIFICATIONS
-- Automatically notifies clients when any action is taken in the dashboard.
-- =========================================================================

-- 1. NOTIFY CLIENT ON NEW TASK
CREATE OR REPLACE FUNCTION public.notify_client_on_new_task()
RETURNS TRIGGER AS $$
DECLARE
  v_client_id UUID;
BEGIN
  SELECT client_id INTO v_client_id FROM public.projects WHERE id = NEW.project_id;
  IF v_client_id IS NOT NULL THEN
    INSERT INTO public.notifications (
      user_id, title_ar, title_en, body_ar, body_en, type, link_path, metadata
    ) VALUES (
      v_client_id,
      '📋 مهمة جديدة بانتظارك',
      '📋 New Task Added',
      'تمت إضافة مهمة جديدة: ' || NEW.title,
      'A new task has been added: ' || NEW.title,
      'task',
      '/tasks',
      jsonb_build_object('project_id', NEW.project_id, 'task_id', NEW.id)
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_notify_client_on_new_task ON public.tasks;
CREATE TRIGGER tr_notify_client_on_new_task
  AFTER INSERT ON public.tasks
  FOR EACH ROW EXECUTE FUNCTION public.notify_client_on_new_task();


-- 2. NOTIFY CLIENT ON TASK STATUS UPDATE
CREATE OR REPLACE FUNCTION public.notify_client_on_task_status_update()
RETURNS TRIGGER AS $$
DECLARE
  v_client_id UUID;
  v_status_ar TEXT;
BEGIN
  IF NEW.status != OLD.status THEN
    SELECT client_id INTO v_client_id FROM public.projects WHERE id = NEW.project_id;
    IF v_client_id IS NOT NULL THEN
      v_status_ar := CASE 
        WHEN NEW.status = 'completed' THEN 'مكتملة'
        WHEN NEW.status = 'in_progress' THEN 'قيد التنفيذ'
        ELSE NEW.status
      END;
      INSERT INTO public.notifications (
        user_id, title_ar, title_en, body_ar, body_en, type, link_path, metadata
      ) VALUES (
        v_client_id,
        '📋 تحديث حالة مهمة',
        '📋 Task Status Updated',
        'تم تحديث حالة المهمة "' || NEW.title || '" إلى: ' || v_status_ar,
        'Task "' || NEW.title || '" status was updated to: ' || NEW.status,
        'task',
        '/tasks',
        jsonb_build_object('project_id', NEW.project_id, 'task_id', NEW.id, 'status', NEW.status)
      );
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_notify_client_on_task_status_update ON public.tasks;
CREATE TRIGGER tr_notify_client_on_task_status_update
  AFTER UPDATE OF status ON public.tasks
  FOR EACH ROW EXECUTE FUNCTION public.notify_client_on_task_status_update();


-- 3. NOTIFY CLIENT ON NEW APPROVAL REQUEST
CREATE OR REPLACE FUNCTION public.notify_client_on_new_approval()
RETURNS TRIGGER AS $$
DECLARE
  v_client_id UUID;
BEGIN
  SELECT client_id INTO v_client_id FROM public.projects WHERE id = NEW.project_id;
  IF v_client_id IS NOT NULL THEN
    INSERT INTO public.notifications (
      user_id, title_ar, title_en, body_ar, body_en, type, link_path, metadata
    ) VALUES (
      v_client_id,
      '✅ طلب موافقة جديد',
      '✅ New Approval Request',
      'يوجد عنصر جديد يحتاج موافقتك: ' || NEW.title,
      'A new approval request is pending: ' || NEW.title,
      'approval',
      '/approvals',
      jsonb_build_object('project_id', NEW.project_id, 'approval_id', NEW.id)
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_notify_client_on_new_approval ON public.approvals;
CREATE TRIGGER tr_notify_client_on_new_approval
  AFTER INSERT ON public.approvals
  FOR EACH ROW EXECUTE FUNCTION public.notify_client_on_new_approval();


-- 4. NOTIFY CLIENT ON NEW PERFORMANCE SNAPSHOT (RESULTS)
CREATE OR REPLACE FUNCTION public.notify_client_on_new_result()
RETURNS TRIGGER AS $$
DECLARE
  v_client_id UUID;
  v_label     TEXT;
BEGIN
  SELECT client_id INTO v_client_id FROM public.projects WHERE id = NEW.project_id;
  IF v_client_id IS NOT NULL THEN
    v_label := COALESCE(NEW.metric_label, NEW.metric_name);
    INSERT INTO public.notifications (
      user_id, title_ar, title_en, body_ar, body_en, type, link_path, metadata
    ) VALUES (
      v_client_id,
      '📊 تحديث لقطات الأداء',
      '📊 Performance Snapshot Update',
      'تم تحديث مؤشر أداء جديد: ' || v_label || ' بقيمة ' || NEW.metric_value || ' ' || COALESCE(NEW.metric_unit, ''),
      'A new performance metric has been updated: ' || v_label || ' to ' || NEW.metric_value || ' ' || COALESCE(NEW.metric_unit, ''),
      'metrics',
      '/results',
      jsonb_build_object('project_id', NEW.project_id, 'result_id', NEW.id)
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_notify_client_on_new_result ON public.results;
CREATE TRIGGER tr_notify_client_on_new_result
  AFTER INSERT ON public.results
  FOR EACH ROW EXECUTE FUNCTION public.notify_client_on_new_result();


-- 5. NOTIFY CLIENT ON NEW REPORT
CREATE OR REPLACE FUNCTION public.notify_client_on_new_report()
RETURNS TRIGGER AS $$
DECLARE
  v_client_id UUID;
BEGIN
  SELECT client_id INTO v_client_id FROM public.projects WHERE id = NEW.project_id;
  IF v_client_id IS NOT NULL THEN
    INSERT INTO public.notifications (
      user_id, title_ar, title_en, body_ar, body_en, type, link_path, metadata
    ) VALUES (
      v_client_id,
      '📄 تقرير جديد متاح',
      '📄 New Report Available',
      'تم رفع تقرير جديد للمشروع: ' || NEW.title,
      'A new report has been uploaded: ' || NEW.title,
      'report',
      '/reports',
      jsonb_build_object('project_id', NEW.project_id, 'report_id', NEW.id)
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_notify_client_on_new_report ON public.reports;
CREATE TRIGGER tr_notify_client_on_new_report
  AFTER INSERT ON public.reports
  FOR EACH ROW EXECUTE FUNCTION public.notify_client_on_new_report();


-- 6. NOTIFY CLIENT ON NEW FILE
CREATE OR REPLACE FUNCTION public.notify_client_on_new_file()
RETURNS TRIGGER AS $$
DECLARE
  v_client_id UUID;
BEGIN
  SELECT client_id INTO v_client_id FROM public.projects WHERE id = NEW.project_id;
  IF v_client_id IS NOT NULL THEN
    INSERT INTO public.notifications (
      user_id, title_ar, title_en, body_ar, body_en, type, link_path, metadata
    ) VALUES (
      v_client_id,
      '📁 ملف جديد متاح',
      '📁 New File Uploaded',
      'تم رفع ملف جديد: ' || NEW.name,
      'A new file has been uploaded: ' || NEW.name,
      'info',
      '/files',
      jsonb_build_object('project_id', NEW.project_id, 'file_id', NEW.id)
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_notify_client_on_new_file ON public.files;
CREATE TRIGGER tr_notify_client_on_new_file
  AFTER INSERT ON public.files
  FOR EACH ROW EXECUTE FUNCTION public.notify_client_on_new_file();


-- 7. NOTIFY CLIENT ON NEW MEETING
CREATE OR REPLACE FUNCTION public.notify_client_on_new_meeting()
RETURNS TRIGGER AS $$
DECLARE
  v_client_id UUID;
BEGIN
  SELECT client_id INTO v_client_id FROM public.projects WHERE id = NEW.project_id;
  IF v_client_id IS NOT NULL THEN
    INSERT INTO public.notifications (
      user_id, title_ar, title_en, body_ar, body_en, type, link_path, metadata
    ) VALUES (
      v_client_id,
      '📅 تم جدولة اجتماع جديد',
      '📅 New Meeting Scheduled',
      'تم جدولة اجتماع جديد بعنوان: ' || NEW.title,
      'A new meeting has been scheduled: ' || NEW.title,
      'meeting',
      '/meetings',
      jsonb_build_object('project_id', NEW.project_id, 'meeting_id', NEW.id)
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_notify_client_on_new_meeting ON public.meetings;
CREATE TRIGGER tr_notify_client_on_new_meeting
  AFTER INSERT ON public.meetings
  FOR EACH ROW EXECUTE FUNCTION public.notify_client_on_new_meeting();


-- 8. NOTIFY CLIENT ON ENGINE PROGRESS UPDATE (STRATEGY CHECKLIST)
CREATE OR REPLACE FUNCTION public.notify_client_on_engine_progress_update()
RETURNS TRIGGER AS $$
DECLARE
  v_client_id UUID;
  v_engine_label TEXT;
  v_should_notify BOOLEAN := FALSE;
BEGIN
  IF TG_OP = 'INSERT' THEN
    v_should_notify := TRUE;
  ELSIF TG_OP = 'UPDATE' AND NEW.progress_percent != COALESCE(OLD.progress_percent, -1) THEN
    v_should_notify := TRUE;
  END IF;

  IF v_should_notify THEN
    SELECT client_id INTO v_client_id FROM public.projects WHERE id = NEW.project_id;
    IF v_client_id IS NOT NULL THEN
      v_engine_label := CASE 
        WHEN NEW.engine = 'seo' THEN 'استراتيجية SEO والظهور'
        WHEN NEW.engine = 'ads' THEN 'الإعلانات الممولة والنمو'
        WHEN NEW.engine = 'ai_visibility' THEN 'ظهور محركات البحث والذكاء الاصطناعي'
        WHEN NEW.engine = 'trust_engine' THEN 'محرك بناء الثقة والمراجعات'
        WHEN NEW.engine = 'conversion' THEN 'تحسين معدل التحويل والمبيعات'
        WHEN NEW.engine = 'leads' THEN 'بناء قنوات الاستحواذ والعملاء'
        ELSE NEW.engine
      END;
      INSERT INTO public.notifications (
        user_id, title_ar, title_en, body_ar, body_en, type, link_path, metadata
      ) VALUES (
        v_client_id,
        '🚀 تقدم في استراتيجية النمو',
        '🚀 Growth Strategy Progress Update',
        'تم إحراز تقدم في ' || v_engine_label || ' ليصل إلى ' || NEW.progress_percent || '%',
        'Progress updated on ' || NEW.engine || ' engine: ' || NEW.progress_percent || '%',
        'milestone',
        '/strategy',
        jsonb_build_object('project_id', NEW.project_id, 'engine', NEW.engine, 'progress', NEW.progress_percent)
      );
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_notify_client_on_engine_progress_update ON public.engine_progress;
CREATE TRIGGER tr_notify_client_on_engine_progress_update
  AFTER INSERT OR UPDATE ON public.engine_progress
  FOR EACH ROW EXECUTE FUNCTION public.notify_client_on_engine_progress_update();


-- 9. RE-CREATE CHAT TRIGGER TO NOTIFY BOTH AM AND ADMINS
CREATE OR REPLACE FUNCTION public.on_message_inserted()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_project_id      UUID;
  project_client_id UUID;
  project_am_id     UUID;
  project_name      TEXT;
  sender_name       TEXT;
  display_body_ar   TEXT;
  display_body_en   TEXT;
BEGIN
  -- Skip system messages
  IF NEW.message_type = 'system' THEN RETURN NEW; END IF;
 
  -- Get the project's client, AM and name for this chat channel
  SELECT p.id, p.client_id, p.account_manager_id, p.name
  INTO v_project_id, project_client_id, project_am_id, project_name
  FROM public.chat_channels c
  JOIN public.projects p ON c.project_id = p.id
  WHERE c.id = NEW.channel_id;
 
  -- Get sender display name
  SELECT COALESCE(full_name, 'مستخدم')
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
 
  -- Determine if the sender is the client
  IF NEW.sender_id = project_client_id THEN
    -- Sender is client -> Notify AM and admins
    
    -- A) Notify AM
    IF project_am_id IS NOT NULL THEN
      INSERT INTO public.notifications (
        user_id, type, title_ar, title_en, body_ar, body_en, is_read, metadata, created_at
      ) VALUES (
        project_am_id, 'chat_message', '💬 رسالة جديدة (' || project_name || ')', '💬 New Message (' || project_name || ')',
        display_body_ar, display_body_en, false,
        jsonb_build_object('sender_id', NEW.sender_id, 'channel_id', NEW.channel_id, 'message_id', NEW.id, 'project_id', v_project_id),
        now()
      );
    END IF;
 
    -- B) Notify Admins
    INSERT INTO public.notifications (
      user_id, type, title_ar, title_en, body_ar, body_en, is_read, metadata, created_at
    )
    SELECT id, 'chat_message', '💬 رسالة جديدة (' || project_name || ')', '💬 New Message (' || project_name || ')',
           display_body_ar, display_body_en, false,
           jsonb_build_object('sender_id', NEW.sender_id, 'channel_id', NEW.channel_id, 'message_id', NEW.id, 'project_id', v_project_id),
           now()
    FROM public.profiles
    WHERE role = 'admin' AND id != COALESCE(project_am_id, '00000000-0000-0000-0000-000000000000'::uuid);
 
  ELSE
    -- Sender is not client (AM or Admin) -> Notify client
    INSERT INTO public.notifications (
      user_id, type, title_ar, title_en, body_ar, body_en, is_read, metadata, created_at
    ) VALUES (
      project_client_id, 'chat_message', '💬 رسالة جديدة', '💬 New Message',
      display_body_ar, display_body_en, false,
      jsonb_build_object('sender_id', NEW.sender_id, 'channel_id', NEW.channel_id, 'message_id', NEW.id, 'project_id', v_project_id),
      now()
    );
  END IF;
 
  RETURN NEW;
END;
$$;
 
DROP TRIGGER IF EXISTS trigger_on_message_inserted ON public.messages;
CREATE TRIGGER trigger_on_message_inserted
  AFTER INSERT ON public.messages
  FOR EACH ROW EXECUTE FUNCTION public.on_message_inserted();


-- 10. ENABLE REALTIME FOR PROJECTS
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'projects'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE projects;
  END IF;
END$$;
