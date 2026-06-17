import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/core/config/app_config.dart';
import 'package:moharek_app/features/ai_assistant/data/ai_assistant_provider.dart';
import 'package:moharek_app/l10n/app_localizations.dart';
import 'package:moharek_app/shared/widgets/shimmer_loading.dart';
import 'package:animate_do/animate_do.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiAssistantProvider);
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: FadeIn(
                child: const Icon(Icons.auto_awesome, color: AppTheme.primaryGreen, size: 18),
              ),
            ),
            const SizedBox(width: 12),
            Text(isAr ? 'مساعد النمو الذكي' : 'Growth Assistant'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => ref.read(aiAssistantProvider.notifier).clearHistory(),
            icon: const Icon(Icons.refresh, size: 20, color: Colors.white54),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [
              AppTheme.primaryGreen.withValues(alpha: 0.05),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: state.messages.isEmpty
                  ? _buildEmptyState(isAr)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(20),
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) {
                        final msg = state.messages[index];
                        return _buildMessageBubble(msg);
                      },
                    ),
            ),
            if (state.isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: ShimmerLoading.aiMessage(),
              ),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(
                  state.error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            _buildInputArea(isAr),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isAr) {
    final suggestions = isAr
        ? ['اشرح لي نتائج SEO الأخيرة', 'ما هي المهام الحالية للفريق؟', 'كيف أحسن مؤشر صحة مشروعي؟']
        : ['Explain my recent SEO results', 'What are the current team tasks?', 'How can I improve my health score?'];

    return Center(
      child: FadeInUp(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(Icons.rocket_launch_rounded, color: AppTheme.primaryGreen, size: 40),
              ),
              const SizedBox(height: 32),
              Text(
                isAr 
                    ? 'أهلاً بك في ${AppConfig.appName} الذكي' 
                    : 'Welcome to ${AppConfig.flavorName == 'rabhan' ? 'Rabhan' : 'Moharek'} AI',
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                isAr 
                    ? 'أنا هنا لمساعدتك في فهم بياناتك وتحسين استراتيجية نموك.'
                    : 'I am here to help you understand your data and optimize your growth strategy.',
                style: const TextStyle(color: Colors.white54, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: suggestions.map((s) => _buildSuggestionChip(s)).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return InkWell(
      onTap: () {
        _controller.text = text;
        _handleSend();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Align(
        alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: msg.isUser ? AppTheme.primaryGreen.withValues(alpha: 0.1) : const Color(0xFF1E293B),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: msg.isUser ? const Radius.circular(20) : Radius.zero,
              bottomRight: msg.isUser ? Radius.zero : const Radius.circular(20),
            ),
            border: Border.all(
              color: msg.isUser ? AppTheme.primaryGreen.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: Text(
            msg.text,
            style: TextStyle(
              color: msg.isUser ? Colors.white : Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isAr) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: isAr ? 'اسأل أي شيء عن مشروعك...' : 'Ask anything about your project...',
                hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
                filled: true,
                fillColor: Colors.black26,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => _handleSend(),
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filled(
            onPressed: _handleSend,
            icon: const Icon(Icons.arrow_upward, size: 22),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.black,
              minimumSize: const Size(48, 48),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSend() {
    if (_controller.text.trim().isEmpty) return;
    ref.read(aiAssistantProvider.notifier).sendMessage(_controller.text);
    _controller.clear();
    _scrollToBottom();
  }
}
