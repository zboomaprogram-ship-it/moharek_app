-- Allow authenticated clients to insert tasks under their own project(s)
DROP POLICY IF EXISTS "tasks_client_insert" ON public.tasks;
CREATE POLICY "tasks_client_insert" ON public.tasks
  FOR INSERT
  WITH CHECK (
    project_id IN (SELECT my_project_ids())
    AND is_client_request = true
    AND (created_by = auth.uid() OR created_by IS NULL)
  );
