-- ==========================================
-- ULTIMATE FIX V2: JOURNEY + CHAT + REALTIME
-- ==========================================

-- 1. Fix Journey Stages Table
ALTER TABLE journey_stages ADD COLUMN IF NOT EXISTS order_index integer DEFAULT 0;

-- 2. Fix Messages Table
ALTER TABLE messages ADD COLUMN IF NOT EXISTS is_read boolean DEFAULT false;

-- 3. Fix Chat Channels (Ensure all projects have a channel)
-- Using a safer way to avoid "ON CONFLICT" errors
INSERT INTO chat_channels (project_id, name)
SELECT id, 'Project Chat' 
FROM projects p
WHERE NOT EXISTS (
    SELECT 1 FROM chat_channels c WHERE c.project_id = p.id
);

-- 4. ENABLE REALTIME for Chat
-- We use the default 'public' publication which often exists, 
-- or we add the table specifically to 'supabase_realtime'
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
        CREATE PUBLICATION supabase_realtime;
    END IF;
END $$;

ALTER PUBLICATION supabase_realtime ADD TABLE messages;

-- 5. Fix RLS Policies (Simplified for absolute access)
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_channels ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view messages in their channels" ON messages;
DROP POLICY IF EXISTS "Users can insert messages into their channels" ON messages;
DROP POLICY IF EXISTS "Users can view their chat channels" ON chat_channels;
DROP POLICY IF EXISTS "Admin full access on messages" ON messages;
DROP POLICY IF EXISTS "Admin full access on channels" ON chat_channels;

-- Admin Access
CREATE POLICY "Admin full access on messages" ON messages FOR ALL USING (
    (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
);
CREATE POLICY "Admin full access on channels" ON chat_channels FOR ALL USING (
    (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
);

-- Client Access
CREATE POLICY "Users can view messages in their channels"
ON messages FOR SELECT
USING (
    channel_id IN (
        SELECT id FROM chat_channels WHERE project_id IN (
            SELECT id FROM projects WHERE client_id = auth.uid()
        )
    )
);

CREATE POLICY "Users can insert messages into their channels"
ON messages FOR INSERT
WITH CHECK (
    auth.uid() = sender_id AND
    channel_id IN (
        SELECT id FROM chat_channels WHERE project_id IN (
            SELECT id FROM projects WHERE client_id = auth.uid()
        )
    )
);

CREATE POLICY "Users can view their chat channels"
ON chat_channels FOR SELECT
USING (
    project_id IN (SELECT id FROM projects WHERE client_id = auth.uid())
);

-- 6. Final Data Integrity
ALTER TABLE projects ADD COLUMN IF NOT EXISTS current_stage text DEFAULT 'audit';
