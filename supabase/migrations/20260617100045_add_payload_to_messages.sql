-- Add payload JSONB column to messages
ALTER TABLE public.messages
ADD COLUMN IF NOT EXISTS payload JSONB;
