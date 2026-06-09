import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/features/chat/services/voice_recorder_service.dart';
import 'package:moharek_app/l10n/app_localizations.dart';
import 'package:moharek_app/shared/services/haptic_service.dart';

class VoiceRecordButton extends StatefulWidget {
  final VoiceRecorderService recorderService;
  final Function(VoiceRecordingResult) onRecordingComplete;
  final bool isRtl;
  final Widget child;
  final bool isTyping;
  final VoidCallback onSendTap;

  const VoiceRecordButton({
    super.key,
    required this.recorderService,
    required this.onRecordingComplete,
    required this.isRtl,
    required this.child,
    required this.isTyping,
    required this.onSendTap,
  });

  @override
  State<VoiceRecordButton> createState() => _VoiceRecordButtonState();
}

class _VoiceRecordButtonState extends State<VoiceRecordButton>
    with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  bool _isLocked = false;
  bool _isCancelling = false;
  double _dragOffset = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  int _seconds = 0;
  Timer? _timer;
  
  static const double _cancelThreshold = 80;
  static const double _lockThreshold = 80;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _safeState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  Future<void> _startRecording() async {
    try {
      await widget.recorderService.startRecording();
      if (!mounted) return;
      if (!kIsWeb) HapticService.medium();
      
      _safeState(() {
        _isRecording = true;
        _isLocked = false;
        _isCancelling = false;
        _dragOffset = 0;
        _seconds = 0;
      });

      int ticks = 0;
      _timer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
        if (!mounted) {
          _timer?.cancel();
          return;
        }
        await widget.recorderService.collectAmplitudeSample();
        if (!mounted) {
          _timer?.cancel();
          return;
        }
        
        ticks++;
        _safeState(() {
          if (ticks % 10 == 0) _seconds++;
        });
      });
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.micPermissionDenied)),
        );
      }
    }
  }

  Future<void> _stopRecording({required bool send}) async {
    if (!_isRecording) return;

    _timer?.cancel();
    _timer = null;

    if (!send) {
      await widget.recorderService.cancelRecording();
      if (!kIsWeb) HapticService.light();
      _safeState(() {
        _isRecording = false;
        _isLocked = false;
        _isCancelling = false;
        _dragOffset = 0;
      });
    } else {
      final result = await widget.recorderService.stopRecording();
      _safeState(() {
        _isRecording = false;
        _isLocked = false;
        _isCancelling = false;
        _dragOffset = 0;
      });
      if (result != null) {
        if (!kIsWeb) HapticService.light();
        widget.onRecordingComplete(result);
      }
    }
  }

  void _onDragUpdate(Offset offsetFromOrigin) {
    if (!_isRecording || _isLocked) return;
    
    final dx = offsetFromOrigin.dx;
    final dy = offsetFromOrigin.dy;

    // Drag left to cancel (dx is negative)
    if (dx < -_cancelThreshold) {
      _stopRecording(send: false);
      return;
    }
    
    // Drag up to lock (dy is negative)
    if (dy < -_lockThreshold) {
      HapticService.medium();
      _safeState(() {
        _isLocked = true;
        _dragOffset = 0;
        _isCancelling = false;
      });
      return;
    }
    
    _safeState(() {
      _dragOffset = dx.abs();
      _isCancelling = dx < -20;
    });
  }

  String get _durationLabel {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.isRtl;
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: _isRecording ? const Color(0xFF1E293B) : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
          ),
          padding: EdgeInsets.symmetric(horizontal: _isRecording ? 12 : 0),
          child: Row(
            children: [
              // Left & Middle panel
              Expanded(
                child: Stack(
                  alignment: isAr ? Alignment.centerRight : Alignment.centerLeft,
                  children: [
                    // The text field child (visible when not recording)
                    Opacity(
                      opacity: _isRecording ? 0.0 : 1.0,
                      child: IgnorePointer(
                        ignoring: _isRecording,
                        child: widget.child,
                      ),
                    ),
                    
                    // Recording Overlay status
                    if (_isRecording)
                      Positioned.fill(
                        child: _buildRecordingOverlay(l10n, isAr),
                      ),
                  ],
                ),
              ),
              
              // Right side Send / Mic Button
              _buildRightActionButton(l10n),
            ],
          ),
        ),
        
        // Floating Lock Indicator when holding
        if (_isRecording && !_isLocked) _buildFloatingLockIndicator(),
      ],
    );
  }

  Widget _buildRightActionButton(AppLocalizations l10n) {
    if (widget.isTyping && !_isRecording) {
      // Normal typing state: Send button
      return GestureDetector(
        onTap: widget.onSendTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: AppTheme.primaryGreen,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.send, color: Colors.black, size: 24),
        ),
      );
    }

    if (_isRecording && _isLocked) {
      // Locked recording state: Send button
      return GestureDetector(
        onTap: () => _stopRecording(send: true),
        child: Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: AppTheme.primaryGreen,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.send, color: Colors.black, size: 24),
        ),
      );
    }

    // Default: Mic button (idle or long pressing)
    return GestureDetector(
      onLongPressStart: (_) => _startRecording(),
      onLongPressEnd: (_) => _stopRecording(send: !_isCancelling),
      onLongPressMoveUpdate: (details) => _onDragUpdate(details.offsetFromOrigin),
      child: _buildMicButton(),
    );
  }

  Widget _buildMicButton() {
    return ScaleTransition(
      scale: _isRecording ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _isRecording ? Colors.redAccent : const Color(0xFF1E293B),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.mic,
          color: _isRecording ? Colors.white : AppTheme.primaryGreen,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildRecordingOverlay(AppLocalizations l10n, bool isAr) {
    final widgets = <Widget>[];

    if (_isLocked) {
      // Locked Mode: Red Trash bin button on the left (or right if RTL)
      widgets.add(
        GestureDetector(
          onTap: () => _stopRecording(send: false),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
          ),
        ),
      );
      widgets.add(const Spacer());
      
      // Timer in the middle
      widgets.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBlinkingDot(),
            const SizedBox(width: 8),
            Text(
              _durationLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      );
      widgets.add(const Spacer());
    } else {
      // Holding Mode: red dot + timer on left, cancel slider in middle
      widgets.add(_buildBlinkingDot());
      widgets.add(const SizedBox(width: 8));
      widgets.add(
        Text(
          _durationLabel,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      );
      widgets.add(const SizedBox(width: 24));
      widgets.add(
        Expanded(
          child: _buildCancelSlider(l10n, isAr),
        ),
      );
    }

    return Row(
      children: isAr ? widgets.reversed.toList() : widgets,
    );
  }

  Widget _buildBlinkingDot() {
    return _BlinkingDot();
  }

  Widget _buildCancelSlider(AppLocalizations l10n, bool isAr) {
    return Transform.translate(
      offset: Offset(-_dragOffset, 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAr ? Icons.chevron_right : Icons.chevron_left,
            color: Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            l10n.swipeToCancel,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingLockIndicator() {
    return Positioned(
      bottom: 64,
      right: widget.isRtl ? null : 15,
      left: widget.isRtl ? 15 : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, color: Colors.white70, size: 18),
          const SizedBox(height: 4),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -_pulseController.value * 8),
                child: child,
              );
            },
            child: const Icon(
              Icons.keyboard_arrow_up,
              color: Colors.white54,
              size: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }
}

class _BlinkingDot extends StatefulWidget {
  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
