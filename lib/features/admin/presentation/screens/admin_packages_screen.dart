import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/core/theme/rabhan_theme.dart';
import 'package:moharek_app/core/theme/rabhan_theme_constants.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';
import 'package:intl/intl.dart';

class AdminPackagesScreen extends ConsumerStatefulWidget {
  const AdminPackagesScreen({super.key});

  @override
  ConsumerState<AdminPackagesScreen> createState() =>
      _AdminPackagesScreenState();
}

class _AdminPackagesScreenState extends ConsumerState<AdminPackagesScreen> {
  String _filterStatus = 'all'; // all, active, expiring_soon

  @override
  Widget build(BuildContext context) {
    final packagesAsync = ref.watch(adminAllPackagesProvider);
    final isMobile = MediaQuery.of(context).size.width < 1000;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الباقات المشتركة',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 22 : 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'إدارة باقات العملاء واشتراكاتهم',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filterStatus,
                      dropdownColor: AppTheme.cardColor,
                      icon: const Icon(
                        Icons.filter_list,
                        color: Colors.white70,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text(
                            'الكل',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'active',
                          child: Text(
                            'نشطة',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'expiring_soon',
                          child: Text(
                            'تنتهي خلال 7 أيام',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _filterStatus = val);
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            packagesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              ),
              error: (err, _) => Center(
                child: Text(
                  'Error: $err',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              data: (packages) {
                // Apply filters
                final now = DateTime.now();
                var filtered = packages.where((pkg) {
                  if (_filterStatus == 'all') return true;
                  final status = pkg['status'] as String? ?? '';
                  final endDateStr = pkg['end_date'] as String?;
                  if (_filterStatus == 'active') {
                    return status == 'active';
                  }
                  if (_filterStatus == 'expiring_soon' && endDateStr != null) {
                    final endDate = DateTime.parse(endDateStr);
                    final diff = endDate.difference(now).inDays;
                    return status == 'active' && diff >= 0 && diff <= 7;
                  }
                  return false;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Text(
                        'لا توجد باقات',
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                    ),
                  );
                }

                return Card(
                  color: AppTheme.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Colors.white10),
                  ),
                  child: isMobile
                      ? ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const Divider(color: Colors.white10, height: 1),
                          itemBuilder: (context, i) =>
                              _buildMobileItem(filtered[i]),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: MediaQuery.of(context).size.width - 64,
                            ),
                            child: DataTable(
                              headingTextStyle: const TextStyle(
                                color: Colors.white54,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              dataTextStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              columns: const [
                                DataColumn(label: Text('العميل')),
                                DataColumn(label: Text('الباقة')),
                                DataColumn(label: Text('الحالة')),
                                DataColumn(
                                  label: Text('الطلبات (المستخدمة/الكلي)'),
                                ),
                                DataColumn(label: Text('تاريخ الانتهاء')),
                              ],
                              rows: filtered
                                  .map((pkg) => _buildDataRow(pkg))
                                  .toList(),
                            ),
                          ),
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileItem(Map<String, dynamic> pkg) {
    final projectName = pkg['projects']?['name'] ?? 'بدون مشروع';
    final clientName =
        pkg['projects']?['profiles']?['company_name'] ??
        pkg['projects']?['profiles']?['full_name'] ??
        'مجهول';
    final tier = pkg['tier'] as String? ?? 'basic';
    final status = pkg['status'] as String? ?? 'inactive';
    final used = pkg['requests_used'] ?? 0;
    final limit = pkg['requests_limit'] ?? 0;

    return ListTile(
      contentPadding: const EdgeInsets.all(16),
      title: Text(
        '$clientName ($projectName)',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildTierBadge(tier),
                const SizedBox(width: 8),
                _buildStatusBadge(status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'الطلبات: $used / $limit',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
      trailing: pkg['end_date'] != null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'تاريخ الانتهاء',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
                Text(
                  DateFormat(
                    'yyyy-MM-dd',
                  ).format(DateTime.parse(pkg['end_date'])),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            )
          : null,
    );
  }

  DataRow _buildDataRow(Map<String, dynamic> pkg) {
    final projectName = pkg['projects']?['name'] ?? 'بدون مشروع';
    final clientName =
        pkg['projects']?['profiles']?['company_name'] ??
        pkg['projects']?['profiles']?['full_name'] ??
        'مجهول';
    final tier = pkg['tier'] as String? ?? 'basic';
    final status = pkg['status'] as String? ?? 'inactive';
    final used = pkg['requests_used'] ?? 0;
    final limit = pkg['requests_limit'] ?? 0;

    return DataRow(
      cells: [
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                clientName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                projectName,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
        DataCell(_buildTierBadge(tier)),
        DataCell(_buildStatusBadge(status)),
        DataCell(Text('$used / $limit')),
        DataCell(
          pkg['end_date'] != null
              ? Text(
                  DateFormat(
                    'yyyy-MM-dd',
                  ).format(DateTime.parse(pkg['end_date'])),
                )
              : const Text('-'),
        ),
      ],
    );
  }

  Widget _buildTierBadge(String tier) {
    Color color;
    String label;
    switch (tier.toLowerCase()) {
      case 'startup':
      case 'basic':
        color = const Color(0xFF2196F3);
        label = 'انطلاق';
        break;
      case 'growth':
      case 'pro':
        color = RabhanTheme.primaryGreen;
        label = 'نمو';
        break;
      case 'scale':
      case 'enterprise':
        color = RabhanTheme.gold;
        label = 'توسع';
        break;
      default:
        color = Colors.grey;
        label = tier;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status.toLowerCase()) {
      case 'active':
        color = RabhanTheme.primaryGreen;
        label = 'نشط';
        break;
      case 'inactive':
        color = Colors.grey;
        label = 'غير نشط';
        break;
      case 'expired':
        color = Colors.redAccent;
        label = 'منتهي';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}
