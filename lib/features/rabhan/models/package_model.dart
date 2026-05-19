class PackageModel {
  final String id, packageName, packageTier, status;
  final DateTime? renewsAt, trialEndsAt;
  final int requestsUsed, requestsLimit;
  final List<String> services;
  final String? notes;

  int get daysUntilRenewal =>
    renewsAt == null ? 0 : renewsAt!.difference(DateTime.now()).inDays;
  double get requestsUsedPercent => requestsLimit == 0 ? 0 : requestsUsed / requestsLimit;

  PackageModel({
    required this.id,
    required this.packageName,
    required this.packageTier,
    required this.status,
    this.renewsAt,
    this.trialEndsAt,
    required this.requestsUsed,
    required this.requestsLimit,
    required this.services,
    this.notes,
  });

  factory PackageModel.fromJson(Map<String, dynamic> j) => PackageModel(
    id: j['id'] ?? '',
    packageName: j['package_name'] ?? '',
    packageTier: j['package_tier'] ?? 'starter',
    status: j['status'] ?? 'active',
    renewsAt: j['renews_at'] != null ? DateTime.parse(j['renews_at'].toString()) : null,
    trialEndsAt: j['trial_ends_at'] != null ? DateTime.parse(j['trial_ends_at'].toString()) : null,
    requestsUsed: j['requests_used'] ?? 0,
    requestsLimit: j['requests_limit'] ?? 200,
    services: (j['services'] as List?)?.cast<String>() ?? [],
    notes: j['notes'],
  );
}
