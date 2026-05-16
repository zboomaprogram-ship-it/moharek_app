class Contract {
  final String id;
  final String projectId;
  final String title;
  final String? fileUrl;
  final String status; // pending, signed, expired
  final DateTime? signedAt;
  final DateTime createdAt;

  const Contract({
    required this.id,
    required this.projectId,
    required this.title,
    this.fileUrl,
    required this.status,
    this.signedAt,
    required this.createdAt,
  });

  factory Contract.fromJson(Map<String, dynamic> json) {
    return Contract(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      title: json['title'] as String,
      fileUrl: json['file_url'] as String?,
      status: json['status'] as String? ?? 'pending',
      signedAt: json['signed_at'] != null
          ? DateTime.parse(json['signed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
