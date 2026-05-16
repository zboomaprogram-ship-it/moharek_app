class SupportTicket {
  final String id;
  final String projectId;
  final String submittedBy;
  final String title;
  final String description;
  final String ticketType;
  final String priority;
  final String status;
  final DateTime createdAt;

  SupportTicket({
    required this.id,
    required this.projectId,
    required this.submittedBy,
    required this.title,
    required this.description,
    required this.ticketType,
    required this.priority,
    required this.status,
    required this.createdAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id']?.toString() ?? '',
      projectId: json['project_id']?.toString() ?? '',
      submittedBy: json['submitted_by']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Support Ticket',
      description: json['description']?.toString() ?? '',
      ticketType: json['ticket_type']?.toString() ?? 'other',
      priority: json['priority']?.toString() ?? 'normal',
      status: json['status']?.toString() ?? 'open',
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
