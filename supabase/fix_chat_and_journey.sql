-- 1. Fix missing order_index in journey_stages
ALTER TABLE journey_stages ADD COLUMN IF NOT EXISTS order_index integer DEFAULT 0;

-- 2. Fix chat messages table and RLS
-- Ensure messages table has the correct structure
CREATE TABLE IF NOT EXISTS messages (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    channel_id uuid REFERENCES chat_channels(id) ON DELETE CASCADE,
    sender_id uuid REFERENCES profiles(id),
    content text,
    message_type text DEFAULT 'text',
    file_url text,
    created_at timestamptz DEFAULT now()
);

-- Enable RLS on messages
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Drop old policies to avoid conflicts
DROP POLICY IF EXISTS "Users can view messages in their channels" ON messages;
DROP POLICY IF EXISTS "Users can insert messages into their channels" ON messages;

-- Policy: Users can view messages in channels they belong to
CREATE POLICY "Users can view messages in their channels"
ON messages FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM chat_channels
        WHERE chat_channels.id = messages.channel_id
        AND (
            chat_channels.project_id IN (SELECT id FROM projects WHERE client_id = auth.uid())
            OR (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
        )
    )
);

-- Policy: Users can insert messages into their channels
CREATE POLICY "Users can insert messages into their channels"
ON messages FOR INSERT
WITH CHECK (
    auth.uid() = sender_id AND
    EXISTS (
        SELECT 1 FROM chat_channels
        WHERE chat_channels.id = channel_id
        AND (
            chat_channels.project_id IN (SELECT id FROM projects WHERE client_id = auth.uid())
            OR (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
        )
    )
);

-- Ensure chat_channels has correct RLS
ALTER TABLE chat_channels ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view their chat channels" ON chat_channels;
CREATE POLICY "Users can view their chat channels"
ON chat_channels FOR SELECT
USING (
    project_id IN (SELECT id FROM projects WHERE client_id = auth.uid())
    OR (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
);
