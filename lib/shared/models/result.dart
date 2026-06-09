class ResultMetric {
  final String id;
  final String projectId;
  final String resultType;
  final String metricName;
  final String? metricLabel;
  final double metricValue;
  final String? metricUnit;
  final String? categoryId;
  final String? notes;
  final double? previousValue;
  final double? changeFromLast;
  final String? trendDirection;
  final DateTime recordedAt;
  final String? fileUrl;

  ResultMetric({
    required this.id,
    required this.projectId,
    required this.resultType,
    required this.metricName,
    this.metricLabel,
    required this.metricValue,
    this.metricUnit,
    this.categoryId,
    this.notes,
    this.previousValue,
    this.changeFromLast,
    this.trendDirection,
    required this.recordedAt,
    this.fileUrl,
  });

  factory ResultMetric.fromJson(Map<String, dynamic> json) {
    return ResultMetric(
      id: json['id'],
      projectId: json['project_id'],
      resultType: json['result_type'] ?? 'General',
      metricName: json['metric_name'] ?? '',
      metricLabel: json['metric_label'],
      metricValue: (json['metric_value'] as num?)?.toDouble() ?? 0.0,
      metricUnit: json['metric_unit'],
      categoryId: json['category_id'],
      notes: json['notes'],
      previousValue: (json['previous_value'] as num?)?.toDouble(),
      changeFromLast: (json['change_from_last'] as num?)?.toDouble(),
      trendDirection: json['trend_direction'],
      recordedAt: DateTime.parse(json['recorded_at'] ?? DateTime.now().toIso8601String()),
      fileUrl: json['file_url'],
    );
  }
}
