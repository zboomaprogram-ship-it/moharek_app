-- Phase 3: Voice Messages
-- Create a private bucket for voice messages
INSERT INTO storage.buckets (id, name, public) 
VALUES ('voice-messages', 'voice-messages', false)
ON CONFLICT (id) DO NOTHING;

-- RLS: only participants of the same project can read
CREATE POLICY "Project members can read voice messages"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'voice-messages' AND
  (storage.foldername(name))[1] IN (
    SELECT project_id::text FROM chat_channels
    WHERE id::text = (storage.foldername(name))[2]
  )
);

-- RLS: authenticated users can upload
CREATE POLICY "Authenticated users can upload voice messages"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'voice-messages' AND auth.role() = 'authenticated');

-- Add columns to messages table
ALTER TABLE messages ADD COLUMN IF NOT EXISTS duration_seconds int;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS waveform_data jsonb;


-- Phase 4: Onboarding
-- Add columns to profiles table
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS onboarding_completed boolean DEFAULT false;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS client_goal text;
