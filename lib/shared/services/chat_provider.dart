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
  int _limit = 20;
  StreamSubscription<List<Map<String, dynamic>>>? _streamSub;
  bool _isFetching = false;
  bool _hasMore = true;

  bool get hasMore => _hasMore;

  @override
  FutureOr<List<ChatMessage>> build(String arg) async {
    _limit = 20;
    _hasMore = true;

    _setupStreamSubscription();

    ref.onDispose(() {
      _streamSub?.cancel();
    });

    final messages = await _fetch(arg, _limit);
    if (messages.length < _limit) {
      _hasMore = false;
    }
    return messages;
  }

  void _setupStreamSubscription() {
    _streamSub?.cancel();
    final client = ref.read(supabaseClientProvider);
    
    _streamSub = client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('channel_id', arg)
        .order('created_at', ascending: false)
        .limit(_limit)
        .map((data) {
          final sorted = List<Map<String, dynamic>>.from(data);
          sorted.sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
          return sorted;
        })
        .listen((data) async {
          final parsed = kIsWeb 
              ? data.map((json) => ChatMessage.fromJson(json)).toList()
              : await compute(_parseMessages, data);
              
          if (parsed.length < _limit) {
            _hasMore = false;
          }
          state = AsyncData(parsed);
        }, onError: (e) {
          debugPrint('Real-time Stream Error: $e');
        });
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
      
      if (kIsWeb) {
        return (raw as List<dynamic>)
            .map((json) => ChatMessage.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        return await compute(_parseMessages, raw as List<dynamic>);
      }
    } catch (e) {
      debugPrint('Error fetching messages: $e');
      return [];
    }
  }

  Future<void> refresh() async {
    if (_isFetching) return;
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

  Future<void> loadMore() async {
    if (!_hasMore || _isFetching || state.isLoading) return;
    _isFetching = true;
    _limit += 15;
    try {
      final messages = await _fetch(arg, _limit);
      if (messages.length < _limit) {
        _hasMore = false;
      }
      
      _setupStreamSubscription();
      
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
