import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/l10n/app_localizations.dart';
import 'package:timeago/timeago.dart' as timeago;

class SupportTicketDetailScreen extends ConsumerStatefulWidget {
  final String ticketId;
  const SupportTicketDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<SupportTicketDetailScreen> createState() => _SupportTicketDetailScreenState();
}

class _SupportTicketDetailScreenState extends ConsumerState<SupportTicketDetailScreen> {
  final TextEditingController _messageCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageCtrl.text.trim().isEmpty) return;
    
    setState(() => _sending = true);
    final text = _messageCtrl.text.trim();
    _messageCtrl.clear();

    try {
      final client = ref.read(supabaseClientProvider);
      await client.from('support_ticket_messages').insert({
        'ticket_id': widget.ticketId,
        'sender_id': client.auth.currentUser!.id,
        'content': text,
      });
      
      // Auto scroll to bottom
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(ticketsProvider);
    final messagesAsync = ref.watch(ticketMessagesProvider(widget.ticketId));
    final l10n = AppLocalizations.of(context)!;
    final currentUserId = ref.read(supabaseClientProvider).auth.currentUser?.id;

    // Find the ticket details from the list
    final ticket = ticketsAsync.whenData(
      (list) => list.firstWhere((t) => t.id == widget.ticketId)
    ).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ticket?.title ?? l10n.supportHub, style: const TextStyle(fontSize: 16)),
            if (ticket != null)
              Text(
                ticket.status.toUpperCase(),
                style: TextStyle(
                  color: ticket.status == 'open' ? AppTheme.primaryBlue : AppTheme.primaryGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (messages) {
                // Combine original description as first message
                final allMessages = [
                  if (ticket != null)
                    {
                      'id': 'original',
                      'content': ticket.description,
                      'sender_id': ticket.submittedBy,
                      'created_at': ticket.createdAt.toIso8601String(),
                    },
                  ...messages,
                ];

                return ListView.builder(
                  controller: _scrollCtrl,
                  reverse: true,
                  padding: const EdgeInsets.all(20),
                  itemCount: allMessages.length,
                  itemBuilder: (context, index) {
                    final msg = allMessages.reversed.toList()[index];
                    final isMe = msg['sender_id'] == currentUserId;
                    
                    return _buildMessageBubble(msg, isMe);
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    final time = DateTime.parse(msg['created_at']);
    final ago = timeago.format(time, locale: Localizations.localeOf(context).languageCode);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primaryGreen.withValues(alpha: 0.1) : AppTheme.cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(20),
          ),
          border: Border.all(
            color: isMe ? AppTheme.primaryGreen.withValues(alpha: 0.2) : Colors.white10,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg['content'],
              style: TextStyle(color: isMe ? Colors.white : Colors.white70, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 8),
            Text(
              ago,
              style: const TextStyle(color: Colors.white24, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageCtrl,
              maxLines: null,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'اكتب ردك هنا...',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.black26,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filled(
            onPressed: _sending ? null : _sendMessage,
            icon: _sending 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send_rounded),
            style: IconButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.black),
          ),
        ],
      ),
    );
  }
}
