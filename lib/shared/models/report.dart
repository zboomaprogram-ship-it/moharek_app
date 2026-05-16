class ProjectReport {
  final String id;
  final String projectId;
  final String title;
  final String? titleAr;
  final String reportType; // monthly, weekly, etc.
  final String? summary;
  final String status;
  final String fileUrl;
  final String? highlightStat;
  final String? highlightContext;
  final String? managerNote;
  final List<String>? nextMonthPriorities;
  final String? aiSummary;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final DateTime createdAt;

  ProjectReport({
    required this.id,
    required this.projectId,
    required this.title,
    this.titleAr,
    required this.reportType,
    this.summary,
    required this.status,
    required this.fileUrl,
    this.highlightStat,
    this.highlightContext,
    this.managerNote,
    this.nextMonthPriorities,
    this.aiSummary,
    this.periodStart,
    this.periodEnd,
    required this.createdAt,
  });

  factory ProjectReport.fromJson(Map<String, dynamic> json) {
    return ProjectReport(
      id: json['id'],
      projectId: json['project_id'],
      title: json['title'] ?? 'Report',
      titleAr: json['title_ar'],
      reportType: json['report_type'] ?? 'monthly',
      summary: json['summary'],
      status: json['status'] ?? 'ready',
      fileUrl: json['file_url'] ?? '',
      highlightStat: json['highlight_stat'],
      highlightContext: json['highlight_context'],
      managerNote: json['manager_note'],
      nextMonthPriorities: (json['next_month_priorities'] as List?)?.map((e) => e.toString()).toList(),
      aiSummary: json['ai_summary'],
      periodStart: json['period_start'] != null ? DateTime.parse(json['period_start']) : null,
      periodEnd: json['period_end'] != null ? DateTime.parse(json['period_end']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
