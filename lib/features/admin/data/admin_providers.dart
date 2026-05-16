import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final adminClientFilterProvider = StateProvider<String>((ref) => 'all');

final allPendingTasksProvider = FutureProvider<int>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final data = await client.from('tasks').select('id').eq('status', 'todo');
  return (data as List).length;
});

final allPendingApprovalsProvider = FutureProvider<int>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final data = await client
      .from('approvals')
      .select('id')
      .eq('status', 'pending');
  return (data as List).length;
});

final allPendingContractsProvider = FutureProvider<int>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final data = await client
      .from('contracts')
      .select('id')
      .eq('status', 'pending');
  return (data as List).length;
});

final allPendingInvoicesProvider = FutureProvider<int>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final data = await client
      .from('invoices')
      .select('id')
      .eq('status', 'unpaid');
  return (data as List).length;
});

final allAmsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final data = await client
      .from('profiles')
      .select()
      .eq('role', 'account_manager')
      .order('full_name');
  return (data as List).cast<Map<String, dynamic>>();
});

final allProjectsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final client = ref.watch(supabaseClientProvider);
  final data = await client
      .from('projects')
      .select('*, profiles!projects_client_id_fkey(full_name, company_name)')
      .order('name');
  return (data as List).cast<Map<String, dynamic>>();
});

class AdminStats {
  final int totalClients;
  final int activeClients;
  final int totalAMs;
  final double avgHealthScore;

  AdminStats({
    required this.totalClients,
    required this.activeClients,
    required this.totalAMs,
    required this.avgHealthScore,
  });
}

class AmPerformance {
  final String amId;
  final String name;
  final String? avatarUrl;
  final int totalClients;
  final double avgHealthScore;
  final int tasksCreated;
  final int tasksCompleted;
  final double clientSatisfactionAvg;
  final double avgResponseTimeHours;

  AmPerformance({
    required this.amId,
    required this.name,
    this.avatarUrl,
    required this.totalClients,
    required this.avgHealthScore,
    required this.tasksCreated,
    required this.tasksCompleted,
    required this.clientSatisfactionAvg,
    required this.avgResponseTimeHours,
  });
}

final adminOverviewProvider = FutureProvider<AdminStats>((ref) async {
  final client = ref.watch(supabaseClientProvider);

  // 1. Get client counts
  final projectsRes = await client
      .from('projects')
      .select('id, status, health_score');
  final projects = projectsRes as List;

  // 2. Get AM count
  final ams = await client
      .from('profiles')
      .select('id')
      .eq('role', 'account_manager');
  final amCount = ams.length;

  int active = 0;
  double totalHealth = 0;
  for (var p in projects) {
    if (p['status'] == 'active') active++;
    totalHealth += (p['health_score'] ?? 0).toDouble();
  }

  return AdminStats(
    totalClients: projects.length,
    activeClients: active,
    totalAMs: amCount,
    avgHealthScore: projects.isNotEmpty ? totalHealth / projects.length : 0,
  );
});

final amPerformanceListProvider = FutureProvider<List<AmPerformance>>((
  ref,
) async {
  final client = ref.watch(supabaseClientProvider);

  // In a real app, we'd join with am_performance table
  // For now, we'll aggregate from projects and profiles
  final amsRes = await client
      .from('profiles')
      .select('id, full_name, avatar_url')
      .eq('role', 'account_manager');
  final ams = amsRes as List;

  List<AmPerformance> results = [];

  for (var am in ams) {
    final projectsRes = await client
        .from('projects')
        .select('id, health_score')
        .eq('account_manager_id', am['id']);
    final projects = projectsRes as List;

    double totalHealth = 0;
    for (var p in projects) {
      totalHealth += (p['health_score'] ?? 0).toDouble();
    }

    final tasksRes = await client
        .from('tasks')
        .select('status')
        .eq('assigned_to', am['id']);
    final tasks = tasksRes as List;
    final completedTasks = tasks
        .where((t) => t['status'] == 'completed')
        .length;

    results.add(
      AmPerformance(
        amId: am['id'],
        name: am['full_name'] ?? 'Unknown AM',
        avatarUrl: am['avatar_url'],
        totalClients: projects.length,
        avgHealthScore: projects.isNotEmpty ? totalHealth / projects.length : 0,
        tasksCreated: tasks.length,
        tasksCompleted: completedTasks,
        clientSatisfactionAvg: 4.8,
        avgResponseTimeHours: 2.5,
      ),
    );
  }

  return results;
});

final allTicketsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client
      .from('support_tickets')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false);
});

final teamListProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final client = ref.watch(supabaseClientProvider);
  final data = await client
      .from('profiles')
      .select()
      .filter(
        'role',
        'in',
        '("account_manager", "seo_team", "ads_team", "content_team", "design_team", "tech_team", "admin")',
      )
      .order('full_name', ascending: true);
  return List<Map<String, dynamic>>.from(data);
});

final adminActionsProvider = Provider((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AdminActions(client);
});

class AdminActions {
  final SupabaseClient client;
  AdminActions(this.client);

  /// Sends an in-app Arabic notification to the client of a project.
  /// The DB trigger on `notifications` will fire the OneSignal push automatically.
  Future<void> _notify({
    required String projectId,
    required String titleAr,
    required String bodyAr,
    required String type,
    String? linkPath,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      // Get client_id for this project
      final proj = await client
          .from('projects')
          .select('client_id')
          .eq('id', projectId)
          .maybeSingle();
      final clientId = proj?['client_id'];
      if (clientId == null) return;

      await client.from('notifications').insert({
        'user_id': clientId,
        'title_ar': titleAr,
        'title_en': titleAr, // same for now
        'body_ar': bodyAr,
        'body_en': bodyAr,
        'type': type,
        'link_path': linkPath,
        'metadata': metadata,
        'is_read': false,
      });
    } catch (_) {} // Non-blocking — never let notification failure break the action
  }

  Future<void> inviteUser({
    required String email,
    required String role,
    String? assignedAmId,
    String? projectId,
  }) async {
    await client.from('invitations').insert({
      'email': email,
      'invited_role': role,
      'invited_by': client.auth.currentUser!.id,
      'assigned_am_id': assignedAmId,
      'project_id': projectId,
    });
  }

