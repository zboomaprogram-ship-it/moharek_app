import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:moharek_app/shared/services/data_providers.dart';

class AdminBillingScreen extends ConsumerWidget {
  const AdminBillingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(billingStatsProvider);
    final invoicesAsync = ref.watch(allInvoicesProvider);
    final isMobile = MediaQuery.of(context).size.width < 1000;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الفواتير والمالية',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'إدارة المدفوعات والاشتراكات لجميع العملاء',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showCreateInvoiceDialog(context, ref),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('إصدار فاتورة جديدة'),
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
                        'الفواتير والمالية',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'إدارة المدفوعات والاشتراكات لجميع العملاء',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateInvoiceDialog(context, ref),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('إصدار فاتورة جديدة'),
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

            statsAsync.when(
              data: (stats) => LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = isMobile
                      ? (constraints.maxWidth > 600
                          ? (constraints.maxWidth - 20) / 2
                          : constraints.maxWidth)
                      : (constraints.maxWidth - 60) / 4;
                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      _buildStatCard(
                        'إجمالي المفوتر',
                        stats.totalBilled,
                        Icons.account_balance_wallet_outlined,
                        AppTheme.primaryGreen,
                        width: cardWidth,
                        isMobile: isMobile,
                      ),
                      _buildStatCard(
                        'المبالغ المحصلة',
                        stats.totalPaid,
                        Icons.check_circle_outline,
                        Colors.blueAccent,
                        width: cardWidth,
                        isMobile: isMobile,
                      ),
                      _buildStatCard(
                        'المبالغ المستحقة',
                        stats.outstanding,
                        Icons.error_outline,
                        Colors.orangeAccent,
                        width: cardWidth,
                        isMobile: isMobile,
                      ),
                      _buildStatCard(
                        'عدد الفواتير',
                        stats.totalInvoices.toDouble(),
                        Icons.description_outlined,
                        Colors.purpleAccent,
                        isCurrency: false,
                        width: cardWidth,
                        isMobile: isMobile,
                      ),
                    ],
                  );
                },
              ),
              loading: () => const LinearProgressIndicator(color: AppTheme.primaryGreen),
              error: (e, _) => Text('Error: $e'),
            ),

            const SizedBox(height: 40),

            const Text(
              'أحدث الفواتير',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            invoicesAsync.when(
              data: (invoices) => isMobile
                  ? Column(
                      children: invoices.map((inv) => _buildInvoiceCard(context, inv)).toList(),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(const Color(0xFF0F172A)),
                            dataRowMaxHeight: 70,
                            columns: const [
                              DataColumn(label: Text('رقم الفاتورة', style: TextStyle(color: Color(0xFF94A3B8)))),
                              DataColumn(label: Text('العميل', style: TextStyle(color: Color(0xFF94A3B8)))),
                              DataColumn(label: Text('المبلغ', style: TextStyle(color: Color(0xFF94A3B8)))),
                              DataColumn(label: Text('التاريخ', style: TextStyle(color: Color(0xFF94A3B8)))),
                              DataColumn(label: Text('الحالة', style: TextStyle(color: Color(0xFF94A3B8)))),
                              DataColumn(label: Text('إجراءات', style: TextStyle(color: Color(0xFF94A3B8)))),
                            ],
                            rows: invoices.map((inv) => DataRow(
                              cells: [
                                DataCell(Text(inv['invoice_number'] ?? '#---', style: const TextStyle(color: Colors.white))),
                                DataCell(Text(inv['projects']?['name'] ?? 'غير معروف', style: const TextStyle(color: Colors.white))),
                                DataCell(Text('${inv['amount']} ${inv['currency']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                DataCell(Text(DateFormat('yyyy-MM-dd').format(DateTime.parse(inv['created_at'])), style: const TextStyle(color: Color(0xFF64748B)))),
                                DataCell(_buildStatusBadge(inv['status'])),
                                DataCell(Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_red_eye_outlined, size: 20, color: Color(0xFF94A3B8)),
                                      onPressed: () => _openInvoice(context, inv['file_url']),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.download_outlined, size: 20, color: Color(0xFF94A3B8)),
                                      onPressed: () => _openInvoice(context, inv['file_url']),
                                    ),
                                  ],
                                )),
                              ],
                            )).toList(),
                          ),
                        ),
                      ),
                    ),
              loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openInvoice(BuildContext context, String? url) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد ملف متاح لهذه الفاتورة')),
      );
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح الملف')),
        );
      }
    }
  }

  Widget _buildStatCard(
    String label,
    double value,
    IconData icon,
    Color color, {
    bool isCurrency = true,
    required double width,
    required bool isMobile,
  }) {
    final formatter = NumberFormat.currency(symbol: '', decimalDigits: 0);
    return Container(
      width: width,
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E293B),
            color.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: isMobile ? 20 : 24),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              isCurrency ? '${formatter.format(value)} AED' : formatter.format(value),
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 20 : 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(BuildContext context, Map<String, dynamic> inv) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                inv['invoice_number'] ?? '#---',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              _buildStatusBadge(inv['status']),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('العميل', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                  Text(
                    inv['projects']?['name'] ?? 'غير معروف',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('المبلغ', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                  Text(
                    '${inv['amount']} ${inv['currency']}',
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('yyyy-MM-dd').format(DateTime.parse(inv['created_at'])),
                style: const TextStyle(color: Color(0xFF475569), fontSize: 11),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_red_eye_outlined, size: 18, color: Color(0xFF64748B)),
                    onPressed: () => _openInvoice(context, inv['file_url']),
                  ),
                  IconButton(
                    icon: const Icon(Icons.download_outlined, size: 18, color: Color(0xFF64748B)),
                    onPressed: () => _openInvoice(context, inv['file_url']),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    final bool isPaid = status == 'paid';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isPaid ? AppTheme.primaryGreen : Colors.orangeAccent).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isPaid ? 'مدفوعة' : 'بانتظار الدفع',
        style: TextStyle(
          color: isPaid ? AppTheme.primaryGreen : Colors.orangeAccent,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showCreateInvoiceDialog(BuildContext context, WidgetRef ref) {
    final amountCtrl = TextEditingController();
    final numberCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? selectedProjectId;
    PlatformFile? selectedFile;
    bool loading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            'إصدار فاتورة جديدة',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('اختر المشروع:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                const SizedBox(height: 8),
                Consumer(
                  builder: (context, ref, _) {
                    final projectsAsync = ref.watch(allProjectsProvider);
                    return projectsAsync.when(
                      data: (projects) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedProjectId,
                            hint: const Text('اختر المشروع', style: TextStyle(color: Color(0xFF64748B))),
                            dropdownColor: const Color(0xFF1E293B),
                            isExpanded: true,
                            items: projects.map((p) => DropdownMenuItem(
                              value: p['id'] as String,
                              child: Text(p['name'] ?? 'مشروع', style: const TextStyle(color: Colors.white)),
                            )).toList(),
                            onChanged: (val) => setModalState(() => selectedProjectId = val),
                          ),
                        ),
                      ),
                      loading: () => const LinearProgressIndicator(color: AppTheme.primaryGreen),
                      error: (_, __) => const Text('Error loading projects', style: TextStyle(color: Colors.red)),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildInput(numberCtrl, 'رقم الفاتورة (مثال: INV-1001)', Icons.numbers),
                const SizedBox(height: 16),
                _buildInput(amountCtrl, 'المبلغ (AED)', Icons.attach_money, keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                _buildInput(descCtrl, 'وصف الفاتورة (اختياري)', Icons.description),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final result = await FilePicker.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf'],
                      withData: kIsWeb,
                    );
                    if (result != null) {
                      setModalState(() => selectedFile = result.files.first);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.attach_file, color: AppTheme.primaryBlue, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            selectedFile?.name ?? 'إرفاق ملف الفاتورة (PDF)',
                            style: TextStyle(
                              color: selectedFile != null ? Colors.white : const Color(0xFF64748B),
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      if (selectedProjectId == null || amountCtrl.text.isEmpty || numberCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('يرجى ملء جميع الحقول المطلوبة')),
                        );
                        return;
                      }

                      setModalState(() => loading = true);
                      try {
                        String? fileUrl;
                        if (selectedFile != null) {
                          final client = ref.read(supabaseClientProvider);
                          final fileName = 'invoice_${DateTime.now().millisecondsSinceEpoch}.pdf';
                          
                          if (kIsWeb && selectedFile!.bytes != null) {
                            await client.storage.from('invoices').uploadBinary(
                                  fileName,
                                  selectedFile!.bytes!,
                                );
                          } else if (!kIsWeb && selectedFile!.path != null) {
                            // Non-web handling would go here if needed, 
                            // but for this dashboard usually kIsWeb is true
                          }
                          fileUrl = client.storage.from('invoices').getPublicUrl(fileName);
                        }

                        final actions = ref.read(adminActionsProvider);
                        await actions.createInvoices([
                          {
                            'project_id': selectedProjectId,
                            'invoice_number': numberCtrl.text.trim(),
                            'amount': double.parse(amountCtrl.text.trim()),
                            'currency': 'AED',
                            'description': descCtrl.text.trim(),
                            'status': 'pending',
                            'file_url': fileUrl,
                            'due_date': DateTime.now().add(const Duration(days: 14)).toIso8601String(),
                          }
                        ]);

                        ref.invalidate(allInvoicesProvider);
                        ref.invalidate(billingStatsProvider);

                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
                          );
                        }
                      } finally {
                        setModalState(() => loading = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.black,
              ),
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Text('إصدار', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String hint, IconData icon, {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 18),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
