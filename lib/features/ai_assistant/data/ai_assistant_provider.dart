import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      final results = _ref.read(resultsProvider).valueOrNull ?? [];
      final tasks = _ref.read(tasksProvider).valueOrNull ?? [];
      final engines = _ref.read(engineProgressListProvider).valueOrNull ?? [];
      final invoices = _ref.read(invoicesProvider).valueOrNull ?? [];
      final contracts = _ref.read(contractsProvider).valueOrNull ?? [];
      final files = _ref.read(filesProvider).valueOrNull ?? [];
      final meetings = _ref.read(meetingsProvider).valueOrNull ?? [];

      final context = {
        'project_name': project?.name,
        'project_goal': project?.projectGoal,
        'current_stage': project?.currentStage,
        'client_brief': project?.clientBrief,
        'recent_results': results.take(10).map((r) => {
          'result_type': r.resultType,
          'metric_name': r.metricName,
          'metric_label': r.metricLabel,
          'metric_value': r.metricValue,
          'metric_unit': r.metricUnit,
          'change_from_last': r.changeFromLast,
          'notes': r.notes,
          'recorded_at': r.recordedAt.toIso8601String(),
        }).toList(),
        'recent_tasks': tasks.take(10).map((t) => {
          'title': t.title,
          'description': t.description,
          'status': t.status,
          'priority': t.priority,
          'category': t.category,
          'stage_name': t.stageName,
          'deadline': t.deadline?.toIso8601String(),
          'is_client_request': t.isClientRequest,
          'request_type': t.requestType,
          'client_proposed_deadline': t.clientProposedDeadline?.toIso8601String(),
        }).toList(),
        'engines': engines.map((e) => e.toJson()).toList(),
        'recent_invoices': invoices.take(5).map((i) => {
          'invoice_number': i.invoiceNumber,
          'amount': i.amount,
          'currency': i.currency,
          'status': i.status,
          'due_date': i.dueDate?.toIso8601String(),
        }).toList(),
        'recent_contracts': contracts.take(5).map((c) => {
          'title': c.title,
          'status': c.status,
          'signed_at': c.signedAt?.toIso8601String(),
          'created_at': c.createdAt.toIso8601String(),
        }).toList(),
        'recent_files': files.take(10).toList(),
        'upcoming_meetings': meetings.take(5).map((m) => {
          'title': m.title,
          'title_ar': m.titleAr,
          'scheduled_at': m.scheduledAt?.toIso8601String(),
          'duration_minutes': m.durationMinutes,
          'meeting_type': m.meetingType,
          'status': m.status,
          'agenda': m.agenda,
          'summary': m.summary,
          'action_items': m.actionItems,
        }).toList(),
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