  Future<void> createTeamMember(Map<String, dynamic> data) async {
    final response = await client.functions.invoke(
      'create-client', // Same edge function handles team members
      body: {
        'email': data['email'],
        'password': data['password'],
        'full_name': data['fullName'],
        'role': data['role'],
        'project_ids': data['projectIds'],
        'is_team': true,
      },
    );if (response.status != 200) {
      final errorMsg = response.data?['error'] ?? 'فشل في إنشاء الحساب';
      throw Exception(errorMsg);
    }

    // Log the action (non-critical, don't let it break the flow)
    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'تم إضافة عضو فريق جديد: ${data['fullName']} (${data['role']})',
        'target_type': 'profile',
      });
    } catch (_) {}
  }

  Future<void> toggleUserStatus(String userId, bool active) async {
    await client
        .from('profiles')
        .update({'is_active': active})
        .eq('id', userId);

    // Log the action (non-critical)
    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': '${active ? 'تفعيل' : 'تعطيل'} حساب المستخدم: $userId',
        'target_type': 'profile',
        'target_id': userId,
      });
    } catch (_) {}
  }

  Future<void> deleteTeamMember(String userId, String fullName) async {
    final response = await client.functions.invoke(
      'delete-user',
      body: {'user_id': userId},
    );

    if (response.status != 200) {
      final errorMsg = response.data?['error'] ?? 'فشل في حذف الحساب';
      throw Exception(errorMsg);
    }

    // Log the action (non-critical)
    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'تم حذف حساب عضو فريق: $fullName ($userId)',
        'target_type': 'profile',
      });
    } catch (_) {}
  }

  Future<void> updateAmProjects(String amId, List<String> projectIds) async {
    // 1. Clear current assignments for this AM
    await client
        .from('projects')
        .update({'account_manager_id': null})
        .eq('account_manager_id', amId);
    // 2. Assign new ones
    if (projectIds.isNotEmpty) {
      await client
          .from('projects')
          .update({'account_manager_id': amId})
          .inFilter('id', projectIds);
    }

    // Log the action (non-critical)
    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'تم تحديث تعيينات المشاريع للمدير: $amId',
        'target_type': 'profile',
        'target_id': amId,
      });
    } catch (_) {}
  }

  // --- New CRUD Methods ---

  Future<void> createTask(Map<String, dynamic> task) async {
    final res = await client.from('tasks').insert(task).select().single();

    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'تم إنشاء مهمة جديدة: ${task['title']}',
        'target_type': 'task',
        'target_id': res['id'],
      });
      await client.from('activity_feed').insert({
        'project_id': task['project_id'],
        'action_ar': 'تم إضافة مهمة جديدة: ${task['title']}',
        'action_en': 'Added new task: ${task['title']}',
        'entity_type': 'task',
        'entity_id': res['id'],
      });
    } catch (_) {}

    if (task['project_id'] != null) {
      await _notify(
        projectId: task['project_id'],
        titleAr: '📋 مهمة جديدة بانتظارك',
        bodyAr: 'تمت إضافة مهمة جديدة: ${task['title']}. يمكنك متابعة التفاصيل الآن.',
        type: 'task',
        linkPath: '/tasks',
      );
    }
  }

  Future<void> updateTaskStatus(String taskId, String status, {String? projectId}) async {
    await client.from('tasks').update({'status': status}).eq('id', taskId);
    
    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'تحديث حالة المهمة $taskId إلى $status',
        'target_type': 'task',
        'target_id': taskId,
      });
      if (projectId != null) {
        await client.from('activity_feed').insert({
          'project_id': projectId,
          'action_ar': 'تحديث حالة المهمة: $status',
          'action_en': 'Updated task status to $status',
          'entity_type': 'task',
          'entity_id': taskId,
        });
      }
    } catch (_) {}
  }

  Future<void> deleteTask(String taskId, String title, {String? projectId}) async {
    await client.from('tasks').delete().eq('id', taskId);
    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'تم حذف المهمة: $title ($taskId)',
        'target_type': 'task',
      });
    } catch (_) {}
  }

  Future<void> createApproval(Map<String, dynamic> approval) async {
    final res = await client.from('approvals').insert(approval).select().single();

    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'طلب موافقة جديد: ${approval['title']}',
        'target_type': 'approval',
        'target_id': res['id'],
      });
    } catch (_) {}

    if (approval['project_id'] != null) {
      await _notify(
        projectId: approval['project_id'],
        titleAr: '✅ طلب موافقة جديد',
        bodyAr: 'يوجد عنصر جديد يحتاج موافقتك: ${approval['title']}. يرجى المراجعة في أقرب وقت.',
        type: 'approval',
        linkPath: '/approvals',
      );
    }
  }

  Future<void> deleteApproval(String approvalId, String title) async {
    await client.from('approvals').delete().eq('id', approvalId);
    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'تم حذف طلب الموافقة: $title',
        'target_type': 'approval',
      });
    } catch (_) {}
  }

  Future<void> uploadContract(Map<String, dynamic> contract) async {
    await client.from('contracts').insert({
      ...contract,
      'status': 'pending',
    });

    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'تم رفع عقد جديد: ${contract['title']}',
        'target_type': 'contract',
      });
    } catch (_) {}
  }

  Future<void> updateTicketStatus(String ticketId, String status) async {
    await client.from('support_tickets').update({'status': status}).eq('id', ticketId);
    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'تحديث حالة تذكرة الدعم $ticketId إلى $status',
        'target_type': 'support_ticket',
        'target_id': ticketId,
      });
    } catch (_) {}
  }

  Future<void> deleteProject(String projectId, String name) async {
    // Delete project will cascade delete related items if schema is correct
    await client.from('projects').delete().eq('id', projectId);
    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'تم حذف المشروع نهائياً: $name ($projectId)',
        'target_type': 'project',
      });
    } catch (_) {}
  }

  Future<void> createClient(Map<String, dynamic> clientData) async {
    final response = await client.functions.invoke(
      'create-client',
      body: clientData,
    );

    if (response.status != 200) {
      final errorMsg = response.data?['error'] ?? 'فشل في إنشاء حساب العميل';
      throw Exception(errorMsg);
    }

    // Log the action
    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'تم إنشاء عميل جديد: ${clientData['company_name']} (${clientData['project_name']})',
        'target_type': 'profile',
      });
    } catch (_) {}
  }

  Future<void> updateUser(Map<String, dynamic> data) async {
    final userId = data['userId'];
    final updates = {...data};
    updates.remove('userId');
    
    await client.from('profiles').update(updates).eq('id', userId);
    
    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'تحديث بيانات المستخدم $userId: ${updates.toString()}',
        'target_type': 'profile',
        'target_id': userId,
      });
    } catch (_) {}
  }

  Future<void> updateProjectStage(String projectId, String stage, String stageLabel) async {
    await client.from('projects').update({'current_stage': stage}).eq('id', projectId);
    
    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'تغيير مرحلة المشروع $projectId إلى $stageLabel',
        'target_type': 'project',
        'target_id': projectId,
      });
      await client.from('activity_feed').insert({
        'project_id': projectId,
        'action_ar': 'تم تغيير مرحلة المشروع إلى $stageLabel',
        'action_en': 'Project stage updated to $stageLabel',
        'entity_type': 'project',
        'entity_id': projectId,
      });
    } catch (_) {}
  }

  Future<void> resetClientPassword(Map<String, dynamic> data) async {
    await client.functions.invoke(
      'update-user-password',
      body: {'userId': data['clientId'], 'password': data['newPassword']},
    );

    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'تم تغيير كلمة مرور العميل: ${data['clientName']}',
        'target_type': 'profile',
        'target_id': data['clientId'],
      });
    } catch (_) {}
  }

  Future<void> updateAdminProfile(Map<String, dynamic> data) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;
    await client.from('profiles').update(data).eq('id', userId);

    try {
      await client.from('admin_logs').insert({
        'actor_id': userId,
        'action': 'تحديث الملف الشخصي للمشرف: ${data['full_name']}',
        'target_type': 'profile',
        'target_id': userId,
      });
    } catch (_) {}
  }

  Future<void> createInvoices(List<Map<String, dynamic>> invoices) async {
    await client.from('invoices').insert(invoices);
    
    try {
      final first = invoices.first;
      final desc = first['description'] ?? 'بدون وصف';
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'إنشاء فواتير جديدة (${invoices.length}): $desc',
        'target_type': 'invoice',
      });
    } catch (_) {}

    if (invoices.isNotEmpty && invoices.first['project_id'] != null) {
      final amount = invoices.first['amount'];
      final currency = invoices.first['currency'] ?? 'AED';
      await _notify(
        projectId: invoices.first['project_id'],
        titleAr: '💰 فاتورة جديدة',
        bodyAr: 'تم إصدار فاتورة جديدة بمبلغ $amount $currency. يرجى المراجعة والدفع.',
        type: 'invoice',
        linkPath: '/dashboard',
      );
    }
  }

  Future<void> updateInvoiceStatus(String invoiceId, String status) async {
    final update = <String, dynamic>{'status': status};
    if (status == 'paid') update['paid_at'] = DateTime.now().toIso8601String();
    
    // Get project_id before update for notification
    final inv = await client.from('invoices').select('project_id').eq('id', invoiceId).maybeSingle();
    await client.from('invoices').update(update).eq('id', invoiceId);

    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'تحديث حالة الفاتورة $invoiceId إلى $status',
        'target_type': 'invoice',
        'target_id': invoiceId,
      });
    } catch (_) {}

    if (inv?['project_id'] != null) {
      final statusMap = {
        'paid': ('✅ تم استلام الدفع', 'شكراً! تم تسجيل دفعتك بنجاح.'),
        'overdue': ('⚠️ فاتورة متأخرة', 'تنبيه: لديك فاتورة متأخرة تحتاج للسداد.'),
        'cancelled': ('❌ فاتورة ملغاة', 'تم إلغاء الفاتورة. تواصل مع الفريق لمزيد من المعلومات.'),
      };
      final (title, body) = statusMap[status] ?? ('💰 تحديث الفاتورة', 'تم تحديث حالة فاتورتك إلى: $status');
      await _notify(
        projectId: inv!['project_id'],
        titleAr: title,
        bodyAr: body,
        type: 'invoice',
        linkPath: '/dashboard',
      );
    }
  }

  Future<void> deleteInvoice(String invoiceId) async {
    await client.from('invoices').delete().eq('id', invoiceId);
    
    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'حذف الفاتورة: $invoiceId',
        'target_type': 'invoice',
      });
    } catch (_) {}
  }

  // --- Support & Chat ---

  Future<void> createSupportTicket(Map<String, dynamic> ticket) async {
    final res = await client.from('support_tickets').insert(ticket).select().single();
    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'إنشاء تذكرة دعم جديدة: ${ticket['title']}',
        'target_type': 'support_ticket',
        'target_id': res['id'],
      });
    } catch (_) {}

    if (ticket['project_id'] != null) {
      await _notify(
        projectId: ticket['project_id'],
        titleAr: '🎫 تذكرة دعم جديدة',
        bodyAr: 'تم إنشاء تذكرة دعم فني بعنوان: ${ticket['title']}. سيتواصل معك الفريق قريباً.',
        type: 'ticket',
        linkPath: '/support',
      );
    }
  }

  Future<void> sendChatMessage(Map<String, dynamic> message) async {
    await client.from('messages').insert(message);
    // Not logging every chat message in admin_logs to avoid noise, 
    // but the write is now centralized.
  }

  // --- Project Assets ---

  Future<void> createMeeting(Map<String, dynamic> meeting) async {
    final res = await client.from('meetings').insert(meeting).select().single();
    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'جدولة اجتماع جديد: ${meeting['title']}',
        'target_type': 'meeting',
        'target_id': res['id'],
      });
    } catch (_) {}

    if (meeting['project_id'] != null) {
      await _notify(
        projectId: meeting['project_id'],
        titleAr: '📅 تم تحديد اجتماع جديد',
        bodyAr: 'تم جدولة اجتماع: ${meeting['title']}. تحقق من التفاصيل والتوقيت.',
        type: 'meeting',
        linkPath: '/meetings',
      );
    }
  }

  Future<void> deleteMeeting(String meetingId, String title) async {
    await client.from('meetings').delete().eq('id', meetingId);
    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'حذف اجتماع: $title',
        'target_type': 'meeting',
      });
    } catch (_) {}
  }

  Future<void> createResult(Map<String, dynamic> result) async {
    final res = await client.from('results').insert(result).select().single();
    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'إضافة نتيجة جديدة: ${result['metric_name']}',
        'target_type': 'result',
        'target_id': res['id'],
      });
    } catch (_) {}

    if (result['project_id'] != null) {
      await _notify(
        projectId: result['project_id'],
        titleAr: '📊 تحديث النتائج',
        bodyAr: 'تمت إضافة نتائج أداء جديدة: ${result['metric_name']}. اطّلع على التقدم الآن.',
        type: 'result',
        linkPath: '/results',
      );
    }
  }

  Future<void> deleteResult(String resultId, String name) async {
    await client.from('results').delete().eq('id', resultId);
    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'حذف نتيجة: $name',
        'target_type': 'result',
      });
    } catch (_) {}
  }

  Future<void> createReport(Map<String, dynamic> report) async {
    final res = await client.from('reports').insert(report).select().single();
    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'رفع تقرير جديد: ${report['title']}',
        'target_type': 'report',
        'target_id': res['id'],
      });
    } catch (_) {}

    if (report['project_id'] != null) {
      await _notify(
        projectId: report['project_id'],
        titleAr: '📄 تقرير جديد متاح',
        bodyAr: 'تم رفع تقرير جديد بعنوان: ${report['title']}. يمكنك تحميله ومراجعته الآن.',
        type: 'report',
        linkPath: '/reports',
      );
    }
  }

  Future<void> deleteReport(String reportId, String title) async {
    await client.from('reports').delete().eq('id', reportId);
    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'حذف تقرير: $title',
        'target_type': 'report',
      });
    } catch (_) {}
  }

  Future<void> createFile(Map<String, dynamic> file) async {
    final res = await client.from('files').insert(file).select().single();
    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'رفع ملف جديد: ${file['name']}',
        'target_type': 'file',
        'target_id': res['id'],
      });
    } catch (_) {}

    if (file['project_id'] != null) {
      await _notify(
        projectId: file['project_id'],
        titleAr: '📁 ملف جديد',
        bodyAr: 'تمت إضافة ملف جديد: ${file['name']}. افتح قسم الملفات للاطلاع عليه.',
        type: 'file',
        linkPath: '/files',
      );
    }
  }

  Future<void> deleteFile(String fileId, String name) async {
    await client.from('files').delete().eq('id', fileId);
    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'حذف ملف: $name',
        'target_type': 'file',
      });
    } catch (_) {}
  }

  // --- Campaigns ---

  Future<void> createCampaign(Map<String, dynamic> campaign) async {
    final res = await client.from('campaigns').insert(campaign).select().single();
    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'إنشاء حملة إعلانية: ${campaign['name']}',
        'target_type': 'campaign',
        'target_id': res['id'],
      });
    } catch (_) {}
  }

  Future<void> deleteCampaign(String campaignId, String name) async {
    await client.from('campaigns').delete().eq('id', campaignId);
    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'حذف حملة إعلانية: $name',
        'target_type': 'campaign',
      });
    } catch (_) {}
  }

  Future<void> createCampaignResult(Map<String, dynamic> result) async {
    await client.from('campaign_results').insert(result);
    // Silent logging for sub-entities
  }

  Future<void> deleteVoiceUpdate(String updateId) async {
    await client.from('voice_updates').delete().eq('id', updateId);
    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'حذف تحديث صوتي: $updateId',
        'target_type': 'voice_update',
      });
    } catch (_) {}
  }

  Future<void> createVoiceUpdate(Map<String, dynamic> update) async {
    final projectId = update['project_id'];
    final url = update['file_url'];
    final title = update['title'];

    // 1. Update project latest update
    await client.from('projects').update({
      'voice_update_url': url,
      'voice_update_at': DateTime.now().toIso8601String(),
    }).eq('id', projectId);

    // 2. Insert into voice_updates history
    await client.from('voice_updates').insert(update);

    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'تحديث صوتي جديد للمشروع: $projectId',
        'target_type': 'voice_update',
      });
    } catch (_) {}
  }

  Future<void> convertMessageToTask({
    required String projectId,
    required String messageId,
    required String title,
    required String description,
  }) async {
    // 1. Create task
    final taskRes = await client.from('tasks').insert({
      'project_id': projectId,
      'title': title,
      'description': description,
      'status': 'todo',
      'source_message_id': messageId,
      'created_by': client.auth.currentUser!.id,
    }).select().single();

    // 2. Update message
    await client.from('messages').update({
      'converted_to_task': true,
      'linked_task_id': taskRes['id'],
    }).eq('id', messageId);

    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'تحويل رسالة إلى مهمة: $title',
        'target_type': 'task',
        'target_id': taskRes['id'],
      });
    } catch (_) {}
  }

  Future<void> createChatChannel(Map<String, dynamic> channel) async {
    final res = await client.from('chat_channels').insert(channel).select().single();
    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'إنشاء قناة محادثة جديدة: ${channel['name']}',
        'target_type': 'chat_channel',
        'target_id': res['id'],
      });
    } catch (_) {}
  }

  Future<void> updateEngineProgress(Map<String, dynamic> progress) async {
    await client.from('engine_progress').upsert(
      progress,
      onConflict: 'project_id,engine',
    );
    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'تحديث محرك ${progress['engine']} للمشروع ${progress['project_id']}',
        'target_type': 'project',
        'target_id': progress['project_id'],
      });
    } catch (_) {}
  }

  // ── Universal Update Methods ──────────────────────────────────────────────

  /// Update any fields on a task (title, description, status, progress_percent, etc.)
  Future<void> updateTask(String taskId, Map<String, dynamic> updates) async {
    await client.from('tasks').update(updates).eq('id', taskId);
    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'تعديل المهمة $taskId: ${updates.keys.join(', ')}',
        'target_type': 'task',
        'target_id': taskId,
      });
    } catch (_) {}
  }

  /// Update approval status or any other approval fields
  Future<void> updateApproval(String approvalId, Map<String, dynamic> updates) async {
    await client.from('approvals').update(updates).eq('id', approvalId);
    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'تعديل طلب الموافقة $approvalId',
        'target_type': 'approval',
        'target_id': approvalId,
      });
    } catch (_) {}
  }

  /// Update meeting details (title, scheduled_at, status, etc.)
  Future<void> updateMeeting(String meetingId, Map<String, dynamic> updates) async {
    await client.from('meetings').update(updates).eq('id', meetingId);
    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'تعديل الاجتماع $meetingId',
        'target_type': 'meeting',
        'target_id': meetingId,
      });
    } catch (_) {}
  }

  /// Update a result/metric
  Future<void> updateResult(String resultId, Map<String, dynamic> updates) async {
    await client.from('results').update(updates).eq('id', resultId);
    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'تعديل نتيجة $resultId',
        'target_type': 'result',
        'target_id': resultId,
      });
    } catch (_) {}
  }

  /// Update a report
  Future<void> updateReport(String reportId, Map<String, dynamic> updates) async {
    await client.from('reports').update(updates).eq('id', reportId);
    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'تعديل تقرير $reportId',
        'target_type': 'report',
        'target_id': reportId,
      });
    } catch (_) {}
  }

  /// Update a file record
  Future<void> updateFile(String fileId, Map<String, dynamic> updates) async {
    await client.from('files').update(updates).eq('id', fileId);
    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'تعديل ملف $fileId',
        'target_type': 'file',
        'target_id': fileId,
      });
    } catch (_) {}
  }

  /// Update a campaign (name, goal, budget, status, etc.)
  Future<void> updateCampaign(String campaignId, Map<String, dynamic> updates) async {
    await client.from('campaigns').update(updates).eq('id', campaignId);
    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'تعديل حملة إعلانية $campaignId',
        'target_type': 'campaign',
        'target_id': campaignId,
      });
    } catch (_) {}
  }

  /// Update a project (name, health_score, status, current_stage, etc.)
  Future<void> updateProject(String projectId, Map<String, dynamic> updates) async {
    await client.from('projects').update(updates).eq('id', projectId);
    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'تعديل المشروع $projectId: ${updates.keys.join(', ')}',
        'target_type': 'project',
        'target_id': projectId,
      });
    } catch (_) {}
  }

  /// Update a contract (title, status, etc.)
  Future<void> updateContract(String contractId, Map<String, dynamic> updates) async {
    await client.from('contracts').update(updates).eq('id', contractId);
    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'تعديل عقد $contractId',
        'target_type': 'contract',
        'target_id': contractId,
      });
    } catch (_) {}
  }

  /// Delete a support ticket
  Future<void> deleteSupportTicket(String ticketId, String title) async {
    await client.from('support_tickets').delete().eq('id', ticketId);
    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'حذف تذكرة دعم: $title',
        'target_type': 'support_ticket',
      });
    } catch (_) {}
  }

  /// Update support ticket details or status
  Future<void> updateSupportTicket(String ticketId, Map<String, dynamic> updates) async {
    await client.from('support_tickets').update(updates).eq('id', ticketId);
    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'تعديل تذكرة دعم $ticketId',
        'target_type': 'support_ticket',
        'target_id': ticketId,
      });
    } catch (_) {}
  }



  /// Generic update for any table (use with caution)
  Future<void> updateAny(String table, String id, Map<String, dynamic> updates) async {
    await client.from(table).update(updates).eq('id', id);
  }

  /// Delete a contract
  Future<void> deleteContract(String contractId, String title) async {
    await client.from('contracts').delete().eq('id', contractId);
    try {
      await client.from('admin_logs').insert({
        'actor_id': client.auth.currentUser!.id,
        'action': 'حذف عقد: $title',
        'target_type': 'contract',
      });
    } catch (_) {}
  }
}











