-- Voice Updates Table
CREATE TABLE IF NOT EXISTS public.voice_updates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    audio_url TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id)
);

-- Enable RLS
ALTER TABLE public.voice_updates ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Clients can view their own voice updates"
    ON public.voice_updates FOR SELECT
    USING (project_id IN (SELECT id FROM public.projects WHERE client_id = auth.uid()));

CREATE POLICY "Admins can manage all voice updates"
    ON public.voice_updates FOR ALL
    USING (auth.jwt() ->> 'role' = 'admin');

-- Add to Activity Logger
CREATE OR REPLACE FUNCTION public.log_activity()
RETURNS TRIGGER AS $$
DECLARE
    action_ar TEXT;
    action_en TEXT;
BEGIN
    IF (TG_TABLE_NAME = 'tasks') THEN
        IF (TG_OP = 'INSERT') THEN
            action_ar := '📝 تم إضافة مهمة جديدة: ' || NEW.title;
            action_en := '📝 New task added: ' || NEW.title;
        ELSIF (NEW.status = 'completed' AND OLD.status != 'completed') THEN
            action_ar := '✅ تم إنجاز المهمة: ' || NEW.title;
            action_en := '✅ Task completed: ' || NEW.title;
        ELSE
            RETURN NEW;
        END IF;
    ELSIF (TG_TABLE_NAME = 'reports') THEN
        action_ar := '📊 تقرير جديد جاهز للمراجعة';
        action_en := '📊 New report ready for review';
    ELSIF (TG_TABLE_NAME = 'approvals') THEN
        action_ar := '🔔 بانتظار موافقتك: ' || NEW.title;
        action_en := '🔔 Awaiting your approval: ' || NEW.title;
    ELSIF (TG_TABLE_NAME = 'voice_updates') THEN
        action_ar := '🎙️ تحديث صوتي جديد من مدير النمو';
        action_en := '🎙️ New voice update from your Growth Manager';
    ELSIF (TG_TABLE_NAME = 'invoices') THEN
        IF (TG_OP = 'INSERT' AND NEW.status = 'unpaid') THEN
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

-- Add trigger for voice updates
DROP TRIGGER IF EXISTS tr_voice_activity ON public.voice_updates;
CREATE TRIGGER tr_voice_activity
    AFTER INSERT ON public.voice_updates
    FOR EACH ROW EXECUTE FUNCTION public.log_activity();
