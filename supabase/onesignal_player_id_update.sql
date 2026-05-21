-- Add onesignal_player_id to profiles for targeted push notifications
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS onesignal_player_id TEXT;

-- Create an index to quickly look up users by their OneSignal Player ID
CREATE INDEX IF NOT EXISTS idx_profiles_onesignal_player_id ON profiles(onesignal_player_id);
