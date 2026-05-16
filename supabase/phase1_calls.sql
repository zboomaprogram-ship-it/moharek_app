-- Add new columns to meetings table for LiveKit integration
ALTER TABLE meetings ADD COLUMN IF NOT EXISTS livekit_room_name text;
ALTER TABLE meetings ADD COLUMN IF NOT EXISTS call_type text DEFAULT 'video'; -- 'video' or 'voice'

-- Check to see that meeting_type constraint accepts 'livekit' if needed
-- Actually, the plan didn't specify changing meeting_type, but let's make sure it doesn't break anything.
