import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:moharek_app/features/chat/services/voice_recorder_service.dart';

// Conditional import: uses file_io_web.dart on web, file_io_native.dart otherwise
import 'file_io_native.dart' if (dart.library.html) 'file_io_web.dart' as file_io;

/// Platform-safe voice upload — works on both web (blob) and mobile (file).
class VoiceUploadService {
  final _supabase = Supabase.instance.client;

  Future<String> uploadAndSend({
    required String channelId,
    required String projectId,
    required String senderId,
    required VoiceRecordingResult recording,
  }) async {
    final fileName = '$projectId/$channelId/${DateTime.now().millisecondsSinceEpoch}.m4a';

    if (kIsWeb) {
      // On web, recording.fileBytes is populated by the recorder service
      if (recording.fileBytes != null) {
        await _supabase.storage.from('voice-messages').uploadBinary(
          fileName,
          recording.fileBytes!,
          fileOptions: const FileOptions(contentType: 'audio/webm', upsert: false),
        );
      }
    } else {
      // Mobile/Desktop — read file bytes using dart:io
      final bytes = await file_io.readFileBytes(recording.filePath);
      if (bytes != null) {
        await _supabase.storage.from('voice-messages').uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(contentType: 'audio/m4a', upsert: false),
        );
      }
    }

    // Get signed URL (valid 7 days)
    final signedUrl = await _supabase.storage
        .from('voice-messages')
        .createSignedUrl(fileName, 60 * 60 * 24 * 7);

    // Insert message row
    await _supabase.from('messages').insert({
      'channel_id': channelId,
      'sender_id': senderId,
      'message_type': 'voice',
      'file_url': signedUrl,
      'duration_seconds': recording.durationSeconds,
      'waveform_data': recording.waveformData,
      'content': '🎤 رسالة صوتية',
    });

    // Clean up temp file on mobile
    if (!kIsWeb && recording.filePath.isNotEmpty) {
      await file_io.deleteTempFile(recording.filePath);
    }

    return signedUrl;
  }
}
