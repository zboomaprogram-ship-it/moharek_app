-- Phase 6: Milestones & Celebrations

-- 1. Create the milestones table
CREATE TABLE IF NOT EXISTS public.milestones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    milestone_type TEXT NOT NULL, -- 'page1_keyword', 'traffic_doubled', 'leads_reached', 'invoice_paid', 'stage_completed'
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    achieved_at TIMESTAMPTZ DEFAULT NOW(),
    seen_by_client BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Enable RLS
ALTER TABLE public.milestones ENABLE ROW LEVEL SECURITY;

-- 3. Policies
CREATE POLICY "Clients can view milestones for their projects" 
ON public.milestones FOR SELECT 
USING (
    project_id IN (
        SELECT id FROM public.projects WHERE client_id = auth.uid()
    )
);

CREATE POLICY "Clients can update seen_by_client" 
ON public.milestones FOR UPDATE 
USING (
    project_id IN (
        SELECT id FROM public.projects WHERE client_id = auth.uid()
    )
)
WITH CHECK (
    seen_by_client = TRUE
);

-- 4. Function to mark milestones as seen
CREATE OR REPLACE FUNCTION mark_milestones_as_seen(p_milestone_ids UUID[])
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.milestones
    SET seen_by_client = TRUE
    WHERE id = ANY(p_milestone_ids);
END;
$$;
