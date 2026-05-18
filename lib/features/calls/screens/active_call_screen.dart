import 'dart:async';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:moharek_app/core/theme/app_theme.dart';

class ActiveCallScreen extends StatefulWidget {
  final Room room;
  final String callType; // 'video' or 'voice'

  const ActiveCallScreen({
    super.key,
    required this.room,
    this.callType = 'video',
  });

  @override
  State<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends State<ActiveCallScreen> {
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isSpeakerOn = false;

  // Duration timer
  int _seconds = 0;
  Timer? _timer;

  // Room event listener
  late final EventsListener<RoomEvent> _roomListener;

  @override
  void initState() {
    super.initState();

    _isSpeakerOn = (widget.callType == 'video');

    if (widget.callType == 'voice') {
      _isVideoOff = true;
      try {
        widget.room.localParticipant?.setCameraEnabled(false);
      } catch (e) {
        debugPrint('Warning: Failed to disable camera: $e');
      }
    }

    // Initialize speakerphone routing
    try {
      Helper.setSpeakerphoneOn(_isSpeakerOn);
    } catch (e) {
      debugPrint('Warning: Failed to initialize speakerphone routing: $e');
    }

    // Start call timer
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });

    // Listen for participant changes to refresh UI
    _roomListener = widget.room.createListener();
    _roomListener
      ..on<ParticipantConnectedEvent>((_) { if (mounted) setState(() {}); })
      ..on<ParticipantDisconnectedEvent>((_) { if (mounted) setState(() {}); })
      ..on<TrackSubscribedEvent>((_) { if (mounted) setState(() {}); })
      ..on<TrackUnsubscribedEvent>((_) { if (mounted) setState(() {}); });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _roomListener.dispose();
    widget.room.disconnect();
    super.dispose();
  }

  void _toggleMute() async {
    final p = widget.room.localParticipant;
    if (p == null) return;
    try {
      await p.setMicrophoneEnabled(_isMuted);
      if (mounted) setState(() => _isMuted = !_isMuted);
    } catch (e) {
      debugPrint('Error toggling microphone: $e');
    }
  }

  void _toggleVideo() async {
    final p = widget.room.localParticipant;
    if (p == null) return;
    try {
      final nextVideoState = !_isVideoOff;
      await p.setCameraEnabled(nextVideoState);
      if (mounted) {
        setState(() {
          _isVideoOff = nextVideoState;
          if (!_isVideoOff) {
            // Force speaker ON when turning camera back on
            _isSpeakerOn = true;
            Helper.setSpeakerphoneOn(true);
          }
        });
      }
    } catch (e) {
      debugPrint('Error toggling camera: $e');
    }
  }

  void _toggleSpeaker() async {
    try {
      final target = !_isSpeakerOn;
      await Helper.setSpeakerphoneOn(target);
      if (mounted) setState(() => _isSpeakerOn = target);
    } catch (e) {
      debugPrint('Error toggling speaker: $e');
    }
  }

  String get _durationLabel {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Safely get first video track from a participant, or null
  VideoTrack? _getVideoTrack(RemoteParticipant p) {
    final pubs = p.videoTrackPublications;
    if (pubs.isEmpty) return null;
    final track = pubs.first.track;
    if (track is VideoTrack) return track;
    return null;
  }

  VideoTrack? _getLocalVideoTrack() {
    final pubs = widget.room.localParticipant?.videoTrackPublications ?? [];
    if (pubs.isEmpty) return null;
    final track = pubs.first.track;
    if (track is VideoTrack) return track;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final remoteParticipants = widget.room.remoteParticipants.values.toList();
    final hasRemote = remoteParticipants.isNotEmpty;
    final localVideoTrack = _getLocalVideoTrack();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Stack(
          children: [
            // ── Background / Remote video ──────────────────────────────
            if (!hasRemote)
              // Waiting state — nobody else in the room yet
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primaryGreen.withAlpha(80), width: 2),
                      ),
                      child: const Icon(Icons.person, size: 48, color: Colors.white54),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'في انتظار الطرف الآخر...',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const SizedBox(
                      width: 32,
                      child: LinearProgressIndicator(
                        color: AppTheme.primaryGreen,
                        backgroundColor: Colors.white12,
                      ),
                    ),
                  ],
                ),
              )
            else
              // Show first remote participant's video
              ...remoteParticipants.map((p) {
                final videoTrack = _getVideoTrack(p);
                if (videoTrack != null) {
                  return Positioned.fill(
                    child: VideoTrackRenderer(videoTrack),
                  );
                }
                // Audio-only remote participant
                return Positioned.fill(
                  child: Container(
                    color: const Color(0xFF0F172A),
                    child: Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          width: 96, height: 96,
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person, size: 48, color: Colors.white54),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          p.name.isNotEmpty ? p.name : 'المتصل',
                          style: const TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ]),
                    ),
                  ),
                );
              }),

            // ── Top bar: timer ─────────────────────────────────────────
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withAlpha(180), Colors.transparent],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _durationLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Local video (PiP) ─────────────────────────────────────
            if (!_isVideoOff && localVideoTrack != null)
              Positioned(
                top: 60, right: 16,
                width: 100, height: 140,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: VideoTrackRenderer(localVideoTrack),
                ),
              ),

            // ── Controls bar ───────────────────────────────────────────
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withAlpha(200), Colors.transparent],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ControlButton(
                      icon: _isMuted ? Icons.mic_off : Icons.mic,
                      label: _isMuted ? 'رفع الكتم' : 'كتم',
                      color: _isMuted ? Colors.red : Colors.white24,
                      onTap: _toggleMute,
                    ),
                    if (widget.callType == 'video')
                      _ControlButton(
                        icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
                        label: _isVideoOff ? 'تشغيل الكاميرا' : 'إيقاف الكاميرا',
                        color: _isVideoOff ? Colors.red : Colors.white24,
                        onTap: _toggleVideo,
                      ),
                    _ControlButton(
                      icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                      label: 'سماعة',
                      color: _isSpeakerOn ? AppTheme.primaryGreen : Colors.white24,
                      onTap: () {
                        if (widget.callType == 'video' && !_isVideoOff) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'لا يمكن إيقاف مكبر الصوت أثناء تشغيل الكاميرا',
                                style: TextStyle(fontFamily: 'monospace'),
                              ),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }
                        _toggleSpeaker();
                      },
                    ),
                    _ControlButton(
                      icon: Icons.call_end,
                      label: 'إنهاء',
                      color: Colors.red,
                      size: 68,
                      onTap: () {
                        if (mounted) Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double size;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    this.size = 56,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size, height: size,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: size * 0.45),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
