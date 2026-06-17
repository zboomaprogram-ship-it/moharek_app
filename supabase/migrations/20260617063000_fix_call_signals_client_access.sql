-- Fix call_signals RLS policy to allow the project's client to access incoming calls
DROP POLICY IF EXISTS "Call signals access" ON call_signals;

CREATE POLICY "Call signals access" ON call_signals
  FOR ALL
  USING (
    sender_id = auth.uid() OR 
    receiver_id = auth.uid() OR 
    caller_id = auth.uid() OR 
    project_id IN (SELECT id FROM public.projects WHERE client_id = auth.uid()) OR 
    is_admin()
  );
