import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/features/rabhan/providers/package_provider.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/features/rabhan/models/package_model.dart';

class RabhanPackageTab extends ConsumerStatefulWidget {
  final String pid;
  const RabhanPackageTab({super.key, required this.pid});

  @override
  ConsumerState<RabhanPackageTab> createState() => _RabhanPackageTabState();
}

class _RabhanPackageTabState extends ConsumerState<RabhanPackageTab> {
  final _nameCtrl = TextEditingController();
  final _limitCtrl = TextEditingController();
  final _usedCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  
  String _selectedTier = 'starter';
  String _selectedStatus = 'active';
  DateTime? _renewsAt;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _limitCtrl.dispose();
    _usedCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _initFields(PackageModel? pkg) {
    if (pkg == null) return;
    _nameCtrl.text = pkg.packageName;
    _limitCtrl.text = pkg.requestsLimit.toString();
    _usedCtrl.text = pkg.requestsUsed.toString();
    _notesCtrl.text = pkg.notes ?? '';
    _selectedTier = pkg.packageTier;
    _selectedStatus = pkg.status;
    _renewsAt = pkg.renewsAt;
  }

  Future<void> _save(PackageModel? existingPkg) async {
    setState(() => _saving = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final payload = {
        'project_id': widget.pid,
        'package_name': _nameCtrl.text.trim().isEmpty ? 'Growth Pro' : _nameCtrl.text.trim(),
        'package_tier': _selectedTier,
        'status': _selectedStatus,
        'requests_limit': int.tryParse(_limitCtrl.text) ?? 200,
        'requests_used': int.tryParse(_usedCtrl.text) ?? 0,
        'notes': _notesCtrl.text.trim(),
        'renews_at': _renewsAt?.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (existingPkg != null) {
        await client.from('packages').update(payload).eq('id', existingPkg.id);
      } else {
        await client.from('packages').insert(payload);
      }

      ref.invalidate(packageProvider(widget.pid));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ الباقة بنجاح ✅'), backgroundColor: AppTheme.primaryGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final packageAsync = ref.watch(packageProvider(widget.pid));

    return packageAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      error: (e, _) => Center(child: Text('خطأ: $e', style: const TextStyle(color: Colors.red))),
      data: (pkg) {
        // Initialize fields once
        if (!_saving && _nameCtrl.text.isEmpty && pkg != null) {
          _initFields(pkg);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pkg == null ? 'لا توجد باقة نشطة - إنشاء باقة جديدة' : 'إدارة باقة العميل',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              _buildField(_nameCtrl, 'اسم الباقة (مثال: الباقة المتقدمة)', Icons.workspace_premium),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('مستوى الباقة', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 6),
                        _buildDropdown(
                          value: _selectedTier,
                          items: const ['starter', 'growth', 'pro', 'enterprise'],
                          onChanged: (val) => setState(() => _selectedTier = val!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('حالة الباقة', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 6),
                        _buildDropdown(
                          value: _selectedStatus,
                          items: const ['active', 'trial', 'expired', 'suspended'],
                          onChanged: (val) => setState(() => _selectedStatus = val!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildField(_limitCtrl, 'الحد الأقصى للطلبات', Icons.speed, type: TextInputType.number),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildField(_usedCtrl, 'الطلبات المستخدمة', Icons.done_all, type: TextInputType.number),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text('تاريخ التجديد', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 6),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _renewsAt ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: AppTheme.primaryGreen,
                            onPrimary: Colors.black,
                            surface: AppTheme.cardColor,
                            onSurface: Colors.white,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() => _renewsAt = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _renewsAt == null ? 'اختر تاريخ التجديد' : _renewsAt!.toLocal().toString().split(' ')[0],
                        style: const TextStyle(color: Colors.white),
                      ),
                      const Icon(Icons.calendar_today, color: Colors.grey, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _buildField(_notesCtrl, 'ملاحظات إضافية', Icons.note, maxLines: 3),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _saving ? null : () => _save(pkg),
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Text('حفظ الإعدادات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint, IconData icon, {TextInputType type = TextInputType.text, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.grey, size: 18),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5), borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildDropdown({required String value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF1E293B),
          items: items.map((i) => DropdownMenuItem(
            value: i,
            child: Text(i.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 13)),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
