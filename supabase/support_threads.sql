-- Support Threads Implementation
-- Allows multiple messages per support ticket

-- 1. Create the messages table
CREATE TABLE IF NOT EXISTS public.support_ticket_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_id UUID NOT NULL REFERENCES public.support_tickets(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id),
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Enable RLS
ALTER TABLE public.support_ticket_messages ENABLE ROW LEVEL SECURITY;

-- 3. Policies
DROP POLICY IF EXISTS "Users can view messages for their own tickets" ON public.support_ticket_messages;
CREATE POLICY "Users can view messages for their own tickets"
    ON public.support_ticket_messages FOR SELECT
    USING (
        ticket_id IN (
            SELECT id FROM public.support_tickets 
            WHERE project_id IN (SELECT id FROM public.projects WHERE client_id = auth.uid())
        ) OR 
        public.is_admin()
    );

DROP POLICY IF EXISTS "Users can send messages to their own tickets" ON public.support_ticket_messages;
CREATE POLICY "Users can send messages to their own tickets"
    ON public.support_ticket_messages FOR INSERT
    WITH CHECK (
        ticket_id IN (
            SELECT id FROM public.support_tickets 
            WHERE project_id IN (SELECT id FROM public.projects WHERE client_id = auth.uid())
        ) OR 
        public.is_admin()
    );

-- 4. Activity Trigger for replies
CREATE OR REPLACE FUNCTION public.log_ticket_reply_activity()
RETURNS TRIGGER AS $$
DECLARE
    p_id UUID;
    t_title TEXT;
    action_ar TEXT;
    action_en TEXT;
    is_team_member BOOLEAN;
BEGIN
    -- Get ticket context
    SELECT project_id, title INTO p_id, t_title FROM public.support_tickets WHERE id = NEW.ticket_id;
    
    -- Check if sender is team member
    SELECT (team_role IS NOT NULL) INTO is_team_member FROM public.profiles WHERE id = NEW.sender_id;

    IF is_team_member THEN
        action_ar := '💬 رد جديد على تذكرتك: ' || t_title;
        action_en := '💬 New reply on your ticket: ' || t_title;
    ELSE
        action_ar := '💬 رد جديد من العميل على التذكرة: ' || t_title;
        action_en := '💬 New client reply on ticket: ' || t_title;
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
        p_id,
        NEW.sender_id,
        action_ar,
        action_en,
        'support_ticket_message',
        NEW.id
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_ticket_reply_activity ON public.support_ticket_messages;
CREATE TRIGGER tr_ticket_reply_activity
    AFTER INSERT ON public.support_ticket_messages
    FOR EACH ROW EXECUTE FUNCTION public.log_ticket_reply_activity();
