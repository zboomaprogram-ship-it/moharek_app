-- Phase 8: Growth Story Report

-- 1. Add manager_note and update reports table
ALTER TABLE public.reports 
ADD COLUMN IF NOT EXISTS manager_note TEXT;

-- 2. Ensure status column exists (was previously in some schema fixes but let's be sure)
ALTER TABLE public.reports 
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'ready' CHECK (status IN ('draft','ready','archived'));

-- 3. Update existing reports with a default note
UPDATE public.reports 
SET manager_note = 'Big wins inside this report! We are on track for our goals.'
WHERE manager_note IS NULL;
