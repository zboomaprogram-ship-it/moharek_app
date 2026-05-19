/// =============================================================
/// MOHAREK APP — CREDENTIALS & CONFIGURATION CHECKLIST
/// =============================================================
/// Fill in each value below. Status:
///   ✅ = Done
///   ❌ = TODO — app won't work without this
/// =============================================================

class AppConfig {
  static AppConfig? _instance;

  static void setInstance(AppConfig instance) {
    _instance = instance;
  }

  static AppConfig get instance {
    if (_instance == null) {
      throw StateError('AppConfig instance has not been initialized. Call AppConfig.setInstance() first.');
    }
    return _instance!;
  }

  // -----------------------------------------------------------
  // Static forwarding getters to preserve backward compatibility
  // -----------------------------------------------------------
  static String get supabaseUrl => instance.supabaseUrlVal;
  static String get supabaseAnonKey => instance.supabaseAnonKeyVal;
  static String get wordpressMediaUrl => instance.wordpressMediaUrlVal;
  static String get oneSignalAppId => instance.oneSignalAppIdVal;
  static bool get notificationsEnabled => instance.notificationsEnabledVal;
  static bool get livekitEnabled => instance.livekitEnabledVal;
  static String get bucketReports => instance.bucketReportsVal;
  static String get bucketFiles => instance.bucketFilesVal;
  static String get bucketAvatars => instance.bucketAvatarsVal;
  static String get bucketApprovals => instance.bucketApprovalsVal;
  static String get bucketContracts => instance.bucketContractsVal;

  // Flavor flags
  static String get appName => instance.appNameVal;
  static String get flavorName => instance.flavorNameVal;

  // -----------------------------------------------------------
  // Instance properties configured per flavor
  // -----------------------------------------------------------
  final String supabaseUrlVal;
  final String supabaseAnonKeyVal;
  final String wordpressMediaUrlVal;
  final String oneSignalAppIdVal;
  final bool notificationsEnabledVal;
  final bool livekitEnabledVal;
  final String bucketReportsVal;
  final String bucketFilesVal;
  final String bucketAvatarsVal;
  final String bucketApprovalsVal;
  final String bucketContractsVal;

  final String appNameVal;
  final String flavorNameVal;

  const AppConfig({
    required this.supabaseUrlVal,
    required this.supabaseAnonKeyVal,
    required this.wordpressMediaUrlVal,
    required this.oneSignalAppIdVal,
    this.notificationsEnabledVal = true,
    this.livekitEnabledVal = true,
    this.bucketReportsVal = 'reports',
    this.bucketFilesVal = 'files',
    this.bucketAvatarsVal = 'avatars',
    this.bucketApprovalsVal = 'approvals',
    this.bucketContractsVal = 'contracts',
    required this.appNameVal,
    required this.flavorNameVal,
  });

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
