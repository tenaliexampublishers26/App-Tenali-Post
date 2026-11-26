class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String? location;
  final String? postalCircle;
  final String role; // 'student' or 'admin'
  final String? avatarUrl;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    this.location,
    this.postalCircle,
    this.role = 'student',
    this.avatarUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isAdmin => role.toLowerCase() == 'admin';

  /// Profile is complete only when all 4 mandatory fields are present and valid:
  /// 1. Full Name
  /// 2. Email Address
  /// 3. Phone Number
  /// 4. Location
  bool get isProfileComplete {
    return fullName.trim().isNotEmpty &&
        email.trim().isNotEmpty &&
        (phoneNumber ?? '').trim().isNotEmpty &&
        (location ?? postalCircle ?? '').trim().isNotEmpty;
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? json['name'] as String? ?? 'Candidate',
      phoneNumber: json['phone_number'] as String?,
      location: json['location'] as String? ?? json['postal_circle'] as String?,
      postalCircle: json['postal_circle'] as String? ?? json['location'] as String?,
      role: json['role'] as String? ?? 'student',
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'location': location ?? postalCircle,
      'postal_circle': postalCircle ?? location,
      'role': role,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? location,
    String? postalCircle,
    String? role,
    String? avatarUrl,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      location: location ?? this.location,
      postalCircle: postalCircle ?? this.postalCircle,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

