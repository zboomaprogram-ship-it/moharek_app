import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart' if (dart.library.html) 'package:moharek_app/core/stubs/callkit_stub.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart' if (dart.library.html) 'package:moharek_app/core/stubs/callkit_stub.dart';
import 'package:moharek_app/features/calls/services/call_signal_service.dart';
import 'package:moharek_app/features/calls/services/call_service.dart';
import 'package:moharek_app/core/router/app_router.dart';
import 'package:moharek_app/core/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:moharek_app/features/calls/screens/active_call_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CallNotificationService {
  static final _signalService = CallSignalService();
  static bool _isInitialized = false;

  // Track call states globally (main isolate only)
  static bool isCallActive = false;
  static final Set<String> _acceptedCallIds = {};
  static final Set<String> _processedCallIds = {};
  static final Set<String> _declinedCallIds = {};

  static bool isCallAccepted(String uuid) {
    return _acceptedCallIds.contains(uuid);
  }

  static bool isCallDeclined(String uuid) {
    return _declinedCallIds.contains(uuid);
  }

  /// Called once from the main app isolate to register CallKit event listeners.
  /// Must NOT be called from a background FCM isolate — event listeners registered
  /// in a background isolate are destroyed when that isolate exits.
  static void init() {
    if (kIsWeb) return;
    if (_isInitialized) return;

    // Check if it's iOS and the region is China to bypass CallKit
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final country = ui.PlatformDispatcher.instance.locale.countryCode?.toUpperCase();
        if (country == 'CN') {
          return;
        }
      } catch (_) {}
    }

    _isInitialized = true;

    // Set the handler for CallKit events (Accept/Decline from native UI)
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) async {
      if (event == null) return;

      final uuid = _extractEventId(event);
      debugPrint('📞 [CallKit] Event: ${event.runtimeType}, extracted UUID: $uuid');

      if (event is CallEventActionCallAccept) {
        if (uuid != null) await _handleAcceptCall(uuid);
      } else if (event is CallEventActionCallDecline) {
        if (uuid != null) await _handleDeclineCall(uuid);
      } else if (event is CallEventActionCallEnded) {
        if (uuid != null) {
          if (_acceptedCallIds.contains(uuid)) {
            await _handleEndCall(uuid);
          } else {
            await _handleDeclineCall(uuid);
          }
        }
      } else if (event is CallEventActionCallTimeout) {
        if (uuid != null) {
          await _signalService.timeoutCall(uuid);
          _cleanupCallState(uuid);
        }
      }
    });
  }

  /// Safely extracts the call UUID from any CallEvent type.
  static String? _extractEventId(CallEvent event) {
    try {
      final id = (event as dynamic).id as String?;
      if (id != null && id.isNotEmpty) return id;
    } catch (_) {}

    try {
      final body = (event as dynamic).body as Map<dynamic, dynamic>?;
      final id = body?['id'] as String?;
      if (id != null && id.isNotEmpty) return id;
    } catch (_) {}

    return null;
  }

  /// Shows the native incoming call UI. 
  /// 
  /// This is SAFE to call from a background FCM isolate — it only triggers the 
  /// native CallKit UI (no Supabase, no navigation, no static state guards).
  /// The Accept/Decline event handling happens later via [init()] in the main isolate.
  static Future<void> handleIncomingCallPush(Map<String, dynamic> data) async {
    if (kIsWeb) return;

    final signalId = data['id'] as String?;
    if (signalId == null || signalId.isEmpty) return;

    // In the MAIN isolate only: skip duplicate/already-handled calls.
    // We cannot do this in a background isolate because static state is not shared.
    // In the background isolate _processedCallIds is always empty (fresh isolate),
    // so we skip this guard there and let the native CallKit UI deduplicate.
    if (_isInitialized) {
      if (isCallActive || _processedCallIds.contains(signalId) || _declinedCallIds.contains(signalId)) {
        debugPrint('📞 [CallKit] Incoming call push ignored (main isolate): '
            'isCallActive=$isCallActive, '
            'alreadyProcessed=${_processedCallIds.contains(signalId)}, '
            'declined=${_declinedCallIds.contains(signalId)}');
        return;
      }
      _processedCallIds.add(signalId);
      Timer(const Duration(minutes: 5), () => _processedCallIds.remove(signalId));
    }

    // iOS China bypass
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final country = ui.PlatformDispatcher.instance.locale.countryCode?.toUpperCase();
        if (country == 'CN') return;
      } catch (_) {}
    }

    final callerName = data['caller_name'] as String? ?? 'Someone';
    final callType = data['call_type'] as String? ?? 'video';

    debugPrint('📞 [CallKit] Showing incoming call UI — signalId=$signalId, caller=$callerName, type=$callType');

    String appName;
    String flavor;
    try {
      appName = AppConfig.appName;
      flavor = AppConfig.flavorName;
    } catch (_) {
      // AppConfig not initialized (e.g. in background isolate before flavor is set)
      appName = 'Moharek';
      flavor = 'moharek';
    }

    final params = CallKitParams(
      id: signalId,
      nameCaller: callerName,
      appName: appName,
      handle: callerName,
      type: callType == 'video' ? 1 : 0,
      duration: 30000,
      android: AndroidParams(
        isCustomNotification: true,
        isShowFullLockedScreen: true,
        isFullScreen: false,
        isImportant: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: flavor == 'rabhan' ? '#181A20' : '#080B12',
        actionColor: flavor == 'rabhan' ? '#4CAF50' : '#2EE59D',
        incomingCallNotificationChannelName: '$appName Calls',
        missedCallNotificationChannelName: '$appName Missed Calls',
        textAccept: 'قبول',
        textDecline: 'رفض',
      ),
      ios: const IOSParams(
        handleType: 'generic',
        supportsVideo: true,
        ringtonePath: 'system_ringtone_default',
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  /// Checks if CallKit has a pending accepted call from a previous background/killed session.
  /// 
  /// Call this from the main app after everything is initialized. This handles the case
  /// where the user accepted a call while the app was killed — CallKit accepted it natively,
  /// but the Dart accept handler never ran because there was no Dart VM yet.
  static Future<void> checkForPendingAcceptedCall() async {
    if (kIsWeb) return;
    try {
      final activeCalls = await FlutterCallkitIncoming.activeCalls();
      debugPrint('📞 [CallKit] checkForPendingAcceptedCall: activeCalls=$activeCalls');

      if (activeCalls.isEmpty) return;

      for (final call in activeCalls) {
        final callId = call.id;

        // Check if this is a call that was already accepted (CallKit shows active calls
        // only after the user has accepted — declined/ended calls are removed)
        debugPrint('📞 [CallKit] Found active call from previous session: $callId');

        // Don't re-process if we already handled it in this app session
        if (_acceptedCallIds.contains(callId)) continue;

        // This call was accepted from the native UI while the app was killed.
        // Handle it now that we're in the main isolate. We DO NOT await this
        // because _handleAcceptCall waits for the router to mount, which
        // blocks runApp() if we wait for it during app initialization.
        _handleAcceptCall(callId);
        return; // Handle one call at a time
      }
    } catch (e) {
      debugPrint('📞 [CallKit] checkForPendingAcceptedCall error (non-fatal): $e');
    }
  }

  static Future<void> _waitForAuthSession() async {
    final client = Supabase.instance.client;
    if (client.auth.currentSession != null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final hasToken = prefs.containsKey('supabase.auth.token');
      if (!hasToken) {
        debugPrint('📞 [CallKit] No saved Supabase session token found, skipping auth wait.');
        return;
      }
    } catch (_) {}

    debugPrint('📞 [CallKit] Waiting for Supabase session to restore...');
    int retries = 0;
    while (client.auth.currentSession == null && retries < 20) { // Wait up to 5 seconds
      await Future.delayed(const Duration(milliseconds: 250));
      retries++;
    }
    debugPrint('📞 [CallKit] Session wait complete. Session exists: ${client.auth.currentSession != null}');
  }

  static Future<void> _handleAcceptCall(String uuid) async {
    // Guard against double-accept
    if (_acceptedCallIds.contains(uuid)) {
      debugPrint('📞 [CallKit] _handleAcceptCall: already accepted $uuid, ignoring');
      return;
    }

    debugPrint('📞 [CallKit] _handleAcceptCall: $uuid');

    try {
      isCallActive = true;
      _acceptedCallIds.add(uuid);

      // Wait for session to restore BEFORE running any database query or joining the call.
      // This is crucial for cold starts when the user accepts from the killed state.
      await _waitForAuthSession();

      // 1. Mark as accepted in database
      await _signalService.acceptCall(uuid);

      // Do NOT call endCall(uuid) here! CallKit naturally handles the accepted state.
      // Calling endCall tells the OS to terminate the active call session, which
      // drops the microphone and can cause the OS to send the app to the background.

      // 3. Fetch signal details to join room
      final response = await Supabase.instance.client
          .from('call_signals')
          .select()
          .eq('id', uuid)
          .maybeSingle();

      if (response == null) {
        debugPrint('📞 [CallKit] _handleAcceptCall: signal $uuid not found in DB');
        _cleanupCallState(uuid);
        return;
      }

      final roomName = response['room_name'] as String?;
      final callType = response['call_type'] as String?;

      if (roomName == null) {
        debugPrint('📞 [CallKit] _handleAcceptCall: roomName is null for signal $uuid');
        _cleanupCallState(uuid);
        return;
      }

      // Wait for the app router to be fully mounted AND app lifecycle to be resumed.
      // LiveKit requires the Activity to be fully resumed (foreground) to access camera/mic.
      int retries = 0;
      while (rootNavigatorKey.currentState == null || 
             !rootNavigatorKey.currentState!.mounted ||
             WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        if (retries > 40) { // Wait up to 10 seconds
          debugPrint('📞 [CallKit] Navigation or Resume failed: rootNavigatorKey not mounted or app not resumed after 10s');
          _cleanupCallState(uuid);
          return;
        }
        await Future.delayed(const Duration(milliseconds: 250));
        retries++;
      }

      // 4. Join the call
      final callService = CallService();
      final user = Supabase.instance.client.auth.currentUser;

      final room = await callService.joinCall(
        roomName,
        user?.email ?? 'User',
        user?.id ?? 'user',
        isVideo: callType == 'video',
      );

      // 5. Navigate to call screen
      _navigateToCallScreen(room, callType ?? 'video', uuid);
    } catch (e) {
      debugPrint('📞 [CallKit] Error handling accepted call: $e');
      _cleanupCallState(uuid);
    }
  }

  static Future<void> _navigateToCallScreen(dynamic room, String callType, String uuid) async {
    try {
      rootNavigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => ActiveCallScreen(
            room: room,
            callType: callType,
            incomingSignalId: uuid,
          ),
        ),
      );
    } catch (e) {
      debugPrint('📞 [CallKit] Error navigating to call screen: $e');
      _cleanupCallState(uuid);
    }
  }

  static Future<void> _handleDeclineCall(String uuid) async {
    debugPrint('📞 [CallKit] _handleDeclineCall: $uuid');

    _declinedCallIds.add(uuid);

    try {
      await FlutterCallkitIncoming.endCall(uuid);
    } catch (e) {
      debugPrint('📞 [CallKit] Warning: could not end native call UI on decline: $e');
    }

    try {
      await _signalService.declineCall(uuid);
      debugPrint('📞 [CallKit] Decline signal sent to DB for $uuid');
    } catch (e) {
      debugPrint('📞 [CallKit] Error declining call in DB: $e');
    }

    _cleanupCallState(uuid);

    Timer(const Duration(minutes: 5), () => _declinedCallIds.remove(uuid));
  }

  static Future<void> _handleEndCall(String uuid) async {
    debugPrint('📞 [CallKit] _handleEndCall: $uuid');
    try {
      await _signalService.endCall(uuid);
    } catch (e) {
      debugPrint('📞 [CallKit] Error ending call in DB: $e');
    }
    _cleanupCallState(uuid);
  }

  static void _cleanupCallState(String uuid) {
    isCallActive = false;
    _acceptedCallIds.remove(uuid);
    _processedCallIds.remove(uuid);
  }

  static Future<void> handleAcceptButtonPush(Map<String, dynamic> data) async {
    final signalId = data['id'] as String?;
    if (signalId == null) return;
    debugPrint('📞 [OneSignal] handleAcceptButtonPush: $signalId');
    await _handleAcceptCall(signalId);
  }

  static Future<void> handleDeclineButtonPush(Map<String, dynamic> data) async {
    final signalId = data['id'] as String?;
    if (signalId == null) return;
    debugPrint('📞 [OneSignal] handleDeclineButtonPush: $signalId');
    await _handleDeclineCall(signalId);
  }
}
