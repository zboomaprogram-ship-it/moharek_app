-- ============================================================
-- MOHAREK GROWTH HUB — PHASE 3+ ADVANCED MIGRATION
-- Phase D: Google Integrations (GSC, GA, GBP)
-- ============================================================

-- 1. Create OAuth Tokens Table
CREATE TABLE IF NOT EXISTS oauth_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE,
  provider text NOT NULL CHECK (provider IN ('google')),
  access_token text NOT NULL,
  refresh_token text,
  expires_at timestamptz NOT NULL,
  scopes text[],
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(company_id, provider)
);

-- Enable RLS
ALTER TABLE oauth_tokens ENABLE ROW LEVEL SECURITY;

-- OAuth Tokens Policy
CREATE POLICY "Access oauth_tokens" ON oauth_tokens FOR ALL USING (
  company_id IN (SELECT company_id FROM company_members WHERE user_id = auth.uid()) OR is_admin()
);

-- 2. Add Google Search Console & Analytics IDs to projects
ALTER TABLE projects ADD COLUMN IF NOT EXISTS gsc_site_url text;
ALTER TABLE projects ADD COLUMN IF NOT EXISTS ga4_property_id text;
ALTER TABLE projects ADD COLUMN IF NOT EXISTS gbp_location_id text;
