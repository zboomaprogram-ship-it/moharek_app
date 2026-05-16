class Profile {
  final String id;
  final String fullName;
  final String? email;
  final String? companyName;
  final String role;
  final String? avatarUrl;
  final String? phone;
  final DateTime createdAt;
  final bool onboardingCompleted;
  final String? clientGoal;
  final DateTime? lastSeenAt;
  final String preferredLanguage;
  final Map<String, dynamic> notificationPreferences;

  Profile({
    required this.id,
    required this.fullName,
    this.email,
    this.companyName,
    required this.role,
    this.avatarUrl,
    this.phone,
    required this.createdAt,
    this.onboardingCompleted = false,
    this.clientGoal,
    this.lastSeenAt,
    this.preferredLanguage = 'en',
    this.notificationPreferences = const {
      'reports': true,
      'tasks': true,
      'messages': true,
      'milestones': true,
      'meetings': true,
    },
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      email: json['email']?.toString(),
      companyName: json['company_name']?.toString(),
      role: json['role']?.toString() ?? 'client',
      avatarUrl: json['avatar_url']?.toString(),
      phone: json['phone']?.toString(),
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      onboardingCompleted: json['onboarding_completed'] ?? false,
      clientGoal: json['client_goal']?.toString(),
      lastSeenAt: json['last_seen_at'] != null 
          ? DateTime.tryParse(json['last_seen_at'].toString()) 
          : null,
      preferredLanguage: json['preferred_language']?.toString() ?? 'en',
      notificationPreferences: Map<String, dynamic>.from(json['notification_preferences'] ?? {
        'reports': true,
        'tasks': true,
        'messages': true,
        'milestones': true,
        'meetings': true,
      }),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'company_name': companyName,
      'role': role,
      'avatar_url': avatarUrl,
      'phone': phone,
      'created_at': createdAt.toIso8601String(),
      'onboarding_completed': onboardingCompleted,
      'client_goal': clientGoal,
      'last_seen_at': lastSeenAt?.toIso8601String(),
      'preferred_language': preferredLanguage,
      'notification_preferences': notificationPreferences,
    };
  }

  Profile copyWith({
    String? fullName,
    String? email,
    String? companyName,
    String? role,
    String? avatarUrl,
    String? phone,
    bool? onboardingCompleted,
    String? clientGoal,
    DateTime? lastSeenAt,
    String? preferredLanguage,
    Map<String, dynamic>? notificationPreferences,
  }) {
    return Profile(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      companyName: companyName ?? this.companyName,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      createdAt: createdAt,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      clientGoal: clientGoal ?? this.clientGoal,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      notificationPreferences: notificationPreferences ?? this.notificationPreferences,
    );
  }
}

