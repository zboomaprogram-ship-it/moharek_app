class JourneyStage {
  final String id;
  final String projectId;
  final String stageName;
  final String status; // not_started, in_progress, completed
  final String? assignedTo;
  final DateTime? deadline;
  final String? notes;
  final String? stageDescription;
  final DateTime? completedAt;

  const JourneyStage({
    required this.id,
    required this.projectId,
    required this.stageName,
    required this.status,
    this.assignedTo,
    this.deadline,
    this.notes,
    this.stageDescription,
    this.completedAt,
  });

  factory JourneyStage.fromJson(Map<String, dynamic> json) {
    return JourneyStage(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      stageName: json['stage_name'] as String,
      status: json['status'] as String? ?? 'not_started',
      assignedTo: json['assigned_to'] as String?,
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      notes: json['notes'] as String?,
      stageDescription: json['stage_description'] as String?,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }
}
