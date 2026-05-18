import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:moharek_app/features/calls/screens/active_call_screen.dart';

class CallService {
  static final _supabase = Supabase.instance.client;

  static Future<void> join(
    BuildContext context, {
    required String roomName,
    required String userName,
    bool isVideo = true,
  }) async {
    final nav = Navigator.of(context);
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final identity = 'user_${DateTime.now().millisecondsSinceEpoch}';
      
      // 1. Get token from Edge Function
      final res = await _supabase.functions.invoke('livekit-token', body: {
        'room_name': roomName,
        'participant_name': userName,
        'participant_identity': identity,
      });

      if (res.status != 200) throw Exception('Failed to get token (Status: ${res.status})');
      
      final data = res.data as Map<String, dynamic>?;
      if (data == null || data['token'] == null || data['url'] == null) {
        throw Exception('Invalid token response from server');
      }

      final token = data['token'] as String;
      final url = data['url'] as String;

      // 2. Connect to LiveKit Room
      final room = Room();
      try {
        await room.connect(url, token);
      } catch (e) {
        await room.dispose();
        rethrow;
      }

      // 3. Turn on camera and mic (graceful hardware fallback)
      try {
        await room.localParticipant?.setMicrophoneEnabled(true);
      } catch (e) {
        debugPrint('Warning: Failed to enable microphone: $e');
      }
      if (isVideo) {
        try {
          await room.localParticipant?.setCameraEnabled(true);
        } catch (e) {
          debugPrint('Warning: Failed to enable camera (possibly no camera device): $e');
        }
      }

      if (nav.canPop()) {
        Future.microtask(() {
          if (nav.canPop()) nav.pop(); // Close loading
          nav.push(
            MaterialPageRoute(
              builder: (_) => ActiveCallScreen(
                room: room,
                callType: isVideo ? 'video' : 'voice',
              ),
            ),
          );
        });
      }
    } catch (e) {
      Future.microtask(() {
        if (nav.canPop()) nav.pop();
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Call error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> startCall(
    BuildContext context,
    String roomName,
    String participantName,
    String identity,
    bool isVideo,
  ) async {
    await join(context, roomName: roomName, userName: participantName, isVideo: isVideo);
  }
}
