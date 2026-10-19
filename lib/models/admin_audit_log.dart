class AdminAuditLog {
  final String id;
  final String adminEmail;
  final String actionType; // 'CREATE', 'UPDATE', 'DELETE', 'IMPORT', 'PUBLISH', 'SUSPEND'
  final String targetEntity; // 'QUESTION', 'EXAM', 'CHAPTER', 'LIVE_TEST', 'STUDENT', 'VIDEO', 'NOTE'
  final String targetId;
  final String description;
  final DateTime timestamp;

  const AdminAuditLog({
    required this.id,
    required this.adminEmail,
    required this.actionType,
    required this.targetEntity,
    required this.targetId,
    required this.description,
    required this.timestamp,
  });

  factory AdminAuditLog.fromJson(Map<String, dynamic> json) {
    return AdminAuditLog(
      id: json['id'] as String? ?? '',
      adminEmail: json['admin_email'] as String? ?? 'admin',
      actionType: json['action_type'] as String? ?? 'UPDATE',
      targetEntity: json['target_entity'] as String? ?? 'SYSTEM',
      targetId: json['target_id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'admin_email': adminEmail,
      'action_type': actionType,
      'target_entity': targetEntity,
      'target_id': targetId,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
