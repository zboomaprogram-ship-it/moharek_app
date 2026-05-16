-- Function to allow users to delete their own account
-- Run this in your Supabase SQL Editor
CREATE OR REPLACE FUNCTION delete_self()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- This will delete the user from auth.users
  -- Supabase will automatically cascade delete any linked profile or data 
  -- if foreign keys are set to ON DELETE CASCADE.
  DELETE FROM auth.users WHERE id = auth.uid();
END;
$$;
