ALTER TABLE public.messages 
ADD COLUMN IF NOT EXISTS duration_seconds INTEGER;

-- To ensure the schema cache is updated so the API immediately recognizes the new column:
NOTIFY pgrst, 'reload schema';
