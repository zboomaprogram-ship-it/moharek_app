import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:moharek_app/shared/models/notification.dart';

final notificationsProvider = StreamProvider.autoDispose<List<AppNotification>>((ref) {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;

  if (userId == null) return Stream.value([]);

  Future<List<AppNotification>> fetch() async {
    final data = await supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);
    return (data as List)
        .map((json) => AppNotification.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  return Stream.multi((controller) async {
    // Initial load
    try {
      controller.add(await fetch());
    } catch (_) {
      controller.add([]);
    }
    // Refresh every 8s — notifications are less time-critical than chat
    final timer = Timer.periodic(const Duration(seconds: 8), (_) async {
      if (controller.isClosed) return;
      try {
        controller.add(await fetch());
      } catch (_) {}
    });
    ref.onDispose(() {
      timer.cancel();
      controller.close();
    });
  });
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final asyncValue = ref.watch(notificationsProvider);
  return asyncValue.when(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final unreadChatNotificationsCountProvider = Provider<int>((ref) {
  final asyncValue = ref.watch(notificationsProvider);
  return asyncValue.when(
    data: (notifications) => notifications.where((n) => !n.isRead && n.type == 'chat_message').length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final unreadTaskNotificationsCountProvider = Provider<int>((ref) {
  final asyncValue = ref.watch(notificationsProvider);
  return asyncValue.when(
    data: (notifications) => notifications.where((n) => !n.isRead && n.type == 'task').length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final unreadApprovalNotificationsCountProvider = Provider<int>((ref) {
  final asyncValue = ref.watch(notificationsProvider);
  return asyncValue.when(
    data: (notifications) => notifications.where((n) => !n.isRead && n.type == 'approval').length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final unreadSupportNotificationsCountProvider = Provider<int>((ref) {
  final asyncValue = ref.watch(notificationsProvider);
  return asyncValue.when(
    data: (notifications) => notifications.where((n) => !n.isRead && (n.type == 'ticket' || n.type == 'support_ticket')).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final unreadMeetingNotificationsCountProvider = Provider<int>((ref) {
  final asyncValue = ref.watch(notificationsProvider);
  return asyncValue.when(
    data: (notifications) => notifications.where((n) => !n.isRead && n.type == 'meeting').length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final unreadReportNotificationsCountProvider = Provider<int>((ref) {
  final asyncValue = ref.watch(notificationsProvider);
  return asyncValue.when(
    data: (notifications) => notifications.where((n) => !n.isRead && n.type == 'report').length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final unreadBillingNotificationsCountProvider = Provider<int>((ref) {
  final asyncValue = ref.watch(notificationsProvider);
  return asyncValue.when(
    data: (notifications) => notifications.where((n) => !n.isRead && n.type == 'invoice').length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final unreadNotificationsByProjectProvider = Provider<Map<String, int>>((ref) {
  final asyncValue = ref.watch(notificationsProvider);
  return asyncValue.when(
    data: (notifications) {
      final unread = notifications.where((n) => !n.isRead);
      final map = <String, int>{};
      for (final n in unread) {
        final meta = n.metadata;
        final pid = meta['project_id']?.toString();
        if (pid != null) {
          map[pid] = (map[pid] ?? 0) + 1;
        }
      }
      return map;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});



final unreadNotificationsByProjectAndTypeProvider = Provider.family<int, String>((ref, projectAndType) {
  final parts = projectAndType.split(':');
  if (parts.length != 2) return 0;
  final projectId = parts[0];
  final type = parts[1];

  final asyncValue = ref.watch(notificationsProvider);
  return asyncValue.when(
    data: (notifications) {
      return notifications.where((n) {
        if (n.isRead) return false;
        
        // Support notifications can be under 'ticket' or 'support_ticket'
        if (type == 'support') {
          if (n.type != 'ticket' && n.type != 'support_ticket') return false;
        } else {
          if (n.type != type) return false;
        }
        
        final pid = n.metadata['project_id']?.toString();
        return pid == projectId;
      }).length;
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final unreadChatNotificationsByChannelProvider = Provider.family<int, String>((ref, channelId) {
  final asyncValue = ref.watch(notificationsProvider);
  return asyncValue.when(
    data: (notifications) {
      return notifications.where((n) {
        if (n.isRead || n.type != 'chat_message') return false;
        final chId = n.metadata['channel_id']?.toString();
        return chId == channelId;
      }).length;
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
});

class NotificationService {
  static Future<void> markAsRead(String id) async {
    await Supabase.instance.client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', id);
  }

  static Future<void> markAllAsRead() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    await Supabase.instance.client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId);
  }

  static Future<void> markChannelMessagesAsRead(String channelId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('type', 'chat_message')
          .filter('metadata->>channel_id', 'eq', channelId);
    } catch (_) {}
  }

  static Future<void> markProjectNotificationsAsRead(String projectId, String type) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      if (type == 'support') {
        await Supabase.instance.client
            .from('notifications')
            .update({'is_read': true})
            .eq('user_id', userId)
            .inFilter('type', ['ticket', 'support_ticket'])
            .filter('metadata->>project_id', 'eq', projectId);
      } else {
        await Supabase.instance.client
            .from('notifications')
            .update({'is_read': true})
            .eq('user_id', userId)
            .eq('type', type)
            .filter('metadata->>project_id', 'eq', projectId);
      }
    } catch (_) {}
  }
}
