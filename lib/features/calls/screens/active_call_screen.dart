import 'dart:async';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/features/calls/services/call_signal_service.dart';
import 'package:moharek_app/features/calls/services/call_service.dart';
import 'package:moharek_app/features/calls/services/call_notification_service.dart';
import 'package:proximity_sensor/proximity_sensor.dart' if (dart.library.html) 'package:moharek_app/core/stubs/proximity_sensor_stub.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart' if (dart.library.html) 'package:moharek_app/core/stubs/callkit_stub.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ActiveCallScreen extends StatefulWidget {
  final Room? room; // Null if outgoing call initiated from this device
  final String callType; // 'video' or 'voice'
  final String? projectId;
  final String? callerName;
  final String? recipientName;
  final String? callerIdentity;
  final bool isOutgoing;
  final String? incomingSignalId;
  final VoidCallback? onCallConnected;

  const ActiveCallScreen({
    super.key,
    this.room,
    required this.callType,
    this.projectId,
    this.callerName,
    this.recipientName,
    this.callerIdentity,
    this.isOutgoing = false,
    this.incomingSignalId,
    this.onCallConnected,
  });

  @override
  State<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends State<ActiveCallScreen> {
  Room? _room;
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isSpeakerOn = false;
  bool _isConnectingRoom = true;
  bool _hasTriggeredConnected = false;
  DateTime? _connectedAt;

  // Duration timer
  int _seconds = 0;
  Timer? _timer;

  // Room event listener
  EventsListener<RoomEvent>? _roomListener;

  // Signal service for outgoing calls
  final _signalService = CallSignalService();
  String? _outgoingSignalId;
  StreamSubscription? _signalSub;
  bool _isHangingUp = false;

  @override
  void initState() {
    super.initState();

    CallNotificationService.isCallActive = true;

    _isSpeakerOn = (widget.callType == 'video');

    if (widget.callType == 'voice') {
      _isVideoOff = true;
    }

    if (widget.isOutgoing) {
      _initiateOutgoingCall();
    } else {
      _room = widget.room;
      _isConnectingRoom = false;
      
      if (widget.callType == 'voice') {
        try {
          _room?.localParticipant?.setCameraEnabled(false);
        } catch (e) {
          debugPrint('Warning: Failed to disable camera: $e');
        }
      }

      // Initialize speakerphone routing
      try {
        Helper.setSpeakerphoneOn(_isSpeakerOn);
        _room?.setSpeakerOn(_isSpeakerOn);
        if (widget.callType == 'voice' && !kIsWeb) {
          _enableProximitySensor(!_isSpeakerOn);
        }
      } catch (e) {
        debugPrint('Warning: Failed to initialize speakerphone routing: $e');
      }

      _setupRoomListeners();
    }

    // Start call timer
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_isConnectingRoom && _hasTriggeredConnected && _connectedAt != null) {
        setState(() => _seconds = DateTime.now().difference(_connectedAt!).inSeconds);
      }
    });
  }

  void _enableProximitySensor(bool enable) {
    if (kIsWeb) return;
    try {
      ProximitySensor.setProximityScreenOff(enable);
    } catch (e) {
      debugPrint('Error setting proximity sensor: $e');
    }
  }

  Future<void> _initiateOutgoingCall() async {
    try {
      // 1. Send call signal
      final signalId = await _signalService.sendCallSignal(
        projectId: widget.projectId!,
        callerName: widget.callerName!,
        callType: widget.callType,
      );
      if (!mounted) {
        await _signalService.declineCall(signalId);
        return;
      }
      setState(() => _outgoingSignalId = signalId);

      // 2. Watch signal status
      _signalSub = _signalService.watchSignal(signalId).listen((signal) async {
        final status = signal['status'] as String?;
        if (status == 'declined' || status == 'timeout') {
          _signalSub?.cancel();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  status == 'declined' ? 'تم رفض المكالمة' : 'لم يتم الرد على المكالمة',
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
                backgroundColor: Colors.red,
              ),
            );
            _safeExit();
          }
        }
      });

      // 3. Connect to LiveKit room
      final callService = CallService();
      final room = await callService.joinCall(
        'moharek-${widget.projectId}',
        widget.callerName!,
        widget.callerIdentity!,
        isVideo: widget.callType == 'video',
      );
      
      if (!mounted) {
        await room.disconnect();
        await room.dispose();
        return;
      }

      if (widget.callType == 'voice') {
        try {
          await room.localParticipant?.setCameraEnabled(false);
        } catch (_) {}
      }

      // Initialize speakerphone routing
      try {
        Hardware.instance.setSpeakerphoneOn(_isSpeakerOn);
        if (widget.callType == 'voice' && !kIsWeb) {
          _enableProximitySensor(!_isSpeakerOn);
        }
      } catch (e) {
        debugPrint('Warning: Failed to initialize speakerphone routing: $e');
      }

      setState(() {
        _room = room;
        _isConnectingRoom = false;
      });

      _setupRoomListeners();
    } catch (e) {
      debugPrint('Error initiating outgoing call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الاتصال: $e'), backgroundColor: Colors.red),
        );
        _safeExit();
      }
    }
  }

  void _onConnected() {
    if (_hasTriggeredConnected) return;
    final hasRemote = _room?.remoteParticipants.isNotEmpty ?? false;
    if (hasRemote) {
      _hasTriggeredConnected = true;
      _connectedAt = DateTime.now();
      widget.onCallConnected?.call();
    }
  }

  void _setupRoomListeners() {
    if (_room == null) return;
    _roomListener = _room!.createListener();
    _roomListener!
      ..on<ParticipantConnectedEvent>((_) {
        if (mounted) {
          setState(() {});
          _onConnected();
        }
      })
      ..on<ParticipantDisconnectedEvent>((_) {
        debugPrint('Participant disconnected - ending call');
        if (mounted) {
          _hangUp();
        }
      })
      ..on<TrackSubscribedEvent>((_) { if (mounted) setState(() {}); })
      ..on<TrackUnsubscribedEvent>((_) { if (mounted) setState(() {}); });

    // Handle case where remote participant is already connected
    _onConnected();
  }

  @override
  void dispose() {
    CallNotificationService.isCallActive = false;
    if (widget.callType == 'voice' && !kIsWeb) {
      _enableProximitySensor(false);
    }
    _timer?.cancel();
    _signalSub?.cancel();
    _roomListener?.dispose();
    _roomListener = null;
    if (_room != null) {
      _room!.disconnect();
      _room!.dispose();
      _room = null;
    }
    super.dispose();
  }

  void _toggleMute() async {
    final p = _room?.localParticipant;
    if (p == null) return;
    try {
      await p.setMicrophoneEnabled(_isMuted);
      if (mounted) setState(() => _isMuted = !_isMuted);
    } catch (e) {
      debugPrint('Error toggling microphone: $e');
    }
  }

  void _toggleVideo() async {
    final p = _room?.localParticipant;
    if (p == null) return;
    try {
      final nextVideoState = !_isVideoOff;
      if (nextVideoState) {
        // nextVideoState is true means we want to turn the video OFF.
        await p.setCameraEnabled(false);
      } else {
        // nextVideoState is false means we want to turn the video ON.
        await p.setCameraEnabled(
          true,
          cameraCaptureOptions: const CameraCaptureOptions(
            params: VideoParametersPresets.h720_169,
          ),
        );
      }
      if (mounted) {
        setState(() {
          _isVideoOff = nextVideoState;
          if (!_isVideoOff) {
            _isSpeakerOn = true;
            Hardware.instance.setSpeakerphoneOn(true);
            if (widget.callType == 'voice' && !kIsWeb) {
              _enableProximitySensor(false);
            }
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
      await Hardware.instance.setSpeakerphoneOn(target);
      if (widget.callType == 'voice' && !kIsWeb) {
        _enableProximitySensor(!target);
      }
      if (mounted) setState(() => _isSpeakerOn = target);
    } catch (e) {
      debugPrint('Error toggling speaker: $e');
    }
  }

  void _flipCamera() async {
    final track = _getLocalVideoTrack();
    if (track == null) return;
    try {
      await Helper.switchCamera(track.mediaStreamTrack);
    } catch (e) {
      debugPrint('Error switching camera: $e');
    }
  }

  void _hangUp() {
    if (_isHangingUp) return;
    _isHangingUp = true;

    CallNotificationService.isCallActive = false;
    if (widget.callType == 'voice' && !kIsWeb) {
      _enableProximitySensor(false);
    }

    _timer?.cancel();
    _signalSub?.cancel();

    // Exit immediately so that screen pops without waiting for network/LiveKit cleanup
    _safeExit();

    // Perform cleanup asynchronously in the background
    _cleanupCall();
  }

  Future<void> _cleanupCall() async {
    final signalId = widget.isOutgoing ? _outgoingSignalId : widget.incomingSignalId;
    try {
      if (signalId != null) {
        final hasRemote = _room?.remoteParticipants.isNotEmpty ?? false;
        // If it was an active call (has remote) or we are the callee, mark as ended. Otherwise, decline it.
        if (hasRemote || !widget.isOutgoing) {
          await _signalService.endCall(signalId);
        } else {
          await _signalService.declineCall(signalId);
        }
      }
    } catch (e) {
      debugPrint('Error ending call signal: $e');
    }

    if (!kIsWeb && signalId != null) {
      try {
        await FlutterCallkitIncoming.endCall(signalId);
      } catch (e) {
        debugPrint('Error ending native CallKit UI: $e');
      }
    }

    try {
      if (_room != null) {
        final roomToDispose = _room!;
        _room = null;
        _roomListener?.dispose();
        _roomListener = null;
        await roomToDispose.disconnect();
        await roomToDispose.dispose();
      }
    } catch (e) {
      debugPrint('Error disconnecting/disposing LiveKit room: $e');
    }
  }

  void _safeExit() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        context.go('/');
      }
    });
  }

  String get _durationLabel {
    if (widget.isOutgoing && !_hasTriggeredConnected) {
      final isAr = Localizations.localeOf(context).languageCode == 'ar';
      return isAr ? 'جاري الاتصال...' : 'Ringing...';
    }
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  VideoTrack? _getVideoTrack(RemoteParticipant p) {
    final pubs = p.videoTrackPublications;
    if (pubs.isEmpty) return null;
    final track = pubs.first.track;
    if (track is VideoTrack) return track;
    return null;
  }

  VideoTrack? _getLocalVideoTrack() {
    final pubs = _room?.localParticipant?.videoTrackPublications ?? [];
    if (pubs.isEmpty) return null;
    final track = pubs.first.track;
    if (track is VideoTrack) return track;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final remoteParticipants = _room?.remoteParticipants.values.toList() ?? [];
    final hasRemote = remoteParticipants.isNotEmpty;
    final localVideoTrack = _getLocalVideoTrack();

    // ── OUTGOING / RINGING STATE UI ──────────────────────────────────────────
    if (_isConnectingRoom || !hasRemote) {
      return Scaffold(
        backgroundColor: const Color(0xFF080B12), // Deep App theme dark
        body: SafeArea(
          child: Column(
            children: [
              // Top row: Back / Down arrow and Call type title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down, size: 36, color: Colors.white70),
                      onPressed: _hangUp,
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          widget.callType == 'video' 
                              ? (isAr ? 'مكالمة فيديو محرك' : 'MOHAREK VIDEO CALL')
                              : (isAr ? 'مكالمة صوتية محرك' : 'MOHAREK VOICE CALL'),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Spacer to balance back button
                  ],
                ),
              ),
              const Spacer(flex: 1),
              
              // Center avatar, recipient name, and ringing status
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withOpacity(0.08),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: AppTheme.primaryGreen.withOpacity(0.25),
                        width: 2.5,
                      ),
                    ),
                    child: const CircleAvatar(
                      radius: 62,
                      backgroundColor: Color(0xFF1E293B),
                      child: Icon(Icons.person, size: 70, color: Colors.white60),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    widget.recipientName ?? (isAr ? 'المتصل' : 'Contact'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isAr ? 'رنين...' : 'RINGING',
                    style: TextStyle(
                      color: AppTheme.primaryGreen.withOpacity(0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 2),

              // Decline / Hang Up Button
              GestureDetector(
                onTap: _hangUp,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444), // Vibrant Red
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFEF4444),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.call_end, color: Colors.white, size: 34),
                ),
              ),
              const SizedBox(height: 40),

              // Bottom control actions row
              Padding(
                padding: const EdgeInsets.only(bottom: 36.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (widget.callType == 'video') ...[
                      // Camera Flip
                      _RingControlButton(
                        icon: Icons.flip_camera_ios_outlined,
                        onTap: _flipCamera,
                      ),
                      // Video Toggle
                      _RingControlButton(
                        icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
                        color: _isVideoOff ? const Color(0xFFEF4444) : Colors.white12,
                        onTap: _toggleVideo,
                      ),
                    ] else ...[
                      // Speaker Toggle
                      _RingControlButton(
                        icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                        color: _isSpeakerOn ? AppTheme.primaryGreen : Colors.white12,
                        onTap: _toggleSpeaker,
                      ),
                    ],
                    // Mic Toggle
                    _RingControlButton(
                      icon: _isMuted ? Icons.mic_off : Icons.mic,
                      color: _isMuted ? const Color(0xFFEF4444) : Colors.white12,
                      onTap: _toggleMute,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── ACTIVE CALL STATE UI ──────────────────────────────────────────────────
    return Scaffold(
      backgroundColor: const Color(0xFF080B12),
      body: SafeArea(
        child: Stack(
          children: [
            // Remote Video or Avatar
            ...remoteParticipants.map((p) {
              final videoTrack = _getVideoTrack(p);
              if (videoTrack != null) {
                return Positioned.fill(
                  child: VideoTrackRenderer(videoTrack),
                );
              }
              // Audio-only Remote Participant UI
              return Positioned.fill(
                child: Container(
                  color: const Color(0xFF080B12),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primaryGreen.withOpacity(0.1),
                              width: 2,
                            ),
                          ),
                          child: const Icon(Icons.person, size: 55, color: Colors.white54),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          p.name.isNotEmpty ? p.name : (widget.recipientName ?? (isAr ? 'المتصل' : 'Contact')),
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            // Top bar (Timer & Info)
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
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

            // Local Video (PiP)
            if (!_isVideoOff && localVideoTrack != null)
              Positioned(
                top: 60, right: 16,
                width: 100, height: 140,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    color: Colors.black26,
                    child: VideoTrackRenderer(localVideoTrack),
                  ),
                ),
              ),

            // Controls overlay at the bottom
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ControlButton(
                      icon: _isMuted ? Icons.mic_off : Icons.mic,
                      label: _isMuted ? 'رفع الكتم' : 'كتم',
                      color: _isMuted ? const Color(0xFFEF4444) : Colors.white24,
                      onTap: _toggleMute,
                    ),
                    if (widget.callType == 'video') ...[
                      _ControlButton(
                        icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
                        label: _isVideoOff ? 'تشغيل الكاميرا' : 'إيقاف الكاميرا',
                        color: _isVideoOff ? const Color(0xFFEF4444) : Colors.white24,
                        onTap: _toggleVideo,
                      ),
                      _ControlButton(
                        icon: Icons.flip_camera_ios,
                        label: 'قلب',
                        color: Colors.white24,
                        onTap: _flipCamera,
                      ),
                    ],
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
                      color: const Color(0xFFEF4444),
                      size: 68,
                      onTap: _hangUp,
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

class _RingControlButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RingControlButton({
    required this.icon,
    this.color = Colors.white12,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 26),
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
