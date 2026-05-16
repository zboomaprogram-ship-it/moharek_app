class Project {
  final String id;
  final String clientId;
  final String? accountManagerId;
  final String name;
  final String status;
  final DateTime? startDate;
  final String currentStage;
  final DateTime createdAt;
  final String? projectGoal;
  final String? targetMarket;
  final String? targetAudience;
  final List<String>? competitors;
  final String? voiceUpdateUrl;
  final DateTime? voiceUpdateAt;
  final String? subscriptionTier;
  final DateTime? nextRenewalDate;

  final String? gscSiteUrl;
  final String? ga4PropertyId;
  final String? gbpLocationId;
  final String? companyId;

  Project({
    required this.id,
    required this.clientId,
    this.accountManagerId,
    required this.name,
    required this.status,
    this.startDate,
    required this.currentStage,
    required this.createdAt,
    this.projectGoal,
    this.targetMarket,
    this.targetAudience,
    this.competitors,
    this.voiceUpdateUrl,
    this.voiceUpdateAt,
    this.subscriptionTier,
    this.nextRenewalDate,
    this.gscSiteUrl,
    this.ga4PropertyId,
    this.gbpLocationId,
    this.companyId,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id']?.toString() ?? '',
      clientId: json['client_id']?.toString() ?? '',
      accountManagerId: json['account_manager_id']?.toString(),
      name: json['name']?.toString() ?? 'Unnamed Project',
      status: json['status']?.toString() ?? 'active',
      startDate: json['start_date'] != null 
          ? DateTime.tryParse(json['start_date'].toString()) 
          : null,
      currentStage: json['current_stage']?.toString() ?? 'Audit',
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      projectGoal: json['project_goal']?.toString(),
      targetMarket: json['target_market']?.toString(),
      targetAudience: json['target_audience']?.toString(),
      competitors: (json['competitors'] as List?)?.map((e) => e.toString()).toList(),
      voiceUpdateUrl: json['voice_update_url']?.toString(),
      voiceUpdateAt: json['voice_update_at'] != null 
          ? DateTime.tryParse(json['voice_update_at'].toString()) 
          : null,
      subscriptionTier: json['subscription_tier']?.toString(),
      nextRenewalDate: json['next_renewal_date'] != null 
          ? DateTime.tryParse(json['next_renewal_date'].toString()) 
          : null,
      gscSiteUrl: json['gsc_site_url']?.toString(),
      ga4PropertyId: json['ga4_property_id']?.toString(),
      gbpLocationId: json['gbp_location_id']?.toString(),
      companyId: json['company_id']?.toString(),
    );
  }
}
