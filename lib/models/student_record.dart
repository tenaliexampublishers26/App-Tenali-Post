import 'live_test.dart';

class StudentRecord {
  final String id;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String postalCircle;
  final String targetExam;
  final String status; // 'Active', 'Suspended'
  final DateTime registeredAt;
  final DateTime lastActiveAt;
  final int totalTestsAttempted;
  final double averagePercentage;
  final List<LiveTestSubmission> testAttempts;

  const StudentRecord({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.postalCircle,
    required this.targetExam,
    this.status = 'Active',
    required this.registeredAt,
    required this.lastActiveAt,
    this.totalTestsAttempted = 0,
    this.averagePercentage = 0.0,
    this.testAttempts = const [],
  });

  bool get isActive => status.toLowerCase() == 'active';
  String get circle => postalCircle;
  String get cadre => targetExam;

  StudentRecord copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? postalCircle,
    String? targetExam,
    String? status,
    DateTime? registeredAt,
    DateTime? lastActiveAt,
    int? totalTestsAttempted,
    double? averagePercentage,
    List<LiveTestSubmission>? testAttempts,
  }) {
    return StudentRecord(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      postalCircle: postalCircle ?? this.postalCircle,
      targetExam: targetExam ?? this.targetExam,
      status: status ?? this.status,
      registeredAt: registeredAt ?? this.registeredAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      totalTestsAttempted: totalTestsAttempted ?? this.totalTestsAttempted,
      averagePercentage: averagePercentage ?? this.averagePercentage,
      testAttempts: testAttempts ?? this.testAttempts,
    );
  }

  factory StudentRecord.fromJson(Map<String, dynamic> json) {
    return StudentRecord(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'Candidate',
      phoneNumber: json['phone_number'] as String? ?? '',
      postalCircle: json['postal_circle'] as String? ?? 'All Circles',
      targetExam: json['target_exam'] as String? ?? 'MTS',
      status: json['status'] as String? ?? 'Active',
      registeredAt: json['registered_at'] != null
          ? DateTime.tryParse(json['registered_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lastActiveAt: json['last_active_at'] != null
          ? DateTime.tryParse(json['last_active_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      totalTestsAttempted: json['total_tests_attempted'] as int? ?? 0,
      averagePercentage: (json['average_percentage'] as num?)?.toDouble() ?? 0.0,
      testAttempts: (json['test_attempts'] as List<dynamic>?)
              ?.map((e) => LiveTestSubmission.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'postal_circle': postalCircle,
      'target_exam': targetExam,
      'status': status,
      'registered_at': registeredAt.toIso8601String(),
      'last_active_at': lastActiveAt.toIso8601String(),
      'total_tests_attempted': totalTestsAttempted,
      'average_percentage': averagePercentage,
      'test_attempts': testAttempts.map((e) => e.toJson()).toList(),
    };
  }
}
