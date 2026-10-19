class StudyNote {
  final String id;
  final String examId;
  final String? chapterId;
  final String title;
  final String description;
  final String fileUrl; // PDF or document link
  final String? fileSize;
  final int pageCount;
  final String languageCode;
  final bool isFree;

  const StudyNote({
    required this.id,
    required this.examId,
    this.chapterId,
    required this.title,
    required this.description,
    required this.fileUrl,
    this.fileSize,
    this.pageCount = 1,
    this.languageCode = 'en',
    this.isFree = true,
  });

  factory StudyNote.fromJson(Map<String, dynamic> json) {
    return StudyNote(
      id: json['id'] as String? ?? '',
      examId: json['exam_id'] as String? ?? '',
      chapterId: json['chapter_id'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      fileUrl: json['file_url'] as String? ?? '',
      fileSize: json['file_size'] as String? ?? '1.2 MB',
      pageCount: json['page_count'] as int? ?? 1,
      languageCode: json['language_code'] as String? ?? 'en',
      isFree: json['is_free'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exam_id': examId,
      'chapter_id': chapterId,
      'title': title,
      'description': description,
      'file_url': fileUrl,
      'file_size': fileSize,
      'page_count': pageCount,
      'language_code': languageCode,
      'is_free': isFree,
    };
  }
}
