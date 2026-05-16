-- Run this in Supabase SQL Editor

-- 1. Remove task constraints for free-text category/priority
ALTER TABLE tasks DROP CONSTRAINT IF EXISTS tasks_category_check;
ALTER TABLE tasks DROP CONSTRAINT IF EXISTS tasks_priority_check;

-- 2. Add batch group support for invoice payments
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS batch_group text;
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS description text;
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS partial_amount numeric DEFAULT 0;
