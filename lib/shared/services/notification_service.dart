import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart'; // Required for WidgetsFlutterBinding
import 'package:moharek_app/core/config/app_config.dart';
import 'package:moharek_app/core/router/app_router.dart';
import 'package:moharek_app/features/calls/services/call_notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moharek_app/core/config/moharek_config.dart';
import 'package:moharek_app/core/config/rabhan_config.dart';

// OneSignal is mobile-only — import conditionally
import 'package:onesignal_flutter/onesignal_flutter.dart'
    if (dart.library.html) 'package:moharek_app/shared/services/onesignal_stub.dart';

// CallKit is mobile-only — import conditionally
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart' 
    if (dart.library.html) 'package:moharek_app/core/stubs/callkit_stub.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // This handler runs in a SEPARATE Dart isolate when the app is killed or in background.
  // IMPORTANT: Static state (isCallActive, _processedCallIds, etc.) is NOT shared with
  // the main isolate — this is a completely fresh Dart VM.
  //
  // Therefore we ONLY show the native CallKit incoming call UI here.
  // Accept/Decline events and navigation are handled by the main isolate once the app
  // launches (via CallNotificationService.init() and checkForPendingAcceptedCall()).
  WidgetsFlutterBinding.ensureInitialized();

  if (message.data['type'] == 'call') {
    debugPrint('🔔 [FCM Background] Incoming call push received — showing CallKit UI');

    // Load the flavor from SharedPreferences so we can use the right colors/name.
    try {
      final prefs = await SharedPreferences.getInstance();
      final flavor = prefs.getString('app_flavor');
      if (flavor == 'rabhan') {
        AppConfig.setInstance(const RabhanConfig());
      } else {
        AppConfig.setInstance(const MoharekConfig());
      }
    } catch (e) {
      debugPrint('🔔 [FCM Background] Could not load app_flavor: $e');
      try { AppConfig.instance; } catch (_) { AppConfig.setInstance(const MoharekConfig()); }
    }

    // Show native CallKit UI — this is all we do in the background isolate.
    // The user's Accept/Decline tap will be handled by the main app on next launch.
    await CallNotificationService.handleIncomingCallPush(message.data);
  }
}

class NotificationService {
  static String? _currentUserId;

