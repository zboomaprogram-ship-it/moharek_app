-- Enable Real-time for core tables
ALTER PUBLICATION supabase_realtime ADD TABLE tasks;
ALTER PUBLICATION supabase_realtime ADD TABLE results;
ALTER PUBLICATION supabase_realtime ADD TABLE approvals;
ALTER PUBLICATION supabase_realtime ADD TABLE reports;
ALTER PUBLICATION supabase_realtime ADD TABLE files;
ALTER PUBLICATION supabase_realtime ADD TABLE contracts;
ALTER PUBLICATION supabase_realtime ADD TABLE journey_stages;

-- Add new columns for flexibility and details

-- Tasks: Subtasks and Attachments
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS subtasks jsonb DEFAULT '[]'::jsonb;
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS attachment_urls text[] DEFAULT '{}';

-- Results: Detailed Notes and Trend Tracking
ALTER TABLE results ADD COLUMN IF NOT EXISTS notes text;
ALTER TABLE results ADD COLUMN IF NOT EXISTS previous_value numeric;
ALTER TABLE results ADD COLUMN IF NOT EXISTS trend_direction text CHECK (trend_direction IN ('up', 'down', 'neutral'));

-- Approvals: Direct File Attachments
ALTER TABLE approvals ADD COLUMN IF NOT EXISTS attachment_url text;

-- Files: Descriptions
ALTER TABLE files ADD COLUMN IF NOT EXISTS description text;
