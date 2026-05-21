class AdCampaign {
  final String id;
  final String projectId;
  final String campaignName;
  final String platform;
  final String status;
  final double budget;
  final double spend;
  final double roas;
  final int clicks;
  final int impressions;
  final int conversions;
  final String? platformCampaignId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String currency;

  AdCampaign({
    required this.id,
    required this.projectId,
    required this.campaignName,
    required this.platform,
    required this.status,
    required this.budget,
    required this.spend,
    required this.roas,
    required this.clicks,
    required this.impressions,
    required this.conversions,
    this.platformCampaignId,
    this.startDate,
    this.endDate,
    required this.currency,
  });

  factory AdCampaign.fromJson(Map<String, dynamic> json) {
    return AdCampaign(
      id: json['id'] ?? '',
      projectId: json['project_id'] ?? '',
      campaignName: json['campaign_name'] ?? '',
      platform: json['platform'] ?? 'other',
      status: json['status'] ?? 'active',
      budget: (json['budget'] ?? 0.0).toDouble(),
      spend: (json['spend'] ?? 0.0).toDouble(),
      roas: (json['roas'] ?? 0.0).toDouble(),
      clicks: json['clicks'] ?? 0,
      impressions: json['impressions'] ?? 0,
      conversions: json['conversions'] ?? 0,
      platformCampaignId: json['platform_campaign_id'],
      startDate: json['start_date'] != null ? DateTime.tryParse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.tryParse(json['end_date']) : null,
      currency: json['currency'] ?? 'SAR',
    );
  }
}
