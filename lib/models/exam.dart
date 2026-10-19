class Exam {
  final String id;
  final String title;
  final String subtitle;
  final String code;
  final int totalChapters;
  final int totalQuestions;
  final String iconName;

  const Exam({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.code,
    this.totalChapters = 0,
    this.totalQuestions = 0,
    this.iconName = 'school',
  });

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      code: json['code'] as String? ?? '',
      totalChapters: json['total_chapters'] as int? ?? 0,
      totalQuestions: json['total_questions'] as int? ?? 0,
      iconName: json['icon_name'] as String? ?? 'school',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'code': code,
      'total_chapters': totalChapters,
      'total_questions': totalQuestions,
      'icon_name': iconName,
    };
  }
}
