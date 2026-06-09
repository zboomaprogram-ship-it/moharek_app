-- =========================================================================
-- CLEANUP AND OPTIMIZE NOTIFICATIONS (Arabic Only + No Duplicates)
-- Run this script in your Supabase SQL Editor (https://supabase.com/dashboard)
-- =========================================================================

-- 1. DROP DUPLICATE PUSH NOTIFICATION TRIGGERS
-- We only need ONE trigger on the notifications table to send push notifications.
DROP TRIGGER IF EXISTS trigger_notification_inserted_push ON public.notifications;
DROP TRIGGER IF EXISTS trigger_notification_inserted ON public.notifications;

-- Re-create exactly ONE trigger for in-app notifications
CREATE OR REPLACE FUNCTION public.on_notification_inserted()
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

CREATE TRIGGER trigger_notification_inserted
  AFTER INSERT ON public.notifications
  FOR EACH ROW
  EXECUTE FUNCTION public.on_notification_inserted();


-- 2. DROP REDUNDANT ACTIVITY FEED PUSH NOTIFICATIONS
-- The activity feed is just a log and shouldn't trigger duplicate push notifications like "Project Update".
DROP TRIGGER IF EXISTS trigger_activity_feed_inserted ON public.activity_feed;


-- 3. UPDATE DB TRIGGERS TO ONLY INSERT ARABIC NOTIFICATION RECORDS
-- This enforces that notification titles and bodies are Arabic for both language columns.

-- 3a. New Approval Request Trigger Function
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
      '✅ طلب موافقة جديد', -- Arabic
      'يوجد عنصر جديد يحتاج موافقتك: ' || NEW.title,
      'يوجد عنصر جديد يحتاج موافقتك: ' || NEW.title, -- Arabic
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


-- 3b. New Task Trigger Function
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
      '📋 مهمة جديدة لمشروعك',
      '📋 مهمة جديدة لمشروعك', -- Arabic
      'تمت إضافة مهمة جديدة: ' || NEW.title,
      'تمت إضافة مهمة جديدة: ' || NEW.title, -- Arabic
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


-- 3c. Task Status Update Trigger Function
CREATE OR REPLACE FUNCTION public.notify_client_on_task_status_update()
RETURNS TRIGGER AS $$
DECLARE
  v_client_id UUID;
  v_status_ar TEXT;
BEGIN
  SELECT client_id INTO v_client_id FROM public.projects WHERE id = NEW.project_id;
  IF v_client_id IS NOT NULL THEN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
      v_status_ar := CASE NEW.status
        WHEN 'completed' THEN 'مكتملة'
        WHEN 'in_progress' THEN 'قيد العمل'
        ELSE 'قيد الانتظار'
      END;

      INSERT INTO public.notifications (
        user_id, title_ar, title_en, body_ar, body_en, type, link_path, metadata
      ) VALUES (
        v_client_id,
        '⚙️ تحديث حالة المهمة',
        '⚙️ تحديث حالة المهمة', -- Arabic
        'تم تحديث حالة المهمة "' || NEW.title || '" إلى: ' || v_status_ar,
        'تم تحديث حالة المهمة "' || NEW.title || '" إلى: ' || v_status_ar, -- Arabic
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


-- 3d. New Performance Results Trigger Function
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
      '📊 تحديث مؤشرات الأداء',
      '📊 تحديث مؤشرات الأداء', -- Arabic
      'تم تحديث مؤشر أداء جديد: ' || v_label || ' بقيمة ' || NEW.metric_value || ' ' || COALESCE(NEW.metric_unit, ''),
      'تم تحديث مؤشر أداء جديد: ' || v_label || ' بقيمة ' || NEW.metric_value || ' ' || COALESCE(NEW.metric_unit, ''), -- Arabic
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


-- 3e. New Report Trigger Function
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
      '📄 تقرير أداء جديد',
      '📄 تقرير أداء جديد', -- Arabic
      'تم إرفاق تقرير جديد لمشروعك: ' || NEW.title,
      'تم إرفاق تقرير جديد لمشروعك: ' || NEW.title, -- Arabic
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


-- 3f. New File Trigger Function
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
      '📁 ملف جديد في لوحة التحكم',
      '📁 ملف جديد في لوحة التحكم', -- Arabic
      'تم رفع ملف جديد لمشروعك: ' || NEW.name,
      'تم رفع ملف جديد لمشروعك: ' || NEW.name, -- Arabic
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


-- 3g. New Meeting Scheduled Trigger Function
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
      '📅 جدولة اجتماع جديد',
      '📅 جدولة اجتماع جديد', -- Arabic
      'تمت جدولة اجتماع جديد بعنوان: ' || NEW.title,
      'تمت جدولة اجتماع جديد بعنوان: ' || NEW.title, -- Arabic
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


-- 3h. New Invoice / Billing Trigger Function
CREATE OR REPLACE FUNCTION public.notify_client_on_new_invoice()
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
      '💰 فاتورة جديدة بانتظار السداد',
      '💰 فاتورة جديدة بانتظار السداد', -- Arabic
      'تم إصدار فاتورة جديدة بقيمة ' || NEW.amount || ' ' || COALESCE(NEW.currency, 'SAR') || '. يرجى المراجعة والسداد.',
      'تم إصدار فاتورة جديدة بقيمة ' || NEW.amount || ' ' || COALESCE(NEW.currency, 'SAR') || '. يرجى المراجعة والسداد.', -- Arabic
      'invoice',
      '/billing',
      jsonb_build_object('project_id', NEW.project_id, 'invoice_id', NEW.id)
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_notify_client_on_new_invoice ON public.invoices;
CREATE TRIGGER tr_notify_client_on_new_invoice
  AFTER INSERT ON public.invoices
  FOR EACH ROW EXECUTE FUNCTION public.notify_client_on_new_invoice();


-- 3i. New Support Ticket Trigger Function
CREATE OR REPLACE FUNCTION public.notify_client_on_new_support_ticket()
RETURNS TRIGGER AS $$
DECLARE
  v_client_id UUID;
BEGIN
  v_client_id := NEW.client_id;
  IF v_client_id IS NULL AND NEW.project_id IS NOT NULL THEN
    SELECT client_id INTO v_client_id FROM public.projects WHERE id = NEW.project_id;
  END IF;
  
  IF v_client_id IS NOT NULL THEN
    INSERT INTO public.notifications (
      user_id, title_ar, title_en, body_ar, body_en, type, link_path, metadata
    ) VALUES (
      v_client_id,
      '🎫 تذكرة دعم جديدة',
      '🎫 تذكرة دعم جديدة', -- Arabic
      'تم إنشاء تذكرة دعم فني بعنوان: ' || NEW.title,
      'تم إنشاء تذكرة دعم فني بعنوان: ' || NEW.title, -- Arabic
      'ticket',
      '/support',
      jsonb_build_object('project_id', NEW.project_id, 'ticket_id', NEW.id)
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_notify_client_on_new_support_ticket ON public.support_tickets;
CREATE TRIGGER tr_notify_client_on_new_support_ticket
  AFTER INSERT ON public.support_tickets
  FOR EACH ROW EXECUTE FUNCTION public.notify_client_on_new_support_ticket();


-- 4. RE-ENABLE CLIENT UPDATE POLICIES FOR APPROVALS AND CONTRACTS
-- Allow clients to approve/reject approval requests and sign contracts.
DROP POLICY IF EXISTS "Clients update approvals" ON public.approvals;
CREATE POLICY "Clients update approvals" ON public.approvals FOR UPDATE
  USING (project_id IN (SELECT my_project_ids()))
  WITH CHECK (project_id IN (SELECT my_project_ids()));

DROP POLICY IF EXISTS "Clients update contracts" ON public.contracts;
CREATE POLICY "Clients update contracts" ON public.contracts FOR UPDATE
  USING (project_id IN (SELECT my_project_ids()))
  WITH CHECK (project_id IN (SELECT my_project_ids()));


-- 5. DATABASE-LEVEL DEDUPLICATION TRIGGER FOR NOTIFICATIONS
-- Prevents duplicate notifications when client and database triggers both fire.
CREATE OR REPLACE FUNCTION public.clean_notification_body(body TEXT)
RETURNS TEXT AS $$
BEGIN
  -- Remove standard prefixes
  body := regexp_replace(
    body, 
    '^(✅ طلب موافقة جديد|✅ رد على طلب موافقة|📋 مهمة جديدة لمشروعك|📋 مهمة جديدة بانتظارك|📋 مهمة جديدة|⚙️ تحديث حالة المهمة|📊 تحديث مؤشرات الأداء|📊 تحديث النتائج|📄 تقرير أداء جديد|📄 تقرير جديد متاح|📄 تقرير جديد|📁 ملف جديد في لوحة التحكم|📁 ملف جديد|📅 جدولة اجتماع جديد|📅 تم تحديد اجتماع جديد|📅 اجتماع جديد|💰 فاتورة جديدة بانتظار السداد|💰 فاتورة جديدة|🎫 تذكرة دعم جديدة|🎫 تذكرة دعم|💳 رابط دفع جديد|💬 رسالة جديدة|يوجد عنصر جديد يحتاج موافقتك:\s*|تمت إضافة مهمة جديدة:\s*|تمت إضافة مهمة:\s*|تم تحديث حالة المهمة\s*|تم تحديث مؤشر أداء جديد:\s*|تم إرفاق تقرير جديد لمشروعك:\s*|تم رفع تقرير جديد لمشروعك:\s*|تم رفع تقرير جديد بعنوان:\s*|تم رفع ملف جديد لمشروعك:\s*|تمت إضافة ملف جديد:\s*|تمت جدولة اجتماع جديد بعنوان:\s*|تم جدولة اجتماع:\s*|تم إنشاء تذكرة دعم فني بعنوان:\s*|تم إنشاء تذكرة دعم فني جديدة بعنوان:\s*|قام العميل بالرد على طلب الموافقة:\s*|رد فريق الدعم على:\s*|تم إصدار فاتورة جديدة بقيمة\s*|تم إصدار فاتورة جديدة بمبلغ\s*|تم إرسال رابط الدفع\s*)', 
    '',
    'i'
  );
  -- Remove standard suffixes and dynamic variables
  body := regexp_replace(
    body, 
    '(\. يرجى المراجعة في أقرب وقت\.?|\. يمكنك متابعة التفاصيل الآن\.?|\. سيتواصل معك الفريق قريباً\.?|\. تحقق من التفاصيل والتوقيت\.?|\. افتح قسم الملفات للاطلاع عليه\.?|\. يرجى المراجعة والسداد\.?|\. يرجى المراجعة والدفع\.?|\. يرجى المراجعة في أقرب وقت\.?|\. يرجى المراجعة\.?|\. شكراً! تم تسجيل دفعتك بنجاح\.?|\. اضغط للدفع الآن\.?|\s*|\")\s*$', 
    '',
    'i'
  );
  RETURN trim(body);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.deduplicate_notification()
RETURNS TRIGGER AS $$
DECLARE
  v_exists BOOLEAN;
  v_new_clean TEXT;
BEGIN
  v_new_clean := public.clean_notification_body(NEW.body_ar);
  
  SELECT EXISTS (
    SELECT 1 FROM public.notifications
    WHERE user_id = NEW.user_id
      AND type = NEW.type
      AND created_at >= (now() - interval '10 seconds')
      AND (
        body_ar = NEW.body_ar 
        OR public.clean_notification_body(body_ar) = v_new_clean
      )
  ) INTO v_exists;

  IF v_exists THEN
    RETURN NULL;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_notification_deduplicate ON public.notifications;
CREATE TRIGGER trigger_notification_deduplicate
  BEFORE INSERT ON public.notifications
  FOR EACH ROW
  EXECUTE FUNCTION public.deduplicate_notification();

