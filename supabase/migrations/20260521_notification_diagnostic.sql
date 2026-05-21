-- ================================================================
-- DIAGNOSTIC: Run each section separately in Supabase SQL Editor
-- to pinpoint the notification failure.
-- ================================================================

-- ── SECTION 1: Check pg_net is enabled ──────────────────────────
SELECT extname, extversion FROM pg_extension WHERE extname = 'pg_net';
-- Expected: 1 row with extname = 'pg_net'
-- If no row: run "CREATE EXTENSION IF NOT EXISTS pg_net;" first

-- ── SECTION 2: Check triggers exist ─────────────────────────────
SELECT
  trigger_name,
  event_object_table,
  action_timing,
  event_manipulation
FROM information_schema.triggers
WHERE trigger_schema = 'public'
  AND trigger_name IN (
    'trigger_on_message_inserted',
    'trigger_notification_inserted',
    'trigger_call_signal_created_v2'
  )
ORDER BY event_object_table;
-- Expected: 3 rows (messages, notifications, call_signals)

-- ── SECTION 3: Manually test the full push pipeline ─────────────
-- Replace these UUIDs with real user IDs from your profiles table
-- to simulate what happens when a message is sent.

-- Step 3a: Find a client user ID to test with:
SELECT id, full_name, role, onesignal_player_id
FROM public.profiles
WHERE role = 'client'
LIMIT 5;

-- Step 3b: Find that user's chat channel:
SELECT cc.id as channel_id, cc.project_id, p.client_id, p.account_manager_id
FROM public.chat_channels cc
JOIN public.projects p ON cc.project_id = p.id
LIMIT 5;

-- ── SECTION 4: Directly call Edge Function to test OneSignal ────
-- Run this to test the send-notification function directly.
-- Replace 'REPLACE_WITH_CLIENT_USER_ID' with a real UUID from profiles.

SELECT net.http_post(
  url := 'https://pyzheqwypoaazpmpgiuq.supabase.co/functions/v1/send-notification',
  headers := jsonb_build_object(
    'Content-Type', 'application/json',
    'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB5emhlcXd5cG9hYXpwbXBnaXVxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkxODUwMzEsImV4cCI6MjA5NDc2MTAzMX0.ZRM1H-5ZR01UwL5KXG0O9vFomc6ZOiMg8r-yNLvvMiw'
  ),
  body := jsonb_build_object(
    'table', 'notifications',
    'record', jsonb_build_object(
      'id', gen_random_uuid(),
      'type', 'chat_message',
      'title_ar', '💬 اختبار إشعار',
      'title_en', '💬 Test Notification',
      'body_ar', 'هذا اختبار لنظام الإشعارات',
      'body_en', 'This is a notification system test'
    ),
    'target_user_id', 'REPLACE_WITH_CLIENT_USER_ID'
  )
) as request_id;

-- Then check the result after ~2 seconds:
-- SELECT * FROM net.http_request_queue ORDER BY created DESC LIMIT 5;
-- SELECT * FROM net.http_response ORDER BY created DESC LIMIT 5;

-- ── SECTION 5: Check onesignal_player_id is saved ────────────────
SELECT id, full_name, role, onesignal_player_id, created_at
FROM public.profiles
WHERE onesignal_player_id IS NOT NULL
ORDER BY created_at DESC
LIMIT 10;
-- If onesignal_player_id is NULL for all users → the app hasn't saved it yet
-- → User needs to open the app → the notification service runs → saves the player ID
