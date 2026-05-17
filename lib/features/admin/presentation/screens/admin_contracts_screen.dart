import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:moharek_app/shared/services/wordpress_upload_service.dart';

final allContractsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final client = ref.watch(supabaseClientProvider);
  final data = await client
      .from('contracts')
      .select(
        '*, projects(profiles!projects_client_id_fkey(full_name, company_name))',
      )
      .order('created_at', ascending: false);
  return (data as List).cast<Map<String, dynamic>>();
});

class AdminContractsScreen extends ConsumerWidget {
  const AdminContractsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contractsAsync = ref.watch(allContractsProvider);
    final isMobile = MediaQuery.of(context).size.width < 1000;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            if (isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'العقود',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'إدارة العقود والاتفاقيات الموقعة مع العملاء',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showUploadContractDialog(context, ref),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('رفع عقد جديد'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'العقود',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'إدارة العقود والاتفاقيات الموقعة مع العملاء',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showUploadContractDialog(context, ref),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('رفع عقد جديد'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 32),

            Expanded(
              child: contractsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                ),
                error: (err, _) => Center(
                  child: Text(
                    'Error: $err',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                data: (contracts) {
                  if (contracts.isEmpty) {
                    return const Center(
                      child: Text(
                        'لا توجد عقود حالياً.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: AppTheme.primaryGreen,
                    onRefresh: () async => ref.invalidate(allContractsProvider),
                    child: ListView.builder(
                      itemCount: contracts.length,
                      itemBuilder: (context, index) => _buildContractCard(
                        context,
                        ref,
                        contracts[index],
                        isMobile,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContractCard(BuildContext context, WidgetRef ref, Map<String, dynamic> contract, bool isMobile) {
    final project = contract['projects'] as Map<String, dynamic>?;
    final profile = project?['profiles'] as Map<String, dynamic>?;
    final clientName = profile?['full_name'] as String? ?? 'عميل غير معروف';
    final title = contract['title'] as String? ?? 'عقد بدون عنوان';
    final status = contract['status'] as String? ?? 'pending';
    final isSigned = status == 'signed';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSigned ? AppTheme.primaryGreen.withValues(alpha: 0.3) : Colors.white10,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSigned ? AppTheme.primaryGreen.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isSigned ? Icons.verified : Icons.hourglass_bottom,
                  color: isSigned ? AppTheme.primaryGreen : Colors.orange,
                  size: isMobile ? 20 : 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 14 : 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'العميل: $clientName',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!isMobile) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSigned ? AppTheme.primaryGreen.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: isSigned ? AppTheme.primaryGreen : Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.download, color: Colors.white70, size: 20),
                  onPressed: () => _downloadContract(context, contract),
                ),
              ],
            ],
          ),
          if (isMobile) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSigned ? AppTheme.primaryGreen.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: isSigned ? AppTheme.primaryGreen : Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _downloadContract(context, contract),
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('تحميل'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryGreen,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _downloadContract(BuildContext context, Map<String, dynamic> contract) async {
    final fileUrl = contract['file_url'] as String?;
    if (fileUrl != null && fileUrl.isNotEmpty) {
      final uri = Uri.parse(fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح الرابط')));
        }
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يوجد ملف متاح للتحميل')));
      }
    }
  }

  void _showUploadContractDialog(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.read(allProjectsProvider);
    final titleCtrl = TextEditingController();
    String? selectedProjectId;
    PlatformFile? selectedFile;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upload New Contract',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              projectsAsync.when(
                data: (projects) => DropdownButtonFormField<String>(
                  dropdownColor: AppTheme.cardColor,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Select Client',
                    labelStyle: TextStyle(color: Colors.grey),
                  ),
                  items: projects.map((p) {
                    final profile = p['profiles'] as Map<String, dynamic>?;
                    return DropdownMenuItem(
                      value: p['id'] as String,
                      child: Text(profile?['full_name'] ?? 'Unknown'),
                    );
                  }).toList(),
                  onChanged: (v) => selectedProjectId = v,
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error loading clients: $e'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Contract Title (e.g. Annual SEO)',
                  labelStyle: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: () async {
                  final result = await FilePicker.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf'],
                    withData: true,
                  );
                  if (result != null) {
                    setState(() => selectedFile = result.files.first);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_file, color: AppTheme.primaryBlue),
                      const SizedBox(width: 12),
                      Text(
                        selectedFile?.name ?? 'Select PDF File',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (selectedProjectId == null || selectedFile == null || titleCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
                      return;
                    }
                    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${selectedFile!.name}';
                    
                    try {
                      String url = '';
                      if (selectedFile!.bytes != null) {
                        url = await WordPressUploadService.uploadBytes(selectedFile!.bytes!, fileName);
                      } else if (selectedFile!.path != null) {
                        url = await WordPressUploadService.uploadFile(selectedFile!.path!, fileName);
                      } else {
                        throw Exception('No file data available');
                      }

                      final actions = ref.read(adminActionsProvider);
                      await actions.uploadContract({
                        'project_id': selectedProjectId!,
                        'title': titleCtrl.text.trim(),
                        'file_url': url,
                      });
                      ref.invalidate(allContractsProvider);
                      if (ctx.mounted) Navigator.pop(ctx);
                    } catch (e) {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Upload Contract', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
