import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moharek_app/core/config/app_config.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/core/theme/rabhan_theme_constants.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/shared/models/profile.dart';
import '../models/package_model.dart';
import '../providers/package_provider.dart';

class _ThemeColors {
  static bool get isRabhan => AppConfig.flavorName == 'rabhan';
  static Color get background => isRabhan ? RabhanTheme.background : AppTheme.background;
  static Color get card => isRabhan ? RabhanTheme.card : AppTheme.cardColor;
  static Color get primaryGreen => isRabhan ? RabhanTheme.primaryGreen : AppTheme.primaryGreen;
  static Color get gold => isRabhan ? RabhanTheme.gold : Colors.amber;
  static Color get error => isRabhan ? RabhanTheme.error : Colors.redAccent;
}

class GrowthProScreen extends ConsumerWidget {
  const GrowthProScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(currentProjectProvider);
    final project = projectAsync.valueOrNull;
    final projectId = project?.id ?? '';

    final packageAsync = ref.watch(packageProvider(projectId));
    final amAsync = ref.watch(accountManagerProvider(projectId));

    return Scaffold(
      backgroundColor: _ThemeColors.background,
      appBar: AppBar(
        title: const Text('الحساب والباقة'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/dashboard/notifications'),
          ),
        ],
      ),
      body: projectId.isEmpty
          ? const Center(child: Text('لا يوجد مشروع نشط حالياً'))
          : packageAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
              error: (e, _) => const Center(child: Text('خطأ في تحميل بيانات الباقة')),
              data: (package) {
                if (package == null) {
                  return const Center(child: Text('لا توجد باقة نشطة حالياً'));
                }
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // SECTION 1: Package header
                      _PackageHeaderCard(package: package),
                      const SizedBox(height: 16),

                      // SECTION 2: Services list
                      _ServicesCard(services: package.services),
                      const SizedBox(height: 16),

                      // SECTION 3: Requests usage
                      _RequestsUsageCard(package: package),
                      const SizedBox(height: 16),

                      // SECTION 4: Account manager
                      amAsync.when(
                        loading: () => const SizedBox(
                          height: 80,
                          child: Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (am) => am != null ? _AccountManagerCard(am: am) : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 16),

                      // SECTION 5: Quick links
                      const _QuickLinksSection(),
                      const SizedBox(height: 32),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _PackageHeaderCard extends StatelessWidget {
  final PackageModel package;
  const _PackageHeaderCard({required this.package});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (package.status) {
      'active' => _ThemeColors.primaryGreen,
      'trial'  => _ThemeColors.gold,
      _        => _ThemeColors.error,
    };
    final statusLabel = switch (package.status) {
      'active' => 'نشطة',
      'trial'  => 'تجريبية',
      'expired'=> 'منتهية',
      _        => package.status,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _ThemeColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _ThemeColors.gold.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        children: [
          // Crown icon
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: _ThemeColors.gold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.workspace_premium, color: _ThemeColors.gold, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  package.packageName,
                  style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 13)),
                ]),
                if (package.renewsAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'تتجدد في ${_formatArabicDate(package.renewsAt!)}',
                    style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          // Tier badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _ThemeColors.gold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _ThemeColors.gold.withOpacity(0.4)),
            ),
            child: const Text(
              'الباقة',
              style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _formatArabicDate(DateTime d) {
    const months = ['يناير','فبراير','مارس','أبريل','مايو','يونيو',
                    'يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _ServicesCard extends StatelessWidget {
  final List<String> services;
  const _ServicesCard({required this.services});

  @override
  Widget build(BuildContext context) {
    return _RabhanCard(
      title: 'الخدمات المشمولة',
      child: services.isEmpty
          ? const Text('لا توجد خدمات مضافة حالياً', style: TextStyle(color: Colors.grey))
          : Column(
              children: services.map((s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  Icon(Icons.check_circle_outline, color: _ThemeColors.primaryGreen, size: 18),
                  const SizedBox(width: 10),
                  Text(s, style: const TextStyle(color: Colors.white, fontSize: 14)),
                ]),
              )).toList(),
            ),
    );
  }
}

class _RequestsUsageCard extends StatelessWidget {
  final PackageModel package;
  const _RequestsUsageCard({required this.package});

  @override
  Widget build(BuildContext context) {
    final used  = package.requestsUsed;
    final limit = package.requestsLimit;
    final pct   = limit == 0 ? 0.0 : used / limit;
    final barColor = pct > 0.9 ? _ThemeColors.error
                   : pct > 0.7 ? _ThemeColors.gold
                   : _ThemeColors.primaryGreen;

    return _RabhanCard(
      title: 'استخدام الطلبات الشهرية',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$used من $limit شهري',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              Text(
                '${(limit - used).clamp(0, limit)} متبقي',
                style: TextStyle(color: barColor, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountManagerCard extends StatelessWidget {
  final Profile am;
  const _AccountManagerCard({required this.am});

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return _RabhanCard(
      title: 'مدير الحساب',
      child: Row(
        children: [
          // Avatar
          Stack(children: [
            CircleAvatar(
              radius: 26,
              backgroundImage: am.avatarUrl != null && am.avatarUrl!.isNotEmpty ? NetworkImage(am.avatarUrl!) : null,
              backgroundColor: Colors.grey[800],
              child: am.avatarUrl == null || am.avatarUrl!.isEmpty
                  ? Text(_getInitials(am.fullName), style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold))
                  : null,
            ),
            Positioned(
              bottom: 0, right: 0,
              child: Container(
                width: 12, height: 12,
                decoration: BoxDecoration(
                  color: _ThemeColors.primaryGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: _ThemeColors.card, width: 2),
                ),
              ),
            ),
          ]),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(am.fullName, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                Text('متصل الآن', style: TextStyle(color: _ThemeColors.primaryGreen, fontSize: 12)),
              ],
            ),
          ),
          // Action buttons
          Row(children: [
            _AmActionBtn(icon: Icons.chat_bubble_outline, onTap: () => context.push('/chat')),
            const SizedBox(width: 8),
            _AmActionBtn(icon: Icons.video_call_outlined, onTap: () => context.push('/dashboard/meetings')),
            const SizedBox(width: 8),
            _AmActionBtn(icon: Icons.mail_outline, onTap: () {
              // Stub email action
            }),
          ]),
        ],
      ),
    );
  }
}

class _AmActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _AmActionBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: Colors.white70, size: 18),
    ),
  );
}

class _QuickLinksSection extends StatelessWidget {
  const _QuickLinksSection();

  static const links = [
    (label: 'الفواتير والمدفوعات', icon: Icons.receipt_outlined,    route: '/dashboard/billing'),
    (label: 'تقارير الأداء',       icon: Icons.bar_chart_outlined,  route: '/dashboard/analytics'),
    (label: 'مركز المساعدة والدعم',icon: Icons.help_outline,        route: '/profile/support'),
    (label: 'الإعدادات',           icon: Icons.settings_outlined,   route: '/profile/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _ThemeColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: links.map((l) => ListTile(
          leading: Icon(l.icon, color: const Color(0xFF9CA3AF), size: 20),
          title: Text(l.label, style: const TextStyle(color: Colors.white, fontSize: 14)),
          trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF), size: 18),
          onTap: () => context.push(l.route),
        )).toList(),
      ),
    );
  }
}

class _RabhanCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _RabhanCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _ThemeColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(
            color: Color(0xFF9CA3AF), fontSize: 13, fontWeight: FontWeight.w500,
          )),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
