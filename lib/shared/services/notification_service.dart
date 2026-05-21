import 'package:flutter/foundation.dart';
import 'package:moharek_app/core/config/app_config.dart';
import 'package:moharek_app/features/calls/services/call_notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// OneSignal is mobile-only — import conditionally
import 'package:onesignal_flutter/onesignal_flutter.dart'
    if (dart.library.html) 'package:moharek_app/shared/services/onesignal_stub.dart';

class NotificationService {
  static String? _currentUserId;

  static Future<void> init() async {
    if (!AppConfig.notificationsEnabled) return;

    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize(AppConfig.oneSignalAppId);

    // Initialize call notification handling
    CallNotificationService.init();

    // ── Listen for push subscription changes ──────────────────────────────
    // This fires when the player/subscription ID becomes available or changes.
    // We use this to reliably save the player ID to Supabase.
    OneSignal.User.pushSubscription.addObserver((state) {
      final newId = state.current.id;
      debugPrint('🔔 [OneSignal] pushSubscription changed: id=$newId, opted=${state.current.optedIn}');
      if (newId != null && newId.isNotEmpty && _currentUserId != null) {
        _savePlayerIdToSupabase(_currentUserId!, newId);
      }
    });

    // ── Foreground notification handler ────────────────────────────────────
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      debugPrint('🔔 [OneSignal] Foreground notification: ${event.notification.title}');
      final data = event.notification.additionalData;
      if (data != null && data['type'] == 'call') {
        event.preventDefault();
        CallNotificationService.handleIncomingCallPush(data);
      }
      // For all other notifications, display them normally (don't preventDefault)
    });

    // ── Notification click handler ─────────────────────────────────────────
    OneSignal.Notifications.addClickListener((event) {
      final data = event.notification.additionalData;
      debugPrint('🔔 [OneSignal] Notification clicked: ${event.notification.title} data=$data');
      if (data != null && data['type'] == 'call') {
        CallNotificationService.handleIncomingCallPush(data);
      }
    });

    // Request permission (prompts user on iOS, silent on Android 12 and below)
    final granted = await OneSignal.Notifications.requestPermission(true);
    debugPrint('🔔 [OneSignal] Permission granted: $granted');
  }

  /// Called after login — links this Supabase user to OneSignal for targeted push
  static Future<void> setExternalUserId(String userId) async {
    if (_currentUserId == userId) return;
    _currentUserId = userId;

    debugPrint('🔔 [OneSignal] Logging in with external user ID: $userId');
    await OneSignal.login(userId);

    // Try to save player ID immediately if already available
    final playerId = OneSignal.User.pushSubscription.id;
    if (playerId != null && playerId.isNotEmpty) {
      await _savePlayerIdToSupabase(userId, playerId);
    } else {
      // Player ID not ready yet — the subscription observer (registered in init())
      // will fire and save it once OneSignal registers the subscription.
      debugPrint('🔔 [OneSignal] Player ID not ready yet — waiting for subscription observer...');
    }
  }

  /// Saves the OneSignal player/subscription ID to Supabase so the Edge Function
  /// can use it for direct push targeting (more reliable than external_user_id).
  static Future<void> _savePlayerIdToSupabase(String userId, String playerId) async {
    try {
      debugPrint('🔔 [OneSignal] Saving player ID to Supabase: $playerId (user: $userId)');
      await Supabase.instance.client
          .from('profiles')
          .update({'onesignal_player_id': playerId})
          .eq('id', userId);
      debugPrint('🔔 [OneSignal] ✅ Player ID saved successfully');
    } catch (e) {
      debugPrint('🔔 [OneSignal] ❌ Failed to save player ID: $e');
    }
  }

  static Future<void> logout() async {
    if (_currentUserId == null) return;
    debugPrint('🔔 [OneSignal] Logging out (user: $_currentUserId)');

    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'onesignal_player_id': null})
          .eq('id', _currentUserId!);
    } catch (e) {
      debugPrint('🔔 [OneSignal] Failed to clear player ID: $e');
    }

    _currentUserId = null;
    await OneSignal.logout();
  }
}
