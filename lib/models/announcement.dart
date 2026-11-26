class Announcement {
  final String id;
  final String title;
  final String message;
  final bool isPublished;
  final DateTime publishedAt;
  final DateTime createdAt;
  final String? createdBy;
  final bool isRead;

  Announcement({
    required this.id,
    required this.title,
    required this.message,
    this.isPublished = true,
    DateTime? publishedAt,
    DateTime? createdAt,
    this.createdBy,
    this.isRead = false,
  })  : publishedAt = publishedAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  factory Announcement.fromJson(Map<String, dynamic> json, {bool isRead = false}) {
    return Announcement(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      isPublished: json['is_published'] as bool? ?? true,
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      createdBy: json['created_by'] as String?,
      isRead: isRead || (json['is_read'] as bool? ?? false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'is_published': isPublished,
      'published_at': publishedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
    };
  }

  Announcement copyWith({
    String? id,
    String? title,
    String? message,
    bool? isPublished,
    DateTime? publishedAt,
    DateTime? createdAt,
    String? createdBy,
    bool? isRead,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      isPublished: isPublished ?? this.isPublished,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      isRead: isRead ?? this.isRead,
    );
  }
}
