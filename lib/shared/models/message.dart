class ChatMessage {
  final String id;
  final String channelId;
  final String senderId;
  final String content;
  final String messageType;
  final String? fileUrl;
  final int? durationSeconds;
  final List<double>? waveformData;
  final bool isRead;
  final bool convertedToTask;
  final String? linkedTaskId;
  final DateTime createdAt;
  final String? replyToId;
  final String? replyToContent;
  final String? replyToSenderName;

  ChatMessage({
    required this.id,
    required this.channelId,
    required this.senderId,
    required this.content,
    required this.messageType,
    this.fileUrl,
    this.durationSeconds,
    this.waveformData,
    required this.isRead,
    this.convertedToTask = false,
    this.linkedTaskId,
    required this.createdAt,
    this.replyToId,
    this.replyToContent,
    this.replyToSenderName,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final payloadJson = json['payload'] is Map<String, dynamic> ? json['payload'] as Map<String, dynamic> : null;
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      channelId: json['channel_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      messageType: json['message_type']?.toString() ?? 'text',
      fileUrl: json['file_url']?.toString(),
      durationSeconds: json['duration_seconds'] != null 
          ? int.tryParse(json['duration_seconds'].toString()) 
          : null,
      waveformData: json['waveform_data'] is List 
          ? (json['waveform_data'] as List).map((e) => double.tryParse(e.toString()) ?? 0.0).toList()
          : null,
      isRead: json['is_read'] == true,
      convertedToTask: json['converted_to_task'] == true,
      linkedTaskId: json['linked_task_id']?.toString(),
      createdAt: json['created_at'] != null 
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()).toLocal()
          : DateTime.now(),
      replyToId: payloadJson?['reply_to_id']?.toString(),
      replyToContent: payloadJson?['reply_to_content']?.toString(),
      replyToSenderName: payloadJson?['reply_to_sender_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'channel_id': channelId,
      'sender_id': senderId,
      'content': content,
      'message_type': messageType,
      'file_url': fileUrl,
      'duration_seconds': durationSeconds,
      'waveform_data': waveformData,
      'is_read': isRead,
      'converted_to_task': convertedToTask,
      'linked_task_id': linkedTaskId,
      'payload': replyToId != null ? {
        'reply_to_id': replyToId,
        'reply_to_content': replyToContent,
        'reply_to_sender_name': replyToSenderName,
      } : null,
    };
  }
}
