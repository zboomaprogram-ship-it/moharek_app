import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';
import 'package:moharek_app/shared/services/chat_provider.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/shared/models/message.dart';
import 'package:moharek_app/features/calls/screens/active_call_screen.dart';
import 'package:moharek_app/features/chat/services/voice_recorder_service.dart';
import 'package:moharek_app/features/chat/services/voice_upload_service.dart';
import 'package:moharek_app/features/chat/widgets/voice_record_button.dart';
import 'package:moharek_app/features/chat/widgets/voice_message_bubble.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moharek_app/shared/services/wordpress_upload_service.dart';
import 'package:moharek_app/shared/utils/file_helper.dart';
import 'package:moharek_app/features/notifications/data/notifications_provider.dart';
import 'package:moharek_app/shared/widgets/shimmer_loading.dart';

// ── Providers ────────────────────────────────────────────────────────────────

final adminChatChannelProvider = FutureProvider.family<String?, String>((
  ref,
  projectId,
) async {
  final client = ref.watch(supabaseClientProvider);
  final data = await client
      .from('chat_channels')
      .select()
      .eq('project_id', projectId)
      .maybeSingle();
  if (data != null) return data['id'];
  final inserted = await client
      .from('chat_channels')
      .insert({
        'project_id': projectId,
        'name': 'Chat',
        'channel_type': 'client_manager',
      })
      .select()
      .single();
  return inserted['id'];
});

