/// =============================================================
/// MOHAREK APP — CREDENTIALS & CONFIGURATION CHECKLIST
/// =============================================================
/// Fill in each value below. Status:
///   ✅ = Done
///   ❌ = TODO — app won't work without this
/// =============================================================

class AppConfig {
  // -----------------------------------------------------------
  // 1. SUPABASE ✅
  // -----------------------------------------------------------
  static const String supabaseUrl = 'https://typbaddqqhpeppzpbbhj.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5cGJhZGRxcWhwZXBwenBiYmhqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgxNTE4MTEsImV4cCI6MjA5MzcyNzgxMX0.nxk43GEdtyEUYvmT6K6uj4MPJVXRFb80uEA_mE9NGJI';

  // -----------------------------------------------------------
  // 2. LIVEKIT — In-App Video & Voice Calls ✅
  // -----------------------------------------------------------
  static const bool livekitEnabled = true;

  // -----------------------------------------------------------
  // 3. ONESIGNAL — Push Notifications ✅
  // -----------------------------------------------------------
  static const String oneSignalAppId = '234d893b-ca81-493d-9afd-6a287a69b27e';
  static const bool notificationsEnabled = true;

  // -----------------------------------------------------------
  // 4. SUPABASE STORAGE BUCKETS ✅
  // -----------------------------------------------------------
  static const String bucketReports = 'reports';
  static const String bucketFiles = 'files';
  static const String bucketAvatars = 'avatars';
  static const String bucketApprovals = 'approvals';
  static const String bucketContracts = 'contracts';

  // -----------------------------------------------------------
  // 5. SUPABASE RLS POLICIES ❌ TODO
  // -----------------------------------------------------------
  // Run the following in your Supabase SQL Editor to complete
  // Row-Level Security for all tables:
  //
  // -- Projects: clients read their own project
  // CREATE POLICY "Client reads own project" ON projects
  //   FOR SELECT USING (client_id = auth.uid());
  //
  // -- Tasks: project members can read tasks
  // CREATE POLICY "Members read project tasks" ON tasks
  //   FOR SELECT USING (
  //     project_id IN (SELECT id FROM projects WHERE client_id = auth.uid())
  //   );
  //
  // -- Messages: channel members can read
  // CREATE POLICY "Members read messages" ON messages
  //   FOR ALL USING (
  //     channel_id IN (
  //       SELECT id FROM chat_channels WHERE project_id IN (
  //         SELECT id FROM projects WHERE client_id = auth.uid()
  //       )
  //     )
  //   );
  //
  // -- Admins bypass all RLS (requires checking role)
  // CREATE POLICY "Admins access all" ON projects
  //   FOR ALL USING (
  //     (SELECT role FROM profiles WHERE id = auth.uid()) = 'admin'
  //   );
  //
  // (Repeat similar policies for results, reports, approvals, files, contracts, invoices)
  // Status: ❌ INCOMPLETE — only basic profile policy exists

  // -----------------------------------------------------------
  // 6. SUPABASE EDGE FUNCTION — send-notification ❌ TODO
  // -----------------------------------------------------------
  // Create at: supabase/functions/send-notification/index.ts
  // This function calls FCM HTTP v1 API to send push notifications.
  // Triggered by database webhooks on:
  //   - New report (status = 'ready') → notify client
  //   - New approval created → notify client
  //   - Task → 'waiting_client' → notify client
  //   - New message → notify recipient
  //   - Contract uploaded → notify client
  // Status: ❌ NOT CREATED

  // -----------------------------------------------------------
  // COMPLETED ITEMS
  // -----------------------------------------------------------
  // ✅ Flutter project structure
  // ✅ Dark theme (#080B12 / #111827 / #2EE59D / #3B82F6)
  // ✅ GoRouter dual-shell routing (client + admin)
  // ✅ Riverpod state management
  // ✅ supabase_schema.sql — all 13 tables
  // ✅ All data providers (profile, project, tasks, results, reports, invoices, approvals)
  // ✅ All data models
  // ✅ Real-time chat via Supabase Realtime
  // ✅ In-App LiveKit video/voice call integration
  // ✅ NotificationService infrastructure (Firebase configured)
  // ✅ Dashboard screen
  // ✅ Approvals screen
  // ✅ Reports screen
  // ✅ Auth + splash screen
  // ✅ Admin dashboard skeleton
}
