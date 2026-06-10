import 'package:flutter/foundation.dart';
import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/shared/services/chat_provider.dart';
import 'package:moharek_app/l10n/app_localizations.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/shared/services/connectivity_service.dart';
import 'package:moharek_app/shared/models/message.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:moharek_app/features/calls/screens/active_call_screen.dart';
import 'package:moharek_app/features/chat/services/voice_recorder_service.dart';
import 'package:moharek_app/features/chat/services/voice_upload_service.dart';
import 'package:moharek_app/features/chat/widgets/voice_record_button.dart';
import 'package:moharek_app/features/chat/widgets/voice_message_bubble.dart';
import 'package:moharek_app/shared/widgets/shimmer_loading.dart';
import 'package:moharek_app/shared/services/haptic_service.dart';
import 'package:moharek_app/shared/utils/file_helper.dart';

final _urlRegExp = RegExp(
  r'((https?:\/\/)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*))',
  caseSensitive: false,
);

class ChatScreen extends ConsumerStatefulWidget {
  final String channelId;
  final String channelName;
  final String? prefilledMessage;
  
  const ChatScreen({
    super.key,
    required this.channelId,
    required this.channelName,
    this.prefilledMessage,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _voiceRecorderService = VoiceRecorderService();
  final _voiceUploadService = VoiceUploadService();
  bool _showAttachMenu = false;
  bool _isTyping = false;
  bool _isConnecting = false;
  String _connectionStatus = 'جاري الاتصال...';
  ChatMessage? _replyingTo;
  String? _senderNameForReply;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledMessage != null) {
      _msgCtrl.text = widget.prefilledMessage!;
    }
    _msgCtrl.addListener(() {
      setState(() => _isTyping = _msgCtrl.text.isNotEmpty);
    });
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.hasClients) {
        final maxScroll = _scrollCtrl.position.maxScrollExtent;
        final currentScroll = _scrollCtrl.position.pixels;
        final notifier = ref.read(chatMessagesProvider(widget.channelId).notifier);
        if (notifier.hasMore && maxScroll > 0 && currentScroll > 0 && currentScroll >= maxScroll - 100) {
          notifier.loadMore();
        }
      }
    });
  }

  Future<void> _sendText() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    if (widget.channelId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لم يتم إنشاء قناة للمحادثة. تواصل مع مدير حسابك.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final replyId = _replyingTo?.id;
    final replyContent = _replyingTo?.content;
    final replySender = _senderNameForReply;

    setState(() {
      _replyingTo = null;
      _senderNameForReply = null;
    });

    // 1. Clear input immediately for snappy UX
    _msgCtrl.clear();
    HapticService.light();

    // 2. Inject an optimistic message so it appears INSTANTLY
    final client = ref.read(supabaseClientProvider);
    final uid = client.auth.currentUser?.id ?? '';
    final tempId = 'opt_${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = ChatMessage(
      id: tempId,
      channelId: widget.channelId,
      senderId: uid,
      content: text,
      messageType: 'text',
      isRead: false,
      createdAt: DateTime.now(),
      replyToId: replyId,
      replyToContent: replyContent,
      replyToSenderName: replySender,
    );
    ref.read(chatMessagesProvider(widget.channelId).notifier).addOptimistic(optimistic);

    // 3. Fire the actual DB insert (Realtime stream will confirm & replace optimistic row)
    try {
      await ref.read(chatNotifierProvider.notifier).sendMessage(
        widget.channelId, 
        text,
        replyToId: replyId,
        replyToContent: replyContent,
        replyToSenderName: replySender,
      );
      // ✅ No manual refresh() needed — Realtime stream updates state automatically
    } catch (e) {
      debugPrint('❌ [Chat] _sendText error: $e');
      // Remove the optimistic message on failure so user knows it didn't send
      ref.read(chatMessagesProvider(widget.channelId).notifier).refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل إرسال الرسالة: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  Future<void> _sendFile() async {
    setState(() => _showAttachMenu = false);
    final result = await FilePicker.pickFiles(withData: kIsWeb);
    if (result == null) return;
    final file = result.files.first;
    await _uploadAndSend(file.name, file.bytes, file.path, 'file');
  }

  Future<void> _sendImage() async {
    setState(() => _showAttachMenu = false);
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    await _uploadAndSend(image.name, bytes, image.path, 'image');
  }

  Future<void> _uploadAndSend(
    String fileName,
    Uint8List? bytes,
    String? path,
    String type,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final client = ref.read(supabaseClientProvider);
    final channelId = widget.channelId;

    final storageName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
    try {
      if (bytes != null) {
        await client.storage
            .from('files')
            .uploadBinary('chat/$storageName', bytes);
      } else if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          final fileBytes = await file.readAsBytes();
          await client.storage
              .from('files')
              .uploadBinary('chat/$storageName', fileBytes);
        } else {
          throw Exception('File does not exist at path: $path');
        }
      } else {
        throw Exception('No file data or path available');
      }
      final url = client.storage
          .from('files')
          .getPublicUrl('chat/$storageName');
      await client.from('messages').insert({
        'channel_id': channelId,
        'sender_id': client.auth.currentUser!.id,
        'content': type == 'image' ? '📷 ${l10n.photoLabel}' : '📎 $fileName',
        'message_type': type,
        'file_url': url,
      });
      ref.read(chatMessagesProvider(widget.channelId).notifier).refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.uploadFailed(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startCall(bool isVideo) async {
    final l10n = AppLocalizations.of(context)!;
    final project = ref.read(currentProjectProvider).value;
    final profile = ref.read(profileProvider).value;
    if (project == null || profile == null) return;

    // Push the active call screen immediately in outgoing/ringing mode
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ActiveCallScreen(
          callType: isVideo ? 'video' : 'voice',
          projectId: project.id,
          callerName: profile.fullName,
          recipientName: widget.channelName,
          callerIdentity: profile.id,
          isOutgoing: true,
        ),
      ),
    );

    if (mounted) {
      ref
          .read(chatNotifierProvider.notifier)
          .sendMessage(
            widget.channelId,
            isVideo
                ? '📹 ${l10n.callStarted(l10n.startVideoCall)}'
                : '📞 ${l10n.callStarted(l10n.startVoiceCall)}',
            messageType: isVideo ? 'video_call' : 'voice_call',
          );
      ref.read(chatMessagesProvider(widget.channelId).notifier).refresh();
    }
  }

  Future<void> _handleVoiceRecording(VoiceRecordingResult recording) async {
    final client = ref.read(supabaseClientProvider);
    final channelId = widget.channelId;
    final project = ref.read(currentProjectProvider).value;
    if (project == null) return;

    try {
      await _voiceUploadService.uploadAndSend(
        channelId: channelId,
        projectId: project.id,
        senderId: client.auth.currentUser!.id,
        recording: recording,
      );
      ref.read(chatMessagesProvider(widget.channelId).notifier).refresh();
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorOccurred(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final messagesAsync = ref.watch(chatMessagesProvider(widget.channelId));
    final currentUser = ref.watch(supabaseClientProvider).auth.currentUser;
    final connectivity = ref.watch(connectivityStatusProvider);
    final isOffline = connectivity.value == ConnectivityStatus.isDisconnected;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.channelName, style: const TextStyle(fontSize: 16)),
            Text(
              l10n.supportTeam,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam, color: AppTheme.primaryBlue),
            onPressed: () => _startCall(true),
            tooltip: l10n.startVideoCall,
          ),
          IconButton(
            icon: const Icon(Icons.call, color: AppTheme.primaryGreen),
            onPressed: () => _startCall(false),
            tooltip: l10n.startVoiceCall,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (isOffline)
                Container(
                  width: double.infinity,
                  color: Colors.redAccent.withValues(alpha: 0.9),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        l10n.localeName == 'ar' 
                            ? 'لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك.' 
                            : 'No internet connection. Please check your connection.',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: messagesAsync.when(
                  data: (messages) {
                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.chat_bubble_outline,
                              size: 48,
                              color: Colors.white12,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.noMessagesYet,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            Text(
                              l10n.sendMessageToStart,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: _scrollCtrl,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount: messages.length,
                      addAutomaticKeepAlives: true,
                      addRepaintBoundaries: true,
                      itemBuilder: (_, i) {
                        final msg = messages[i];
                        final isMe = msg.senderId == currentUser?.id;
                        
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
                            _buildBubble(msg, isMe, l10n),
                          ],
                        );
                      },
                    );
                  },
                  loading: () => ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 6,
                    itemBuilder: (_, index) => ShimmerLoading.listTile(),
                  ),
                  error: (err, _) {
                    final isRlsError = err.toString().contains('infinite recursion') ||
                        err.toString().contains('company_members');
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isRlsError ? Icons.settings_outlined : Icons.error_outline,
                              color: isRlsError ? Colors.orange : Colors.red,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.localeName == 'ar'
                                  ? (isRlsError
                                      ? 'يرجى تطبيق إصلاح قاعدة البيانات في لوحة Supabase SQL'
                                      : 'خطأ في تحميل الرسائل')
                                  : (isRlsError
                                      ? 'Run fix_company_members_rls.sql in Supabase SQL editor'
                                      : 'Error loading messages'),
                              style: TextStyle(
                                color: isRlsError ? Colors.orange : Colors.red,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_showAttachMenu) _buildAttachMenu(),
              _buildInput(),
            ],
          ),

          if (_isConnecting)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: AppTheme.primaryGreen,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _connectionStatus,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
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

  void _showContextOptions(ChatMessage msg, bool isMe, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final isAr = Localizations.localeOf(context).languageCode == 'ar';
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
                        : widget.channelName;
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildBubble(ChatMessage msg, bool isMe, AppLocalizations l10n) {
    final isImage = msg.messageType == 'image';
    final isFile = msg.messageType == 'file';
    final isVoice = msg.messageType == 'voice';
    final isVideoCall = msg.messageType == 'video_call';
    final isVoiceCall = msg.messageType == 'voice_call';
    final isCall = isVideoCall || isVoiceCall;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () {
          HapticService.medium();
          _showContextOptions(msg, isMe, l10n);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.all(isImage ? 4 : 12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: isMe ? AppTheme.primaryGreen : AppTheme.cardColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
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
                      left: BorderSide(
                        color: isMe ? Colors.black38 : AppTheme.primaryGreen,
                        width: 3,
                      ),
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
              if (isImage && msg.fileUrl != null)
                GestureDetector(
                onTap: () => openFileInApp(context, msg.fileUrl!, msg.content),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    msg.fileUrl!,
                    height: 200,
                    width: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 100,
                      width: 200,
                      color: Colors.white10,
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
              )
            // File message
            else if (isFile && msg.fileUrl != null)
              GestureDetector(
                onTap: () => openFileInApp(context, msg.fileUrl!, msg.content),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isMe ? Colors.black : Colors.white).withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.insert_drive_file,
                        size: 20,
                        color: isMe ? Colors.black54 : AppTheme.primaryBlue,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          msg.content,
                          style: TextStyle(
                            color: isMe ? Colors.black : AppTheme.primaryBlue,
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            // Call message
            else if (isCall)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.content,
                    style: TextStyle(
                      color: isMe ? Colors.black : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.callEnded,
                    style: TextStyle(
                      color: isMe ? Colors.black54 : Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              )
            // Voice Message
            else if (isVoice && msg.fileUrl != null)
              VoiceMessageBubble(
                url: msg.fileUrl!,
                durationSeconds: msg.durationSeconds ?? 0,
                isMe: isMe,
              )
            // Normal text with Link detection
            else
              _buildLinkifiedText(msg.content, isMe),

            if (msg.convertedToTask) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.link, size: 12, color: isMe ? Colors.black54 : AppTheme.primaryGreen),
                    const SizedBox(width: 4),
                    Text(
                      l10n.localeName == 'ar' ? 'مرتبطة بمهمة' : 'Linked to Task', 
                      style: TextStyle(color: isMe ? Colors.black87 : AppTheme.primaryGreen, fontSize: 10)
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 4),
            Text(
              DateFormat('hh:mm a').format(msg.createdAt),
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

  Widget _buildAttachMenu() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: AppTheme.cardColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _attachOption(Icons.image, l10n.photo, Colors.purple, _sendImage),
          _attachOption(
            Icons.insert_drive_file,
            l10n.files,
            AppTheme.primaryBlue,
            _sendFile,
          ),
          _attachOption(Icons.videocam, l10n.startVideoCall, Colors.teal, () {
            setState(() => _showAttachMenu = false);
            _startCall(true);
          }),
          _attachOption(
            Icons.call,
            l10n.startVoiceCall,
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

  Widget _buildInput() {
    final isRtl = Localizations.localeOf(context).languageCode == 'ar';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: AppTheme.background,
      child: SafeArea(
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
                  IconButton(
                    icon: Icon(
                      _showAttachMenu ? Icons.close : Icons.add,
                      color: Colors.grey,
                    ),
                    onPressed: () =>
                        setState(() => _showAttachMenu = !_showAttachMenu),
                  ),
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
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.typeMessage,
                          hintStyle: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
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
