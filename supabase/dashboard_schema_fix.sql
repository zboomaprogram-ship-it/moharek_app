-- ==========================================
-- MOHAREK DASHBOARD STABILIZATION SCRIPT
-- ==========================================

-- 1. ENABLE SUPABASE REALTIME PUB/SUB
-- This ensures the 'stream' providers in the app work correctly.
DO $$ 
BEGIN
    -- Create publication if missing
    IF NOT EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
        CREATE PUBLICATION supabase_realtime;
    END IF;

    -- Add tables to publication individually to avoid failing the whole script
    -- if some tables are already in the publication.
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE campaigns;
    EXCEPTION WHEN OTHERS THEN NULL; END;

    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE support_tickets;
    EXCEPTION WHEN OTHERS THEN NULL; END;

    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE files;
    EXCEPTION WHEN OTHERS THEN NULL; END;

    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE meetings;
    EXCEPTION WHEN OTHERS THEN NULL; END;

    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE tasks;
    EXCEPTION WHEN OTHERS THEN NULL; END;

    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE projects;
    EXCEPTION WHEN OTHERS THEN NULL; END;

    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE engines;
    EXCEPTION WHEN OTHERS THEN NULL; END;
END $$;

-- 2. FIX CAMPAIGNS TABLE
CREATE TABLE IF NOT EXISTS campaigns (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES projects(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now()
);

DO $$ 
BEGIN
    -- If 'title' exists and 'name' doesn't, rename title to name
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='campaigns' AND column_name='title') 
       AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='campaigns' AND column_name='name') THEN
        ALTER TABLE campaigns RENAME COLUMN title TO name;
    END IF;

    -- Ensure 'name' exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='campaigns' AND column_name='name') THEN
        ALTER TABLE campaigns ADD COLUMN name text;
    END IF;

    -- Ensure 'title' is NOT required if it still exists for some reason
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='campaigns' AND column_name='title') THEN
        ALTER TABLE campaigns ALTER COLUMN title DROP NOT NULL;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='campaigns' AND column_name='channel') THEN
        ALTER TABLE campaigns ADD COLUMN channel text;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='campaigns' AND column_name='goal') THEN
        ALTER TABLE campaigns ADD COLUMN goal text;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='campaigns' AND column_name='budget') THEN
        ALTER TABLE campaigns ADD COLUMN budget numeric;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='campaigns' AND column_name='status') THEN
        ALTER TABLE campaigns ADD COLUMN status text DEFAULT 'planned';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='campaigns' AND column_name='currency') THEN
        ALTER TABLE campaigns ADD COLUMN currency text DEFAULT 'EGP';
    END IF;
END $$;

ALTER TABLE campaigns REPLICA IDENTITY FULL;

-- 3. FIX SUPPORT TICKETS SCHEMA
CREATE TABLE IF NOT EXISTS support_tickets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES projects(id) ON DELETE CASCADE,
  title text,
  status text DEFAULT 'open',
  created_at timestamptz DEFAULT now()
);

DO $$ 
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='support_tickets' AND column_name='subject') THEN
    ALTER TABLE support_tickets RENAME COLUMN subject TO title;
  END IF;
END $$;

ALTER TABLE support_tickets REPLICA IDENTITY FULL;

-- 4. FIX FILES TABLE
CREATE TABLE IF NOT EXISTS files (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES projects(id) ON DELETE CASCADE,
  name text,
  file_url text,
  created_at timestamptz DEFAULT now()
);

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='files' AND column_name='size_kb') THEN
        ALTER TABLE files ADD COLUMN size_kb int;
    END IF;
END $$;

ALTER TABLE files REPLICA IDENTITY FULL;

-- 5. FIX MEETINGS & RESULTS TABLES
ALTER TABLE meetings REPLICA IDENTITY FULL;

CREATE TABLE IF NOT EXISTS results (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES projects(id) ON DELETE CASCADE,
  result_type text DEFAULT 'seo',
  metric_name text,
  metric_label text,
  metric_value numeric,
  metric_unit text,
  recorded_at timestamptz DEFAULT now()
);

-- Ensure missing columns in 'results'
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='results' AND column_name='result_type') THEN
        ALTER TABLE results ADD COLUMN result_type text DEFAULT 'seo';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='results' AND column_name='metric_name') THEN
        ALTER TABLE results ADD COLUMN metric_name text;
    END IF;
END $$;

ALTER TABLE results REPLICA IDENTITY FULL;

CREATE TABLE IF NOT EXISTS campaign_results (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id uuid REFERENCES campaigns(id) ON DELETE CASCADE,
  metric_label text,
  metric_value numeric,
  metric_unit text,
  recorded_at timestamptz DEFAULT now()
);

ALTER TABLE campaign_results REPLICA IDENTITY FULL;

-- Ensure results & campaign_results are in the publication
DO $$
BEGIN
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE results;
    EXCEPTION WHEN OTHERS THEN NULL; END;
    
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE campaign_results;
    EXCEPTION WHEN OTHERS THEN NULL; END;
END $$;

-- 6. PERMISSIVE RLS FOR ADMIN/AM (Authenticated)
ALTER TABLE results ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaign_results ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow authenticated all results" ON results;
CREATE POLICY "Allow authenticated all results" ON results FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow authenticated all campaign_results" ON campaign_results;
CREATE POLICY "Allow authenticated all campaign_results" ON campaign_results FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- 7. STORAGE BUCKETS
INSERT INTO storage.buckets (id, name, public) VALUES ('files', 'files', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('reports', 'reports', true) ON CONFLICT (id) DO NOTHING;

-- RLS
DROP POLICY IF EXISTS "Allow authenticated uploads" ON storage.objects;
CREATE POLICY "Allow authenticated uploads" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id IN ('files', 'reports'));

DROP POLICY IF EXISTS "Allow public downloads" ON storage.objects;
CREATE POLICY "Allow public downloads" ON storage.objects FOR SELECT TO public USING (bucket_id IN ('files', 'reports'));

-- RELOAD SCHEMA
NOTIFY pgrst, 'reload schema';
-- 8. ACTIVITY FEED TABLE
CREATE TABLE IF NOT EXISTS activity_feed (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES projects(id) ON DELETE CASCADE,
  actor_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
  action text NOT NULL,
  action_ar text,
  action_en text,
  entity_type text,
  entity_id uuid,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE activity_feed REPLICA IDENTITY FULL;

DO $$
BEGIN
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE activity_feed;
    EXCEPTION WHEN OTHERS THEN NULL; END;
END $$;

-- RLS for activity_feed
ALTER TABLE activity_feed ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow authenticated all activity" ON activity_feed;
CREATE POLICY "Allow authenticated all activity" ON activity_feed FOR ALL TO authenticated USING (true) WITH CHECK (true);
