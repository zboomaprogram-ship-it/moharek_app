import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:moharek_app/features/calls/services/call_signal_service.dart';
import 'package:moharek_app/features/calls/screens/active_call_screen.dart';

class CallService {
  final _supabase = Supabase.instance.client;
  final _signalService = CallSignalService();

  Future<Room> joinCall(
    String roomName, 
    String participantName, 
    String identity, {
    bool isVideo = true,
  }) async {
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

      // 3. Turn on camera and mic (graceful hardware fallback)
      if (isVideo) {
        try {
          await room.localParticipant?.setCameraEnabled(
            true,
            cameraCaptureOptions: const CameraCaptureOptions(
              params: VideoParametersPresets.h720_169,
            ),
          );
        } catch (e) {
          debugPrint('Warning: Failed to enable camera (possibly no camera device): $e');
        }
      } else {
        try {
          await room.localParticipant?.setCameraEnabled(false);
        } catch (e) {
          debugPrint('Warning: Failed to disable camera: $e');
        }
      }

      try {
        await room.localParticipant?.setMicrophoneEnabled(true);
      } catch (e) {
        debugPrint('Warning: Failed to enable microphone: $e');
      }

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
          final room = await joinCall(
            'moharek-$projectId', 
            callerName, 
            identity,
            isVideo: callType == 'video',
          );
          if (!completer.isCompleted) {
            completer.complete(room);
          }
        } catch (e) {
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        }
      } else if (status == 'declined' || status == 'timeout') {
        sub?.cancel();
        if (!completer.isCompleted) {
          completer.completeError(status ?? 'unknown');
        }
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

  /// Unified join method to connect to a LiveKit room and navigate to the ActiveCallScreen.
  /// Used for scheduled/ongoing meetings.
  static Future<void> join(
    BuildContext context, {
    required String roomName,
    required String userName,
    bool isVideo = true,
  }) async {
    final nav = Navigator.of(context);
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final identity = 'user_${DateTime.now().millisecondsSinceEpoch}';
      final callService = CallService();
      
      final room = await callService.joinCall(
        roomName,
        userName,
        identity,
        isVideo: isVideo,
      );

      Future.microtask(() {
        if (nav.canPop()) nav.pop(); // Close loading indicator
        nav.push(
          MaterialPageRoute(
            builder: (_) => ActiveCallScreen(
              room: room,
              callType: isVideo ? 'video' : 'voice',
            ),
          ),
        );
      });
    } catch (e) {
      Future.microtask(() {
        if (nav.canPop()) nav.pop(); // Close loading indicator
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Call error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
