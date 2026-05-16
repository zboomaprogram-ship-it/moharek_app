import 'dart:async';
import 'package:flutter/material.dart';
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

class _IncomingCallOverlayState extends State<IncomingCallOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  int _secondsLeft = 30;
  Timer? _timer;
  final _signalService = CallSignalService();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          _timer?.cancel();
          _onTimeout();
        }
      });
    });
  }

  void _onTimeout() async {
    await _signalService.timeoutCall(widget.signal['id']);
    widget.onDecline();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final callerName = widget.signal['caller_name'] ?? 'متصل';
    final callType = widget.signal['call_type'] == 'video' ? 'فيديو' : 'صوتية';

    return Material(
      color: Colors.black.withValues(alpha: 0.9),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            // Caller Avatar
            ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 1.1).animate(
                CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
              ),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryGreen, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.person, size: 60, color: Colors.white),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              callerName,
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'مكالمة $callType واردة...',
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const Spacer(),
            // Countdown ring
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: _secondsLeft / 30,
                    strokeWidth: 4,
                    color: AppTheme.primaryGreen,
                    backgroundColor: Colors.white10,
                  ),
                ),
                Text(
                  '$_secondsLeft',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 60),
            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Decline
                  _CallActionButton(
                    icon: Icons.call_end,
                    color: Colors.red,
                    label: 'رفض',
                    onTap: widget.onDecline,
                  ),
                  // Accept
                  _CallActionButton(
                    icon: widget.signal['call_type'] == 'video' ? Icons.videocam : Icons.call,
                    color: AppTheme.primaryGreen,
                    label: 'قبول',
                    onTap: widget.onAccept,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _CallActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _CallActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      ],
    );
  }
}
