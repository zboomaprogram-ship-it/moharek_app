-- ─────────────────────────────────────────────────────────────────────────────
-- FIX: Remove duplicate message notification trigger
-- ─────────────────────────────────────────────────────────────────────────────
-- Two triggers existed on public.messages that both called on_message_inserted():
--   1. trigger_message_inserted       (from 20260521_automated_notification_triggers.sql)
--   2. trigger_on_message_inserted    (from add_client_brief_and_fix_notifications.sql)
--
-- This caused every chat message to generate TWO push notifications to the recipient,
-- and also incorrectly sent a notification back to the SENDER (via the double-fire).
--
-- We keep ONLY trigger_on_message_inserted because its function body is the more
-- complete version (handles image/voice/file message types, skips system messages,
-- and builds richer bilingual notification text).
-- ─────────────────────────────────────────────────────────────────────────────

-- Drop the duplicate/older trigger:
DROP TRIGGER IF EXISTS trigger_message_inserted ON public.messages;

-- The surviving trigger is trigger_on_message_inserted — no changes needed there.
-- Verify by running:
--   SELECT tgname FROM pg_trigger WHERE tgrelid = 'public.messages'::regclass;
-- You should see exactly one row: trigger_on_message_inserted
