import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/features/admin/widgets/admin_voice_recorder.dart';

final _voiceUpdatesForProject =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, pid) {
      final c = ref.watch(supabaseClientProvider);
      return c
          .from('voice_updates')
          .stream(primaryKey: ['id'])
          .eq('project_id', pid)
          .order('created_at', ascending: false);
    });

class VoiceUpdatesTab extends ConsumerWidget {
  final String pid;
  const VoiceUpdatesTab({super.key, required this.pid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceAsync = ref.watch(_voiceUpdatesForProject(pid));

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        heroTag: 'record_voice',
        backgroundColor: Colors.redAccent,
        onPressed: () => _showRecorder(context, ref),
        child: const Icon(Icons.mic, color: Colors.white),
      ),
      body: voiceAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (updates) {
          if (updates.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mic_none, color: Colors.grey, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'No voice updates yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Record a quick update for the client',
                    style: TextStyle(color: Colors.white24, fontSize: 12),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: updates.length,
            itemBuilder: (context, index) {
              final v = updates[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.play_circle_outline,
                    color: AppTheme.primaryGreen,
                  ),
                  title: Text(
                    v['title'] ?? 'Growth Update',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    (v['created_at'] as String).split('T')[0],
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.white24,
                      size: 18,
                    ),
                    onPressed: () async {
                      final actions = ref.read(adminActionsProvider);
                      await actions.deleteVoiceUpdate(v['id']);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showRecorder(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) => AdminVoiceRecorder(
        projectId: pid,
        onComplete: (url) {
          Navigator.pop(ctx);
          ref.invalidate(_voiceUpdatesForProject(pid));
        },
      ),
    );
  }
}
