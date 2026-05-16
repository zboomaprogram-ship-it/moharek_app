-- Phase 5: Living Dashboard
-- Add last_seen_at to profiles for "What's new" banner logic

ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS last_seen_at TIMESTAMPTZ;

-- Function to safely update last_seen_at
CREATE OR REPLACE FUNCTION update_last_seen()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NOT NULL THEN
    UPDATE profiles
    SET last_seen_at = NOW()
    WHERE id = auth.uid();
  END IF;
END;
$$;
