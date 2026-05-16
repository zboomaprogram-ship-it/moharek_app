import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/features/admin/presentation/screens/admin_chat_screen.dart'; // Reuse the message list logic if possible

final amChatChannelsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final user = client.auth.currentUser;
  if (user == null) return [];

  // Fetch all channels for projects assigned to this AM
  final data = await client
      .from('chat_channels')
      .select('*, projects!inner(id, name, account_manager_id)')
      .eq('projects.account_manager_id', user.id)
      .order('created_at', ascending: false);
  
  return List<Map<String, dynamic>>.from(data);
});

class AmChatScreen extends ConsumerWidget {
  const AmChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channels = ref.watch(amChatChannelsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'المحادثات',
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const Text(
              'تواصل مباشر مع عملائك الموكلين إليك',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
            const SizedBox(height: 32),

            Expanded(
              child: channels.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (list) {
                  if (list.isEmpty) {
                    return _buildEmptyState();
                  }
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) => _ChatChannelTile(channel: list[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: const Color(0xFF334155)),
          const SizedBox(height: 16),
          const Text(
            'لا توجد محادثات نشطة حالياً',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _ChatChannelTile extends StatelessWidget {
  final Map<String, dynamic> channel;
  const _ChatChannelTile({required this.channel});

  @override
  Widget build(BuildContext context) {
    final project = channel['projects'] as Map<String, dynamic>;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.forum_outlined, color: AppTheme.primaryGreen, size: 24),
        ),
        title: Text(
          project['name'] ?? '',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text(
            'تواصل مع العميل بخصوص المشروع',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF475569), size: 16),
        onTap: () => _showChatDialog(context, channel, project),
      ),
    );
  }

  void _showChatDialog(BuildContext context, Map<String, dynamic> channel, Map<String, dynamic> project) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF0F172A),
        insetPadding: const EdgeInsets.all(40),
        child: SizedBox(
          width: 800,
          height: 800,
          child: AdminChatScreen(
            projectId: project['id'],
            clientName: project['name'] ?? 'Client',
            channelId: channel['id'],
            channelName: channel['name'] ?? 'Chat',
          ),
        ),
      ),
    );
  }
}
