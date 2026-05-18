import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/features/calls/services/call_signal_service.dart';
import 'package:moharek_app/features/calls/widgets/incoming_call_overlay.dart';
import 'package:moharek_app/features/calls/services/call_service.dart';
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

  @override
  void initState() {
    super.initState();
    // Start listening immediately if the user is already authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final profile = ref.read(profileProvider).value;
        if (profile != null) {
          _startListening();
        }
      }
    });
  }

  void _startListening() {
    _sub?.cancel();
    _sub = _signalService.watchAllIncomingCalls().listen((signals) {
      if (signals.isNotEmpty && _activeSignal == null) {
        setState(() => _activeSignal = signals.first);
      } else if (signals.isEmpty && _activeSignal != null) {
        // Signal gone (caller cancelled or timeout)
        setState(() => _activeSignal = null);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onAccept() async {
    if (_activeSignal == null) return;
    final signal = _activeSignal!;
    final signalId = signal['id'];
    final roomName = signal['room_name'];
    final callType = signal['call_type'];
    final callerName = signal['caller_name'];

    setState(() => _activeSignal = null);

    await _signalService.acceptCall(signalId);

    try {
      final callService = CallService();
      final profile = ref.read(profileProvider).value;
      final room = await callService.joinCall(
        roomName,
        profile?.fullName ?? 'User',
        profile?.id ?? 'user',
      );

      if (!mounted) return;

      // Navigate using the root navigator key
      rootNavigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => ActiveCallScreen(room: room, callType: callType),
        ),
      );
    } catch (e) {
      debugPrint('Error joining call: $e');
    }
  }

  void _onDecline() async {
    if (_activeSignal == null) return;
    await _signalService.declineCall(_activeSignal!['id']);
    setState(() => _activeSignal = null);
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
        }
      }
    });

    return Stack(
      children: [
        widget.child,
        if (_activeSignal != null)
          IncomingCallOverlay(
            signal: _activeSignal!,
            onAccept: _onAccept,
            onDecline: _onDecline,
          ),
      ],
    );
  }
}
