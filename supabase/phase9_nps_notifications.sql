-- Phase 9: Smart Notifications & NPS

-- 1. Update profiles table
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS preferred_language TEXT DEFAULT 'en' CHECK (preferred_language IN ('en', 'ar')),
ADD COLUMN IF NOT EXISTS notification_preferences JSONB DEFAULT '{"reports":true,"tasks":true,"messages":true,"milestones":true,"meetings":true}';

-- 2. Create satisfaction_surveys table
CREATE TABLE IF NOT EXISTS public.satisfaction_surveys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    score INT NOT NULL CHECK (score >= 1 AND score <= 10),
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Enable RLS for surveys
ALTER TABLE public.satisfaction_surveys ENABLE ROW LEVEL SECURITY;

-- 4. Policies for surveys
CREATE POLICY "Clients can view their own surveys" 
ON public.satisfaction_surveys FOR SELECT 
USING (client_id = auth.uid());

CREATE POLICY "Clients can insert their own surveys" 
ON public.satisfaction_surveys FOR INSERT 
WITH CHECK (client_id = auth.uid());

-- 5. Helper function to check if NPS is due
CREATE OR REPLACE FUNCTION is_nps_due(p_client_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    last_survey_at TIMESTAMPTZ;
BEGIN
    -- Get the most recent survey for this client
    SELECT created_at INTO last_survey_at
    FROM public.satisfaction_surveys
    WHERE client_id = p_client_id
    ORDER BY created_at DESC
    LIMIT 1;

    -- If no survey or last survey was > 30 days ago, it's due
    IF last_survey_at IS NULL OR last_survey_at < NOW() - INTERVAL '30 days' THEN
        RETURN TRUE;
    END IF;

    RETURN FALSE;
END;
$$;
