class GrowthEngineModel {
  final String engineType, status;
  final int healthScore;

  String get arabicName => {
    'store':      'محرك المتجر',
    'product':    'محرك المنتجات',
    'ads':        'محرك الإعلانات',
    'sales_page': 'محرك صفحات البيع',
    'operations': 'محرك العمليات',
    'analytics':  'محرك التحليلات',
  }[engineType] ?? engineType;

  GrowthEngineModel({
    required this.engineType,
    required this.status,
    required this.healthScore,
  });

  factory GrowthEngineModel.fromJson(Map<String, dynamic> j) => GrowthEngineModel(
    engineType: j['engine_type'] ?? '',
    status: j['status'] ?? 'pending',
    healthScore: j['health_score'] ?? 0,
  );
}
