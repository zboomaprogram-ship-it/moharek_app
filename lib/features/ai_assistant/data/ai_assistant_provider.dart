import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'dart:convert';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class AiAssistantState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  AiAssistantState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  AiAssistantState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return AiAssistantState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final aiAssistantProvider =
    StateNotifierProvider<AiAssistantNotifier, AiAssistantState>((ref) {
      return AiAssistantNotifier(ref);
    });

class AiAssistantNotifier extends StateNotifier<AiAssistantState> {
  final Ref _ref;
  AiAssistantNotifier(this._ref) : super(AiAssistantState());

  Future<void> sendMessage(String prompt) async {
    if (prompt.trim().isEmpty) return;

    final userMsg = ChatMessage(
      text: prompt,
      isUser: true,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      error: null,
    );

    try {
      final client = _ref.read(supabaseClientProvider);

      // Collect Context
      final project = _ref.read(currentProjectProvider).valueOrNull;
      final results =
          _ref.read(projectResultsProvider(project?.id ?? '')).valueOrNull ??
          [];
      final tasks =
          _ref.read(projectTasksProvider(project?.id ?? '')).valueOrNull ?? [];

      final context = {
        'project_name': project?.name,
        'current_stage': project?.currentStage,
        'recent_results': results.take(5).toList(),
        'recent_tasks': tasks.take(5).toList(),
        'engines':
            _ref.read(projectEnginesProvider(project?.id ?? '')).valueOrNull ??
            {},
      };

      final response = await client.functions.invoke(
        'ai-assistant',
        body: {
          'prompt': prompt,
          'context': context,
          'history': state.messages
              .map(
                (m) => {
                  'role': m.isUser ? 'user' : 'assistant',
                  'content': m.text,
                },
              )
              .toList(),
        },
      );

      if (response.status == 200) {
        final data = response.data;
        final aiMsg = ChatMessage(
          text: data['text'],
          isUser: false,
          timestamp: DateTime.now(),
        );
        state = state.copyWith(
          messages: [...state.messages, aiMsg],
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to get response from AI',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearHistory() {
    state = AiAssistantState();
  }
}
