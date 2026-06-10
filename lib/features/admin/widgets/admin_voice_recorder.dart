import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:moharek_app/shared/services/wordpress_upload_service.dart';

class AdminVoiceRecorder extends ConsumerStatefulWidget {
  final String projectId;
  final Function(String url) onComplete;

  const AdminVoiceRecorder({
    super.key,
    required this.projectId,
    required this.onComplete,
  });

  @override
  ConsumerState<AdminVoiceRecorder> createState() => _AdminVoiceRecorderState();
}

class _AdminVoiceRecorderState extends ConsumerState<AdminVoiceRecorder> {
  late AudioRecorder _recorder;
  bool _isRecording = false;
  bool _isUploading = false;
  String? _path;

  @override
  void initState() {
    super.initState();
    _recorder = AudioRecorder();
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        _path = '${dir.path}/voice_update_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _recorder.start(const RecordConfig(), path: _path!);
        setState(() => _isRecording = true);
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stop();
      setState(() => _isRecording = false);
      if (path != null) {
        _uploadRecording(path);
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  Future<void> _uploadRecording(String path) async {
    setState(() => _isUploading = true);
    try {
      final fileName = 'voice_${widget.projectId}_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final url = await WordPressUploadService.uploadFile(path, fileName);
      
      final actions = ref.read(adminActionsProvider);
      await actions.createVoiceUpdate({
        'project_id': widget.projectId,
        'file_url': url,
        'title': 'Growth Update ${DateTime.now().day}/${DateTime.now().month}',
      });
      
      widget.onComplete(url);
    } catch (e) {
      debugPrint('Error uploading: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Record Growth Update',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Keep it short and punchy for the client dashboard',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: () {
              final isAr = Localizations.localeOf(context).languageCode == 'ar';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isAr ? 'اضغط مطولاً للتسجيل' : 'Please press and hold the button to record.'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            onLongPressStart: (_) => _startRecording(),
            onLongPressEnd: (_) => _stopRecording(),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _isRecording ? Colors.redAccent : AppTheme.primaryGreen,
                shape: BoxShape.circle,
                boxShadow: [
                  if (_isRecording)
                    BoxShadow(color: Colors.redAccent.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 5),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: _isRecording ? Colors.white : Colors.black,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _isRecording ? 'Recording... Release to stop' : 'Long press to record',
            style: TextStyle(color: _isRecording ? Colors.redAccent : Colors.grey),
          ),
          if (_isUploading) ...[
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: AppTheme.primaryGreen),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
