import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:moharek_app/shared/models/profile.dart';
import 'package:moharek_app/shared/models/project.dart';
import 'package:moharek_app/shared/models/task.dart';
import 'package:moharek_app/shared/models/result.dart';
import 'package:moharek_app/shared/models/financials.dart';
import 'package:moharek_app/shared/models/report.dart';
import 'package:moharek_app/shared/models/approval.dart';
import 'package:moharek_app/shared/models/contract.dart';
import 'package:moharek_app/shared/models/journey_stage.dart';
import 'package:moharek_app/shared/models/milestone.dart';
import 'package:moharek_app/shared/models/engine_progress.dart';
import 'package:moharek_app/shared/models/campaign.dart';
import 'package:moharek_app/shared/models/meeting.dart';
import 'package:moharek_app/shared/models/support.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Watch the Supabase Auth State
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

// Current User Profile
final profileProvider = FutureProvider<Profile?>((ref) async {
  // Watch auth state - when it changes, this provider automatically re-runs
  ref.watch(authStateProvider);

  final client = ref.watch(supabaseClientProvider);
  final user = client.auth.currentUser;
  if (user == null) return null;

  // Use maybeSingle to avoid PGRST116 crash if profile doesn't exist yet
  Map<String, dynamic>? data;
  try {
    data = await client.from('profiles').select().eq('id', user.id).maybeSingle();
  } catch (_) {
    data = null;
  }

  if (data == null) {
    // Auto-create the profile row so push notifications can target this user
    final metaName = user.userMetadata?['full_name']?.toString() ??
                     user.userMetadata?['name']?.toString() ??
                     user.email?.split('@').first ?? '';
    try {
      await client.from('profiles').insert({
        'id': user.id,
        'email': user.email,
        'full_name': metaName,
        'role': 'client',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Row may already exist (race condition) — ignore
    }
    return Profile(
      id: user.id,
      email: user.email,
      fullName: metaName,
      createdAt: DateTime.now(),
      role: 'client',
    );
  }

  final profile = Profile.fromJson(data);
  // Always ensure the email from auth is present
  return profile.copyWith(email: user.email);
});


// Current Project
final currentProjectProvider = FutureProvider<Project?>((ref) async {
  // Watch auth state to clear on logout
  ref.watch(authStateProvider);
  
  final client = ref.watch(supabaseClientProvider);
  final user = client.auth.currentUser;
  if (user == null) return null;
  
  final data = await client.from('projects').select().eq('client_id', user.id).maybeSingle();
  if (data == null) return null;
  return Project.fromJson(data);
});

Stream<List<T>> robustQueryStream<T>({
  required SupabaseClient client,
  required String table,
  String? filterColumn,
  dynamic filterValue,
  required T Function(Map<String, dynamic>) fromJson,
  String? orderColumn,
  bool ascending = false,
  int? limit,
}) {
  final controller = StreamController<List<T>>.broadcast();
  StreamSubscription? sub;
  Timer? pollTimer;
  bool isPolling = false;

  Future<void> doPoll() async {
    try {
      dynamic query = client.from(table).select();
      if (filterColumn != null && filterValue != null) {
        query = query.eq(filterColumn, filterValue);
      }
      if (orderColumn != null) {
        query = query.order(orderColumn, ascending: ascending);
      }
      if (limit != null) {
        query = query.limit(limit);
      }
      final data = await query;
      final list = (data as List).map<T>((json) => fromJson(json as Map<String, dynamic>)).toList().cast<T>();
      if (!controller.isClosed) {
        controller.add(list);
      }
    } catch (e) {
      if (!controller.isClosed) {
        controller.addError(e);
      }
    }
  }

  void startPolling() {
    if (isPolling) return;
    isPolling = true;
    sub?.cancel();
    sub = null;
    
    debugPrint('⚠️ Falling back to polling for table: $table');
    doPoll();
    pollTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      doPoll();
    });
  }

  void startRealtime() {
    try {
      dynamic streamQuery = client
          .from(table)
          .stream(primaryKey: ['id']);
      
      if (filterColumn != null && filterValue != null) {
        streamQuery = streamQuery.eq(filterColumn, filterValue);
      }
      if (orderColumn != null) {
        streamQuery = streamQuery.order(orderColumn, ascending: ascending);
      }
      if (limit != null) {
        streamQuery = streamQuery.limit(limit);
      }

      sub = streamQuery.listen(
        (data) {
          final list = data.map<T>((json) => fromJson(json as Map<String, dynamic>)).toList().cast<T>();
          if (!controller.isClosed) {
            controller.add(list);
          }
        },
        onError: (err) {
          debugPrint('🚨 Realtime stream error on $table: $err. Switching to fallback polling.');
          startPolling();
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('🚨 Failed to start realtime stream on $table: $e. Switching to fallback polling.');
      startPolling();
    }
  }

  startRealtime();

  controller.onCancel = () {
    sub?.cancel();
    pollTimer?.cancel();
    controller.close();
  };

  return controller.stream;
}

// ── Real-time Stream Providers ──

// Tasks (Stream)
final tasksProvider = StreamProvider.autoDispose<List<ProjectTask>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final projectAsync = ref.watch(currentProjectProvider);

  return projectAsync.when(
    data: (project) {
      if (project == null) return Stream<List<ProjectTask>>.value(<ProjectTask>[]);
      return robustQueryStream<ProjectTask>(
        client: client,
        table: 'tasks',
        filterColumn: 'project_id',
        filterValue: project.id,
        fromJson: ProjectTask.fromJson,
        orderColumn: 'created_at',
        ascending: false,
      );
    },
    loading: () => Stream<List<ProjectTask>>.value(<ProjectTask>[]),
    error: (_, __) => Stream<List<ProjectTask>>.value(<ProjectTask>[]),
  );
});

