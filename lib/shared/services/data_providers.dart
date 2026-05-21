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

// ── Real-time Stream Providers ──

// Tasks (Stream)
final tasksProvider = StreamProvider.autoDispose<List<ProjectTask>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final projectAsync = ref.watch(currentProjectProvider);

  return projectAsync.when(
    data: (project) {
      if (project == null) return Stream.value([]);
      return client
          .from('tasks')
          .stream(primaryKey: ['id'])
          .eq('project_id', project.id)
          .order('created_at', ascending: false)
          .map((data) => data.map((json) => ProjectTask.fromJson(json)).toList());
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// Results (Stream)
final resultsProvider = StreamProvider.autoDispose<List<ResultMetric>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final projectAsync = ref.watch(currentProjectProvider);

  return projectAsync.when(
    data: (project) {
      if (project == null) return Stream.value([]);
      return client
          .from('results')
          .stream(primaryKey: ['id'])
          .eq('project_id', project.id)
          .order('recorded_at', ascending: false)
          .map((data) => data.map((json) => ResultMetric.fromJson(json)).toList());
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// Engine Progress (Stream)
final engineProgressListProvider = StreamProvider.autoDispose<List<EngineProgress>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final projectAsync = ref.watch(currentProjectProvider);

  return projectAsync.when(
    data: (project) {
      if (project == null) return Stream.value([]);
      return client
          .from('engine_progress')
          .stream(primaryKey: ['id'])
          .eq('project_id', project.id)
          .map((data) => data.map((json) => EngineProgress.fromJson(json)).toList());
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// Approvals (Stream)
final approvalsProvider = StreamProvider.autoDispose<List<ApprovalRequest>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final projectAsync = ref.watch(currentProjectProvider);

  return projectAsync.when(
    data: (project) {
      if (project == null) return Stream.value([]);
      return client
          .from('approvals')
          .stream(primaryKey: ['id'])
          .eq('project_id', project.id)
          .order('created_at', ascending: false)
          .map((data) => data.map((json) => ApprovalRequest.fromJson(json)).toList());
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// Journey Stages (Stream)
final journeyStagesProvider = StreamProvider.autoDispose<List<JourneyStage>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final projectAsync = ref.watch(currentProjectProvider);

  return projectAsync.when(
    data: (project) {
      if (project == null) return Stream.value([]);
      return client
          .from('journey_stages')
          .stream(primaryKey: ['id'])
          .eq('project_id', project.id)
          .order('order_index', ascending: true)
          .map((data) => data.map((json) => JourneyStage.fromJson(json)).toList());
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// Reports (Stream)
final reportsProvider = StreamProvider.autoDispose<List<ProjectReport>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final projectAsync = ref.watch(currentProjectProvider);

  return projectAsync.when(
    data: (project) {
      if (project == null) return Stream.value([]);
      return client
          .from('reports')
          .stream(primaryKey: ['id'])
          .eq('project_id', project.id)
          .order('created_at', ascending: false)
          .map((data) => data.map((json) => ProjectReport.fromJson(json)).toList());
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// Invoices (Stream)
final invoicesProvider = StreamProvider.autoDispose<List<Invoice>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final projectAsync = ref.watch(currentProjectProvider);

  return projectAsync.when(
    data: (project) {
      if (project == null) return Stream.value([]);
      return client
          .from('invoices')
          .stream(primaryKey: ['id'])
          .eq('project_id', project.id)
          .order('created_at', ascending: false)
          .map((data) => data.map((json) => Invoice.fromJson(json)).toList());
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// Contracts (Stream)
final contractsProvider = StreamProvider.autoDispose<List<Contract>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final projectAsync = ref.watch(currentProjectProvider);

  return projectAsync.when(
    data: (project) {
      if (project == null) return Stream.value([]);
      return client
          .from('contracts')
          .stream(primaryKey: ['id'])
          .eq('project_id', project.id)
          .order('created_at', ascending: false)
          .map((data) => data.map((json) => Contract.fromJson(json)).toList());
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// Files (Stream)
final filesProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final projectAsync = ref.watch(currentProjectProvider);

  return projectAsync.when(
    data: (project) {
      if (project == null) return Stream.value([]);
      return client
          .from('files')
          .stream(primaryKey: ['id'])
          .eq('project_id', project.id)
          .order('created_at', ascending: false);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// Meetings (Stream)
final meetingsProvider = StreamProvider.autoDispose<List<ProjectMeeting>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final projectAsync = ref.watch(currentProjectProvider);

  return projectAsync.when(
    data: (project) {
      if (project == null) return Stream.value([]);
      return client
          .from('meetings')
          .stream(primaryKey: ['id'])
          .eq('project_id', project.id)
          .order('scheduled_at', ascending: false)
          .map((data) => data.map((json) => ProjectMeeting.fromJson(json)).toList());
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// Support Tickets (Stream)
final ticketsProvider = StreamProvider.autoDispose<List<SupportTicket>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final projectAsync = ref.watch(currentProjectProvider);

  return projectAsync.when(
    data: (project) {
      if (project == null) return Stream.value([]);
      return client
          .from('support_tickets')
          .stream(primaryKey: ['id'])
          .eq('project_id', project.id)
          .order('created_at', ascending: false)
          .map((data) => data.map((json) => SupportTicket.fromJson(json)).toList());
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// Client-specific Activity Feed (Stream)
final clientActivityFeedProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final projectAsync = ref.watch(currentProjectProvider);

  return projectAsync.when(
    data: (project) {
      if (project == null) return Stream.value([]);
      return client
          .from('activity_feed')
          .stream(primaryKey: ['id'])
          .eq('project_id', project.id)
          .order('created_at', ascending: false)
          .limit(10);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// Support Ticket Messages (Stream)
final ticketMessagesProvider = StreamProvider.family.autoDispose<List<Map<String, dynamic>>, String>((ref, ticketId) {
  final client = ref.watch(supabaseClientProvider);
  return client
      .from('support_ticket_messages')
      .stream(primaryKey: ['id'])
      .eq('ticket_id', ticketId)
      .order('created_at', ascending: true);
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
      if (project == null) return Stream.value([]);
      return client
          .from('campaigns')
          .stream(primaryKey: ['id'])
          .eq('project_id', project.id)
          .order('created_at', ascending: false)
          .map((data) => data.map((json) => ProjectCampaign.fromJson(json)).toList());
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// Campaign Results (Stream)
final campaignResultsProvider = StreamProvider.family.autoDispose<List<CampaignResult>, String>((ref, campaignId) {
  final client = ref.watch(supabaseClientProvider);
  return client
      .from('campaign_results')
      .stream(primaryKey: ['id'])
      .eq('campaign_id', campaignId)
      .order('recorded_at', ascending: false)
      .map((data) => data.map((json) => CampaignResult.fromJson(json)).toList());
});

// Engine Progress (Stream) — provides a map of engine_type → progress (0.0-1.0)
final engineProgressMapProvider = StreamProvider.autoDispose<Map<String, double>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final projectAsync = ref.watch(currentProjectProvider);

  return projectAsync.when(
    data: (project) {
      if (project == null) return Stream.value({});
      return client
          .from('engine_progress')
          .stream(primaryKey: ['id'])
          .eq('project_id', project.id)
          .map((data) {
        final Map<String, double> result = {};
        for (var item in data) {
          // Column is 'engine_type' not 'engine', and 'progress' (0-100) not 'progress_percent'
          final engineType = item['engine_type'] as String? ?? item['engine'] as String? ?? '';
          final progressRaw = (item['progress'] ?? item['progress_percent'] ?? 0) as num;
          if (engineType.isNotEmpty) {
            result[engineType] = progressRaw.toDouble() / 100.0;
          }
        }
        return result;
      }).handleError((e) {
        // Non-fatal: return empty map on realtime errors
      });
    },
    loading: () => Stream.value({}),
    error: (_, __) => Stream.value({}),
  );
});

// End of file
