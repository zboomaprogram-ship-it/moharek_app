-- Harden Milestones RLS for Admins/Team
DROP POLICY IF EXISTS "Team members can manage milestones" ON public.milestones;
CREATE POLICY "Team members can manage milestones" 
ON public.milestones FOR ALL 
USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND team_role IS NOT NULL)
);

-- Ensure select policy covers both client and team
DROP POLICY IF EXISTS "Clients can view milestones for their projects" ON public.milestones;
CREATE POLICY "View milestones" 
ON public.milestones FOR SELECT 
USING (
    project_id IN (SELECT id FROM public.projects WHERE client_id = auth.uid()) OR
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND team_role IS NOT NULL)
);
