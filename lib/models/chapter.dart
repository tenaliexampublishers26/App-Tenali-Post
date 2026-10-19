class Chapter {
  final String id;
  final String examId;
  final String title;
  final String? description;
  final int chapterNumber;
  final int totalQuestions;
  final List<String> supportedLanguages;

  const Chapter({
    required this.id,
    required this.examId,
    required this.title,
    this.description,
    required this.chapterNumber,
    this.totalQuestions = 0,
    this.supportedLanguages = const ['en', 'te', 'hi'],
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'] as String? ?? '',
      examId: json['exam_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      chapterNumber: json['chapter_number'] as int? ?? 1,
      totalQuestions: json['total_questions'] as int? ?? 0,
      supportedLanguages: json['supported_languages'] != null
          ? List<String>.from(json['supported_languages'])
          : const ['en', 'te', 'hi'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exam_id': examId,
      'title': title,
      'description': description,
      'chapter_number': chapterNumber,
      'total_questions': totalQuestions,
      'supported_languages': supportedLanguages,
    };
  }
}
