import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/l10n/app_localizations.dart';

class ClientRequestBottomSheet extends ConsumerStatefulWidget {
  const ClientRequestBottomSheet({super.key});

  @override
  ConsumerState<ClientRequestBottomSheet> createState() => _ClientRequestBottomSheetState();
}

class _ClientRequestBottomSheetState extends ConsumerState<ClientRequestBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _requestType = 'Content Edit';
  DateTime? _selectedDate;
  bool _isUrgent = false;
  bool _isLoading = false;

  final List<String> _requestTypes = [
    'Content Edit',
    'New Page Request',
    'SEO Campaign Idea',
    'Report Clarification',
    'Other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    try {
      final client = ref.read(supabaseClientProvider);
      final project = ref.read(currentProjectProvider).value;
      
      if (project == null) throw Exception('No project found');

      await client.from('tasks').insert({
        'project_id': project.id,
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'category': 'client_request',
        'is_client_request': true,
        'request_type': _requestType,
        'priority': _isUrgent ? 'urgent' : 'normal',
        'client_proposed_deadline': _selectedDate?.toIso8601String(),
        'status': 'new',
        'created_by': client.auth.currentUser?.id,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'تم إرسال طلبك بنجاح!' : 'Request sent successfully!'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24, left: 24, right: 24,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAr ? 'طلب جديد' : 'New Request',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                isAr ? 'كيف يمكننا مساعدتك؟' : 'How can we help you?',
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 24),
              
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: isAr ? 'عنوان الطلب' : 'Request Title',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                validator: (v) => v == null || v.isEmpty ? (isAr ? 'مطلوب' : 'Required') : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _requestType,
                dropdownColor: AppTheme.cardColor,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: isAr ? 'نوع الطلب' : 'Request Type',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: _requestTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _requestType = v!),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: isAr ? 'التفاصيل' : 'Details',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final now = DateTime.now();
                        final date = await showDatePicker(
                          context: context,
                          initialDate: now.add(const Duration(days: 3)),
                          firstDate: now,
                          lastDate: now.add(const Duration(days: 365)),
                        );
                        if (date != null) setState(() => _selectedDate = date);
                      },
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        _selectedDate == null 
                          ? (isAr ? 'موعد مقترح' : 'Proposed Deadline')
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildUrgentToggle(isAr),
                ],
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : Text(isAr ? 'إرسال الطلب' : 'Send Request', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUrgentToggle(bool isAr) {
    return GestureDetector(
      onTap: () => setState(() => _isUrgent = !_isUrgent),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _isUrgent ? Colors.redAccent.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _isUrgent ? Colors.redAccent : Colors.white10),
        ),
        child: Row(
          children: [
            Icon(Icons.flash_on, color: _isUrgent ? Colors.redAccent : Colors.grey, size: 18),
            const SizedBox(width: 8),
            Text(
              isAr ? 'عاجل' : 'Urgent',
              style: TextStyle(color: _isUrgent ? Colors.redAccent : Colors.grey, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
