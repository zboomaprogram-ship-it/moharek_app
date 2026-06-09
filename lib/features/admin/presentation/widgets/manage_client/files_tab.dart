import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:moharek_app/shared/services/wordpress_upload_service.dart';
import 'package:moharek_app/features/notifications/data/notifications_provider.dart';

class FilesTab extends ConsumerWidget {
  final String pid;
  const FilesTab({super.key, required this.pid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.markProjectNotificationsAsRead(pid, 'info');
      ref.invalidate(notificationsProvider);
    });

    final filesAsync = ref.watch(projectFilesProvider(pid));
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        heroTag: 'upload_file_$pid',
        backgroundColor: AppTheme.primaryBlue,
        onPressed: () => _uploadFile(context, ref),
        child: const Icon(Icons.upload_file, color: Colors.white),
      ),
      body: filesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (files) {
          if (files.isEmpty) {
            return const Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.folder_open_outlined, color: Colors.grey, size: 48),
                SizedBox(height: 16),
                Text('لا توجد ملفات', style: TextStyle(color: Colors.grey)),
              ]),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: files.length,
            itemBuilder: (context, index) => _buildCard(context, ref, files[index]),
          );
        },
      ),
    );
  }

  Widget _buildCard(BuildContext context, WidgetRef ref, Map<String, dynamic> f) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        leading: const Icon(Icons.insert_drive_file_outlined, color: AppTheme.primaryBlue),
        title: Text(f['name'] ?? 'ملف', style: const TextStyle(color: Colors.white, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${(f['size_kb'] ?? 0)} KB • ${(f['created_at'] ?? '').toString().split('T')[0]}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
          tooltip: 'حذف',
          onPressed: () => _confirmDelete(context, ref, f),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Map<String, dynamic> f) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('حذف الملف', style: TextStyle(color: Colors.white)),
        content: Text('حذف "${f['name']}"؟', style: const TextStyle(color: Color(0xFF94A3B8))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(adminActionsProvider).deleteFile(f['id'], f['name'] ?? '');
      ref.invalidate(projectFilesProvider(pid));
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف ✅'), backgroundColor: AppTheme.primaryGreen));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _uploadFile(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.pickFiles(withData: true);
    if (result == null) return;
    final file = result.files.first;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    try {
      String url = '';
      if (file.bytes != null) {
        url = await WordPressUploadService.uploadBytes(file.bytes!, fileName);
      } else if (file.path != null) {
        url = await WordPressUploadService.uploadFile(file.path!, fileName);
      } else {
        throw Exception('No file data available');
      }

      await ref.read(adminActionsProvider).createFile({
        'project_id': pid,
        'name': file.name,
        'file_url': url,
        'size_kb': (file.size / 1024).round(),
        'file_type': file.extension ?? 'bin',
      });
      ref.invalidate(projectFilesProvider(pid));
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم رفع الملف ✅'), backgroundColor: AppTheme.primaryGreen));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الرفع: $e'), backgroundColor: Colors.red));
    }
  }
}
