import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/features/admin/presentation/screens/admin_chat_screen.dart';
import 'package:moharek_app/features/notifications/data/notifications_provider.dart';

class AdminChannelsScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String clientName;

  const AdminChannelsScreen({
    super.key,
    required this.projectId,
    required this.clientName,
  });

  @override
  ConsumerState<AdminChannelsScreen> createState() => _AdminChannelsScreenState();
}

class _AdminChannelsScreenState extends ConsumerState<AdminChannelsScreen> {
  Future<void> _createChannel() async {
    final nameCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text('Create New Channel', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Channel Name (e.g. SEO Updates)',
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.black),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (confirmed == true && nameCtrl.text.isNotEmpty) {
      try {
        final actions = ref.read(adminActionsProvider);
        await actions.createChatChannel({
          'project_id': widget.projectId,
          'name': nameCtrl.text.trim(),
          'channel_type': 'custom',
        });
        setState(() {}); // Refresh future
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure default channel exists
    final defaultChannelAsync = ref.watch(adminChatChannelProvider(widget.projectId));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.clientName, style: const TextStyle(fontSize: 16)),
            const Text('Channels', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.primaryGreen),
            onPressed: _createChannel,
            tooltip: 'Create Channel',
          ),
        ],
      ),
      body: defaultChannelAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
        data: (_) {
          // Now fetch all channels for this project
          return FutureBuilder<List<dynamic>>(
            future: ref.read(supabaseClientProvider).from('chat_channels').select().eq('project_id', widget.projectId).order('created_at', ascending: true),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
              }

              final channels = snapshot.data as List<dynamic>? ?? [];

              if (channels.isEmpty) {
                return const Center(child: Text('No channels found', style: TextStyle(color: Colors.grey)));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: channels.length,
                itemBuilder: (context, index) {
                  final channel = channels[index];
                  return Card(
                    color: AppTheme.cardColor,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      onTap: () {
                        final chId = channel['id']?.toString() ?? '';
                        final chName = channel['name']?.toString() ?? 'Channel';
                        context.push('/admin/chat/${widget.projectId}/$chId?clientName=${Uri.encodeComponent(widget.clientName)}&channelName=${Uri.encodeComponent(chName)}');
                      },
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                        child: const Icon(Icons.tag, color: AppTheme.primaryGreen),
                      ),
                      title: Text(channel['name']?.toString() ?? 'Channel', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        (channel['channel_type']?.toString() ?? 'client_manager') == 'client_manager' ? 'Support Team' : 'Custom Channel',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      trailing: Consumer(
                        builder: (context, ref, child) {
                          final chId = channel['id']?.toString() ?? '';
                          final unreadCount = ref.watch(unreadChatNotificationsByChannelProvider(chId));
                          if (unreadCount > 0) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(10),
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
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right, color: Colors.white24),
                              ],
                            );
                          }
                          return const Icon(Icons.chevron_right, color: Colors.white24);
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
