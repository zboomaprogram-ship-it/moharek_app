import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/shared/models/message.dart';
import 'package:moharek_app/shared/services/data_providers.dart';

// ─── Background isolate parser ───────────────────────────────────────────────
// Keeps all JSON parsing off the main thread — the root cause of the 97s ANR.
List<ChatMessage> _parseMessages(List<dynamic> raw) {
  return raw
      .map((json) => ChatMessage.fromJson(json as Map<String, dynamic>))
      .toList();
}

// ─── Messages provider ────────────────────────────────────────────────────────
// Uses Stream.periodic instead of while(true) — avoids tight loops.
// Parses JSON with compute() so the main thread is never blocked.
// ─── Messages Notifier ────────────────────────────────────────────────────────
// Handles pagination, polling, and background parsing.
class ChatMessagesNotifier extends AutoDisposeFamilyAsyncNotifier<List<ChatMessage>, String> {
  int _limit = 10;
  Timer? _timer;
  bool _isFetching = false;

  @override
  FutureOr<List<ChatMessage>> build(String arg) async {
    final messages = await _fetch(arg, _limit);
    
    // Start polling for new messages every 4 seconds
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _poll());
    
    ref.onDispose(() {
      _timer?.cancel();
    });
    
    return messages;
  }

  Future<List<ChatMessage>> _fetch(String channelId, int limit) async {
    final client = ref.read(supabaseClientProvider);
    if (channelId.isEmpty) return [];

    try {
      final raw = await client
          .from('messages')
          .select()
          .eq('channel_id', channelId)
          .order('created_at', ascending: false)
          .limit(limit);
      
      return await compute(_parseMessages, raw as List<dynamic>);
    } catch (e) {
      debugPrint('Error fetching messages: $e');
      return [];
    }
  }

  Future<void> _poll() async {
    if (_isFetching || state.isLoading) return;
    _isFetching = true;
    try {
      final messages = await _fetch(arg, _limit);
      if (state.hasValue && !listEquals(state.value, messages)) {
        state = AsyncData(messages);
      }
    } finally {
      _isFetching = false;
    }
  }

  Future<void> refresh() async {
    await _poll();
  }

  Future<void> loadMore() async {
    if (_isFetching || state.isLoading) return;
    _isFetching = true;
    _limit += 10;
    try {
      final messages = await _fetch(arg, _limit);
      state = AsyncData(messages);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    } finally {
      _isFetching = false;
    }
  }
}

final chatMessagesProvider =
    AsyncNotifierProvider.family.autoDispose<ChatMessagesNotifier, List<ChatMessage>, String>(
  ChatMessagesNotifier.new,
);

// ─── Message Sender ───────────────────────────────────────────────────────────
class ChatNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> sendMessage(String channelId, String content,
      {String messageType = 'text'}) async {
    final client = ref.read(supabaseClientProvider);
    final user = client.auth.currentUser;
    if (user == null || channelId.isEmpty) return;

    await client.from('messages').insert({
      'channel_id': channelId,
      'sender_id': user.id,
      'content': content,
      'message_type': messageType,
    });
  }
}

final chatNotifierProvider =
    AsyncNotifierProvider.autoDispose<ChatNotifier, void>(() => ChatNotifier());

// ─── Channel lookup ───────────────────────────────────────────────────────────
final chatChannelProvider = FutureProvider<String?>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final project = await ref.watch(currentProjectProvider.future);
  if (project == null) return null;

  final data = await client
      .from('chat_channels')
      .select('id')
      .eq('project_id', project.id)
      .maybeSingle();

  return data?['id'] as String?;
});
