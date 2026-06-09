-- =========================================================================
-- RABHAN SUPABASE FUNCTIONALITY FIX
-- Run this script in your Rabhan Supabase SQL Editor (project: pyzheqwypoaazpmpgiuq)
-- =========================================================================

-- ── 1. SCHEMA FIX: Add missing invoice_number column to public.invoices ──
-- This prevents the "type 'Null' is not a subtype of type 'String'" crash in settings/billing.
ALTER TABLE public.invoices ADD COLUMN IF NOT EXISTS invoice_number TEXT DEFAULT '1';

-- ── 2. APPROVALS UPDATE POLICY: Allow clients to approve/request modifications ──
-- The previous comprehensive_fix.sql dropped this policy, blocking client actions.
DROP POLICY IF EXISTS "approvals_client_update" ON public.approvals;
DROP POLICY IF EXISTS "Clients update approvals" ON public.approvals;
CREATE POLICY "approvals_client_update" ON public.approvals
  FOR UPDATE
  USING (project_id IN (SELECT my_project_ids()));

-- ── 3. CONTRACTS UPDATE POLICY: Allow clients to sign/reject contracts ──
DROP POLICY IF EXISTS "contracts_client_update" ON public.contracts;
DROP POLICY IF EXISTS "Clients update contracts" ON public.contracts;
CREATE POLICY "contracts_client_update" ON public.contracts
  FOR UPDATE
  USING (project_id IN (SELECT my_project_ids()));

-- ── 4. MILESTONES UPDATE POLICY: Allow clients to mark milestones as seen ──
DROP POLICY IF EXISTS "milestones_client_update" ON public.milestones;
CREATE POLICY "milestones_client_update" ON public.milestones
  FOR UPDATE
  USING (project_id IN (SELECT my_project_ids()));

-- ── 5. STORAGE BUCKET INITIALIZATION AND POLICIES ──
-- Ensure both 'files' and 'voice-messages' buckets exist and are public.
INSERT INTO storage.buckets (id, name, public)
VALUES ('files', 'files', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('voice-messages', 'voice-messages', true)
ON CONFLICT (id) DO NOTHING;

-- Grant public read access to both buckets
DROP POLICY IF EXISTS "Public Read Files" ON storage.objects;
CREATE POLICY "Public Read Files" ON storage.objects
  FOR SELECT TO public
  USING (bucket_id IN ('files', 'voice-messages'));

-- Grant authenticated upload access to both buckets
DROP POLICY IF EXISTS "Authenticated Upload Files" ON storage.objects;
CREATE POLICY "Authenticated Upload Files" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id IN ('files', 'voice-messages'));
