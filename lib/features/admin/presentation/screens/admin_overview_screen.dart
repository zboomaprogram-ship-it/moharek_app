import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminOverviewScreen extends ConsumerWidget {
  const AdminOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminOverviewProvider);

    final isMobile = MediaQuery.of(context).size.width < 1000;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PageHeader(
              title: 'النظرة العامة',
              subtitle: 'ملخص أداء محرك هذا الشهر والنشاط الحالي',
              isMobile: isMobile,
            ),
            const SizedBox(height: 32),

            // KPI Cards Row
            stats.when(
              loading: () => _KpiRowSkeleton(isMobile: isMobile),
              error: (e, _) => Center(
                child: Text(
                  'Error: $e',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              data: (d) => LayoutBuilder(
                builder: (context, constraints) {
                  final kpiWidth = isMobile 
                    ? (constraints.maxWidth > 500 ? (constraints.maxWidth - 20) / 2 : constraints.maxWidth)
                    : 240.0;
                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      _KpiCard(
                        label: 'إجمالي العملاء',
                        value: '${d.totalClients}',
                        icon: Icons.business_center_outlined,
                        color: AppTheme.primaryGreen,
                        width: kpiWidth,
                      ),
                      _KpiCard(
                        label: 'عملاء نشطون',
                        value: '${d.activeClients}',
                        icon: Icons.check_circle_outline,
                        color: const Color(0xFF2196F3),
                        width: kpiWidth,
                      ),
                      _KpiCard(
                        label: 'مديرو الحسابات',
                        value: '${d.totalAMs}',
                        icon: Icons.people_alt_outlined,
                        color: const Color(0xFFFFC107),
                        width: kpiWidth,
                      ),
                      _KpiCard(
                        label: 'متوسط مؤشر الصحة',
                        value: '${d.avgHealthScore.toStringAsFixed(0)}%',
                        icon: Icons.favorite_outline,
                        color: const Color(0xFFEF4444),
                        width: kpiWidth,
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // Performance Table & Alerts Row
            if (isMobile)
              const Column(
                children: [
                  _AmPerformanceSection(),
                  SizedBox(height: 24),
                  _QuickAlertsSection(),
                  SizedBox(height: 24),
                  _ProjectDistributionSection(),
                  SizedBox(height: 24),
                  _RecentActivitySection(),
                ],
              )
            else
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AM Performance Table (Left 65%)
                  Expanded(flex: 65, child: _AmPerformanceSection()),
                  SizedBox(width: 24),
                  // Alerts & Activity (Right 35%)
                  Expanded(
                    flex: 35,
                    child: Column(
                      children: [
                        _QuickAlertsSection(),
                        SizedBox(height: 24),
                        _ProjectDistributionSection(),
                        SizedBox(height: 24),
                        _RecentActivitySection(),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isMobile;
  const _PageHeader({
    required this.title,
    required this.subtitle,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 22 : 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final double width;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 20),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmPerformanceSection extends ConsumerWidget {
  const _AmPerformanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ams = ref.watch(amPerformanceListProvider);

    final isMobile = MediaQuery.of(context).size.width < 1000;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'أداء مديري الحسابات',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/admin/team'),
                child: const Text('عرض الكل'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (!isMobile) ...[
            _buildTableHeader(),
            const Divider(color: Color(0xFF334155), height: 32),
          ],
          ams.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (list) => Column(
              children: list.map((am) => isMobile 
                ? _buildMobileAmCard(context, am)
                : _buildTableRow(context, am)
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileAmCard(BuildContext context, AmPerformance am) {
    return InkWell(
      onTap: () => context.go('/admin/team/${am.amId}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  backgroundImage: am.avatarUrl != null ? NetworkImage(am.avatarUrl!) : null,
                  child: am.avatarUrl == null ? Text(am.name.isNotEmpty ? am.name[0] : 'A', style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 14, fontWeight: FontWeight.bold)) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    am.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF64748B), size: 20),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white10),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCompactStat('العملاء', '${am.totalClients}'),
                _buildCompactStat('الاستجابة', am.avgResponseTimeHours > 0 ? '${am.avgResponseTimeHours}h' : '—'),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('مؤشر الصحة', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(
                      '${am.avgHealthScore.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: am.avgHealthScore >= 70 ? AppTheme.primaryGreen : am.avgHealthScore >= 40 ? Colors.orange : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }

  Widget _buildTableHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'مدير الحساب',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'العملاء',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'متوسط الصحة',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'وقت الاستجابة',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          ),
          Expanded(flex: 1, child: SizedBox()),
        ],
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, AmPerformance am) {
    return InkWell(
      onTap: () => context.go('/admin/team/${am.amId}'),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.primaryGreen.withValues(
                      alpha: 0.1,
                    ),
                    backgroundImage: am.avatarUrl != null
                        ? NetworkImage(am.avatarUrl!)
                        : null,
                    child: am.avatarUrl == null
                        ? Text(
                            am.name.isNotEmpty ? am.name[0] : 'A',
                            style: const TextStyle(
                              color: AppTheme.primaryGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      am.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                '${am.totalClients}',
                style: const TextStyle(color: Color(0xFF94A3B8)),
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: am.avgHealthScore / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          color: am.avgHealthScore >= 70
                              ? AppTheme.primaryGreen
                              : am.avgHealthScore >= 40
                              ? Colors.orange
                              : Colors.red,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${am.avgHealthScore.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                am.avgResponseTimeHours > 0
                    ? '${am.avgResponseTimeHours}h'
                    : '—',
                style: const TextStyle(color: Color(0xFF94A3B8)),
              ),
            ),
            Expanded(
              flex: 1,
              child: IconButton(
                icon: const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF64748B),
                  size: 20,
                ),
                onPressed: () => context.go('/admin/team/${am.amId}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAlertsSection extends ConsumerWidget {
  const _QuickAlertsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(criticalAlertsProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFEF4444),
                size: 20,
              ),
              SizedBox(width: 10),
              Text(
                'تنبيهات حرجة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          alerts.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(
              'Error: $e',
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
            data: (list) {
              if (list.isEmpty) {
                return const Text(
                  'لا توجد تنبيهات حرجة حالياً',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                );
              }
              return Column(
                children: list
                    .map((a) => _buildAlertItem(a['message'], a['time']))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(String message, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              color: Color(0xFFEF4444),
              size: 14,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentActivitySection extends ConsumerWidget {
  const _RecentActivitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(adminLogsProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'آخر العمليات',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/admin/logs'),
                child: const Text(
                  'السجل الكامل',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          logs.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(
              'Error: $e',
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
            data: (list) {
              final latest = list.take(6).toList();
              if (latest.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.history_toggle_off,
                          color: Color(0xFF334155),
                          size: 40,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'لا توجد عمليات مسجلة',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: latest.map((log) {
                  final profile = log['profiles'] as Map<String, dynamic>?;
                  final name = profile?['full_name'] ?? 'System';
                  return _buildActivityItem(
                    name,
                    log['action'] ?? '',
                    log['created_at'].toString().split('T')[0],
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String actor, String action, String time) {
    IconData icon = Icons.info_outline;
    Color color = AppTheme.primaryBlue;

    if (action.contains('حذف')) {
      icon = Icons.delete_outline;
      color = Colors.redAccent;
    } else if (action.contains('إنشاء') || action.contains('إضافة')) {
      icon = Icons.add_circle_outline;
      color = AppTheme.primaryGreen;
    } else if (action.contains('تعديل') || action.contains('تحديث')) {
      icon = Icons.edit_outlined;
      color = Colors.orange;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 13,
                    ),
                    children: [
                      TextSpan(
                        text: actor,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(text: ': $action'),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectDistributionSection extends ConsumerWidget {
  const _ProjectDistributionSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminOverviewProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'توزيع المشاريع',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          statsAsync.when(
            loading: () => const SizedBox(
              height: 150,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Error: $e'),
            data: (stats) {
              final active = stats.activeClients.toDouble();
              final inactive = (stats.totalClients - stats.activeClients)
                  .toDouble();
              final total = stats.totalClients.toDouble();

              return Column(
                children: [
                  SizedBox(
                    height: 150,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 40,
                        sections: [
                          PieChartSectionData(
                            value: active,
                            title: active > 0
                                ? '${((active / total) * 100).toStringAsFixed(0)}%'
                                : '',
                            color: AppTheme.primaryGreen,
                            radius: 20,
                            titleStyle: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                          PieChartSectionData(
                            value: inactive,
                            title: inactive > 0
                                ? '${((inactive / total) * 100).toStringAsFixed(0)}%'
                                : '',
                            color: const Color(0xFF334155),
                            radius: 20,
                            titleStyle: const TextStyle(
                              color: Colors.white54,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildLegendItem(
                    'مشاريع نشطة',
                    '${stats.activeClients}',
                    AppTheme.primaryGreen,
                  ),
                  const SizedBox(height: 12),
                  _buildLegendItem(
                    'مشاريع متوقفة / مكتملة',
                    '${stats.totalClients - stats.activeClients}',
                    const Color(0xFF334155),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        ),
        const Spacer(),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _KpiRowSkeleton extends StatelessWidget {
  final bool isMobile;
  const _KpiRowSkeleton({this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      children: List.generate(
        4,
        (index) => Container(
          width: isMobile ? (MediaQuery.of(context).size.width - 52) / 2 : 240,
          height: 140,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
