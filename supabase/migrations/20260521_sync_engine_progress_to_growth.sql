-- ============================================================
-- FIX: Sync engine_progress ↔ growth_engines
--
-- Root cause: The web dashboard writes to engine_progress
-- (columns: engine, progress_percent) but the mobile app
-- reads from growth_engines (columns: engine_type, health_score)
-- via get_engine_health() RPC. The two tables were never linked.
--
-- Solution:
--   1. Create a trigger on engine_progress that upserts into
--      growth_engines whenever a slider is moved in the web.
--   2. Fix column name mismatch: engine_progress uses 'engine'
--      but the table was created with 'engine_type'. Ensure
--      'engine' column exists (add it if missing).
--   3. Also fix 'progress_percent' column (created table has
--      'progress' column instead).
-- ============================================================

-- ── Step 1: Ensure engine_progress has the columns the app writes ──
-- The admin code writes: engine, progress_percent, project_id, updated_at
-- But the table was created with: engine_type, progress
ALTER TABLE public.engine_progress
  ADD COLUMN IF NOT EXISTS engine          text,
  ADD COLUMN IF NOT EXISTS progress_percent int;

-- Backfill from existing columns if they have data
UPDATE public.engine_progress
  SET engine = engine_type
  WHERE engine IS NULL AND engine_type IS NOT NULL;

UPDATE public.engine_progress
  SET progress_percent = progress::int
  WHERE progress_percent IS NULL AND progress IS NOT NULL;

-- ── Step 2: Trigger that syncs engine_progress → growth_engines ──

CREATE OR REPLACE FUNCTION public.sync_engine_progress_to_growth()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_engine_type  public.engine_type;
  v_health_score int;
  v_engine_name  text;
BEGIN
  -- Use whichever column has the engine name
  v_engine_name := COALESCE(NEW.engine, NEW.engine_type::text);

  -- Skip if we can't determine the engine
  IF v_engine_name IS NULL THEN
    RETURN NEW;
  END IF;

  -- Cast text → engine_type enum (silently skip if not valid)
  BEGIN
    v_engine_type := v_engine_name::public.engine_type;
  EXCEPTION WHEN invalid_text_representation THEN
    RETURN NEW;
  END;

  -- Use whichever column has the numeric value
  v_health_score := COALESCE(
    NEW.progress_percent,
    NEW.progress::int,
    0
  );

  -- Upsert into growth_engines
  INSERT INTO public.growth_engines (
    project_id,
    engine_type,
    health_score,
    status,
    updated_at
  )
  VALUES (
    NEW.project_id,
    v_engine_type,
    v_health_score,
    CASE
      WHEN v_health_score >= 80 THEN 'healthy'
      WHEN v_health_score >= 50 THEN 'in_progress'
      WHEN v_health_score > 0   THEN 'needs_attention'
      ELSE 'pending'
    END,
    now()
  )
  ON CONFLICT (project_id, engine_type)
  DO UPDATE SET
    health_score = EXCLUDED.health_score,
    status       = EXCLUDED.status,
    updated_at   = now();

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS tr_sync_engine_to_growth ON public.engine_progress;
CREATE TRIGGER tr_sync_engine_to_growth
  AFTER INSERT OR UPDATE ON public.engine_progress
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_engine_progress_to_growth();

-- ── Step 3: Backfill existing engine_progress rows → growth_engines ──
-- Run once to sync any data that was written before this trigger existed.
INSERT INTO public.growth_engines (project_id, engine_type, health_score, status, updated_at)
SELECT
  ep.project_id,
  COALESCE(ep.engine, ep.engine_type)::public.engine_type,
  COALESCE(ep.progress_percent, ep.progress::int, 0),
  CASE
    WHEN COALESCE(ep.progress_percent, ep.progress::int, 0) >= 80 THEN 'healthy'
    WHEN COALESCE(ep.progress_percent, ep.progress::int, 0) >= 50 THEN 'in_progress'
    WHEN COALESCE(ep.progress_percent, ep.progress::int, 0) >  0  THEN 'needs_attention'
    ELSE 'pending'
  END,
  now()
FROM public.engine_progress ep
WHERE COALESCE(ep.engine, ep.engine_type::text) IS NOT NULL
ON CONFLICT (project_id, engine_type) DO UPDATE SET
  health_score = EXCLUDED.health_score,
  status       = EXCLUDED.status,
  updated_at   = now();

-- ── Step 4: Ensure Realtime is on for growth_engines ──
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'growth_engines'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE growth_engines;
  END IF;
END$$;
