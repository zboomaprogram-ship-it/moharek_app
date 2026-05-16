-- Hardening foreign keys and adding is_read to activity_feed
-- 1. Update projects table FK for account_manager_id
ALTER TABLE projects DROP CONSTRAINT IF EXISTS projects_account_manager_id_fkey;
ALTER TABLE projects ADD CONSTRAINT projects_account_manager_id_fkey 
    FOREIGN KEY (account_manager_id) REFERENCES profiles(id) ON DELETE SET NULL;

-- 2. Update tasks table FK for assigned_to
ALTER TABLE tasks DROP CONSTRAINT IF EXISTS tasks_assigned_to_fkey;
ALTER TABLE tasks ADD CONSTRAINT tasks_assigned_to_fkey 
    FOREIGN KEY (assigned_to) REFERENCES profiles(id) ON DELETE SET NULL;

-- 3. Update journey_stages table FK for assigned_to
ALTER TABLE journey_stages DROP CONSTRAINT IF EXISTS journey_stages_assigned_to_fkey;
ALTER TABLE journey_stages ADD CONSTRAINT journey_stages_assigned_to_fkey 
    FOREIGN KEY (assigned_to) REFERENCES profiles(id) ON DELETE SET NULL;

-- 4. Ensure activity_feed has action_ar/en and is_read
ALTER TABLE activity_feed ADD COLUMN IF NOT EXISTS action_ar text;
ALTER TABLE activity_feed ADD COLUMN IF NOT EXISTS action_en text;
ALTER TABLE activity_feed ADD COLUMN IF NOT EXISTS is_read boolean DEFAULT false;

-- 5. Add actor_name to activity_feed for easier display (optional but helpful)
ALTER TABLE activity_feed ADD COLUMN IF NOT EXISTS actor_name text;
