-- =========================================================================
-- RABHAN SUPABASE ULTIMATE REMEDIATION SCRIPT (REVISED)
-- Run this script in your Rabhan Supabase SQL Editor (project: pyzheqwypoaazpmpgiuq)
-- =========================================================================

-- ── 1. BILLING HISTORY CRASH FIX ──
-- Ensure invoice_number column exists, clean up any existing NULLs, and make it NOT NULL
ALTER TABLE public.invoices ADD COLUMN IF NOT EXISTS invoice_number TEXT DEFAULT '1';

UPDATE public.invoices 
SET invoice_number = '1' 
WHERE invoice_number IS NULL;

ALTER TABLE public.invoices ALTER COLUMN invoice_number SET DEFAULT '1';
ALTER TABLE public.invoices ALTER COLUMN invoice_number SET NOT NULL;


-- ── 2. TEAM MANAGEMENT SCHEMA & RLS FIX ──
-- Define is_admin helper to ensure policies compile successfully
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean 
LANGUAGE sql SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
    AND role IN ('admin', 'account_manager')
  );
$$;

-- Create companies table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.companies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Create company_members table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.company_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('owner', 'manager', 'marketing', 'finance', 'viewer')),
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(company_id, user_id)
);

-- Ensure company_id exists on public.projects
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES public.companies(id) ON DELETE SET NULL;

-- Define non-recursive helper function my_company_ids()
CREATE OR REPLACE FUNCTION my_company_ids()
RETURNS SETOF uuid
LANGUAGE sql SECURITY DEFINER
STABLE
AS $$
  SELECT company_id FROM public.company_members WHERE user_id = auth.uid();
$$;

-- Enable RLS on team tables
ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.company_members ENABLE ROW LEVEL SECURITY;

-- Fix company_members policy recursion
DROP POLICY IF EXISTS "Access company_members" ON public.company_members;
CREATE POLICY "Access company_members" ON public.company_members
FOR ALL USING (
  company_id IN (SELECT my_company_ids()) OR is_admin()
);

-- Fix companies policy recursion
DROP POLICY IF EXISTS "Access companies" ON public.companies;
CREATE POLICY "Access companies" ON public.companies
FOR ALL USING (
  id IN (SELECT my_company_ids()) OR is_admin()
);


-- ── 3. VOICE PLAYBACK STORAGE TRIGGER ──
-- Trigger to automatically fix MIME type for Web voice recordings uploaded to Supabase Storage.
-- Note: Function is created in 'public' schema to bypass 'storage' schema write permissions.
CREATE OR REPLACE FUNCTION public.fix_web_voice_mimetype()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.name LIKE '%voice_%.m4a' THEN
    NEW.metadata := jsonb_set(COALESCE(NEW.metadata, '{}'::jsonb), '{mimetype}', '"audio/webm"');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_fix_web_voice_mimetype ON storage.objects;
CREATE TRIGGER trigger_fix_web_voice_mimetype
  BEFORE INSERT OR UPDATE ON storage.objects
  FOR EACH ROW
  EXECUTE FUNCTION public.fix_web_voice_mimetype();

-- Retroactively fix MIME types of any existing recordings
UPDATE storage.objects 
SET metadata = jsonb_set(COALESCE(metadata, '{}'::jsonb), '{mimetype}', '"audio/webm"')
WHERE name LIKE '%voice_%.m4a';
