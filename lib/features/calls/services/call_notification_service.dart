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

class CallNotificationService {
  static final _signalService = CallSignalService();
  static bool _isInitialized = false;

  // Track call states globally
  static bool isCallActive = false;
  static final Set<String> _acceptedCallIds = {};
  static final Set<String> _processedCallIds = {};

  static bool isCallAccepted(String uuid) {
    return _acceptedCallIds.contains(uuid);
  }

  static void init() {
    if (kIsWeb) return; // CallKeep not supported on web
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
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      if (event == null) return;

      if (event is CallEventActionCallAccept) {
        _handleAcceptCall(event.id);
      } else if (event is CallEventActionCallDecline) {
        _handleDeclineCall(event.id);
      } else if (event is CallEventActionCallEnded) {
        if (_acceptedCallIds.contains(event.id)) {
          _handleEndCall(event.id);
        } else {
          _handleDeclineCall(event.id);
        }
      }
    });
  }

  /// Called when a push notification with call data is received
  static Future<void> handleIncomingCallPush(Map<String, dynamic> data) async {
    if (kIsWeb) return;

    final signalId = data['id'] as String?;
    if (signalId == null) return;

    // Prevent showing duplicate notifications for the same call or during an active call
    if (isCallActive || _processedCallIds.contains(signalId)) {
      debugPrint('Incoming call push ignored: isCallActive=$isCallActive, alreadyProcessed=${_processedCallIds.contains(signalId)}');
      return;
    }
    _processedCallIds.add(signalId);
    
    // Auto-remove from processed set after 5 minutes to prevent memory leak
    Timer(const Duration(minutes: 5), () {
      _processedCallIds.remove(signalId);
    });

    // Check if it's iOS and the region is China to bypass CallKit
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final country = ui.PlatformDispatcher.instance.locale.countryCode?.toUpperCase();
        if (country == 'CN') {
          return;
        }
      } catch (_) {}
    }

    final callerName = data['caller_name'] as String? ?? 'Someone';
    final callType = data['call_type'] as String? ?? 'video';

    // Display the native Incoming Call UI (WhatsApp style)
    final params = CallKitParams(
      id: signalId,
      nameCaller: callerName,
      appName: AppConfig.appName,
      handle: callerName,
      type: callType == 'video' ? 1 : 0, // 0: audio, 1: video
      duration: 30000,
      android: AndroidParams(
        isCustomNotification: true,
        backgroundColor: '#0955fa',
        incomingCallNotificationChannelName: '${AppConfig.appName} Calls',
      ),
      ios: const IOSParams(
        handleType: 'generic',
        supportsVideo: true,
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  static Future<void> _handleAcceptCall(String uuid) async {
    try {
      isCallActive = true;
      _acceptedCallIds.add(uuid);

      // 1. Mark as accepted in database
      await _signalService.acceptCall(uuid);
      
      // 2. Fetch signal details to join room
      final response = await Supabase.instance.client
          .from('call_signals')
          .select()
          .eq('id', uuid)
          .maybeSingle();
      
      if (response == null) return;
      
      final roomName = response['room_name'];
      final callType = response['call_type'];

      // 3. Join the call
      final callService = CallService();
      // We need profile but we're outside widget tree, use Supabase directly
      final user = Supabase.instance.client.auth.currentUser;
      
      final room = await callService.joinCall(
        roomName,
        user?.email ?? 'User', // Fallback
        user?.id ?? 'user',
        isVideo: callType == 'video',
      );

      // 4. Navigate to call screen using root navigator
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
      debugPrint('Error handling accepted call push: $e');
    }
  }

  static Future<void> _handleDeclineCall(String uuid) async {
    isCallActive = false;
    _acceptedCallIds.remove(uuid);
    _processedCallIds.remove(uuid);
    await _signalService.declineCall(uuid);
  }

  static Future<void> _handleEndCall(String uuid) async {
    isCallActive = false;
    _acceptedCallIds.remove(uuid);
    _processedCallIds.remove(uuid);
    await _signalService.endCall(uuid);
  }

  static Future<void> handleAcceptButtonPush(Map<String, dynamic> data) async {
    final signalId = data['id'] as String?;
    if (signalId == null) return;
    await _handleAcceptCall(signalId);
  }

  static Future<void> handleDeclineButtonPush(Map<String, dynamic> data) async {
    final signalId = data['id'] as String?;
    if (signalId == null) return;
    await _handleDeclineCall(signalId);
  }
}
