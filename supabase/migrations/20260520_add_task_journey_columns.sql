ALTER TABLE public.tasks 
ADD COLUMN IF NOT EXISTS stage_type text,
ADD COLUMN IF NOT EXISTS is_client_pending boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS journey_order integer DEFAULT 0;

NOTIFY pgrst, 'reload schema';
