import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:moharek_app/features/calls/services/call_signal_service.dart';

class CallService {
  final _supabase = Supabase.instance.client;
  final _signalService = CallSignalService();

  Future<Room> joinCall(String roomName, String participantName, String identity) async {
    try {
      // 1. Get token from Edge Function
      final res = await _supabase.functions.invoke('livekit-token', body: {
        'room_name': roomName,
        'participant_name': participantName,
        'participant_identity': identity,
      });

      if (res.status != 200 || res.data == null) {
        throw Exception('Failed to get call token: ${res.status} ${res.data?['error'] ?? ''}');
      }

      final token = res.data['token'] as String?;
      final url = res.data['url'] as String?;

      if (token == null || url == null) {
        throw Exception('Token or URL is missing from server response');
      }

      // 2. Connect to LiveKit Room
      final room = Room();
      
      const connectOptions = ConnectOptions(
        autoSubscribe: true,
      );
      
      const roomOptions = RoomOptions(
        adaptiveStream: true,
        dynacast: true,
      );

      await room.connect(
        url, 
        token, 
        roomOptions: roomOptions,
        connectOptions: connectOptions,
      );

      // 3. Turn on camera and mic
      await room.localParticipant?.setCameraEnabled(true);
      await room.localParticipant?.setMicrophoneEnabled(true);

      return room;
    } catch (e) {
      debugPrint('LiveKit Connection Error: $e');
      rethrow;
    }
  }

  /// Starts a call by sending a signal and waiting for the other party to accept.
  /// Returns the room if accepted, or throws an error if declined/timeout.
  Future<Room> startCallWithSignal({
    required String projectId,
    required String callerName,
    required String callType,
    required String identity,
    required Function(String status) onStatusUpdate,
  }) async {
    // 1. Send signal
    final signalId = await _signalService.sendCallSignal(
      projectId: projectId,
      callerName: callerName,
      callType: callType,
    );

    final completer = Completer<Room>();
    StreamSubscription? sub;

    // 2. Watch signal status
    sub = _signalService.watchSignal(signalId).listen((signal) async {
      final status = signal['status'] as String?;
      if (status != null) onStatusUpdate(status);

      if (status == 'accepted') {
        sub?.cancel();
        try {
          final room = await joinCall('moharek-$projectId', callerName, identity);
          completer.complete(room);
        } catch (e) {
          completer.completeError(e);
        }
      } else if (status == 'declined' || status == 'timeout') {
        sub?.cancel();
        completer.completeError(status ?? 'unknown');
      }
    });

    // 3. Local timeout backup
    Timer(CallSignalService.callTimeout + const Duration(seconds: 2), () {
      if (!completer.isCompleted) {
        sub?.cancel();
        _signalService.timeoutCall(signalId);
        completer.completeError('timeout');
      }
    });

    return completer.future;
  }
}