final amDetailProvider = FutureProvider.family<Map<String, dynamic>, String>((
  ref,
  amId,
) async {
  final client = ref.watch(supabaseClientProvider);

  // 1. Fetch profile
  final profile = await client
      .from('profiles')
      .select()
      .eq('id', amId)
      .single();

  // 2. Fetch projects
  final projects = await client
      .from('projects')
      .select()
      .eq('account_manager_id', amId);

  // 3. Fetch performance metrics (aggregated for now)
  double totalHealth = 0;
  final projectsList = projects as List;
  for (var p in projectsList) {
    totalHealth += (p['health_score'] ?? 0).toDouble();
  }

  return {
    'profile': profile,
    'projects': projectsList,
    'avg_health': projectsList.isNotEmpty
        ? totalHealth / projectsList.length
        : 0,
  };
});

class BillingStats {
  final double totalBilled;
  final double totalPaid;
  final double outstanding;
  final int totalInvoices;

  BillingStats({
    required this.totalBilled,
    required this.totalPaid,
    required this.outstanding,
    required this.totalInvoices,
  });
}

final allInvoicesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final data = await client
      .from('invoices')
      .select('*, projects(name, profiles!projects_client_id_fkey(full_name, company_name))')
      .order('created_at', ascending: false);
  return (data as List).cast<Map<String, dynamic>>();
});

