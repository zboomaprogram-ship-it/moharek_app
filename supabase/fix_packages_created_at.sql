-- Add created_at column to packages table if it doesn't exist
ALTER TABLE public.packages ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT now();
