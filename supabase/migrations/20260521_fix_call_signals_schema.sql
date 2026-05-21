-- ============================================================
-- FIX: call_signals table missing columns
-- The Rabhan master setup had a different call_signals schema
-- (WebRTC-style with channel_id/sdp/candidate) but the Dart
-- code expects a simpler presence-based schema with status,
-- caller_name, call_type, room_name, project_id.
-- This migration adds the missing columns safely.
-- ============================================================

-- Add missing columns to call_signals (safe with IF NOT EXISTS guards)
ALTER TABLE public.call_signals 
  ADD COLUMN IF NOT EXISTS project_id uuid REFERENCES public.projects(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS caller_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS caller_name text NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS call_type text NOT NULL DEFAULT 'voice',
  ADD COLUMN IF NOT EXISTS room_name text NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'ringing';

-- Index for fast lookup of ringing calls by project
CREATE INDEX IF NOT EXISTS idx_call_signals_project_status 
  ON public.call_signals(project_id, status);

-- Index for lookup by status alone (for global listener)
CREATE INDEX IF NOT EXISTS idx_call_signals_status 
  ON public.call_signals(status);

-- Ensure realtime is enabled on this table
ALTER PUBLICATION supabase_realtime ADD TABLE public.call_signals;

-- Drop old policies if they exist and recreate more permissive ones
-- (old schema used sender_id/receiver_id, new uses caller_id/project_id)
DROP POLICY IF EXISTS "Call signals access" ON public.call_signals;
CREATE POLICY "Call signals access" ON public.call_signals FOR ALL USING (
  sender_id = auth.uid() 
  OR receiver_id = auth.uid()
  OR caller_id = auth.uid()
  OR project_id IN (
    SELECT id FROM public.projects 
    WHERE client_id = auth.uid() 
       OR account_manager_id = auth.uid()
  )
  OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);
