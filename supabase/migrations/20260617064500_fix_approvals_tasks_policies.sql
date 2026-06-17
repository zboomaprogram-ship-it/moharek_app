-- Fix approvals constraint to allow 'rejected'
ALTER TABLE public.approvals DROP CONSTRAINT IF EXISTS approvals_status_check;
ALTER TABLE public.approvals ADD CONSTRAINT approvals_status_check CHECK (status IN ('pending', 'approved', 'rejected', 'changes_requested'));

-- Add insert policy for tasks for clients
DROP POLICY IF EXISTS "Clients insert tasks" ON public.tasks;
CREATE POLICY "Clients insert tasks" ON public.tasks
  FOR INSERT
  WITH CHECK (project_id IN (SELECT public.my_project_ids()));