final _urlRegExp = RegExp(
  r'((https?:\/\/)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*))',
  caseSensitive: false,
);

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminChatScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String clientName;
  final String channelId;
  final String channelName;

  const AdminChatScreen({
    super.key,
    required this.projectId,
    required this.clientName,
    required this.channelId,
    required this.channelName,
  });

  @override
  ConsumerState<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends ConsumerState<AdminChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _voiceRecorderService = VoiceRecorderService();
  final _voiceUploadService = VoiceUploadService();

  bool _isTyping = false;
  bool _showAttachMenu = false;
  bool _isConnecting = false; // call loading overlay
  String _connectionStatus = 'جاري الاتصال...';
  ChatMessage? _replyingTo;
  String? _senderNameForReply;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.hasClients) {
      final maxScroll = _scrollCtrl.position.maxScrollExtent;
      final currentScroll = _scrollCtrl.position.pixels;
      final notifier = ref.read(chatMessagesProvider(widget.channelId).notifier);
      if (notifier.hasMore && maxScroll > 0 && currentScroll > 0 && currentScroll >= maxScroll - 100) {
        notifier.loadMore();
      }
    }
  }

  // ── Send text ────────────────────────────────────────────────────────────
  Future<void> _sendText() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    final replyId = _replyingTo?.id;
    final replyContent = _replyingTo?.content;
    final replySender = _senderNameForReply;

    setState(() {
      _replyingTo = null;
      _senderNameForReply = null;
      _isTyping = false;
    });

    _msgCtrl.clear();

    final actions = ref.read(adminActionsProvider);
    final channelId = widget.channelId;
    final uid = actions.client.auth.currentUser!.id;

    // Snappy UX: optimistic UI injection
    final tempId = 'opt_${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = ChatMessage(
      id: tempId,
      channelId: channelId,
      senderId: uid,
      content: text,
      messageType: 'text',
      isRead: false,
      createdAt: DateTime.now(),
      replyToId: replyId,
      replyToContent: replyContent,
      replyToSenderName: replySender,
    );
    ref.read(chatMessagesProvider(channelId).notifier).addOptimistic(optimistic);

    try {
      await actions.sendChatMessage({
        'channel_id': channelId,
        'sender_id': uid,
        'content': text,
        'message_type': 'text',
        'payload': replyId != null ? {
          'reply_to_id': replyId,
          'reply_to_content': replyContent,
          'reply_to_sender_name': replySender,
        } : null,
      });
    } catch (e) {
      debugPrint('Error sending message: $e');
      ref.read(chatMessagesProvider(channelId).notifier).refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل إرسال الرسالة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── Send file ────────────────────────────────────────────────────────────
  Future<void> _sendFile() async {
    setState(() => _showAttachMenu = false);
    final result = await FilePicker.pickFiles(withData: true);
    if (result == null) return;
    final file = result.files.first;
    final client = ref.read(supabaseClientProvider);
    final channelId = widget.channelId;

    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    try {
      String url = '';
      if (file.bytes != null) {
        url = await WordPressUploadService.uploadBytes(file.bytes!, fileName);
      } else if (file.path != null) {
        url = await WordPressUploadService.uploadFile(file.path!, fileName);
      } else {
        throw Exception('No file data available');
      }

      final actions = ref.read(adminActionsProvider);
      await actions.sendChatMessage({
        'channel_id': channelId,
        'sender_id': client.auth.currentUser!.id,
        'content': '📎 ${file.name}',
        'message_type': 'file',
        'file_url': url,
      });
      ref.read(chatMessagesProvider(widget.channelId).notifier).refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في رفع الملف: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── Send image ───────────────────────────────────────────────────────────
  Future<void> _sendImage() async {
    setState(() => _showAttachMenu = false);
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image == null) return;

    final bytes = await image.readAsBytes();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
    final client = ref.read(supabaseClientProvider);
    final channelId = widget.channelId;

    try {
      final url = await WordPressUploadService.uploadBytes(bytes, fileName);
      final actions = ref.read(adminActionsProvider);
      await actions.sendChatMessage({
        'channel_id': channelId,
        'sender_id': client.auth.currentUser!.id,
        'content': '📷 صورة',
        'message_type': 'image',
        'file_url': url,
      });
      ref.read(chatMessagesProvider(widget.channelId).notifier).refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في رفع الصورة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── Send voice message ────────────────────────────────────────────────────
  Future<void> _handleVoiceRecording(VoiceRecordingResult recording) async {
    final client = ref.read(supabaseClientProvider);
    final channelId = widget.channelId;

    try {
      await _voiceUploadService.uploadAndSend(
        channelId: channelId,
        projectId: widget.projectId,
        senderId: client.auth.currentUser!.id,
        recording: recording,
      );
      ref.read(chatMessagesProvider(widget.channelId).notifier).refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إرسال الرسالة الصوتية: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── Start LiveKit call ────────────────────────────────────────────────────
  Future<void> _startCall(bool isVideo) async {
    final client = ref.read(supabaseClientProvider);
    final profile = ref.read(profileProvider).valueOrNull;
    final adminName = profile?.fullName ?? 'Admin';
    final adminRole = profile?.role ?? 'admin';
    final callerName = '$adminName {$adminRole}';

    // Push the active call screen immediately in outgoing/ringing mode
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ActiveCallScreen(
          callType: isVideo ? 'video' : 'voice',
          projectId: widget.projectId,
          callerName: callerName,
          recipientName: widget.clientName,
          callerIdentity: client.auth.currentUser!.id,
          isOutgoing: true,
          onCallConnected: () async {
            try {
              final channelId = widget.channelId;
              final actions = ref.read(adminActionsProvider);
              await actions.sendChatMessage({
                'channel_id': channelId,
                'sender_id': client.auth.currentUser!.id,
                'content': isVideo ? '📹 بدأت مكالمة فيديو' : '📞 بدأت مكالمة صوتية',
                'message_type': 'system', // System message type avoids double push notifications
              });
              ref.read(chatMessagesProvider(widget.channelId).notifier).refresh();
            } catch (e) {
              debugPrint('Error sending call connected message: $e');
            }
          },
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    // Clear notifications for this channel when opened / rendered
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await NotificationService.markChannelMessagesAsRead(widget.channelId);
      ref.invalidate(notificationsProvider);
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.clientName} - ${widget.channelName}',
              style: const TextStyle(fontSize: 16),
            ),
            const Text(
              'محادثة العميل',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          // ── Call buttons ──────────────────────────────────────────
          if (_isConnecting)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _connectionStatus,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.videocam, color: AppTheme.primaryBlue),
              onPressed: () => _startCall(true),
              tooltip: 'مكالمة فيديو',
            ),
            IconButton(
              icon: const Icon(Icons.call, color: AppTheme.primaryGreen),
              onPressed: () => _startCall(false),
              tooltip: 'مكالمة صوتية',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessages(widget.channelId)),
          if (_showAttachMenu) _buildAttachMenu(),
          _buildInput(isRtl),
        ],
      ),
    );
  }

  // ── Messages list ─────────────────────────────────────────────────────────
  Widget _buildMessages(String channelId) {
    final msgsAsync = ref.watch(chatMessagesProvider(channelId));
    final currentUserId = ref.read(supabaseClientProvider).auth.currentUser?.id;

    return msgsAsync.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, index) => ShimmerLoading.listTile(),
      ),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (messages) {
        if (messages.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 48,
                  color: Colors.white12,
                ),
                SizedBox(height: 12),
                Text(
                  'لا توجد رسائل بعد. ابدأ المحادثة!',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          controller: _scrollCtrl,
          reverse: true,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          addAutomaticKeepAlives: true,
          addRepaintBoundaries: true,
          itemBuilder: (_, i) {
            final msg = messages[i];
            final isMe = msg.senderId == currentUserId;
            
            bool showDateHeader = false;
            if (i == messages.length - 1) {
              showDateHeader = true;
            } else {
              final olderMsg = messages[i + 1];
              if (msg.createdAt.day != olderMsg.createdAt.day ||
                  msg.createdAt.month != olderMsg.createdAt.month ||
                  msg.createdAt.year != olderMsg.createdAt.year) {
                showDateHeader = true;
              }
            }

            return Column(
              children: [
                if (showDateHeader) _buildDateHeader(msg.createdAt),
                _buildBubble(msg, isMe),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(date.year, date.month, date.day);

    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    String dateText;
    if (msgDate == today) {
      dateText = isAr ? 'اليوم' : 'Today';
    } else if (msgDate == yesterday) {
      dateText = isAr ? 'أمس' : 'Yesterday';
    } else {
      dateText = DateFormat.yMMMMd().format(date);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            dateText,
            style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildLinkifiedText(String text, bool isMe) {
    final matches = _urlRegExp.allMatches(text);
    if (matches.isEmpty) {
      return SelectableText(
        text,
        style: TextStyle(
          color: isMe ? Colors.black : Colors.white,
          fontSize: 14,
        ),
      );
    }

    final List<TextSpan> spans = [];
    int lastMatchEnd = 0;

    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: TextStyle(color: isMe ? Colors.black : Colors.white, fontSize: 14),
        ));
      }

      final url = match.group(0)!;
      final tapUrl = url.startsWith('http') ? url : 'https://$url';
      spans.add(TextSpan(
        text: url,
        style: TextStyle(
          color: isMe ? Colors.blue[900] : AppTheme.primaryBlue,
          fontSize: 14,
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => openFileInApp(context, tapUrl, 'Link'),
      ));
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: TextStyle(color: isMe ? Colors.black : Colors.white, fontSize: 14),
      ));
    }

    return SelectableText.rich(
      TextSpan(children: spans),
    );
  }

  // ── Message bubble ────────────────────────────────────────────────────────
  Widget _buildBubble(ChatMessage msg, bool isMe) {
    final isFile = msg.messageType == 'file';
    final isImage = msg.messageType == 'image';
    final isVoice = msg.messageType == 'voice';
    final isCall =
        msg.messageType == 'video_call' || msg.messageType == 'voice_call';

    Widget content;

    if (isVoice && msg.fileUrl != null) {
      content = VoiceMessageBubble(
        url: msg.fileUrl!,
        durationSeconds: msg.durationSeconds ?? 0,
        isMe: isMe,
      );
    } else if (isImage && msg.fileUrl != null) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(msg.fileUrl!, width: 200, fit: BoxFit.cover),
      );
    } else if ((isFile) && msg.fileUrl != null) {
      content = GestureDetector(
        onTap: () => openFileInApp(context, msg.fileUrl!, msg.content),
        child: Row(
          children: [
            Icon(
              Icons.attach_file,
              size: 16,
              color: isMe ? Colors.black54 : Colors.white54,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                msg.content,
                style: TextStyle(
                  color: isMe ? Colors.black : AppTheme.primaryBlue,
                  decoration: TextDecoration.underline,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (isCall) {
      content = Row(
        children: [
          Icon(
            msg.messageType == 'video_call' ? Icons.videocam : Icons.call,
            size: 16,
            color: isMe ? Colors.black54 : AppTheme.primaryGreen,
          ),
          const SizedBox(width: 6),
          Text(
            msg.content,
            style: TextStyle(
              color: isMe ? Colors.black87 : Colors.white,
              fontSize: 13,
            ),
          ),
        ],
      );
    } else {
      content = _buildLinkifiedText(msg.content, isMe);
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () {
          _showContextOptions(msg, isMe);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.65,
          ),
          decoration: BoxDecoration(
            color: isMe ? AppTheme.primaryGreen : AppTheme.cardColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 0),
              bottomRight: Radius.circular(isMe ? 0 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (msg.replyToId != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isMe ? Colors.black : Colors.white).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border(
                      left: isMe ? BorderSide.none : const BorderSide(color: AppTheme.primaryGreen, width: 3),
                      right: isMe ? const BorderSide(color: AppTheme.primaryGreen, width: 3) : BorderSide.none,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg.replyToSenderName ?? '',
                        style: TextStyle(
                          color: isMe ? Colors.black87 : AppTheme.primaryGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        msg.replyToContent ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isMe ? Colors.black54 : Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              content,
              if (msg.convertedToTask) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.link,
                        size: 12,
                        color: isMe ? Colors.black54 : AppTheme.primaryGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'مرتبطة بمهمة',
                        style: TextStyle(
                          color: isMe ? Colors.black87 : AppTheme.primaryGreen,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                '${msg.createdAt.hour}:${msg.createdAt.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: isMe ? Colors.black38 : Colors.white30,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContextOptions(ChatMessage msg, bool isMe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final isAr = Localizations.localeOf(context).languageCode == 'ar';
        final showConvert = !isMe && (msg.messageType == 'text' || msg.messageType == 'voice');

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.reply, color: Colors.white70),
                title: Text(
                  isAr ? 'رد' : 'Reply',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _replyingTo = msg;
                    _senderNameForReply = isMe 
                        ? (isAr ? 'أنت' : 'You')
                        : widget.clientName;
                  });
                },
              ),
              if (msg.messageType == 'text')
                ListTile(
                  leading: const Icon(Icons.copy, color: Colors.white70),
                  title: Text(
                    isAr ? 'نسخ النص' : 'Copy Text',
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Clipboard.setData(ClipboardData(text: msg.content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isAr ? 'تم نسخ النص إلى الحافظة' : 'Text copied to clipboard'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              if (showConvert)
                ListTile(
                  leading: const Icon(Icons.task_alt, color: AppTheme.primaryGreen),
                  title: Text(
                    isAr ? 'حوّل إلى مهمة' : 'Convert to Task',
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showTaskModal(this.context, msg);
                  },
                ),
            ],
          ),
        );
      },
    );
  }



  void _showTaskModal(BuildContext context, ChatMessage sourceMsg) {
    final titleController = TextEditingController();
    final descController = TextEditingController(
      text: sourceMsg.messageType == 'text' ? sourceMsg.content : 'رسالة صوتية',
    );
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'إنشاء مهمة جديدة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'عنوان المهمة',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'التفاصيل',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (titleController.text.isEmpty) return;
                          setModalState(() => isLoading = true);
                          try {
                            final actions = ref.read(adminActionsProvider);
                            await actions.convertMessageToTask(
                              projectId: widget.projectId,
                              messageId: sourceMsg.id,
                              title: titleController.text.trim(),
                              description: descController.text.trim(),
                            );

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'تم تحويل الرسالة إلى مهمة بنجاح',
                                  ),
                                  backgroundColor: AppTheme.primaryGreen,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('خطأ: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (context.mounted)
                              setModalState(() => isLoading = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'إنشاء المهمة',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachMenu() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: AppTheme.cardColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _attachOption(Icons.image, 'صورة', Colors.purple, _sendImage),
          _attachOption(
            Icons.insert_drive_file,
            'ملف',
            AppTheme.primaryBlue,
            _sendFile,
          ),
          _attachOption(Icons.videocam, 'مكالمة فيديو', Colors.teal, () {
            setState(() => _showAttachMenu = false);
            _startCall(true);
          }),
          _attachOption(
            Icons.call,
            'مكالمة صوتية',
            AppTheme.primaryGreen,
            () {
              setState(() => _showAttachMenu = false);
              _startCall(false);
            },
          ),
        ],
      ),
    );
  }

  Widget _attachOption(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildReplyPreviewBanner(bool isRtl) {
    if (_replyingTo == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: isRtl ? BorderSide.none : const BorderSide(color: AppTheme.primaryGreen, width: 4),
          right: isRtl ? const BorderSide(color: AppTheme.primaryGreen, width: 4) : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.reply, color: AppTheme.primaryGreen, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _senderNameForReply ?? '',
                  style: const TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _replyingTo!.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey, size: 18),
            onPressed: () {
              setState(() {
                _replyingTo = null;
                _senderNameForReply = null;
              });
            },
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  // ── Input bar ─────────────────────────────────────────────────────────────
  Widget _buildInput(bool isRtl) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border(top: BorderSide(color: Colors.white.withAlpha(15))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyingTo != null) _buildReplyPreviewBanner(isRtl),
          VoiceRecordButton(
            recorderService: _voiceRecorderService,
            onRecordingComplete: _handleVoiceRecording,
            isRtl: isRtl,
            isTyping: _isTyping,
            onSendTap: _sendText,
            child: Row(
              children: [
                // Attach toggle
                IconButton(
                  icon: Icon(
                    _showAttachMenu ? Icons.close : Icons.add,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => _showAttachMenu = !_showAttachMenu),
                  tooltip: 'إرفاق وسائط',
                ),
                const SizedBox(width: 8),

                // Text field
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: TextField(
                      controller: _msgCtrl,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.right,
                      onChanged: (v) => setState(() => _isTyping = v.isNotEmpty),
                      decoration: const InputDecoration(
                        hintText: 'اكتب رسالة...',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendText(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _voiceRecorderService.dispose();
    super.dispose();
  }
}
