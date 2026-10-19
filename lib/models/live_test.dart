class LiveTest {
  final String id;
  final String title;
  final String description;
  final String examId;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final double totalMarks;
  final int totalQuestions;
  final double passMarks;
  final double negativeMarksPerWrong;
  final bool isPublished;
  final bool isResultsPublished;

  const LiveTest({
    required this.id,
    required this.title,
    required this.description,
    required this.examId,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.totalMarks,
    required this.totalQuestions,
    required this.passMarks,
    this.negativeMarksPerWrong = 0.0,
    this.isPublished = false,
    this.isResultsPublished = false,
  });

  LiveTest copyWith({
    String? id,
    String? title,
    String? description,
    String? examId,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    double? totalMarks,
    int? totalQuestions,
    double? passMarks,
    double? negativeMarksPerWrong,
    bool? isPublished,
    bool? isResultsPublished,
  }) {
    return LiveTest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      examId: examId ?? this.examId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      totalMarks: totalMarks ?? this.totalMarks,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      passMarks: passMarks ?? this.passMarks,
      negativeMarksPerWrong: negativeMarksPerWrong ?? this.negativeMarksPerWrong,
      isPublished: isPublished ?? this.isPublished,
      isResultsPublished: isResultsPublished ?? this.isResultsPublished,
    );
  }

  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime) && isPublished;
  }

  bool get isUpcoming {
    final now = DateTime.now();
    return now.isBefore(startTime) && isPublished;
  }

  bool get isEnded {
    final now = DateTime.now();
    return now.isAfter(endTime);
  }

  factory LiveTest.fromJson(Map<String, dynamic> json) {
    return LiveTest(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      examId: json['exam_id'] as String? ?? '',
      startTime: json['start_time'] != null
          ? DateTime.tryParse(json['start_time'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endTime: json['end_time'] != null
          ? DateTime.tryParse(json['end_time'].toString()) ?? DateTime.now().add(const Duration(hours: 2))
          : DateTime.now().add(const Duration(hours: 2)),
      durationMinutes: json['duration_minutes'] as int? ?? 60,
      totalMarks: (json['total_marks'] as num?)?.toDouble() ?? 100.0,
      totalQuestions: json['total_questions'] as int? ?? 50,
      passMarks: (json['pass_marks'] as num?)?.toDouble() ?? 40.0,
      negativeMarksPerWrong: (json['negative_marks'] as num?)?.toDouble() ?? 0.0,
      isPublished: json['is_published'] as bool? ?? false,
      isResultsPublished: json['is_results_published'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'exam_id': examId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'duration_minutes': durationMinutes,
      'total_marks': totalMarks,
      'total_questions': totalQuestions,
      'pass_marks': passMarks,
      'negative_marks': negativeMarksPerWrong,
      'is_published': isPublished,
      'is_results_published': isResultsPublished,
    };
  }
}

class LiveTestSubmission {
  final String id;
  final String testId;
  final String studentName;
  final String phoneNumber;
  final double marksObtained;
  final double totalMarks;
  final int correctCount;
  final int wrongCount;
  final int skippedCount;
  final double percentage;
  final int? rank;
  final Map<String, String> answers;
  final DateTime submittedAt;

  const LiveTestSubmission({
    required this.id,
    required this.testId,
    required this.studentName,
    required this.phoneNumber,
    required this.marksObtained,
    required this.totalMarks,
    required this.correctCount,
    required this.wrongCount,
    required this.skippedCount,
    required this.percentage,
    this.rank,
    required this.answers,
    required this.submittedAt,
  });

  factory LiveTestSubmission.fromJson(Map<String, dynamic> json) {
    Map<String, String> parsedAnswers = {};
    if (json['answers'] is Map) {
      json['answers'].forEach((key, val) {
        parsedAnswers[key.toString()] = val.toString();
      });
    }

    return LiveTestSubmission(
      id: json['id'] as String? ?? '',
      testId: json['test_id'] as String? ?? '',
      studentName: json['student_name'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
      marksObtained: (json['marks_obtained'] as num?)?.toDouble() ?? 0.0,
      totalMarks: (json['total_marks'] as num?)?.toDouble() ?? 0.0,
      correctCount: json['correct_count'] as int? ?? 0,
      wrongCount: json['wrong_count'] as int? ?? 0,
      skippedCount: json['skipped_count'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      rank: json['rank'] as int?,
      answers: parsedAnswers,
      submittedAt: json['submitted_at'] != null
          ? DateTime.tryParse(json['submitted_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'test_id': testId,
      'student_name': studentName,
      'phone_number': phoneNumber,
      'marks_obtained': marksObtained,
      'total_marks': totalMarks,
      'correct_count': correctCount,
      'wrong_count': wrongCount,
      'skipped_count': skippedCount,
      'percentage': percentage,
      'rank': rank,
      'answers': answers,
      'submitted_at': submittedAt.toIso8601String(),
    };
  }
}
