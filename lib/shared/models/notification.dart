class AppNotification {
  final String id;
  final String userId;
  final String titleAr;
  final String titleEn;
  final String bodyAr;
  final String bodyEn;
  final String type;
  final String? linkPath;
  final bool isRead;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.titleAr,
    required this.titleEn,
    required this.bodyAr,
    required this.bodyEn,
    required this.type,
    this.linkPath,
    this.isRead = false,
    this.metadata = const {},
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      userId: json['user_id'],
      titleAr: json['title_ar'] ?? '',
      titleEn: json['title_en'] ?? '',
      bodyAr: json['body_ar'] ?? '',
      bodyEn: json['body_en'] ?? '',
      type: json['type'] ?? 'info',
      linkPath: json['link_path'],
      isRead: json['is_read'] ?? false,
      metadata: json['metadata'] ?? {},
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String getLocalizedTitle(bool isAr) {
    if (isAr) {
      return (titleAr.isNotEmpty) ? titleAr : (titleEn.isNotEmpty ? titleEn : 'تنبيه جديد');
    }
    return titleEn.isNotEmpty ? titleEn : titleAr;
  }

  String getLocalizedBody(bool isAr) {
    if (isAr) {
      return (bodyAr.isNotEmpty) ? bodyAr : (bodyEn.isNotEmpty ? bodyEn : 'لديك تحديث جديد بانتظار المراجعة');
    }
    return bodyEn.isNotEmpty ? bodyEn : bodyAr;
  }
}
