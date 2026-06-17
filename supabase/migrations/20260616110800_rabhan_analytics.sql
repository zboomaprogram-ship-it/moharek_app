-- ========================================================================================
-- RABHAN ANALYTICS SCHEMA
-- Defines the tables to hold live metrics, growth engines, and campaigns for the client app.
-- ========================================================================================

-- 1. Metrics Table
CREATE TABLE IF NOT EXISTS public.rabhan_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    sales NUMERIC DEFAULT 0,
    profit NUMERIC DEFAULT 0,
    ad_spend NUMERIC DEFAULT 0,
    roas NUMERIC DEFAULT 0,
    conversion_rate NUMERIC DEFAULT 0,
    orders INTEGER DEFAULT 0,
    clicks INTEGER DEFAULT 0,
    impressions INTEGER DEFAULT 0,
    add_to_cart INTEGER DEFAULT 0,
    period_start TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    period_end TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Growth Engines Table
CREATE TABLE IF NOT EXISTS public.rabhan_growth_engines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    engine_name TEXT NOT NULL, -- 'Store', 'Product', 'Ads', 'Sales Page', 'Operations', 'Analytics'
    health_score INTEGER DEFAULT 0 CHECK (health_score >= 0 AND health_score <= 100),
    status_text TEXT, -- e.g., 'On track', 'Needs attention'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(project_id, engine_name)
);

-- 3. Engine Tasks Table
CREATE TABLE IF NOT EXISTS public.rabhan_engine_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    engine_id UUID NOT NULL REFERENCES public.rabhan_growth_engines(id) ON DELETE CASCADE,
    task_name TEXT NOT NULL,
    status TEXT DEFAULT 'In Progress', -- 'To Do', 'In Progress', 'Done'
    assignee TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Ad Campaigns Table
CREATE TABLE IF NOT EXISTS public.rabhan_ad_campaigns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    platform TEXT NOT NULL, -- 'Meta', 'TikTok', 'Google'
    campaign_name TEXT NOT NULL,
    status TEXT DEFAULT 'Active', -- 'Active', 'Paused'
    spend NUMERIC DEFAULT 0,
    budget NUMERIC DEFAULT 0,
    roas NUMERIC DEFAULT 0,
    clicks INTEGER DEFAULT 0,
    conversions INTEGER DEFAULT 0,
    link_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. AI Summary Table (Or Weekly Narrative)
CREATE TABLE IF NOT EXISTS public.rabhan_weekly_summaries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    summary_text TEXT NOT NULL,
    anomaly_alert TEXT, -- e.g., 'ROAS dropped on Thursday'
    week_start TIMESTAMP WITH TIME ZONE,
    week_end TIMESTAMP WITH TIME ZONE,
    created_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add to publication for Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.rabhan_metrics;
ALTER PUBLICATION supabase_realtime ADD TABLE public.rabhan_growth_engines;
ALTER PUBLICATION supabase_realtime ADD TABLE public.rabhan_engine_tasks;
ALTER PUBLICATION supabase_realtime ADD TABLE public.rabhan_ad_campaigns;
ALTER PUBLICATION supabase_realtime ADD TABLE public.rabhan_weekly_summaries;

-- Enable Row Level Security (RLS)
ALTER TABLE public.rabhan_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rabhan_growth_engines ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rabhan_engine_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rabhan_ad_campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rabhan_weekly_summaries ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users to read and write (Simplifying for Admin Web Dashboard access)
-- Note: In a strict production environment, we would restrict writes to admins/account managers.
CREATE POLICY "Allow authenticated read" ON public.rabhan_metrics FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow authenticated insert" ON public.rabhan_metrics FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Allow authenticated update" ON public.rabhan_metrics FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Allow authenticated delete" ON public.rabhan_metrics FOR DELETE TO authenticated USING (true);

CREATE POLICY "Allow authenticated read" ON public.rabhan_growth_engines FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow authenticated insert" ON public.rabhan_growth_engines FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Allow authenticated update" ON public.rabhan_growth_engines FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Allow authenticated delete" ON public.rabhan_growth_engines FOR DELETE TO authenticated USING (true);

CREATE POLICY "Allow authenticated read" ON public.rabhan_engine_tasks FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow authenticated insert" ON public.rabhan_engine_tasks FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Allow authenticated update" ON public.rabhan_engine_tasks FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Allow authenticated delete" ON public.rabhan_engine_tasks FOR DELETE TO authenticated USING (true);

CREATE POLICY "Allow authenticated read" ON public.rabhan_ad_campaigns FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow authenticated insert" ON public.rabhan_ad_campaigns FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Allow authenticated update" ON public.rabhan_ad_campaigns FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Allow authenticated delete" ON public.rabhan_ad_campaigns FOR DELETE TO authenticated USING (true);

CREATE POLICY "Allow authenticated read" ON public.rabhan_weekly_summaries FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow authenticated insert" ON public.rabhan_weekly_summaries FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Allow authenticated update" ON public.rabhan_weekly_summaries FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Allow authenticated delete" ON public.rabhan_weekly_summaries FOR DELETE TO authenticated USING (true);