final billingStatsProvider = FutureProvider<BillingStats>((ref) async {
  final invoices = await ref.watch(allInvoicesProvider.future);
  double total = 0;
  double paid = 0;
  for (var inv in invoices) {
    final amount = (inv['amount'] as num?)?.toDouble() ?? 0;
    total += amount;
    if (inv['status'] == 'paid') paid += amount;
  }
  return BillingStats(
    totalBilled: total,
    totalPaid: paid,
    outstanding: total - paid,
    totalInvoices: invoices.length,
  );
});

final adminLogsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final client = ref.watch(supabaseClientProvider);
  final data = await client
      .from('admin_logs')
      .select('*, profiles!actor_id(full_name)')
      .order('created_at', ascending: false)
      .limit(100);
  return List<Map<String, dynamic>>.from(data);
});

final criticalAlertsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final client = ref.watch(supabaseClientProvider);

  // 1. Projects with low health (< 40)
  final lowHealth = await client
      .from('projects')
      .select('name, health_score')
      .lt('health_score', 40)
      .limit(5);

  // 2. Overdue tasks
  final overdueTasks = await client
      .from('tasks')
      .select('title, deadline, projects(name)')
      .lt('deadline', DateTime.now().toIso8601String())
      .neq('status', 'completed')
      .limit(5);

  final List<Map<String, dynamic>> alerts = [];

  for (var p in lowHealth) {
    alerts.add({
      'type': 'health',
      'message':
          'انخفاض مؤشر الصحة لعميل "${p['name']}" إلى ${p['health_score']}%',
      'time': 'تنبيه فوري',
    });
  }

  for (var t in overdueTasks) {
    final pName = (t['projects'] as Map)['name'];
    alerts.add({
      'type': 'task',
      'message': 'مهمة متأخرة في مشروع "$pName": ${t['title']}',
      'time': 'تجاوز الموعد',
    });
  }

  return alerts;
});

