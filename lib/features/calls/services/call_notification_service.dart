import 'package:flutter/foundation.dart';
import 'package:flutter_callkeep/flutter_callkeep.dart';
import 'package:moharek_app/features/calls/services/call_signal_service.dart';
import 'package:moharek_app/features/calls/services/call_service.dart';
import 'package:moharek_app/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:moharek_app/features/calls/screens/active_call_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CallNotificationService {
  static final _signalService = CallSignalService();
  static bool _isInitialized = false;

  static void init() {
    if (kIsWeb) return; // CallKeep not supported on web
    if (_isInitialized) return;
    _isInitialized = true;

    // Set the handler for CallKeep events (Accept/Decline from native UI)
    CallKeep.instance.handler = CallEventHandler(
      onCallAccepted: (CallEvent event) {
        _handleAcceptCall(event.uuid);
      },
      onCallEnded: (CallEvent event) {
        _handleDeclineCall(event.uuid);
      },
      onCallDeclined: (CallEvent event) {
        _handleDeclineCall(event.uuid);
      },
    );
  }

  /// Called when a push notification with call data is received
  static Future<void> handleIncomingCallPush(Map<String, dynamic> data) async {
    if (kIsWeb) return;

    final signalId = data['id'] as String?;
    final callerName = data['caller_name'] as String? ?? 'Someone';
    final callType = data['call_type'] as String? ?? 'video';
    
    if (signalId == null) return;

    // Display the native Incoming Call UI (WhatsApp style)
    await CallKeep.instance.displayIncomingCall(
      CallEvent(
        uuid: signalId,
        callerName: callerName,
        handle: callerName,
        hasVideo: callType == 'video',
      ),
    );
  }

  static Future<void> _handleAcceptCall(String uuid) async {
    try {
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
      );

      // 4. Navigate to call screen using root navigator
      rootNavigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => ActiveCallScreen(
            room: room,
            callType: callType,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error handling accepted call push: $e');
    }
  }

  static Future<void> _handleDeclineCall(String uuid) async {
    await _signalService.declineCall(uuid);
  }
}