// Results (Stream)
final resultsProvider = StreamProvider.autoDispose<List<ResultMetric>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final projectAsync = ref.watch(currentProjectProvider);

  return projectAsync.when(
    data: (project) {
      if (project == null) return Stream<List<ResultMetric>>.value(<ResultMetric>[]);
      return robustQueryStream<ResultMetric>(
        client: client,
        table: 'results',
        filterColumn: 'project_id',
        filterValue: project.id,
        fromJson: ResultMetric.fromJson,
        orderColumn: 'recorded_at',
        ascending: false,
      );
    },
    loading: () => Stream<List<ResultMetric>>.value(<ResultMetric>[]),
    error: (_, __) => Stream<List<ResultMetric>>.value(<ResultMetric>[]),
  );
});

// Engine Progress (Stream)
final engineProgressListProvider = StreamProvider.autoDispose<List<EngineProgress>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final projectAsync = ref.watch(currentProjectProvider);

  return projectAsync.when(
    data: (project) {
      if (project == null) return Stream<List<EngineProgress>>.value(<EngineProgress>[]);
      return robustQueryStream<EngineProgress>(
        client: client,
        table: 'engine_progress',
        filterColumn: 'project_id',
        filterValue: project.id,
        fromJson: EngineProgress.fromJson,
      );
    },
    loading: () => Stream<List<EngineProgress>>.value(<EngineProgress>[]),
    error: (_, __) => Stream<List<EngineProgress>>.value(<EngineProgress>[]),
  );
});

// Approvals (Stream)
final approvalsProvider = StreamProvider.autoDispose<List<ApprovalRequest>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final projectAsync = ref.watch(currentProjectProvider);

  return projectAsync.when(
    data: (project) {
      if (project == null) return Stream<List<ApprovalRequest>>.value(<ApprovalRequest>[]);
      return robustQueryStream<ApprovalRequest>(
        client: client,
        table: 'approvals',
        filterColumn: 'project_id',
        filterValue: project.id,
        fromJson: ApprovalRequest.fromJson,
        orderColumn: 'created_at',
        ascending: false,
      );
    },
    loading: () => Stream<List<ApprovalRequest>>.value(<ApprovalRequest>[]),
    error: (_, __) => Stream<List<ApprovalRequest>>.value(<ApprovalRequest>[]),
  );
});

// Journey Stages (Stream)
final journeyStagesProvider = StreamProvider.autoDispose<List<JourneyStage>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final projectAsync = ref.watch(currentProjectProvider);

  return projectAsync.when(
    data: (project) {
      if (project == null) return Stream<List<JourneyStage>>.value(<JourneyStage>[]);
      return robustQueryStream<JourneyStage>(
        client: client,
        table: 'journey_stages',
        filterColumn: 'project_id',
        filterValue: project.id,
        fromJson: JourneyStage.fromJson,
        orderColumn: 'order_index',
        ascending: true,
      );
    },
    loading: () => Stream<List<JourneyStage>>.value(<JourneyStage>[]),
    error: (_, __) => Stream<List<JourneyStage>>.value(<JourneyStage>[]),
  );
});

