import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/shared/models/campaign.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/core/config/app_config.dart';
import 'package:moharek_app/features/rabhan/models/ad_campaign.dart';
import 'package:moharek_app/features/rabhan/providers/ad_campaign_provider.dart';

class CampaignsTab extends ConsumerWidget {
  final String pid;
  const CampaignsTab({super.key, required this.pid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRabhan = AppConfig.flavorName == 'rabhan';
    final campaignsAsync = isRabhan
        ? ref.watch(adCampaignsProvider(pid))
        : ref.watch(projectCampaignsProvider(pid));

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_campaign_$pid',
        backgroundColor: AppTheme.primaryGreen,
        onPressed: () => _showEditCampaign(context, ref, null, isRabhan),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: campaignsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
        data: (campaigns) {
          if (campaigns.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.campaign_outlined, color: Colors.grey, size: 48),
                  SizedBox(height: 16),
                  Text('لا توجد حملات إعلانية', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: campaigns.length,
            itemBuilder: (context, index) {
              if (isRabhan) {
                final c = campaigns[index] as AdCampaign;
                return _buildAdCampaignCard(context, ref, c);
              } else {
                final c = ProjectCampaign.fromJson(campaigns[index] as Map<String, dynamic>);
                return _buildCampaignCard(context, ref, c);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildAdCampaignCard(BuildContext context, WidgetRef ref, AdCampaign c) {
    final statusColor = c.status == 'active' ? AppTheme.primaryGreen 
                        : c.status == 'paused' ? Colors.orangeAccent
                        : Colors.grey;

    final platformIcon = switch (c.platform.toLowerCase()) {
      'meta' || 'facebook' || 'instagram' => Icons.facebook,
      'google' || 'youtube' => Icons.g_mobiledata,
      'tiktok' => Icons.music_note,
      'snapchat' => Icons.snapchat,
      _ => Icons.campaign,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(platformIcon, color: AppTheme.primaryGreen, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  c.campaignName,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 0.5),
                ),
                child: Text(
                  c.status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryGreen, size: 18),
                    onPressed: () => _showEditCampaign(context, ref, c, true),
                    tooltip: 'تعديل',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                    onPressed: () => _confirmDeleteAd(context, ref, c),
                    tooltip: 'حذف',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metricLabelVal('الميزانية', '${c.budget} ${c.currency}'),
              _metricLabelVal('الإنفاق', '${c.spend} ${c.currency}'),
              _metricLabelVal('ROAS', '${c.roas}x'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metricLabelVal('النقرات', '${c.clicks}'),
              _metricLabelVal('الظهور', '${c.impressions}'),
              _metricLabelVal('التحويلات', '${c.conversions}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricLabelVal(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCampaignCard(BuildContext context, WidgetRef ref, ProjectCampaign c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  c.channel.toUpperCase(),
                  style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryGreen, size: 18),
                    onPressed: () => _showEditCampaign(context, ref, c, false),
                    tooltip: 'تعديل',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                    onPressed: () => _confirmDelete(context, ref, c),
                    tooltip: 'حذف',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(c.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          if (c.goal != null && c.goal!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(c.goal!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _metric(Icons.payments_outlined, '${c.budget ?? 0} ${c.currency}'),
              const SizedBox(width: 16),
              _metric(Icons.timer_outlined, c.status.toUpperCase()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(IconData icon, String val) {
    return Row(
      children: [
        Icon(icon, color: Colors.white24, size: 14),
        const SizedBox(width: 6),
        Text(val, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  void _showEditCampaign(BuildContext context, WidgetRef ref, dynamic campaign, bool isRabhan) {
    final isEditing = campaign != null;
    final nameCtrl = TextEditingController(
      text: isRabhan ? (campaign as AdCampaign?)?.campaignName ?? '' : (campaign as ProjectCampaign?)?.name ?? ''
    );
    final goalCtrl = TextEditingController(text: isRabhan ? '' : (campaign as ProjectCampaign?)?.goal ?? '');
    final budgetCtrl = TextEditingController(
      text: isRabhan ? (campaign as AdCampaign?)?.budget.toString() ?? '' : (campaign as ProjectCampaign?)?.budget?.toString() ?? ''
    );

    final spendCtrl = TextEditingController(text: isRabhan ? (campaign as AdCampaign?)?.spend.toString() ?? '0.0' : '');
    final roasCtrl = TextEditingController(text: isRabhan ? (campaign as AdCampaign?)?.roas.toString() ?? '0.0' : '');
    final clicksCtrl = TextEditingController(text: isRabhan ? (campaign as AdCampaign?)?.clicks.toString() ?? '0' : '');
    final impressionsCtrl = TextEditingController(text: isRabhan ? (campaign as AdCampaign?)?.impressions.toString() ?? '0' : '');
    final conversionsCtrl = TextEditingController(text: isRabhan ? (campaign as AdCampaign?)?.conversions.toString() ?? '0' : '');

    String platform = isRabhan ? (campaign as AdCampaign?)?.platform ?? 'meta' : (campaign as ProjectCampaign?)?.channel ?? 'google_ads';
    String status = campaign?.status ?? 'active';
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isEditing ? 'تعديل الحملة' : 'حملة إعلانية جديدة',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(nameCtrl, 'اسم الحملة', Icons.campaign),
                const SizedBox(height: 12),
                if (!isRabhan) ...[
                  _field(goalCtrl, 'الهدف (مثال: زيادة المبيعات)', Icons.flag_outlined),
                  const SizedBox(height: 12),
                ],
                _field(budgetCtrl, 'الميزانية', Icons.payments_outlined, type: TextInputType.number),
                const SizedBox(height: 12),
                if (isRabhan) ...[
                  _field(spendCtrl, 'الإنفاق الحالي', Icons.monetization_on_outlined, type: TextInputType.number),
                  const SizedBox(height: 12),
                  _field(roasCtrl, 'العائد ROAS (مثال: 2.5)', Icons.trending_up, type: TextInputType.number),
                  const SizedBox(height: 12),
                  _field(clicksCtrl, 'عدد النقرات Clicks', Icons.ads_click, type: TextInputType.number),
                  const SizedBox(height: 12),
                  _field(impressionsCtrl, 'مرات الظهور Impressions', Icons.remove_red_eye_outlined, type: TextInputType.number),
                  const SizedBox(height: 12),
                  _field(conversionsCtrl, 'عدد التحويلات Conversions', Icons.shopping_basket_outlined, type: TextInputType.number),
                  const SizedBox(height: 12),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: platform,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1E293B),
                      items: isRabhan
                          ? const [
                              DropdownMenuItem(value: 'meta', child: Text('Meta (Facebook/Instagram)', style: TextStyle(color: Colors.white))),
                              DropdownMenuItem(value: 'google', child: Text('Google Ads', style: TextStyle(color: Colors.white))),
                              DropdownMenuItem(value: 'snapchat', child: Text('Snapchat', style: TextStyle(color: Colors.white))),
                              DropdownMenuItem(value: 'tiktok', child: Text('TikTok', style: TextStyle(color: Colors.white))),
                            ]
                          : const [
                              DropdownMenuItem(value: 'google_ads', child: Text('Google Ads', style: TextStyle(color: Colors.white))),
                              DropdownMenuItem(value: 'meta_ads', child: Text('Meta Ads', style: TextStyle(color: Colors.white))),
                              DropdownMenuItem(value: 'snapchat_ads', child: Text('Snapchat Ads', style: TextStyle(color: Colors.white))),
                              DropdownMenuItem(value: 'tiktok_ads', child: Text('TikTok Ads', style: TextStyle(color: Colors.white))),
                            ],
                      onChanged: (v) => setState(() => platform = v!),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: status,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1E293B),
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('نشطة', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'paused', child: Text('متوقفة مؤقتاً', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'completed', child: Text('مكتملة', style: TextStyle(color: Colors.white))),
                      ],
                      onChanged: (v) => setState(() => status = v!),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.black),
              onPressed: saving ? null : () async {
                if (nameCtrl.text.trim().isEmpty) return;
                setState(() => saving = true);
                try {
                  final client = ref.read(supabaseClientProvider);
                  if (isRabhan) {
                    final data = {
                      'project_id': pid,
                      'campaign_name': nameCtrl.text.trim(),
                      'platform': platform,
                      'status': status,
                      'budget': double.tryParse(budgetCtrl.text) ?? 0.0,
                      'spend': double.tryParse(spendCtrl.text) ?? 0.0,
                      'roas': double.tryParse(roasCtrl.text) ?? 0.0,
                      'clicks': int.tryParse(clicksCtrl.text) ?? 0,
                      'impressions': int.tryParse(impressionsCtrl.text) ?? 0,
                      'conversions': int.tryParse(conversionsCtrl.text) ?? 0,
                      'currency': 'SAR',
                    };
                    if (isEditing) {
                      await client.from('ad_campaigns').update(data).eq('id', (campaign as AdCampaign).id);
                    } else {
                      await client.from('ad_campaigns').insert(data);
                    }
                    ref.invalidate(adCampaignsProvider(pid));
                  } else {
                    final actions = ref.read(adminActionsProvider);
                    final data = {
                      'project_id': pid,
                      'name': nameCtrl.text.trim(),
                      'goal': goalCtrl.text.trim(),
                      'budget': double.tryParse(budgetCtrl.text) ?? 0,
                      'channel': platform,
                      'status': status,
                      'currency': 'AED',
                    };
                    if (isEditing) {
                      await actions.updateCampaign((campaign as ProjectCampaign).id, data);
                    } else {
                      await actions.createCampaign(data);
                    }
                    ref.invalidate(projectCampaignsProvider(pid));
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
                } finally {
                  if (ctx.mounted) setState(() => saving = false);
                }
              },
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : Text(isEditing ? 'حفظ' : 'إنشاء', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, ProjectCampaign c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('حذف الحملة', style: TextStyle(color: Colors.white)),
        content: Text('هل تريد حذف "${c.name}"؟', style: const TextStyle(color: Color(0xFF94A3B8))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(adminActionsProvider).deleteCampaign(c.id, c.name);
      ref.invalidate(projectCampaignsProvider(pid));
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف ✅'), backgroundColor: AppTheme.primaryGreen));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _confirmDeleteAd(BuildContext context, WidgetRef ref, AdCampaign c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('حذف الحملة', style: TextStyle(color: Colors.white)),
        content: Text('هل تريد حذف "${c.campaignName}"؟', style: const TextStyle(color: Color(0xFF94A3B8))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      final client = ref.read(supabaseClientProvider);
      await client.from('ad_campaigns').delete().eq('id', c.id);
      ref.invalidate(adCampaignsProvider(pid));
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف ✅'), backgroundColor: AppTheme.primaryGreen));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
    }
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon, {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF64748B)),
        prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 18),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        border: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(10))),
      ),
    );
  }
}
