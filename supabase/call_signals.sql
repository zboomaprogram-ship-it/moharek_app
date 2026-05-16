-- Call Signals table for real-time call signaling
-- Run this in your Supabase SQL editor

CREATE TABLE IF NOT EXISTS call_signals (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  project_id uuid REFERENCES projects(id) ON DELETE CASCADE,
  caller_id uuid REFERENCES auth.users(id),
  caller_name text NOT NULL DEFAULT '',
  call_type text NOT NULL DEFAULT 'voice', -- 'voice' or 'video'
  room_name text NOT NULL,
  status text NOT NULL DEFAULT 'ringing', -- 'ringing', 'accepted', 'declined', 'timeout', 'ended'
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE call_signals ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to see and manage call signals
CREATE POLICY "Authenticated users can view call signals"
  ON call_signals FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can insert call signals"
  ON call_signals FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Authenticated users can update call signals"
  ON call_signals FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Enable realtime on this table
ALTER PUBLICATION supabase_realtime ADD TABLE call_signals;

-- Auto-cleanup: delete signals older than 2 minutes (they're ephemeral)
-- You can run this as a cron job or pg_cron
-- SELECT cron.schedule('cleanup-call-signals', '* * * * *', $$
--   DELETE FROM call_signals WHERE created_at < now() - interval '2 minutes';
-- $$);