// ── Project Specific Providers (Family) ──────────────────────────

final projectTasksProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, pid) {
  final c = ref.watch(supabaseClientProvider);
  return c.from('tasks')
      .stream(primaryKey: ['id'])
      .eq('project_id', pid)
      .order('created_at', ascending: false);
});

final projectMeetingsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, pid) {
  final c = ref.watch(supabaseClientProvider);
  return c.from('meetings')
      .stream(primaryKey: ['id'])
      .eq('project_id', pid)
      .order('scheduled_at', ascending: false);
});

final projectTicketsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, pid) {
  final c = ref.watch(supabaseClientProvider);
  return c.from('support_tickets')
      .stream(primaryKey: ['id'])
      .eq('project_id', pid)
      .order('created_at', ascending: false);
});

final projectResultsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, pid) async {
  final c = ref.watch(supabaseClientProvider);
  final data = await c.from('results').select().eq('project_id', pid).order('recorded_at', ascending: false);
  return (data as List).cast<Map<String, dynamic>>();
});

final projectEnginesProvider = StreamProvider.family<Map<String, double>, String>((ref, pid) {
  final c = ref.watch(supabaseClientProvider);
  return c.from('engine_progress')
      .stream(primaryKey: ['id'])
      .eq('project_id', pid)
      .map((data) {
        final Map<String, double> result = {};
        for (var item in data) {
          result[item['engine']] = (item['progress_percent'] as num).toDouble() / 100.0;
        }
        return result;
      });
});

final projectInvoicesProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, pid) async {
  final c = ref.watch(supabaseClientProvider);
  final data = await c.from('invoices').select().eq('project_id', pid).order('created_at', ascending: false);
  return (data as List).cast<Map<String, dynamic>>();
});

final projectReportsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, pid) async {
  final c = ref.watch(supabaseClientProvider);
  final data = await c.from('reports').select().eq('project_id', pid).order('created_at', ascending: false);
  return (data as List).cast<Map<String, dynamic>>();
});

final projectCampaignsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, pid) {
  final c = ref.watch(supabaseClientProvider);
  return c.from('campaigns')
      .stream(primaryKey: ['id'])
      .eq('project_id', pid)
      .order('created_at', ascending: false);
});

final projectFilesProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, pid) {
  final c = ref.watch(supabaseClientProvider);
  return c.from('files')
      .stream(primaryKey: ['id'])
      .eq('project_id', pid)
      .order('created_at', ascending: false);
});
