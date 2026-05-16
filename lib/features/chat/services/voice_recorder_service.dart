import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart' as rec;
import 'package:path_provider/path_provider.dart' as pp;
import 'package:permission_handler/permission_handler.dart';
import 'package:moharek_app/features/chat/services/file_io_native.dart' if (dart.library.html) 'package:moharek_app/features/chat/services/file_io_web.dart' as file_io;

/// Truly Native voice recorder service using Platform Channels for Mobile.
class VoiceRecorderService {
  static const _channel = MethodChannel('com.zbooma.moharek/voice_recorder');
  
  // Web remains using browser's MediaRecorder via 'record' package
  rec.AudioRecorder? _webRecorder;

  String? _filePath;
  DateTime? _startTime;
  bool _isRecording = false;
  double _lastAmplitude = 0.0;

  bool get isRecording => _isRecording;
  double get lastAmplitude => _lastAmplitude;

  VoiceRecorderService() {
    if (kIsWeb) {
      _webRecorder = rec.AudioRecorder();
    }
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) {
      return await _webRecorder?.hasPermission() ?? false;
    }
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> startRecording() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) throw Exception('Microphone permission denied');

    _isRecording = true;
    _startTime = DateTime.now();

    if (kIsWeb) {
      await _webRecorder?.start(
        const rec.RecordConfig(encoder: rec.AudioEncoder.opus, bitRate: 128000),
        path: '', 
      );
    } else {
      final dir = await pp.getTemporaryDirectory();
      _filePath = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _channel.invokeMethod('startRecording', {'path': _filePath});
    }
  }

  Future<void> collectAmplitudeSample() async {
    if (!_isRecording) return;
    if (kIsWeb) {
      final amp = await _webRecorder?.getAmplitude();
      if (amp != null) {
        _lastAmplitude = ((amp.current + 50) / 50).clamp(0.0, 1.0);
      }
    } else {
      try {
        final amp = await _channel.invokeMethod<double>('getAmplitude');
        _lastAmplitude = amp ?? 0.0;
      } catch (e) {
        _lastAmplitude = 0.2;
      }
    }
  }

  Future<VoiceRecordingResult?> stopRecording() async {
    if (!_isRecording || _startTime == null) return null;
    
    _isRecording = false;
    final duration = DateTime.now().difference(_startTime!).inSeconds;

    try {
      if (kIsWeb) {
        final path = await _webRecorder?.stop();
        if (duration < 1 || path == null) return null;

        final bytes = await file_io.readBlobAsBytes(path);
        if (bytes == null || bytes.isEmpty) return null;

        return VoiceRecordingResult(
          filePath: '', 
          durationSeconds: duration,
          waveformData: [],
          fileBytes: bytes,
        );
      } else {
        final path = await _channel.invokeMethod<String>('stopRecording');
        if (duration < 1 || path == null) return null;

        return VoiceRecordingResult(
          filePath: path,
          durationSeconds: duration,
          waveformData: [],
        );
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      return null;
    } finally {
      _startTime = null;
    }
  }

  Future<void> cancelRecording() async {
    _isRecording = false;
    if (kIsWeb) {
      await _webRecorder?.cancel();
    } else {
      await _channel.invokeMethod('cancelRecording');
    }
    _filePath = null;
    _startTime = null;
  }

  void dispose() {
    _webRecorder?.dispose();
  }
}

class VoiceRecordingResult {
  final String filePath;
  final int durationSeconds;
  final List<double> waveformData;
  final Uint8List? fileBytes;

  const VoiceRecordingResult({
    required this.filePath,
    required this.durationSeconds,
    required this.waveformData,
    this.fileBytes,
  });
}