  static Future<void> init() async {
    if (!AppConfig.notificationsEnabled) return;

    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize(AppConfig.oneSignalAppId);

    // Initialize call notification handling
    CallNotificationService.init();

    // ── Firebase Cloud Messaging (FCM) Setup for Background Calls ───────
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Also listen for FCM messages while the app is actively open
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data['type'] == 'call') {
        debugPrint('🔔 [FCM Foreground] Incoming call push received');
        CallNotificationService.handleIncomingCallPush(message.data);
      }
    });
    
    // Request FCM permissions
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Listen to token refresh
    messaging.onTokenRefresh.listen((fcmToken) {
      if (_currentUserId != null) {
        _saveFcmTokenToSupabase(_currentUserId!, fcmToken);
      }
    });

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
    // Always suppress the intrusive in-app popup for ALL notification types.
    // Push notifications still arrive and ring normally when the app is backgrounded.
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      final data = event.notification.additionalData;
      debugPrint('🔔 [OneSignal] Foreground notification suppressed: ${event.notification.title}');
      if (data != null && data['type'] == 'call') {
        // For call notifications, hand off to CallNotificationService instead of showing a popup.
        CallNotificationService.handleIncomingCallPush(data);
      }
      // Always prevent the in-app banner — it is annoying during active use.
      event.preventDefault();
    });

    // ── Notification click handler ─────────────────────────────────────────
    OneSignal.Notifications.addClickListener((event) {
      final data = event.notification.additionalData;
      final actionId = event.result.actionId;
      debugPrint('🔔 [OneSignal] Notification clicked: ${event.notification.title} data=$data actionId=$actionId');
      
      if (data != null) {
        if (data['type'] == 'call') {
          if (actionId == 'accept') {
            CallNotificationService.handleAcceptButtonPush(data);
          } else if (actionId == 'reject') {
            CallNotificationService.handleDeclineButtonPush(data);
          } else {
            CallNotificationService.handleIncomingCallPush(data);
          }
        } else if (data['type'] == 'meeting') {
          try {
            appRouter.push('/dashboard/meetings');
          } catch (e) {
            debugPrint('🔔 [Notification Click] Meeting navigation error: $e');
          }
        } else if (data['link_path'] != null || data['route'] != null) {
          try {
            final rawRoute = (data['link_path'] ?? data['route']) as String;
            final route = resolveNotificationPath(rawRoute);
            appRouter.push(route);
          } catch (e) {
            debugPrint('🔔 [Notification Click] Deep-link navigation error: $e');
          }
        }
      }
    });

    // Request permission (prompts user on iOS, silent on Android 12 and below)
    final granted = await OneSignal.Notifications.requestPermission(true);
    debugPrint('🔔 [OneSignal] Permission granted: $granted');
  }

  /// Called after login — links this Supabase user to OneSignal for targeted push
  static Future<void> setExternalUserId(String userId) async {
    final isNewUser = _currentUserId != userId;
    _currentUserId = userId;

    if (isNewUser) {
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

    // Try to save FCM token with retries (always runs on app boot/state change, even if userId matches)
    _fetchAndSaveFcmTokenWithRetry(userId);

    // Try to save Apple VoIP PushKit token
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final voipToken = await FlutterCallkitIncoming.getDevicePushTokenVoIP();
        if (voipToken != null && voipToken.toString().isNotEmpty) {
          await _saveVoipTokenToSupabase(userId, voipToken.toString());
        }
      } catch (e) {
        debugPrint('🔔 [CallKit] Failed to get VoIP token: $e');
      }
    }
  }

  /// Fetches FCM token and saves to Supabase, retrying if null or empty (e.g. during emulator startup).
  static Future<void> _fetchAndSaveFcmTokenWithRetry(String userId, {int attempt = 1}) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await _saveFcmTokenToSupabase(userId, fcmToken);
      } else {
        if (attempt <= 5) {
          debugPrint('🔔 [FCM] Token is null/empty on attempt $attempt, retrying in ${attempt * 2}s...');
          Future.delayed(Duration(seconds: attempt * 2), () {
            _fetchAndSaveFcmTokenWithRetry(userId, attempt: attempt + 1);
          });
        } else {
          debugPrint('🔔 [FCM] Failed to get FCM token after 5 attempts.');
        }
      }
    } catch (e) {
      debugPrint('🔔 [FCM] Error getting token (attempt $attempt): $e');
      if (attempt <= 5) {
        Future.delayed(Duration(seconds: attempt * 2), () {
          _fetchAndSaveFcmTokenWithRetry(userId, attempt: attempt + 1);
        });
      }
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

  /// Saves the Firebase Cloud Messaging (FCM) token to Supabase for background pushes
  static Future<void> _saveFcmTokenToSupabase(String userId, String token) async {
    try {
      debugPrint('🔔 [FCM] Saving FCM token to Supabase: $token');
      await Supabase.instance.client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', userId);
      debugPrint('🔔 [FCM] ✅ FCM token saved successfully');
    } catch (e) {
      debugPrint('🔔 [FCM] ❌ Failed to save FCM token: $e');
    }
  }

  /// Saves the Apple VoIP PushKit token to Supabase for iOS background calls
  static Future<void> _saveVoipTokenToSupabase(String userId, String token) async {
    try {
      debugPrint('🔔 [APNs] Saving VoIP token to Supabase: $token');
      await Supabase.instance.client
          .from('profiles')
          .update({'apns_voip_token': token})
          .eq('id', userId);
      debugPrint('🔔 [APNs] ✅ VoIP token saved successfully');
    } catch (e) {
      debugPrint('🔔 [APNs] ❌ Failed to save VoIP token: $e');
    }
  }

  static Future<void> logout() async {
    if (_currentUserId == null) return;
    debugPrint('🔔 [OneSignal] Logging out (user: $_currentUserId)');

    try {
      await Supabase.instance.client
          .from('profiles')
          .update({
            'onesignal_player_id': null,
            'fcm_token': null,
            'apns_voip_token': null,
          })
          .eq('id', _currentUserId!);
    } catch (e) {
      debugPrint('🔔 [OneSignal/FCM] Failed to clear tokens: $e');
    }

    _currentUserId = null;
    await OneSignal.logout();
  }
}
