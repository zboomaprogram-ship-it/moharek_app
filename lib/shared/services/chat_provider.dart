import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/shared/models/message.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:postgrest/postgrest.dart';

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
          // Merge: keep any optimistic messages not yet confirmed by the server,
          // then prepend the server list (which is the source of truth).
          final optimistics = (state.valueOrNull ?? [])
              .where((m) => m.id.startsWith('opt_'))
              .toList();
          final serverIds = parsed.map((m) => m.content).toSet();
          // Only keep optimistics whose content hasn't appeared in server list yet
          final pendingOptimistics = optimistics
              .where((m) => !serverIds.contains(m.content))
              .toList();
          state = AsyncData([...pendingOptimistics, ...parsed]);
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

  /// Instantly adds a message to local state (optimistic UI).
  /// The Realtime stream will replace state with the confirmed DB row shortly after.
  void addOptimistic(ChatMessage message) {
    final current = state.valueOrNull ?? [];
    // Avoid duplicates if stream fires before optimistic is shown
    if (current.any((m) => m.id == message.id)) return;
    state = AsyncData([message, ...current]);
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

  Future<void> sendMessage(
    String channelId,
    String content, {
    String messageType = 'text',
    String? replyToId,
    String? replyToContent,
    String? replyToSenderName,
  }) async {
    final client = ref.read(supabaseClientProvider);
    final user = client.auth.currentUser;
    if (user == null) {
      debugPrint('❌ [Chat] sendMessage: user is null — not authenticated');
      return;
    }
    if (channelId.isEmpty) {
      debugPrint('❌ [Chat] sendMessage: channelId is empty — no channel found for this project');
      return;
    }

    try {
      await client.from('messages').insert({
        'channel_id': channelId,
        'sender_id': user.id,
        'content': content,
        'message_type': messageType,
        'payload': replyToId != null ? {
          'reply_to_id': replyToId,
          'reply_to_content': replyToContent,
          'reply_to_sender_name': replyToSenderName,
        } : null,
      });
      debugPrint('✅ [Chat] Message sent successfully');
    } on PostgrestException catch (e) {
      debugPrint('❌ [Chat] PostgrestException sending message:');
      debugPrint('   code   : ${e.code}');
      debugPrint('   message: ${e.message}');
      debugPrint('   details: ${e.details}');
      debugPrint('   hint   : ${e.hint}');
      rethrow;
    } catch (e) {
      debugPrint('❌ [Chat] Unexpected error sending message: $e');
      rethrow;
    }
  }
}

final chatNotifierProvider =
    AsyncNotifierProvider.autoDispose<ChatNotifier, void>(() => ChatNotifier());

// ─── Channel lookup (auto-creates if missing) ─────────────────────────────────
final chatChannelProvider = FutureProvider<String?>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final project = await ref.watch(currentProjectProvider.future);
  if (project == null) {
    debugPrint('❌ [Chat] chatChannelProvider: no project found');
    return null;
  }

  try {
    // Uses SECURITY DEFINER RPC that auto-creates the channel if missing
    final result = await client
        .rpc('get_or_create_chat_channel', params: {'p_project_id': project.id});

    final channelId = result?.toString();
    debugPrint('✅ [Chat] channel resolved: $channelId (project: ${project.id})');
    return channelId;
  } catch (e) {
    debugPrint('❌ [Chat] chatChannelProvider error: $e');
    // Fallback: try direct select
    try {
      final data = await client
          .from('chat_channels')
          .select('id')
          .eq('project_id', project.id)
          .maybeSingle();
      return data?['id'] as String?;
    } catch (_) {
      return null;
    }
  }
});
