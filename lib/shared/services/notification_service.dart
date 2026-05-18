import 'package:flutter/foundation.dart';
import 'package:moharek_app/core/config/app_config.dart';
import 'package:moharek_app/features/calls/services/call_notification_service.dart';

// OneSignal is mobile-only — import conditionally
import 'package:onesignal_flutter/onesignal_flutter.dart'
    if (dart.library.html) 'package:moharek_app/shared/services/onesignal_stub.dart';

class NotificationService {
  static String? _currentUserId;

  static Future<void> init() async {
    if (!AppConfig.notificationsEnabled) return;

    OneSignal.Debug.setLogLevel(OSLogLevel.debug);
    OneSignal.initialize(AppConfig.oneSignalAppId);

    // Initialize call notification handling
    CallNotificationService.init();

    // Listen for incoming notifications (Foreground)
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      debugPrint('DEBUG: Notification received in foreground: ${event.notification.title}');
      
      final data = event.notification.additionalData;
      if (data != null && data['type'] == 'call') {
        // If it's a call, let CallKeep handle the UI instead of a normal notification
        event.preventDefault();
        CallNotificationService.handleIncomingCallPush(data);
      }
    });

    // Listen for notification clicks
    OneSignal.Notifications.addClickListener((event) {
      final data = event.notification.additionalData;
      if (data != null && data['type'] == 'call') {
        CallNotificationService.handleIncomingCallPush(data);
      }
    });

    // Request permission on iOS/Android
    await OneSignal.Notifications.requestPermission(true);
  }

  static Future<void> setExternalUserId(String userId) async {
    if (_currentUserId == userId) return;
    _currentUserId = userId;
    debugPrint('DEBUG: Setting OneSignal External User ID to: $userId');
    await OneSignal.login(userId);
  }

  static Future<void> logout() async {
    if (_currentUserId == null) return;
    debugPrint('DEBUG: Logging out from OneSignal (ID: $_currentUserId)');
    _currentUserId = null;
    await OneSignal.logout();
  }
}
