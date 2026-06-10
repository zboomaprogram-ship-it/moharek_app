-- Tighten RLS on call_signals to prevent unauthorized users from viewing, inserting, or modifying signals
DROP POLICY IF EXISTS "Call signals access" ON public.call_signals;
DROP POLICY IF EXISTS "Call signals select" ON public.call_signals;
DROP POLICY IF EXISTS "Call signals insert" ON public.call_signals;
DROP POLICY IF EXISTS "Call signals update" ON public.call_signals;
DROP POLICY IF EXISTS "Call signals delete" ON public.call_signals;
DROP POLICY IF EXISTS "Authenticated users can view call signals" ON public.call_signals;
DROP POLICY IF EXISTS "Authenticated users can insert call signals" ON public.call_signals;
DROP POLICY IF EXISTS "Authenticated users can update call signals" ON public.call_signals;

CREATE POLICY "Call signals access" ON public.call_signals
  FOR ALL
  TO authenticated
  USING (
    caller_id = auth.uid()
    OR project_id IN (
      SELECT id FROM public.projects 
      WHERE client_id = auth.uid() 
         OR account_manager_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() 
        AND role = 'admin'
    )
  )
  WITH CHECK (
    caller_id = auth.uid()
    OR project_id IN (
      SELECT id FROM public.projects 
      WHERE client_id = auth.uid() 
         OR account_manager_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() 
        AND role = 'admin'
    )
  );
