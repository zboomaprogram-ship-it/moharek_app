import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Manages call signaling via the `call_signals` Supabase table.
/// 
/// Flow:
/// 1. Caller inserts a row with status='ringing'
/// 2. Callee listens for rows where their project_id matches
/// 3. Callee accepts (status='accepted') or declines (status='declined')
/// 4. Caller watches the status change and joins LiveKit if accepted
/// 5. After 30 seconds, if still 'ringing', status auto-updates to 'timeout'
class CallSignalService {
  final _supabase = Supabase.instance.client;

  /// Timeout duration for unanswered calls
  static const callTimeout = Duration(seconds: 30);

  /// Send a call signal (insert a ringing row)
  /// Returns the signal ID
  Future<String> sendCallSignal({
    required String projectId,
    required String callerName,
    required String callType, // 'voice' or 'video'
  }) async {
    final userId = _supabase.auth.currentUser!.id;
    final roomName = 'moharek-$projectId';

    final result = await _supabase.from('call_signals').insert({
      'project_id': projectId,
      'caller_id': userId,
      'caller_name': callerName,
      'call_type': callType,
      'room_name': roomName,
      'status': 'ringing',
    }).select().single();

    return result['id'] as String;
  }

  /// Listen for status changes on a specific signal (used by the caller)
  Stream<Map<String, dynamic>> watchSignal(String signalId) {
    return Stream.periodic(const Duration(seconds: 1)).asyncMap((_) async {
      try {
        final data = await _supabase
            .from('call_signals')
            .select()
            .eq('id', signalId)
            .maybeSingle();
        return data ?? <String, dynamic>{};
      } catch (_) {
        return <String, dynamic>{};
      }
    });
  }

  /// Listen for incoming calls for a specific project (used by the callee)
  Stream<List<Map<String, dynamic>>> watchIncomingCalls(String projectId) {
    final currentUserId = _supabase.auth.currentUser?.id;
    return Stream.periodic(const Duration(seconds: 2)).asyncMap((_) async {
      final data = await _supabase
          .from('call_signals')
          .select()
          .eq('project_id', projectId)
          .eq('status', 'ringing');
      return (data as List)
          .cast<Map<String, dynamic>>()
          .where((s) => s['caller_id'] != currentUserId)
          .toList();
    });
  }

  /// Listen for ALL incoming calls for the current user (across all projects)
  Stream<List<Map<String, dynamic>>> watchAllIncomingCalls() {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return const Stream.empty();

    return Stream.periodic(const Duration(seconds: 2)).asyncMap((_) async {
      try {
        final cutoff = DateTime.now().toUtc()
            .subtract(const Duration(seconds: 35))
            .toIso8601String();
        final data = await _supabase
            .from('call_signals')
            .select()
            .eq('status', 'ringing')
            .neq('caller_id', currentUserId)
            .gte('created_at', cutoff)
            .order('created_at', ascending: false)
            .limit(5);
        return (data as List).cast<Map<String, dynamic>>();
      } catch (_) {
        return <Map<String, dynamic>>[];
      }
    });
  }

  /// Accept a call
  Future<void> acceptCall(String signalId) async {
    await _supabase.from('call_signals')
        .update({'status': 'accepted'})
        .eq('id', signalId);
  }

  /// Decline a call
  Future<void> declineCall(String signalId) async {
    await _supabase.from('call_signals')
        .update({'status': 'declined'})
        .eq('id', signalId);
  }

  /// Timeout a call (called after 30s)
  Future<void> timeoutCall(String signalId) async {
    // Only update if still ringing
    await _supabase.from('call_signals')
        .update({'status': 'timeout'})
        .eq('id', signalId)
        .eq('status', 'ringing');
  }

  /// End a call
  Future<void> endCall(String signalId) async {
    await _supabase.from('call_signals')
        .update({'status': 'ended'})
        .eq('id', signalId);
  }

  /// Clean up old signals (optional, called on app start)
  Future<void> cleanupOldSignals() async {
    try {
      final cutoff = DateTime.now().toUtc().subtract(const Duration(minutes: 2)).toIso8601String();
      await _supabase.from('call_signals')
          .delete()
          .lt('created_at', cutoff);
    } catch (e) {
      debugPrint('Cleanup old signals error: $e');
    }
  }
}
