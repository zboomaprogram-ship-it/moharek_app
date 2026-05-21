ALTER TABLE public.messages 
ADD COLUMN IF NOT EXISTS waveform_data jsonb;

-- Notify PostgREST to reload schema
NOTIFY pgrst, 'reload schema';
