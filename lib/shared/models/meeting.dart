class ProjectMeeting {
  final String id;
  final String projectId;
  final String title;
  final String? titleAr;
  final DateTime? scheduledAt;
  final int durationMinutes;
  final String meetingType; // video, voice, external
  final String? livekitRoomName;
  final String? externalLink;
  final List<String> agenda;
  final String? summary;
  final List<String> actionItems;
  final List<String> decisions;
  final String status;
  final String? initiatedBy;
  final String? transcript;
  final String? recordingUrl;
  final DateTime createdAt;

  ProjectMeeting({
    required this.id,
    required this.projectId,
    required this.title,
    this.titleAr,
    this.scheduledAt,
    this.durationMinutes = 60,
    required this.meetingType,
    this.livekitRoomName,
    this.externalLink,
    this.agenda = const [],
    this.summary,
    this.actionItems = const [],
    this.decisions = const [],
    required this.status,
    this.initiatedBy,
    this.transcript,
    this.recordingUrl,
    required this.createdAt,
  });

  factory ProjectMeeting.fromJson(Map<String, dynamic> json) {
    return ProjectMeeting(
      id: json['id'],
      projectId: json['project_id'],
      title: json['title'] ?? 'Meeting',
      titleAr: json['title_ar'],
      scheduledAt: json['scheduled_at'] != null ? DateTime.parse(json['scheduled_at']) : null,
      durationMinutes: json['duration_minutes'] ?? 60,
      meetingType: json['meeting_type'] ?? 'video',
      livekitRoomName: json['livekit_room_name'],
      externalLink: json['external_link'],
      agenda: (json['agenda'] as List?)?.cast<String>() ?? [],
      summary: json['summary'],
      actionItems: (json['action_items'] as List?)?.cast<String>() ?? [],
      decisions: (json['decisions'] as List?)?.cast<String>() ?? [],
      status: json['status'] ?? 'upcoming',
      initiatedBy: json['initiated_by'],
      transcript: json['transcript'],
      recordingUrl: json['recording_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
