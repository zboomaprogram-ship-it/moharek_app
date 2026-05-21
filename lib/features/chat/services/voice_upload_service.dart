import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:moharek_app/features/chat/services/voice_recorder_service.dart';

import 'package:moharek_app/shared/services/wordpress_upload_service.dart';

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
    final fileName = 'voice_${projectId}_${channelId}_${DateTime.now().millisecondsSinceEpoch}.m4a';
    String publicUrl = '';

    if (kIsWeb) {
      // On web, upload to Supabase Storage 'files' bucket to bypass CORS limitations on the WordPress server
      if (recording.fileBytes != null) {
        final storagePath = 'voice/$fileName';
        await _supabase.storage.from('files').uploadBinary(storagePath, recording.fileBytes!);
        publicUrl = _supabase.storage.from('files').getPublicUrl(storagePath);
      } else {
        throw Exception('VoiceUploadService: Voice bytes are null on web');
      }
    } else {
      // Mobile/Desktop — read file bytes using dart:io
      final bytes = await file_io.readFileBytes(recording.filePath);
      if (bytes != null) {
        publicUrl = await WordPressUploadService.uploadBytes(
          bytes,
          fileName,
        );
      } else {
        throw Exception('VoiceUploadService: Could not read voice file bytes');
      }
    }

    // Insert message row
    await _supabase.from('messages').insert({
      'channel_id': channelId,
      'sender_id': senderId,
      'message_type': 'voice',
      'file_url': publicUrl,
      'duration_seconds': recording.durationSeconds,
      'waveform_data': recording.waveformData,
      'content': '🎤 رسالة صوتية',
    });

    // Clean up temp file on mobile
    if (!kIsWeb && recording.filePath.isNotEmpty) {
      await file_io.deleteTempFile(recording.filePath);
    }

    return publicUrl;
  }
}
