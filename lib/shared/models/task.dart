class ProjectTask {
  final String id;
  final String projectId;
  final String title;
  final String? description;
  final String status;
  final String? assignedTo;
  final DateTime? deadline;
  final String priority;
  final String? category;
  final String? stageName;
  final List<Map<String, dynamic>> subtasks;
  final List<String> attachmentUrls;
  final DateTime createdAt;
  final bool isClientRequest;
  final String? requestType;
  final DateTime? clientProposedDeadline;

  final String? stageType;
  final bool isClientPending;
  final int journeyOrder;

  ProjectTask({
    required this.id,
    required this.projectId,
    required this.title,
    this.description,
    required this.status,
    this.assignedTo,
    this.deadline,
    required this.priority,
    this.category,
    this.stageName,
    this.subtasks = const [],
    this.attachmentUrls = const [],
    required this.createdAt,
    this.isClientRequest = false,
    this.requestType,
    this.clientProposedDeadline,
    this.stageType,
    this.isClientPending = false,
    this.journeyOrder = 0,
  });

  factory ProjectTask.fromJson(Map<String, dynamic> json) {
    return ProjectTask(
      id: json['id'],
      projectId: json['project_id'],
      title: json['title'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'todo',
      assignedTo: json['assigned_to'],
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      priority: json['priority'] ?? 'normal',
      category: json['category'],
      stageName: json['stage_name'],
      subtasks: json['subtasks'] != null 
          ? List<Map<String, dynamic>>.from(json['subtasks']) 
          : const [],
      attachmentUrls: json['attachment_urls'] != null 
          ? List<String>.from(json['attachment_urls']) 
          : const [],
      createdAt: DateTime.parse(json['created_at']),
      isClientRequest: json['is_client_request'] ?? false,
      requestType: json['request_type'],
      clientProposedDeadline: json['client_proposed_deadline'] != null 
          ? DateTime.parse(json['client_proposed_deadline']) 
          : null,
      stageType: json['stage_type'],
      isClientPending: json['is_client_pending'] ?? false,
      journeyOrder: json['journey_order'] ?? 0,
    );
  }
}
