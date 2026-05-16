class ApprovalRequest {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final String approvalType;
  final String status; // pending, approved, needs_revision, rejected
  final String? fileUrl;
  final String? previewUrl;
  final String? teamNotes;
  final String? clientNotes;
  final DateTime createdAt;
  final DateTime? respondedAt;

  ApprovalRequest({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.approvalType,
    required this.status,
    this.fileUrl,
    this.previewUrl,
    this.teamNotes,
    this.clientNotes,
    required this.createdAt,
    this.respondedAt,
  });

  factory ApprovalRequest.fromJson(Map<String, dynamic> json) {
    return ApprovalRequest(
      id: json['id'],
      projectId: json['project_id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      approvalType: json['approval_type'] ?? '',
      status: json['status'] ?? 'pending',
      fileUrl: json['file_url'],
      previewUrl: json['preview_url'],
      teamNotes: json['team_notes'],
      clientNotes: json['client_notes'],
      createdAt: DateTime.parse(json['created_at']),
      respondedAt: json['responded_at'] != null ? DateTime.parse(json['responded_at']) : null,
    );
  }
}
