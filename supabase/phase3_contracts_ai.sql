-- ============================================================
-- MOHAREK GROWTH HUB — PHASE 3+ ADVANCED MIGRATION
-- Phase E: Contracts E-Signing & Meeting AI Transcripts
-- ============================================================

-- 1. Update Contracts table for signatures
ALTER TABLE contracts ADD COLUMN IF NOT EXISTS signature_url text;
ALTER TABLE contracts ADD COLUMN IF NOT EXISTS signed_at timestamptz;

-- 2. Update Meetings table for AI transcripts
ALTER TABLE meetings ADD COLUMN IF NOT EXISTS transcript text;
ALTER TABLE meetings ADD COLUMN IF NOT EXISTS recording_url text;
ALTER TABLE meetings ADD COLUMN IF NOT EXISTS processed_at timestamptz;
