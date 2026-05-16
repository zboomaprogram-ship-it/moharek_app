import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/features/chat/services/voice_recorder_service.dart';
import 'package:moharek_app/l10n/app_localizations.dart';

class VoiceRecordButton extends StatefulWidget {
  final VoiceRecorderService recorderService;
  final Function(VoiceRecordingResult) onRecordingComplete;
  final Function(bool) onRecordingToggle;
  final bool isRtl;

  const VoiceRecordButton({
    super.key,
    required this.recorderService,
    required this.onRecordingComplete,
    required this.onRecordingToggle,
    required this.isRtl,
  });

  @override
  State<VoiceRecordButton> createState() => _VoiceRecordButtonState();
}

class _VoiceRecordButtonState extends State<VoiceRecordButton>
    with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  bool _isCancelling = false;
  double _dragOffset = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  int _seconds = 0;
  Timer? _timer;
  
  // Custom Waveform data
  final List<double> _bars = [];
  static const int _maxBars = 30;
  static const double _cancelThreshold = 100;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
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
      if (!kIsWeb) HapticFeedback.mediumImpact();
      
      widget.onRecordingToggle(true);
      _safeState(() {
        _isRecording = true;
        _isCancelling = false;
        _dragOffset = 0;
        _seconds = 0;
        _bars.clear();
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
        final newSample = widget.recorderService.lastAmplitude;

        _safeState(() {
          if (ticks % 10 == 0) _seconds++;
          if (_bars.length >= _maxBars) _bars.removeAt(0);
          _bars.add(newSample);
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

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    _timer?.cancel();
    _timer = null;
    widget.onRecordingToggle(false);

    if (_isCancelling) {
      await widget.recorderService.cancelRecording();
      if (!kIsWeb) HapticFeedback.lightImpact();
      _safeState(() {
        _isRecording = false;
        _isCancelling = false;
        _dragOffset = 0;
        _bars.clear();
      });
    } else {
      final result = await widget.recorderService.stopRecording();
      _safeState(() {
        _isRecording = false;
        _isCancelling = false;
        _dragOffset = 0;
        _bars.clear();
      });
      if (result != null) {
        if (!kIsWeb) HapticFeedback.lightImpact();
        widget.onRecordingComplete(result);
      }
    }
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_isRecording) return;
    _safeState(() {
      final delta = widget.isRtl ? details.delta.dx : -details.delta.dx;
      _dragOffset = (_dragOffset + delta).clamp(0, double.infinity);
      _isCancelling = _dragOffset > _cancelThreshold;
    });
    if (_isCancelling && !kIsWeb) HapticFeedback.selectionClick();
  }

  String get _durationLabel {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onLongPressStart: (_) => _startRecording(),
      onLongPressEnd: (_) => _stopRecording(),
      onLongPressMoveUpdate: (details) => _onDragUpdate(
        DragUpdateDetails(
          globalPosition: details.globalPosition,
          delta: details.offsetFromOrigin,
          localPosition: details.localPosition,
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _isRecording ? _buildRecordingState(l10n) : _buildIdleState(),
      ),
    );
  }

  Widget _buildIdleState() {
    return Container(
      key: const ValueKey('idle'),
      width: 48, height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.mic, color: Color(0xFF4CAF50), size: 24),
    );
  }

  Widget _buildRecordingState(AppLocalizations l10n) {
    return Container(
      key: const ValueKey('recording'),
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(26),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: _isCancelling ? Colors.red : const Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _durationLabel,
            style: const TextStyle(
              color: Colors.white, fontSize: 13, fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _isCancelling
                ? Text(
                    l10n.recordingCancelled,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  )
                : _buildWaveform(),
          ),
          const SizedBox(width: 8),
          if (!_isCancelling)
            Expanded(
              child: Stack(
                alignment: widget.isRtl ? Alignment.centerLeft : Alignment.centerRight,
                children: [
                  Opacity(
                    opacity: (1 - (_dragOffset / _cancelThreshold)).clamp(0.0, 1.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.isRtl ? Icons.chevron_right : Icons.chevron_left,
                          color: Colors.grey, size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.swipeToCancel,
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  // Progress indicator of the slide
                  Positioned(
                    left: widget.isRtl ? _dragOffset : null,
                    right: !widget.isRtl ? _dragOffset : null,
                    child: Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
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

  Widget _buildWaveform() {
    return LayoutBuilder(builder: (ctx, constraints) {
      final width = constraints.maxWidth;
      final barWidth = (width / _maxBars).clamp(2.0, 6.0);

      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(_bars.length, (i) {
          final height = (_bars[i] * 30).clamp(4.0, 30.0);
          return Container(
            width: barWidth - 1,
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 0.5),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }
}
