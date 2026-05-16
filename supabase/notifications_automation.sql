-- Automation: Generate Notifications on Key Events

-- 1. Support Ticket Reply Trigger
CREATE OR REPLACE FUNCTION public.notify_ticket_reply()
RETURNS TRIGGER AS $$
DECLARE
    p_id UUID;
    c_id UUID;
    t_title TEXT;
    is_team BOOLEAN;
BEGIN
    -- Get ticket context
    SELECT project_id, title INTO p_id, t_title FROM public.support_tickets WHERE id = NEW.ticket_id;
    SELECT client_id INTO c_id FROM public.projects WHERE id = p_id;
    
    -- Check if sender is team
    SELECT (team_role IS NOT NULL) INTO is_team FROM public.profiles WHERE id = NEW.sender_id;

    IF is_team THEN
        INSERT INTO public.notifications (user_id, title_ar, title_en, body_ar, body_en, type, link_path)
        VALUES (
            c_id,
            'رد جديد على التذكرة',
            'New Ticket Reply',
            'رد فريق الدعم على: ' || t_title,
            'Support team replied to: ' || t_title,
            'ticket',
            '/profile/support/' || NEW.ticket_id
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_notify_ticket_reply ON public.support_ticket_messages;
CREATE TRIGGER tr_notify_ticket_reply
    AFTER INSERT ON public.support_ticket_messages
    FOR EACH ROW EXECUTE FUNCTION public.notify_ticket_reply();

-- 2. New Task Notification
CREATE OR REPLACE FUNCTION public.notify_new_task()
RETURNS TRIGGER AS $$
DECLARE
    c_id UUID;
BEGIN
    SELECT client_id INTO c_id FROM public.projects WHERE id = NEW.project_id;
    
    INSERT INTO public.notifications (user_id, title_ar, title_en, body_ar, body_en, type, link_path)
    VALUES (
        c_id,
        'مهمة جديدة',
        'New Task Assigned',
        'تمت إضافة مهمة: ' || NEW.title,
        'A new task was added: ' || NEW.title,
        'task',
        '/tasks'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_notify_new_task ON public.tasks;
CREATE TRIGGER tr_notify_new_task
    AFTER INSERT ON public.tasks
    FOR EACH ROW EXECUTE FUNCTION public.notify_new_task();

-- 3. Milestone Achievement
CREATE OR REPLACE FUNCTION public.notify_milestone()
RETURNS TRIGGER AS $$
DECLARE
    c_id UUID;
BEGIN
    SELECT client_id INTO c_id FROM public.projects WHERE id = NEW.project_id;
    
    INSERT INTO public.notifications (user_id, title_ar, title_en, body_ar, body_en, type, link_path)
    VALUES (
        c_id,
        'إنجاز جديد! 🎉',
        'New Milestone! 🎉',
        NEW.title_ar,
        NEW.title_en,
        'milestone',
        '/dashboard/growth-story'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_notify_milestone ON public.milestones;
CREATE TRIGGER tr_notify_milestone
    AFTER INSERT ON public.milestones
    FOR EACH ROW EXECUTE FUNCTION public.notify_milestone();
