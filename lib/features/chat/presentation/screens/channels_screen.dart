import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/l10n/app_localizations.dart';
import 'package:moharek_app/features/chat/presentation/screens/chat_screen.dart';

final projectChannelsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final user = client.auth.currentUser;
  if (user == null) return [];

  try {
    // Direct query - let RLS handle the filtering by project/client
    final data = await client
        .from('chat_channels')
        .select();

    return (data as List).cast<Map<String, dynamic>>();
  } catch (e) {
    // If joining fails (e.g. RLS on projects), try an even more direct path
    // or just throw to let the UI handle the error state
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

    return channelsAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: Text(l10n.chatTab),
        ),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      ),
      error: (err, _) {
        final isRlsError = err.toString().contains('infinite recursion') ||
            err.toString().contains('company_members');
        return Scaffold(
          appBar: AppBar(
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
                            ? 'Run fix_company_members_rls.sql in Supabase SQL editor'
                            : 'Error loading chat: ${err.toString()}'),
                    style: TextStyle(
                      color: isRlsError ? Colors.orange : Colors.red,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
      data: (channels) {
        // If there's exactly one channel, render the ChatScreen DIRECTLY without any list screen or navigation!
        if (channels.length == 1) {
          final ch = channels.first;
          return ChatScreen(
            channelId: ch['id']!.toString(),
            channelName: ch['name']?.toString() ?? 'Chat',
          );
        }

        // Multiple channels (or empty channels) -> Show the list layout with Scaffold
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.chatTab),
          ),
          body: channels.isEmpty
              ? Center(
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
                    ],
                  ),
                )
              : ListView.builder(
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
                          isAr ? 'مع فريق محرك' : 'With Moharek team',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.white24),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
