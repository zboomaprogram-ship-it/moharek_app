import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/features/calls/services/call_signal_service.dart';

class IncomingCallOverlay extends StatefulWidget {
  final Map<String, dynamic> signal;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const IncomingCallOverlay({
    super.key,
    required this.signal,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<IncomingCallOverlay> createState() => _IncomingCallOverlayState();
}

class _IncomingCallOverlayState extends State<IncomingCallOverlay> {
  int _secondsLeft = 30;
  Timer? _timer;
  final _signalService = CallSignalService();
  final _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsLeft > 0) {
            _secondsLeft--;
          } else {
            _timer?.cancel();
            _onTimeout();
          }
        });
      }
    });

    _playRingtone();
  }

  Future<void> _playRingtone() async {
    try {
      await _audioPlayer.setUrl('https://assets.mixkit.co/active_storage/sfx/903/903-84.wav');
      await _audioPlayer.setLoopMode(LoopMode.one);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing ringtone: $e');
    }
  }

  void _onTimeout() async {
    await _signalService.timeoutCall(widget.signal['id']);
    widget.onDecline();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final callerName = widget.signal['caller_name'] ?? (isAr ? 'متصل' : 'Caller');
    final callType = widget.signal['call_type'] == 'video' 
        ? (isAr ? 'فيديو' : 'Video') 
        : (isAr ? 'صوتية' : 'Voice');

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: -150.0, end: 0.0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, value),
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white, // Classic Premium White Card
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isAr ? 'مكالمة $callType واردة' : 'Incoming $callType Call',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          callerName,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, size: 28, color: Colors.white54),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  // Decline Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.onDecline,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF43F5E), // Rose / Red
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: Text(
                        isAr ? 'رفض' : 'Decline',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Accept Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981), // Emerald / Green
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: Text(
                        isAr ? 'قبول' : 'Accept',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
