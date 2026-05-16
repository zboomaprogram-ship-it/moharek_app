-- Activity Feed Automation Triggers

-- Function to insert activity log
CREATE OR REPLACE FUNCTION public.log_activity()
RETURNS TRIGGER AS $$
DECLARE
    client_name TEXT;
    project_name TEXT;
    action_ar TEXT;
    action_en TEXT;
BEGIN
    -- Get project and client context
    SELECT name INTO project_name FROM public.projects WHERE id = NEW.project_id;
    
    -- Determine action based on table and event
    IF (TG_TABLE_NAME = 'tasks') THEN
        IF (NEW.status = 'done' AND OLD.status != 'done') THEN
            action_ar := '✅ تم إنجاز مهمة: ' || NEW.title;
            action_en := '✅ Task completed: ' || NEW.title;
        ELSIF (TG_OP = 'INSERT') THEN
            action_ar := '📝 مهمة جديدة: ' || NEW.title;
            action_en := '📝 New task: ' || NEW.title;
        ELSE
            RETURN NEW;
        END IF;
        
    ELSIF (TG_TABLE_NAME = 'reports') THEN
        IF (TG_OP = 'INSERT') THEN
            action_ar := '📄 تم رفع تقرير جديد: ' || COALESCE(NEW.title_ar, NEW.title);
            action_en := '📄 New report uploaded: ' || NEW.title;
        ELSE
            RETURN NEW;
        END IF;
        
    ELSIF (TG_TABLE_NAME = 'approvals') THEN
        IF (TG_OP = 'INSERT') THEN
            action_ar := '⚠️ بانتظار موافقتك: ' || NEW.title;
            action_en := '⚠️ Pending approval: ' || NEW.title;
        ELSE
            RETURN NEW;
        END IF;
        
    ELSIF (TG_TABLE_NAME = 'invoices') THEN
        IF (TG_OP = 'INSERT') THEN
            action_ar := '💳 فاتورة جديدة بانتظار السداد';
            action_en := '💳 New invoice pending payment';
        ELSIF (NEW.status = 'paid' AND OLD.status != 'paid') THEN
            action_ar := '💰 تم استلام دفعة مالية - شكراً لك';
            action_en := '💰 Payment received - Thank you';
        ELSE
            RETURN NEW;
        END IF;
    END IF;

    -- Insert into activity feed
    INSERT INTO public.activity_feed (
        project_id,
        actor_id,
        action_ar,
        action_en,
        entity_type,
        entity_id
    ) VALUES (
        NEW.project_id,
        auth.uid(),
        action_ar,
        action_en,
        TG_TABLE_NAME,
        NEW.id
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Triggers
DROP TRIGGER IF EXISTS tr_task_activity ON public.tasks;
CREATE TRIGGER tr_task_activity
    AFTER INSERT OR UPDATE ON public.tasks
    FOR EACH ROW EXECUTE FUNCTION public.log_activity();

DROP TRIGGER IF EXISTS tr_report_activity ON public.reports;
CREATE TRIGGER tr_report_activity
    AFTER INSERT ON public.reports
    FOR EACH ROW EXECUTE FUNCTION public.log_activity();

DROP TRIGGER IF EXISTS tr_approval_activity ON public.approvals;
CREATE TRIGGER tr_approval_activity
    AFTER INSERT ON public.approvals
    FOR EACH ROW EXECUTE FUNCTION public.log_activity();

DROP TRIGGER IF EXISTS tr_invoice_activity ON public.invoices;
CREATE TRIGGER tr_invoice_activity
    AFTER INSERT OR UPDATE ON public.invoices
    FOR EACH ROW EXECUTE FUNCTION public.log_activity();
