class Milestone {
  final String id;
  final String projectId;
  final String milestoneType;
  final String title;
  final String description;
  final String titleAr;
  final String titleEn;
  final String descriptionAr;
  final String descriptionEn;
  final DateTime achievedAt;
  final bool seenByClient;

  Milestone({
    required this.id,
    required this.projectId,
    required this.milestoneType,
    required this.title,
    required this.description,
    required this.titleAr,
    required this.titleEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.achievedAt,
    this.seenByClient = false,
  });

  factory Milestone.fromJson(Map<String, dynamic> json) {
    return Milestone(
      id: json['id'],
      projectId: json['project_id'],
      milestoneType: json['milestone_type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      titleAr: json['title_ar'] ?? json['title'] ?? '',
      titleEn: json['title_en'] ?? json['title'] ?? '',
      descriptionAr: json['description_ar'] ?? json['description'] ?? '',
      descriptionEn: json['description_en'] ?? json['description'] ?? '',
      achievedAt: DateTime.parse(json['achieved_at'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
      seenByClient: json['seen_by_client'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'milestone_type': milestoneType,
      'title': title,
      'description': description,
      'title_ar': titleAr,
      'title_en': titleEn,
      'description_ar': descriptionAr,
      'description_en': descriptionEn,
      'achieved_at': achievedAt.toIso8601String(),
      'seen_by_client': seenByClient,
    };
  }
}
