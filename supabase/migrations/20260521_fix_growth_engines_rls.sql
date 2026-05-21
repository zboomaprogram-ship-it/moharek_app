-- ============================================================
-- FIX: Allow admin/account_manager to upsert into growth_engines
-- Root cause: "team_manage_engines" policy only applies to
-- users with specific roles, but the Flutter admin client
-- authenticated as an admin couldn't INSERT because of a missing
-- INSERT policy (or the role check was failing).
--
-- Also ensure Realtime is enabled so the admin web stream
-- (projectEnginesProvider) sees changes instantly.
-- ============================================================

-- Drop old policies
DROP POLICY IF EXISTS "client_read_engines"   ON public.growth_engines;
DROP POLICY IF EXISTS "team_manage_engines"   ON public.growth_engines;

-- Clients can only read their own project engines
CREATE POLICY "client_read_engines" ON public.growth_engines
  FOR SELECT
  USING (project_id IN (SELECT my_project_ids()));

-- Admins and all team roles can do everything
CREATE POLICY "team_manage_engines" ON public.growth_engines
  FOR ALL
  USING (
    (SELECT role FROM public.profiles WHERE id = auth.uid())
    IN ('admin', 'account_manager', 'ads_team', 'seo_team',
        'content_team', 'design_team', 'tech_team')
  )
  WITH CHECK (
    (SELECT role FROM public.profiles WHERE id = auth.uid())
    IN ('admin', 'account_manager', 'ads_team', 'seo_team',
        'content_team', 'design_team', 'tech_team')
  );

-- Enable Realtime so the web stream picks up changes without page reload
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'growth_engines'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.growth_engines;
  END IF;
END $$;

-- Ensure RLS is on
ALTER TABLE public.growth_engines ENABLE ROW LEVEL SECURITY;
