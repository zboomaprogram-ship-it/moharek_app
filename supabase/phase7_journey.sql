-- Phase 7: Journey Screen Reborn

-- 1. Add stage_description to journey_stages
ALTER TABLE public.journey_stages 
ADD COLUMN IF NOT EXISTS stage_description TEXT;

-- 2. Add stage_name to tasks to link them to journey stages
ALTER TABLE public.tasks 
ADD COLUMN IF NOT EXISTS stage_name TEXT;

-- 3. Data Migration: Map existing tasks to default stages based on category
-- Categories: 'seo','ads','content','design','tech','ai_visibility'
-- Stages: 'audit', 'strategy', 'setup', 'execution', 'optimization', 'results'

UPDATE public.tasks 
SET stage_name = 'audit' 
WHERE stage_name IS NULL AND category IN ('seo', 'ai_visibility');

UPDATE public.tasks 
SET stage_name = 'setup' 
WHERE stage_name IS NULL AND category IN ('tech', 'design');

UPDATE public.tasks 
SET stage_name = 'execution' 
WHERE stage_name IS NULL AND category IN ('ads', 'content');

-- Default remaining to audit
UPDATE public.tasks 
SET stage_name = 'audit' 
WHERE stage_name IS NULL;
