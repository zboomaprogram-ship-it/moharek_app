-- SQL Migration: Add period column to reports table
-- Run this in your Supabase SQL Editor (https://supabase.com/dashboard/project/typbaddqqhpeppzpbbhj/sql/new)

ALTER TABLE public.reports ADD COLUMN IF NOT EXISTS period TEXT;

-- Force PostgREST to reload schema
NOTIFY pgrst, 'reload schema';
