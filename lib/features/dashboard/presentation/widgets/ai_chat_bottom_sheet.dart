import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/arabic_formatter.dart';

class AIChatBottomSheet extends ConsumerStatefulWidget {
  const AIChatBottomSheet({super.key});

  @override
  ConsumerState<AIChatBottomSheet> createState() => _AIChatBottomSheetState();
}

class _AIChatBottomSheetState extends ConsumerState<AIChatBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Welcome message
    _messages.add({
      'role': 'assistant',
      'content': 'مرحباً! أنا مساعد محرك للنمو. كيف يمكنني مساعدتك اليوم في فهم نتائجك أو استراتيجيتك؟',
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _controller.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final supabase = Supabase.instance.client;
      
      // Get some context (current project ID)
      final user = supabase.auth.currentUser;
      final profile = await supabase
          .from('profiles')
          .select('id, onboarding_completed')
          .eq('id', user?.id ?? '')
          .single();
          
      final project = await supabase
          .from('projects')
          .select('id, name, project_goal, client_brief, current_stage')
          .eq('client_id', user?.id ?? '')
          .maybeSingle();

      if (project == null) throw Exception('No project found');

      // Fetch expanded context data
      final resultsData = await supabase
          .from('results')
          .select('result_type, metric_name, metric_label, metric_value, metric_unit, change_from_last, notes, recorded_at')
          .eq('project_id', project['id'])
          .order('recorded_at', ascending: false)
          .limit(10);

      final tasksData = await supabase
          .from('tasks')
          .select('title, description, status, priority, category, stage_name, deadline, is_client_request, request_type, client_proposed_deadline')
          .eq('project_id', project['id'])
          .order('updated_at', ascending: false)
          .limit(10);

      final meetingsData = await supabase
          .from('meetings')
          .select('title, title_ar, scheduled_at, duration_minutes, meeting_type, status, agenda, summary, action_items')
          .eq('project_id', project['id'])
          .order('scheduled_at', ascending: true)
          .limit(5);

      final campaignsData = await supabase
          .from('campaigns')
          .select('name, channel, budget, status')
          .eq('project_id', project['id'])
          .eq('status', 'active')
          .limit(5);

      final engineData = await supabase
          .from('engine_progress')
          .select('engine, progress_percent, health_score, status')
          .eq('project_id', project['id']);

      final invoicesData = await supabase
          .from('invoices')
          .select('invoice_number, amount, currency, status, due_date')
          .eq('project_id', project['id'])
          .order('created_at', ascending: false)
          .limit(5);

      final contractsData = await supabase
          .from('contracts')
          .select('title, status, signed_at, created_at')
          .eq('project_id', project['id'])
          .order('created_at', ascending: false)
          .limit(5);

      final filesData = await supabase
          .from('files')
          .select('name, file_url, file_type, size_bytes, created_at')
          .eq('project_id', project['id'])
          .order('created_at', ascending: false)
          .limit(10);

      final response = await supabase.functions.invoke(
        'ai-assistant',
        body: {
          'prompt': text,
          'history': _messages.map((m) => {
            'role': m['role'],
            'content': m['content']
          }).toList(),
          'context': {
            'project_name': project['name'],
            'project_goal': project['project_goal'],
            'current_stage': project['current_stage'],
            'client_brief': project['client_brief'],
            'recent_results': resultsData,
            'recent_tasks': tasksData,
            'upcoming_meetings': meetingsData,
            'active_campaigns': campaignsData,
            'engines': engineData,
            'recent_invoices': invoicesData,
            'recent_contracts': contractsData,
            'recent_files': filesData,
          }
        },
      );

      if (response.status == 200) {
        final data = response.data;
        final text = data is Map ? (data['text'] ?? data['error'] ?? 'عذراً، لم أستطع معالجة الطلب.') : 'عذراً، لم أستطع معالجة الطلب.';
        setState(() {
          _messages.add({'role': 'assistant', 'content': text});
        });
      } else {
        // Surface the actual error from the edge function
        final errMsg = response.data is Map ? (response.data['error'] ?? 'Status ${response.status}') : 'Status ${response.status}';
        throw Exception(errMsg);
      }
    } catch (e) {
      final isApiKeyError = e.toString().contains('GROQ_API_KEY') || e.toString().contains('401');
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': isApiKeyError
              ? 'المساعد الذكي يحتاج إلى إعداد مفتاح API في لوحة Supabase. يرجى إضافة GROQ_API_KEY في إعدادات Edge Functions.'
              : 'حدث خطأ أثناء الاتصال بالمساعد. يرجى المحاولة لاحقاً.',
        });
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
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
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome, color: AppTheme.primaryGreen, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'مساعد النمو الذكي',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white54),
                ),
              ],
            ),
          ),
          
          const Divider(color: Colors.white10),
          
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildLoadingIndicator();
                }
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),
          
          // Input
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _sendMessage(),
                    style: TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'اسأل عن نتائجك، استراتيجيتك، أو مهامك...',
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                      filled: true,
                      fillColor: AppTheme.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send_rounded, color: Colors.black, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final isAssistant = msg['role'] == 'assistant';
    return Align(
      alignment: isAssistant ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isAssistant ? AppTheme.cardColor : AppTheme.primaryGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isAssistant ? 20 : 4),
            bottomRight: Radius.circular(isAssistant ? 4 : 20),
          ),
          border: isAssistant ? Border.all(color: Colors.white.withValues(alpha: 0.05)) : null,
          boxShadow: isAssistant ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: SelectableText(
          msg['content'],
          style: TextStyle(
            color: isAssistant ? Colors.white : Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
          ),
        ),
      ),
    );
  }
}
