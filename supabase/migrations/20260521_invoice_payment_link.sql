-- ============================================================
-- Add payment_link and description columns to invoices table
-- Safe: uses IF NOT EXISTS — idempotent
-- ============================================================

ALTER TABLE public.invoices
  ADD COLUMN IF NOT EXISTS payment_link TEXT,
  ADD COLUMN IF NOT EXISTS description  TEXT;
