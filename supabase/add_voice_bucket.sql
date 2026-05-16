-- Create the 'voice-messages' bucket for chat audio
INSERT INTO storage.buckets (id, name, public) 
VALUES ('voice-messages', 'voice-messages', true)
ON CONFLICT (id) DO NOTHING;

-- Set up RLS policies for the bucket
-- Allow anyone to read (public bucket)
CREATE POLICY "Public Access" ON storage.objects FOR SELECT USING (bucket_id = 'voice-messages');

-- Allow authenticated users to upload
CREATE POLICY "Authenticated Upload" ON storage.objects FOR INSERT WITH CHECK (
  bucket_id = 'voice-messages' AND auth.role() = 'authenticated'
);
