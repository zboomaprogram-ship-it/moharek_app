import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/shared/widgets/fade_in_slide.dart';

class CompanyProfileScreen extends ConsumerWidget {
  const CompanyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(currentProjectProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ملف الشركة', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: projectAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (project) {
          if (project == null) {
            return const Center(child: Text('لا يوجد مشروع نشط حالياً', style: TextStyle(color: Colors.white70)));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(project),
                const SizedBox(height: 32),
                _buildSectionHeader('أهداف المشروع'),
                const SizedBox(height: 12),
                _buildInfoCard(project.projectGoal ?? 'لا يوجد هدف محدد حالياً'),
                const SizedBox(height: 32),
                _buildSectionHeader('السوق المستهدف'),
                const SizedBox(height: 12),
                _buildInfoCard(project.targetMarket ?? 'غير محدد'),
                const SizedBox(height: 32),
                _buildSectionHeader('المنافسون'),
                const SizedBox(height: 12),
                _buildCompetitorsList(project.competitors),
                const SizedBox(height: 32),
                _buildSectionHeader('الاشتراك والنمو'),
                const SizedBox(height: 12),
                _buildSubscriptionDetails(project),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(project) {
    return FadeInSlide(
      duration: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.primaryGreen,
              child: Icon(Icons.business, color: Colors.black, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'الحالة: ${project.status}',
                    style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
    );
  }

  Widget _buildInfoCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, height: 1.5),
      ),
    );
  }

  Widget _buildCompetitorsList(List<String>? competitors) {
    if (competitors == null || competitors.isEmpty) {
      return _buildInfoCard('لم يتم إضافة منافسين بعد');
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: competitors.map((c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
        ),
        child: Text(c, style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 12, fontWeight: FontWeight.bold)),
      )).toList(),
    );
  }

  Widget _buildSubscriptionDetails(project) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          _buildDetailRow('الباقة الحالية', project.subscriptionTier?.toUpperCase() ?? 'FREE', Icons.star),
          const Divider(color: Color(0xFF334155), height: 32),
          _buildDetailRow('المرحلة الحالية', project.currentStage, Icons.insights),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryGreen, size: 18),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        const Spacer(),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
