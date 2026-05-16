-- Migration: Add Arabic/English actions and is_read to activity_feed
ALTER TABLE activity_feed ADD COLUMN IF NOT EXISTS action_ar text;
ALTER TABLE activity_feed ADD COLUMN IF NOT EXISTS action_en text;
ALTER TABLE activity_feed ADD COLUMN IF NOT EXISTS is_read boolean DEFAULT false;

-- Add a policy for AMs to update is_read
DROP POLICY IF EXISTS "am_update_activity_read" ON activity_feed;
CREATE POLICY "am_update_activity_read" ON activity_feed FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM projects p 
    WHERE p.id = activity_feed.project_id 
    AND p.account_manager_id = auth.uid()
  )
) WITH CHECK (true);
