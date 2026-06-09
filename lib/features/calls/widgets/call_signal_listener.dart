import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_callkeep/flutter_callkeep.dart';
import 'package:moharek_app/features/calls/services/call_signal_service.dart';
import 'package:moharek_app/features/calls/widgets/incoming_call_overlay.dart';
import 'package:moharek_app/features/calls/services/call_service.dart';
import 'package:moharek_app/features/calls/services/call_notification_service.dart';
import 'package:moharek_app/features/calls/screens/active_call_screen.dart';
import 'package:moharek_app/shared/models/profile.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/core/router/app_router.dart';

class CallSignalListener extends ConsumerStatefulWidget {
  final Widget child;
  const CallSignalListener({super.key, required this.child});

  @override
  ConsumerState<CallSignalListener> createState() => _CallSignalListenerState();
}

class _CallSignalListenerState extends ConsumerState<CallSignalListener> {
  final _signalService = CallSignalService();
  StreamSubscription? _sub;
  Map<String, dynamic>? _activeSignal;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final profile = ref.read(profileProvider).value;
        if (profile != null) {
          _startListening();
        }
      }
    });
  }

  void _showWebIncomingCallOverlay(Map<String, dynamic> signal) {
    _hideWebIncomingCallOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          child: IncomingCallOverlay(
            signal: signal,
            onAccept: _onAccept,
            onDecline: _onDecline,
          ),
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final overlayState = rootNavigatorKey.currentState?.overlay;
      if (overlayState != null && _overlayEntry != null) {
        overlayState.insert(_overlayEntry!);
      }
    });
  }

  void _hideWebIncomingCallOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  void _startListening() {
    _sub?.cancel();
    _sub = _signalService.watchAllIncomingCalls().listen((signals) {
      if (signals.isNotEmpty) {
        final signal = signals.first;
        if (_activeSignal == null || _activeSignal!['id'] != signal['id']) {
          setState(() => _activeSignal = signal);
          
          if (!kIsWeb) {
            // Mobile: Display native incoming calling UI (ConnectionService/CallKit)
            CallNotificationService.handleIncomingCallPush(signal);
          } else {
            // Web: Show custom overlay card
            _showWebIncomingCallOverlay(signal);
          }
        }
      } else {
        if (_activeSignal != null) {
          final oldSignalId = _activeSignal!['id'];
          setState(() => _activeSignal = null);
          
          if (!kIsWeb) {
            // Mobile: Cancel native incoming UI if caller hung up
            CallKeep.instance.endCall(oldSignalId);
          } else {
            // Web: Remove custom overlay card
            _hideWebIncomingCallOverlay();
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _hideWebIncomingCallOverlay();
    super.dispose();
  }

  void _onAccept() async {
    if (_activeSignal == null) return;
    final signal = _activeSignal!;
    final signalId = signal['id'];
    final roomName = signal['room_name'];
    final callType = signal['call_type'];

    setState(() => _activeSignal = null);
    if (kIsWeb) {
      _hideWebIncomingCallOverlay();
    }

    await _signalService.acceptCall(signalId);

    try {
      final callService = CallService();
      final profile = ref.read(profileProvider).value;
      final room = await callService.joinCall(
        roomName,
        profile?.fullName ?? 'User',
        profile?.id ?? 'user',
        isVideo: callType == 'video',
      );

      if (!mounted) return;

      rootNavigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => ActiveCallScreen(
            room: room, 
            callType: callType,
            incomingSignalId: signalId,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error joining call: $e');
    }
  }

  void _onDecline() async {
    if (_activeSignal == null) return;
    final signalId = _activeSignal!['id'];
    setState(() => _activeSignal = null);
    if (kIsWeb) {
      _hideWebIncomingCallOverlay();
    }
    await _signalService.declineCall(signalId);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<Profile?>>(profileProvider, (prev, next) {
      final user = next.value;
      if (user != null) {
        _startListening();
      } else {
        _sub?.cancel();
        _sub = null;
        if (mounted && _activeSignal != null) {
          setState(() => _activeSignal = null);
          if (kIsWeb) {
            _hideWebIncomingCallOverlay();
          }
        }
      }
    });

    return widget.child;
  }
}
