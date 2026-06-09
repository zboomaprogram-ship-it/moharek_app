-- =========================================================================
-- DEBUG HELPER: GET VOICE MESSAGES FROM DATABASE
-- Run this in your Rabhan Supabase SQL Editor
-- =========================================================================

CREATE OR REPLACE FUNCTION public.get_voice_messages()
RETURNS json AS $$
DECLARE
  res json;
BEGIN
  SELECT json_agg(t) INTO res FROM (
    SELECT id, channel_id, file_url, message_type, duration_seconds, created_at 
    FROM public.messages 
    WHERE message_type = 'voice'
    ORDER BY created_at DESC 
    LIMIT 20
  ) t;
  RETURN res;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
