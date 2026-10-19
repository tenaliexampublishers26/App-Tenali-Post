class VideoLesson {
  final String id;
  final String examId;
  final String? chapterId;
  final String title;
  final String description;
  final String videoUrl;
  final String? thumbnailUrl;
  final String duration;
  final String languageCode;
  final bool isFree;

  const VideoLesson({
    required this.id,
    required this.examId,
    this.chapterId,
    required this.title,
    required this.description,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.duration,
    this.languageCode = 'te',
    this.isFree = true,
  });

  factory VideoLesson.fromJson(Map<String, dynamic> json) {
    return VideoLesson(
      id: json['id'] as String? ?? '',
      examId: json['exam_id'] as String? ?? '',
      chapterId: json['chapter_id'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      videoUrl: json['video_url'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String?,
      duration: json['duration'] as String? ?? '15:00',
      languageCode: json['language_code'] as String? ?? 'te',
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
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'duration': duration,
      'language_code': languageCode,
      'is_free': isFree,
    };
  }
}
