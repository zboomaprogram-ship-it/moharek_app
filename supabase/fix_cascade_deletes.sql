-- ==========================================
-- FIX CASCADE DELETES FOR MOHAREK & RABHAN
-- Run this in your Supabase SQL Editor to enable 
-- complete cascading deletes for projects and clients.
-- ==========================================

-- 1. Fix projects referencing profiles
ALTER TABLE public.projects
DROP CONSTRAINT IF EXISTS projects_client_id_fkey,
ADD CONSTRAINT projects_client_id_fkey 
  FOREIGN KEY (client_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

-- 2. Fix journey_stages referencing projects
ALTER TABLE public.journey_stages
DROP CONSTRAINT IF EXISTS journey_stages_project_id_fkey,
ADD CONSTRAINT journey_stages_project_id_fkey 
  FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

-- 3. Fix tasks referencing projects
ALTER TABLE public.tasks
DROP CONSTRAINT IF EXISTS tasks_project_id_fkey,
ADD CONSTRAINT tasks_project_id_fkey 
  FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

-- 4. Fix results referencing projects
ALTER TABLE public.results
DROP CONSTRAINT IF EXISTS results_project_id_fkey,
ADD CONSTRAINT results_project_id_fkey 
  FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

-- 5. Fix reports referencing projects
ALTER TABLE public.reports
DROP CONSTRAINT IF EXISTS reports_project_id_fkey,
ADD CONSTRAINT reports_project_id_fkey 
  FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

-- 6. Fix approvals referencing projects
ALTER TABLE public.approvals
DROP CONSTRAINT IF EXISTS approvals_project_id_fkey,
ADD CONSTRAINT approvals_project_id_fkey 
  FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

-- 7. Fix chat_channels referencing projects
ALTER TABLE public.chat_channels
DROP CONSTRAINT IF EXISTS chat_channels_project_id_fkey,
ADD CONSTRAINT chat_channels_project_id_fkey 
  FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

-- 8. Fix meetings referencing projects
ALTER TABLE public.meetings
DROP CONSTRAINT IF EXISTS meetings_project_id_fkey,
ADD CONSTRAINT meetings_project_id_fkey 
  FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

-- 9. Fix contracts referencing projects
ALTER TABLE public.contracts
DROP CONSTRAINT IF EXISTS contracts_project_id_fkey,
ADD CONSTRAINT contracts_project_id_fkey 
  FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

-- 10. Fix invoices referencing projects
ALTER TABLE public.invoices
DROP CONSTRAINT IF EXISTS invoices_project_id_fkey,
ADD CONSTRAINT invoices_project_id_fkey 
  FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

-- 11. Fix activity_feed referencing projects
ALTER TABLE public.activity_feed
DROP CONSTRAINT IF EXISTS activity_feed_project_id_fkey,
ADD CONSTRAINT activity_feed_project_id_fkey 
  FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;

-- 12. Fix files referencing projects
ALTER TABLE public.files
DROP CONSTRAINT IF EXISTS files_project_id_fkey,
ADD CONSTRAINT files_project_id_fkey 
  FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;