// Reports (Stream)
final reportsProvider = StreamProvider.autoDispose<List<ProjectReport>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final projectAsync = ref.watch(currentProjectProvider);

  return projectAsync.when(
    data: (project) {
      if (project == null) return Stream<List<ProjectReport>>.value(<ProjectReport>[]);
      return robustQueryStream<ProjectReport>(
        client: client,
        table: 'reports',
        filterColumn: 'project_id',
        filterValue: project.id,
        fromJson: ProjectReport.fromJson,
        orderColumn: 'created_at',
        ascending: false,
      );
    },
    loading: () => Stream<List<ProjectReport>>.value(<ProjectReport>[]),
    error: (_, __) => Stream<List<ProjectReport>>.value(<ProjectReport>[]),
  );
});

// Invoices (Stream)
final invoicesProvider = StreamProvider.autoDispose<List<Invoice>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final projectAsync = ref.watch(currentProjectProvider);

  return projectAsync.when(
    data: (project) {
      if (project == null) return Stream<List<Invoice>>.value(<Invoice>[]);
      return robustQueryStream<Invoice>(
        client: client,
        table: 'invoices',
        filterColumn: 'project_id',
        filterValue: project.id,
        fromJson: Invoice.fromJson,
        orderColumn: 'created_at',
        ascending: false,
      );
    },
    loading: () => Stream<List<Invoice>>.value(<Invoice>[]),
    error: (_, __) => Stream<List<Invoice>>.value(<Invoice>[]),
  );
});

// Contracts (Stream)
final contractsProvider = StreamProvider.autoDispose<List<Contract>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final projectAsync = ref.watch(currentProjectProvider);

  return projectAsync.when(
    data: (project) {
      if (project == null) return Stream<List<Contract>>.value(<Contract>[]);
      return robustQueryStream<Contract>(
        client: client,
        table: 'contracts',
        filterColumn: 'project_id',
        filterValue: project.id,
        fromJson: Contract.fromJson,
        orderColumn: 'created_at',
        ascending: false,
      );
    },
    loading: () => Stream<List<Contract>>.value(<Contract>[]),
    error: (_, __) => Stream<List<Contract>>.value(<Contract>[]),
  );
});

// Files (Stream)
final filesProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final projectAsync = ref.watch(currentProjectProvider);

  return projectAsync.when(
    data: (project) {
      if (project == null) return Stream<List<Map<String, dynamic>>>.value(<Map<String, dynamic>>[]);
      return robustQueryStream<Map<String, dynamic>>(
        client: client,
        table: 'files',
        filterColumn: 'project_id',
        filterValue: project.id,
        fromJson: (json) => json,
        orderColumn: 'created_at',
        ascending: false,
      );
    },
    loading: () => Stream<List<Map<String, dynamic>>>.value(<Map<String, dynamic>>[]),
    error: (_, __) => Stream<List<Map<String, dynamic>>>.value(<Map<String, dynamic>>[]),
  );
});

// Meetings (Stream)
final meetingsProvider = StreamProvider.autoDispose<List<ProjectMeeting>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final projectAsync = ref.watch(currentProjectProvider);

  return projectAsync.when(
    data: (project) {
      if (project == null) return Stream<List<ProjectMeeting>>.value(<ProjectMeeting>[]);
      return robustQueryStream<ProjectMeeting>(
        client: client,
        table: 'meetings',
        filterColumn: 'project_id',
        filterValue: project.id,
        fromJson: ProjectMeeting.fromJson,
        orderColumn: 'scheduled_at',
        ascending: false,
      );
    },
    loading: () => Stream<List<ProjectMeeting>>.value(<ProjectMeeting>[]),
    error: (_, __) => Stream<List<ProjectMeeting>>.value(<ProjectMeeting>[]),
  );
});

// Support Tickets (Stream)
final ticketsProvider = StreamProvider.autoDispose<List<SupportTicket>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final projectAsync = ref.watch(currentProjectProvider);

  return projectAsync.when(
    data: (project) {
      if (project == null) return Stream<List<SupportTicket>>.value(<SupportTicket>[]);
      return robustQueryStream<SupportTicket>(
        client: client,
        table: 'support_tickets',
        filterColumn: 'project_id',
        filterValue: project.id,
        fromJson: SupportTicket.fromJson,
        orderColumn: 'created_at',
        ascending: false,
      );
    },
    loading: () => Stream<List<SupportTicket>>.value(<SupportTicket>[]),
    error: (_, __) => Stream<List<SupportTicket>>.value(<SupportTicket>[]),
  );
});

