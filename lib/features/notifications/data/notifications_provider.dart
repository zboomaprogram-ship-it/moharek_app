import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:moharek_app/shared/models/notification.dart';

final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
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
}
