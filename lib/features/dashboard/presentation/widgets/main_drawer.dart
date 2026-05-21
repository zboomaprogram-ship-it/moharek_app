import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/shared/services/haptic_service.dart';
import 'package:moharek_app/core/config/app_config.dart';

class MainDrawer extends ConsumerWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Drawer(
      backgroundColor: AppTheme.background,
      child: Column(
        children: [
          // Header
          profileAsync.when(
            data: (profile) => UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: AppTheme.cardColor),
              currentAccountPicture: CircleAvatar(
                backgroundColor: AppTheme.primaryGreen,
                backgroundImage: profile?.avatarUrl != null 
                  ? NetworkImage(profile!.avatarUrl!) 
                  : null,
                child: profile?.avatarUrl == null 
                  ? Text(profile?.fullName[0] ?? 'U', style: const TextStyle(color: Colors.black))
                  : null,
              ),
              accountName: Text(profile?.fullName ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: Text(profile?.companyName ?? 'Moharek Client'),
            ),
            loading: () => const DrawerHeader(child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const DrawerHeader(child: Icon(Icons.error)),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildItem(
                  context,
                  leading: Image.asset(AppConfig.logoAsset, height: 22, width: 22, fit: BoxFit.contain),
                  title: AppConfig.flavorName == 'rabhan'
                      ? (isAr ? 'نظام النمو' : 'Growth System')
                      : (isAr ? 'الاستراتيجية' : 'Strategy'),
                  onTap: () => context.push(
                    AppConfig.flavorName == 'rabhan'
                        ? '/dashboard/growth-system'
                        : '/strategy',
                  ),
                ),
                _buildItem(
                  context,
                  leading: const Icon(Icons.check_circle_outline, color: Colors.white70, size: 22),
                  title: isAr ? 'الموافقات' : 'Approvals',
                  onTap: () => context.push('/dashboard/approvals'),
                ),
                _buildItem(
                  context,
                  leading: const Icon(Icons.campaign_outlined, color: Colors.white70, size: 22),
                  title: isAr ? 'الحملات' : 'Campaigns',
                  onTap: () => context.push('/dashboard/campaigns'),
                ),
                _buildItem(
                  context,
                  leading: const Icon(Icons.folder_open_outlined, color: Colors.white70, size: 22),
                  title: isAr ? 'الملفات' : 'Files',
                  onTap: () => context.push('/dashboard/files'),
                ),
                _buildItem(
                  context,
                  leading: const Icon(Icons.videocam_outlined, color: Colors.white70, size: 22),
                  title: isAr ? 'الاجتماعات' : 'Meetings',
                  onTap: () => context.push('/dashboard/meetings'),
                ),
                _buildItem(
                  context,
                  leading: const Icon(Icons.receipt_long_outlined, color: Colors.white70, size: 22),
                  title: isAr ? 'الفواتير' : 'Billing',
                  onTap: () => context.push('/dashboard/billing'),
                ),
                _buildItem(
                  context,
                  leading: const Icon(Icons.help_outline, color: Colors.white70, size: 22),
                  title: isAr ? 'الدعم' : 'Support',
                  onTap: () => context.push('/profile/support'),
                ),
                const Divider(color: Colors.white10),
                if (AppConfig.flavorName == 'rabhan') ...[
                  _buildItem(
                    context,
                    leading: const Icon(Icons.workspace_premium_outlined, color: Colors.amber, size: 22),
                    title: isAr ? 'الحساب والباقة' : 'Growth Pro',
                    onTap: () => context.push('/dashboard/package'),
                  ),
                  const Divider(color: Colors.white10),
                ],
                _buildItem(
                  context,
                  leading: const Icon(Icons.person_outline, color: Colors.white70, size: 22),
                  title: isAr ? 'الملف الشخصي' : 'Profile',
                  onTap: () => context.push('/profile'),
                ),
              ],
            ),
          ),
          
          // Footer
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'v3.0.0 — ${AppConfig.appName} Growth Hub',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, {required Widget leading, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: leading,
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
      onTap: () {
        HapticService.light();
        Navigator.pop(context);
        onTap();
      },
    );
  }
}
