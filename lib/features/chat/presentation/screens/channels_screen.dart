import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moharek_app/core/config/app_config.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/l10n/app_localizations.dart';
import 'package:moharek_app/features/chat/presentation/screens/chat_screen.dart';
import 'package:moharek_app/features/notifications/data/notifications_provider.dart';

/// Fetches channels — and for Rabhan auto-creates the channel if missing via RPC.
final projectChannelsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final user = client.auth.currentUser;
  if (user == null) return [];

  try {
    final data = await client.from('chat_channels').select();
    final channels = (data as List).cast<Map<String, dynamic>>();

    // For Rabhan: if the client has no channel yet, auto-create one via RPC
    if (channels.isEmpty && AppConfig.flavorName == 'rabhan') {
      try {
        // Get the user's project_id
        final profile = await client
            .from('projects')
            .select('id')
            .eq('client_id', user.id)
            .maybeSingle();

        if (profile != null) {
          final projectId = profile['id'] as String;
          final channelId = await client.rpc(
            'get_or_create_chat_channel',
            params: {'p_project_id': projectId},
          );
          if (channelId != null) {
            // Fetch the newly created channel
            final newChannel = await client
                .from('chat_channels')
                .select()
                .eq('id', channelId.toString())
                .maybeSingle();
            if (newChannel != null) return [newChannel];
          }
        }
      } catch (e) {
        debugPrint('[ChannelsScreen] auto-create channel error: $e');
      }
    }

    return channels;
  } catch (e) {
    debugPrint('Chat channels fetch error: $e');
    rethrow;
  }
});

class ChannelsScreen extends ConsumerWidget {
  const ChannelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(projectChannelsProvider);
    final l10n = AppLocalizations.of(context)!;
    final isAr = l10n.localeName == 'ar';
    final isRabhan = AppConfig.flavorName == 'rabhan';

    return channelsAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.background,
          title: Text(l10n.chatTab),
        ),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      ),
      error: (err, _) {
        final isRlsError = err.toString().contains('infinite recursion') ||
            err.toString().contains('company_members');
        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: AppTheme.background,
            title: Text(l10n.chatTab),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isRlsError ? Icons.settings_outlined : Icons.error_outline,
                    color: isRlsError ? Colors.orange : Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isAr
                        ? (isRlsError
                            ? 'يرجى تطبيق إصلاح قاعدة البيانات في لوحة Supabase SQL'
                            : 'خطأ في تحميل المحادثة: ${err.toString()}')
                        : (isRlsError
                            ? 'Run fix_realtime_and_rls.sql in Supabase SQL editor'
                            : 'Error loading chat: ${err.toString()}'),
                    style: TextStyle(
                      color: isRlsError ? Colors.orange : Colors.red,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(projectChannelsProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.black,
                    ),
                    child: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      data: (channels) {
        // ── Single channel → go directly to ChatScreen (no list) ──
        if (channels.length == 1) {
          final ch = channels.first;
          return ChatScreen(
            channelId: ch['id']!.toString(),
            channelName: ch['name']?.toString() ?? 'Chat',
          );
        }

        // ── No channels → prompt with refresh ──
        if (channels.isEmpty) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            appBar: AppBar(
              backgroundColor: AppTheme.background,
              title: Text(l10n.chatTab),
            ),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chat_bubble_outline, size: 40, color: AppTheme.primaryGreen),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isAr ? 'محادثتك تبدأ قريباً' : 'Your chat starts soon',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAr
                        ? 'سيقوم فريقك بإنشاء قناة المحادثة الخاصة بك'
                        : 'Your account manager will set up your channel shortly',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextButton.icon(
                    onPressed: () => ref.invalidate(projectChannelsProvider),
                    icon: const Icon(Icons.refresh, color: AppTheme.primaryGreen),
                    label: Text(
                      isAr ? 'تحديث' : 'Refresh',
                      style: const TextStyle(color: AppTheme.primaryGreen),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // ── Multiple channels → show list ──
        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: AppTheme.background,
            title: Text(l10n.chatTab),
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: channels.length,
            itemBuilder: (context, index) {
              final channel = channels[index];
              return Card(
                color: AppTheme.cardColor,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  onTap: () {
                    context.push('/chat/${channel['id']}?name=${Uri.encodeComponent(channel['name'] ?? 'Chat')}');
                  },
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    child: const Icon(Icons.tag, color: AppTheme.primaryGreen),
                  ),
                  title: Text(channel['name'] ?? 'Channel', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    isAr
                        ? (isRabhan ? 'مع فريق ربحان' : 'مع فريق محرك')
                        : (isRabhan ? 'With Rabhan team' : 'With Moharek team'),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  trailing: Consumer(
                    builder: (context, ref, _) {
                      final unreadCount = ref.watch(
                        unreadChatNotificationsByChannelProvider(channel['id']?.toString() ?? ''),
                      );
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (unreadCount > 0) const SizedBox(width: 8),
                          Icon(
                            isAr ? Icons.chevron_left : Icons.chevron_right,
                            color: Colors.white24,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
