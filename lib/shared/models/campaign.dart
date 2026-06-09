class ProjectCampaign {
  final String id;
  final String projectId;
  final String name;
  final String? nameAr;
  final String? goal;
  final String? goalAr;
  final String channel;
  final double? budget;
  final String currency;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;

  ProjectCampaign({
    required this.id,
    required this.projectId,
    required this.name,
    this.nameAr,
    this.goal,
    this.goalAr,
    required this.channel,
    this.budget,
    required this.currency,
    required this.status,
    this.startDate,
    this.endDate,
    required this.createdAt,
  });

  factory ProjectCampaign.fromJson(Map<String, dynamic> json) {
    return ProjectCampaign(
      id: json['id'] ?? '',
      projectId: json['project_id'] ?? '',
      name: json['name'] ?? '',
      nameAr: json['name_ar'],
      goal: json['goal'],
      goalAr: json['goal_ar'],
      channel: json['channel'] ?? '',
      budget: (json['budget'] as num?)?.toDouble(),
      currency: json['currency'] ?? 'EGP',
      status: json['status'] ?? 'planned',
      startDate: json['start_date'] != null ? DateTime.tryParse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.tryParse(json['end_date']) : null,
      createdAt: json['created_at'] != null ? (DateTime.tryParse(json['created_at']) ?? DateTime.now()) : DateTime.now(),
    );
  }
}

class CampaignResult {
  final String id;
  final String campaignId;
  final String metricLabel;
  final double metricValue;
  final String metricUnit;
  final DateTime recordedAt;

  CampaignResult({
    required this.id,
    required this.campaignId,
    required this.metricLabel,
    required this.metricValue,
    required this.metricUnit,
    required this.recordedAt,
  });

  factory CampaignResult.fromJson(Map<String, dynamic> json) {
    return CampaignResult(
      id: json['id'] ?? '',
      campaignId: json['campaign_id'] ?? '',
      metricLabel: json['metric_label'] ?? '',
      metricValue: (json['metric_value'] as num?)?.toDouble() ?? 0.0,
      metricUnit: json['metric_unit'] ?? '',
      recordedAt: json['recorded_at'] != null ? (DateTime.tryParse(json['recorded_at']) ?? DateTime.now()) : DateTime.now(),
    );
  }
}
