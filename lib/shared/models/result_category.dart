class ResultCategory {
  final String id;
  final String projectId;
  final String nameAr;
  final String nameEn;
  final String? icon;

  ResultCategory({
    required this.id,
    required this.projectId,
    required this.nameAr,
    required this.nameEn,
    this.icon,
  });

  factory ResultCategory.fromJson(Map<String, dynamic> json) {
    return ResultCategory(
      id: json['id'],
      projectId: json['project_id'],
      nameAr: json['name_ar'],
      nameEn: json['name_en'],
      icon: json['icon'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'name_ar': nameAr,
      'name_en': nameEn,
      'icon': icon,
    };
  }
}
