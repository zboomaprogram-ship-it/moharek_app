-- Enhance Milestones with Localization
ALTER TABLE public.milestones ADD COLUMN IF NOT EXISTS title_ar TEXT;
ALTER TABLE public.milestones ADD COLUMN IF NOT EXISTS title_en TEXT;
ALTER TABLE public.milestones ADD COLUMN IF NOT EXISTS description_ar TEXT;
ALTER TABLE public.milestones ADD COLUMN IF NOT EXISTS description_en TEXT;

-- Migration: Copy existing title/description to localized columns if empty
UPDATE public.milestones 
SET 
    title_ar = title,
    title_en = title,
    description_ar = description,
    description_en = description
WHERE title_ar IS NULL;
