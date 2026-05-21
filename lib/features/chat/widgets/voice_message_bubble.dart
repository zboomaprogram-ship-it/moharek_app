import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:moharek_app/core/theme/app_theme.dart';

class VoiceMessageBubble extends StatefulWidget {
  final String url;
  final int durationSeconds;
  final bool isMe;

  const VoiceMessageBubble({
    super.key,
    required this.url,
    required this.durationSeconds,
    required this.isMe,
  });

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  AudioPlayer? _player;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  StreamSubscription? _stateSub;
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _initAudio() async {
    if (_player != null || _isLoading) return;
    if (mounted) setState(() => _isLoading = true);
    
    try {
      final player = AudioPlayer();
      String audioUrl = widget.url;
      if (audioUrl.startsWith('http://')) {
        audioUrl = audioUrl.replaceFirst('http://', 'https://');
      }
      
      await player.setUrl(audioUrl);
      
      _stateSub = player.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing && state.processingState != ProcessingState.completed;
          });
        }
        if (state.processingState == ProcessingState.completed) {
          player.seek(Duration.zero);
          player.pause();
        }
      });
      
      _posSub = player.positionStream.listen((pos) {
        if (mounted) setState(() => _position = pos);
      });
      
      _durSub = player.durationStream.listen((dur) {
        if (mounted && dur != null) setState(() => _duration = dur);
      });
      
      _player = player;
    } catch (e) {
      debugPrint("Error loading audio: $e");
      _player = null;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _togglePlay() async {
    if (_player == null) {
      await _initAudio();
    }
    if (_player != null) {
      if (_isPlaying) {
        _player!.pause();
      } else {
        _player!.play();
      }
    }
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If _duration is zero, fallback to the database duration
    final displayDuration = _duration.inSeconds > 0 
        ? _formatDuration(_position) 
        : _formatDuration(Duration(seconds: widget.durationSeconds));

    final totalDuration = _duration.inSeconds > 0 
        ? _duration 
        : Duration(seconds: widget.durationSeconds);

    double progress = totalDuration.inMilliseconds > 0 
        ? _position.inMilliseconds / totalDuration.inMilliseconds 
        : 0.0;
        
    return Container(
      width: 240,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Play/Pause button
          GestureDetector(
            onTap: _togglePlay,
            child: _isLoading
                ? SizedBox(
                    width: 36,
                    height: 36,
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: widget.isMe ? Colors.white : AppTheme.primaryGreen,
                      ),
                    ),
                  )
                : Icon(
                    _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                    color: widget.isMe ? Colors.white : AppTheme.primaryGreen,
                    size: 36,
                  ),
          ),
          const SizedBox(width: 12),
          
          // Slider and Duration
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 2.0,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
                    activeTrackColor: widget.isMe ? Colors.white : AppTheme.primaryGreen,
                    inactiveTrackColor: widget.isMe ? Colors.white38 : Colors.grey.withValues(alpha: 0.3),
                    thumbColor: widget.isMe ? Colors.white : AppTheme.primaryGreen,
                  ),
                  child: Slider(
                    value: progress.clamp(0.0, 1.0),
                    onChanged: _isLoading ? null : (val) async {
                      if (_player == null) {
                        await _initAudio();
                      }
                      if (_player != null) {
                        final pos = Duration(milliseconds: (val * totalDuration.inMilliseconds).round());
                        _player!.seek(pos);
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    displayDuration,
                    style: TextStyle(
                      color: widget.isMe ? Colors.white70 : Colors.grey,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