// Client-specific Activity Feed (Stream)
final clientActivityFeedProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final projectAsync = ref.watch(currentProjectProvider);

  return projectAsync.when(
    data: (project) {
      if (project == null) return Stream<List<Map<String, dynamic>>>.value(<Map<String, dynamic>>[]);
      return robustQueryStream<Map<String, dynamic>>(
        client: client,
        table: 'activity_feed',
        filterColumn: 'project_id',
        filterValue: project.id,
        fromJson: (json) => json,
        orderColumn: 'created_at',
        ascending: false,
        limit: 10,
      );
    },
    loading: () => Stream<List<Map<String, dynamic>>>.value(<Map<String, dynamic>>[]),
    error: (_, __) => Stream<List<Map<String, dynamic>>>.value(<Map<String, dynamic>>[]),
  );
});

// Support Ticket Messages (Stream)
final ticketMessagesProvider = StreamProvider.family.autoDispose<List<Map<String, dynamic>>, String>((ref, ticketId) {
  final client = ref.watch(supabaseClientProvider);
  return robustQueryStream<Map<String, dynamic>>(
    client: client,
    table: 'support_ticket_messages',
    filterColumn: 'ticket_id',
    filterValue: ticketId,
    fromJson: (json) => json,
    orderColumn: 'created_at',
    ascending: true,
  );
});


// Milestones (Polling Future)
final milestonesProvider = FutureProvider.autoDispose<List<Milestone>>((ref) async {
  // Watch auth state to clear on logout
  ref.watch(authStateProvider);
  
  final client = ref.watch(supabaseClientProvider);
  final user = client.auth.currentUser;
  if (user == null) return [];

  final data = await client
      .from('milestones')
      .select()
      .order('created_at', ascending: false);
      
  return (data as List).map((json) => Milestone.fromJson(json)).toList();
});


// Campaigns (Stream)
final campaignsProvider = StreamProvider.autoDispose<List<ProjectCampaign>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final projectAsync = ref.watch(currentProjectProvider);

  return projectAsync.when(
    data: (project) {
      if (project == null) return Stream<List<ProjectCampaign>>.value(<ProjectCampaign>[]);
      return robustQueryStream<ProjectCampaign>(
        client: client,
        table: 'campaigns',
        filterColumn: 'project_id',
        filterValue: project.id,
        fromJson: ProjectCampaign.fromJson,
        orderColumn: 'created_at',
        ascending: false,
      );
    },
    loading: () => Stream<List<ProjectCampaign>>.value(<ProjectCampaign>[]),
    error: (_, __) => Stream<List<ProjectCampaign>>.value(<ProjectCampaign>[]),
  );
});

// Campaign Results (Stream)
final campaignResultsProvider = StreamProvider.family.autoDispose<List<CampaignResult>, String>((ref, campaignId) {
  final client = ref.watch(supabaseClientProvider);
  return robustQueryStream<CampaignResult>(
    client: client,
    table: 'campaign_results',
    filterColumn: 'campaign_id',
    filterValue: campaignId,
    fromJson: CampaignResult.fromJson,
    orderColumn: 'recorded_at',
    ascending: false,
  );
});

// Engine Progress (Stream) — provides a map of engine_type → progress (0.0-1.0)
final engineProgressMapProvider = StreamProvider.autoDispose<Map<String, double>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final projectAsync = ref.watch(currentProjectProvider);

  return projectAsync.when(
    data: (project) {
      if (project == null) return Stream<Map<String, double>>.value(<String, double>{});
      return robustQueryStream<Map<String, dynamic>>(
        client: client,
        table: 'engine_progress',
        filterColumn: 'project_id',
        filterValue: project.id,
        fromJson: (json) => json,
      ).map((data) {
        final Map<String, double> result = {};
        for (var item in data) {
          final engineType = item['engine_type'] as String? ?? item['engine'] as String? ?? '';
          final progressRaw = (item['progress'] ?? item['progress_percent'] ?? 0) as num;
          if (engineType.isNotEmpty) {
            result[engineType] = progressRaw.toDouble() / 100.0;
          }
        }
        return result;
      });
    },
    loading: () => Stream<Map<String, double>>.value(<String, double>{}),
    error: (_, __) => Stream<Map<String, double>>.value(<String, double>{}),
  );
});

// End of file
