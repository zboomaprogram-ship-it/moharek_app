class EngineProgress {
  final String id;
  final String projectId;
  final String engine;
  final int progressPercent;
  final String? statusNotes;
  final DateTime updatedAt;

  EngineProgress({
    required this.id,
    required this.projectId,
    required this.engine,
    required this.progressPercent,
    this.statusNotes,
    required this.updatedAt,
  });

  factory EngineProgress.fromJson(Map<String, dynamic> json) {
    return EngineProgress(
      id: json['id'],
      projectId: json['project_id'],
      engine: json['engine'],
      progressPercent: json['progress_percent'] ?? 0,
      statusNotes: json['status_notes'],
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'engine': engine,
      'progress_percent': progressPercent,
      'status_notes': statusNotes,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
