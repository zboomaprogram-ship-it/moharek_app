import 'package:flutter/material.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:moharek_app/shared/services/haptic_service.dart';
import 'package:moharek_app/core/config/app_config.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(isAr ? 'مركز الدعم' : 'Support Center'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isAr),
            const SizedBox(height: 32),
            _buildSupportOption(
              context,
              icon: Icons.chat_bubble_outline,
              title: isAr ? 'المحادثة الفورية' : 'Live Chat',
              subtitle: isAr ? 'تحدث مع مدير حسابك مباشرة' : 'Talk to your account manager',
              color: AppTheme.primaryGreen,
              onTap: () {
                HapticService.light();
                // Navigate to chat
                // context.go('/chat');
              },
            ),
            const SizedBox(height: 16),
            _buildSupportOption(
              context,
              icon: Icons.chat_outlined,
              title: 'WhatsApp Support',
              subtitle: isAr ? 'دعم سريع عبر واتساب' : 'Quick support via WhatsApp',
              color: const Color(0xFF25D366),
              onTap: () => _launchWhatsApp(),
            ),
            const SizedBox(height: 16),
            _buildSupportOption(
              context,
              icon: Icons.mail_outline,
              title: isAr ? 'البريد الإلكتروني' : 'Email Support',
              subtitle: 'support@moharek.com',
              color: AppTheme.primaryBlue,
              onTap: () => _launchEmail(),
            ),
            const SizedBox(height: 40),
            Text(
              isAr ? 'الأسئلة الشائعة' : 'Frequently Asked Questions',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFaqItem(isAr ? 'كيف أتابع نتائج حملاتي؟' : 'How do I track my campaign results?', isAr),
            _buildFaqItem(isAr ? 'كيف يمكنني طلب اجتماع جديد؟' : 'How can I request a new meeting?', isAr),
            _buildFaqItem(isAr ? 'متى يتم تحديث استراتيجية النمو؟' : 'When is the growth strategy updated?', isAr),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isAr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAr ? 'كيف يمكننا مساعدتك اليوم؟' : 'How can we help you today?',
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          isAr ? 'فريق الدعم الفني ومدراء الحسابات متاحون لمساعدتك في أي وقت' : 'Our support team and account managers are available to help you anytime',
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSupportOption(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, bool isAr) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(question, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        trailing: const Icon(Icons.add, color: Colors.grey, size: 20),
        onTap: () {},
      ),
    );
  }

  Future<void> _launchWhatsApp() async {
    final whatsappNumber = AppConfig.complaintsWhatsapp;
    final cleanNumber = whatsappNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final url = Uri.parse('https://wa.me/$cleanNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchEmail() async {
    final url = Uri.parse('mailto:support@moharek.com');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}
