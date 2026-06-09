-- =========================================================================
-- RABHAN VOICE MESSAGE PLAYBACK MIME-TYPE FIX
-- Run this script in your Rabhan Supabase SQL Editor (project: pyzheqwypoaazpmpgiuq)
-- =========================================================================

-- Trigger to automatically fix MIME type for Web voice recordings uploaded to Supabase Storage.
-- Note: Function is created in 'public' schema to bypass 'storage' schema write permissions.
CREATE OR REPLACE FUNCTION public.fix_web_voice_mimetype()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.name LIKE '%voice_%.m4a' THEN
    NEW.metadata := jsonb_set(COALESCE(NEW.metadata, '{}'::jsonb), '{mimetype}', '"audio/webm"');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_fix_web_voice_mimetype ON storage.objects;
CREATE TRIGGER trigger_fix_web_voice_mimetype
  BEFORE INSERT OR UPDATE ON storage.objects
  FOR EACH ROW
  EXECUTE FUNCTION public.fix_web_voice_mimetype();

-- Retroactively fix MIME types of any existing recordings
UPDATE storage.objects 
SET metadata = jsonb_set(COALESCE(metadata, '{}'::jsonb), '{mimetype}', '"audio/webm"')
WHERE name LIKE '%voice_%.m4a';
