import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/features/admin/data/admin_providers.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:moharek_app/shared/models/message.dart';
import 'package:moharek_app/features/calls/services/call_service.dart';
import 'package:moharek_app/features/calls/screens/active_call_screen.dart';
import 'package:moharek_app/features/chat/services/voice_recorder_service.dart';
import 'package:moharek_app/features/chat/services/voice_upload_service.dart';
import 'package:moharek_app/features/chat/widgets/voice_record_button.dart';
import 'package:moharek_app/features/chat/widgets/voice_message_bubble.dart';
import 'package:file_picker/file_picker.dart';
import 'package:moharek_app/shared/services/wordpress_upload_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:moharek_app/shared/services/chat_provider.dart';

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
  bool _isRecording = false;
  bool _isConnecting = false; // call loading overlay
  String _connectionStatus = 'جاري الاتصال...';

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    // Reverse list: scrolling up (towards older messages) increases pixels towards maxScrollExtent
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(chatMessagesProvider(widget.channelId).notifier).loadMore();
    }
  }

  // ── Send text ────────────────────────────────────────────────────────────
  Future<void> _sendText() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    setState(() => _isTyping = false);

    final actions = ref.read(adminActionsProvider);
    final channelId = widget.channelId;

    await actions.sendChatMessage({
      'channel_id': channelId,
      'sender_id': actions.client.auth.currentUser!.id,
      'content': text,
      'message_type': 'text',
    });
    ref.read(chatMessagesProvider(widget.channelId).notifier).refresh();
  }

  // ── Send file ────────────────────────────────────────────────────────────
  Future<void> _sendFile() async {
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

    if (mounted)
      setState(() {
        _isConnecting = true;
        _connectionStatus = 'جاري طلب المكالمة...';
      });

    try {
      final callService = CallService();
      final room = await callService.startCallWithSignal(
        projectId: widget.projectId,
        callerName: 'Admin',
        callType: isVideo ? 'video' : 'voice',
        identity: client.auth.currentUser!.id,
        onStatusUpdate: (status) {
          if (mounted) {
            setState(() {
              if (status == 'ringing') _connectionStatus = 'يرن الآن...';
              if (status == 'accepted')
                _connectionStatus = 'تم القبول، جاري الانضمام...';
            });
          }
        },
      );

      if (mounted) setState(() => _isConnecting = false);
      if (!mounted) return;

      // Navigate to in-app call screen
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ActiveCallScreen(
            room: room,
            callType: isVideo ? 'video' : 'voice',
          ),
        ),
      );

      // Post-call: send a notification message in chat
      if (mounted) {
        final channelId = widget.channelId;
        final actions = ref.read(adminActionsProvider);
        await actions.sendChatMessage({
          'channel_id': channelId,
          'sender_id': client.auth.currentUser!.id,
          'content': isVideo ? '📹 بدأت مكالمة فيديو' : '📞 بدأت مكالمة صوتية',
          'message_type': isVideo ? 'video_call' : 'voice_call',
        });
        ref.read(chatMessagesProvider(widget.channelId).notifier).refresh();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConnecting = false);
        String errorMsg = 'خطأ في الاتصال';
        if (e == 'declined') errorMsg = 'تم رفض المكالمة';
        if (e == 'timeout') errorMsg = 'لا يوجد رد من الطرف الآخر';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

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
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryGreen),
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
            return _buildBubble(msg, isMe);
          },
        );
      },
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
        onTap: () => launchUrl(Uri.parse(msg.fileUrl!)),
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
      content = Text(
        msg.content,
        style: TextStyle(
          color: isMe ? Colors.black : Colors.white,
          fontSize: 14,
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () {
          if (!isMe &&
              (msg.messageType == 'text' || msg.messageType == 'voice')) {
            _showConvertTaskMenu(context, msg);
          }
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

  void _showConvertTaskMenu(BuildContext context, ChatMessage msg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.task_alt, color: AppTheme.primaryGreen),
              title: const Text(
                'حوّل إلى مهمة',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showTaskModal(context, msg);
              },
            ),
          ],
        ),
      ),
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

  // ── Input bar ─────────────────────────────────────────────────────────────
  Widget _buildInput(bool isRtl) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border(top: BorderSide(color: Colors.white.withAlpha(15))),
      ),
      child: Row(
        children: [
          if (!_isRecording) ...[
            // Attach file
            IconButton(
              icon: const Icon(Icons.attach_file, color: Colors.grey),
              onPressed: _sendFile,
              tooltip: 'إرفاق ملف',
            ),
          ],

          // Voice record button (shows idle mic or recording bar)
          _isRecording
              ? Expanded(
                  child: VoiceRecordButton(
                    recorderService: _voiceRecorderService,
                    isRtl: isRtl,
                    onRecordingComplete: _handleVoiceRecording,
                    onRecordingToggle: (val) =>
                        setState(() => _isRecording = val),
                  ),
                )
              : VoiceRecordButton(
                  recorderService: _voiceRecorderService,
                  isRtl: isRtl,
                  onRecordingComplete: _handleVoiceRecording,
                  onRecordingToggle: (val) =>
                      setState(() => _isRecording = val),
                ),

          if (!_isRecording) ...[
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

            // Send button
            if (_isTyping)
              GestureDetector(
                onTap: _sendText,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send, color: Colors.black, size: 20),
                ),
              ),
          ],
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
