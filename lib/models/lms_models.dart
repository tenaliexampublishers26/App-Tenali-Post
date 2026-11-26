class LmsSettings {
  final bool mcqEnabled;
  final bool liveTestEnabled;
  final bool maintenanceMode;
  final bool liveNotificationEnabled;
  final String liveNotificationText;
  final String liveNotificationLink;

  const LmsSettings({
    this.mcqEnabled = true,
    this.liveTestEnabled = true,
    this.maintenanceMode = false,
    this.liveNotificationEnabled = false,
    this.liveNotificationText = '',
    this.liveNotificationLink = '',
  });

  LmsSettings copyWith({
    bool? mcqEnabled,
    bool? liveTestEnabled,
    bool? maintenanceMode,
    bool? liveNotificationEnabled,
    String? liveNotificationText,
    String? liveNotificationLink,
  }) {
    return LmsSettings(
      mcqEnabled: mcqEnabled ?? this.mcqEnabled,
      liveTestEnabled: liveTestEnabled ?? this.liveTestEnabled,
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      liveNotificationEnabled:
          liveNotificationEnabled ?? this.liveNotificationEnabled,
      liveNotificationText: liveNotificationText ?? this.liveNotificationText,
      liveNotificationLink: liveNotificationLink ?? this.liveNotificationLink,
    );
  }

  factory LmsSettings.fromKeyValueRows(List<dynamic> rows) {
    final map = <String, String>{};
    for (final row in rows) {
      if (row is Map) {
        final k = row['key']?.toString() ?? '';
        final v = row['value']?.toString() ?? '';
        if (k.isNotEmpty) map[k] = v;
      }
    }
    return LmsSettings(
      mcqEnabled: map['mcq_enabled'] != 'false',
      liveTestEnabled: map['live_test_enabled'] != 'false',
      maintenanceMode: map['maintenance_mode'] == 'true',
      liveNotificationEnabled: map['live_notification_enabled'] == 'true',
      liveNotificationText: map['live_notification_text'] ?? '',
      liveNotificationLink: map['live_notification_link'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'mcq_enabled': mcqEnabled,
        'live_test_enabled': liveTestEnabled,
        'maintenance_mode': maintenanceMode,
        'live_notification_enabled': liveNotificationEnabled,
        'live_notification_text': liveNotificationText,
        'live_notification_link': liveNotificationLink,
      };
}

class LmsAuditLog {
  final String id;
  final String adminId;
  final String adminName;
  final String adminEmail;
  final String actionType;
  final String targetType;
  final String targetName;
  final Map<String, dynamic>? previousValue;
  final Map<String, dynamic>? newValue;
  final String ipAddress;
  final String locationName;
  final DateTime createdAt;

  const LmsAuditLog({
    required this.id,
    required this.adminId,
    required this.adminName,
    required this.adminEmail,
    required this.actionType,
    required this.targetType,
    required this.targetName,
    this.previousValue,
    this.newValue,
    this.ipAddress = 'mobile-app',
    this.locationName = 'Tenali, Andhra Pradesh, India',
    required this.createdAt,
  });

  factory LmsAuditLog.fromJson(Map<String, dynamic> json) {
    return LmsAuditLog(
      id: json['id']?.toString() ?? '',
      adminId: json['admin_id']?.toString() ?? '',
      adminName: json['admin_name']?.toString() ?? 'Admin',
      adminEmail: json['admin_email']?.toString() ?? '',
      actionType: json['action_type']?.toString() ?? 'UPDATE',
      targetType: json['target_type']?.toString() ?? 'settings',
      targetName: json['target_name']?.toString() ?? '',
      previousValue: json['previous_value'] is Map
          ? Map<String, dynamic>.from(json['previous_value'] as Map)
          : null,
      newValue: json['new_value'] is Map
          ? Map<String, dynamic>.from(json['new_value'] as Map)
          : null,
      ipAddress: json['ip_address']?.toString() ?? 'mobile-app',
      locationName:
          json['location_name']?.toString() ?? 'Tenali, Andhra Pradesh, India',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class McqTopic {
  final String id;
  final String slug;
  final String name;
  final String category;
  final String? description;
  final String icon;
  final int displayOrder;
  final bool isPublished;
  final bool isActive;
  final String? parentId;
  final int chapterCount;
  final int questionCount;

  const McqTopic({
    required this.id,
    required this.slug,
    required this.name,
    this.category = 'General',
    this.description,
    this.icon = 'book-open',
    this.displayOrder = 1,
    this.isPublished = true,
    this.isActive = true,
    this.parentId,
    this.chapterCount = 0,
    this.questionCount = 0,
  });

  McqTopic copyWith({
    String? id,
    String? slug,
    String? name,
    String? category,
    String? description,
    String? icon,
    int? displayOrder,
    bool? isPublished,
    bool? isActive,
    String? parentId,
    bool clearParentId = false,
    int? chapterCount,
    int? questionCount,
  }) {
    return McqTopic(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      displayOrder: displayOrder ?? this.displayOrder,
      isPublished: isPublished ?? this.isPublished,
      isActive: isActive ?? this.isActive,
      parentId: clearParentId ? null : (parentId ?? this.parentId),
      chapterCount: chapterCount ?? this.chapterCount,
      questionCount: questionCount ?? this.questionCount,
    );
  }

  factory McqTopic.fromJson(Map<String, dynamic> json) {
    return McqTopic(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      description: json['description']?.toString(),
      icon: json['icon']?.toString() ?? 'book-open',
      displayOrder:
          (json['display_order'] as num?)?.toInt() ?? (json['order_index'] as num?)?.toInt() ?? 1,
      isPublished: json['is_published'] as bool? ?? true,
      isActive: json['is_active'] as bool? ?? true,
      parentId: json['parent_id']?.toString(),
      chapterCount: (json['chapter_count'] as num?)?.toInt() ?? 0,
      questionCount: (json['question_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class McqChapter {
  final String id;
  final String topicId;
  final String title;
  final String slug;
  final String? description;
  final int displayOrder;
  final bool isPublished;
  final int questionCount;
  final int publishedSetsCount;

  const McqChapter({
    required this.id,
    required this.topicId,
    required this.title,
    required this.slug,
    this.description,
    this.displayOrder = 1,
    this.isPublished = true,
    this.questionCount = 0,
    this.publishedSetsCount = 0,
  });

  McqChapter copyWith({
    String? id,
    String? topicId,
    String? title,
    String? slug,
    String? description,
    int? displayOrder,
    bool? isPublished,
    int? questionCount,
    int? publishedSetsCount,
  }) {
    return McqChapter(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      displayOrder: displayOrder ?? this.displayOrder,
      isPublished: isPublished ?? this.isPublished,
      questionCount: questionCount ?? this.questionCount,
      publishedSetsCount: publishedSetsCount ?? this.publishedSetsCount,
    );
  }

  factory McqChapter.fromJson(Map<String, dynamic> json) {
    final titleVal = (json['title'] ?? json['name'] ?? '').toString();
    return McqChapter(
      id: json['id']?.toString() ?? '',
      topicId: json['topic_id']?.toString() ?? '',
      title: titleVal,
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
      displayOrder:
          (json['display_order'] as num?)?.toInt() ?? (json['order_index'] as num?)?.toInt() ?? 1,
      isPublished: json['is_published'] as bool? ?? (json['is_active'] as bool? ?? true),
      questionCount: (json['question_count'] as num?)?.toInt() ?? 0,
      publishedSetsCount: (json['published_sets_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class McqMedium {
  final String id;
  final String code;
  final String displayName;
  final bool isActive;

  const McqMedium({
    required this.id,
    required this.code,
    required this.displayName,
    this.isActive = true,
  });

  McqMedium copyWith({
    String? id,
    String? code,
    String? displayName,
    bool? isActive,
  }) {
    return McqMedium(
      id: id ?? this.id,
      code: code ?? this.code,
      displayName: displayName ?? this.displayName,
      isActive: isActive ?? this.isActive,
    );
  }

  factory McqMedium.fromJson(Map<String, dynamic> json) {
    return McqMedium(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? 'en',
      displayName: json['display_name']?.toString() ?? 'English',
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

class McqQuestionSet {
  final String id;
  final String chapterId;
  final String mediumId;
  final int version;
  final String status; // 'draft' | 'published' | 'archived'
  final int questionCount;
  final DateTime createdAt;
  final DateTime? publishedAt;

  const McqQuestionSet({
    required this.id,
    required this.chapterId,
    required this.mediumId,
    this.version = 1,
    this.status = 'draft',
    this.questionCount = 0,
    required this.createdAt,
    this.publishedAt,
  });

  bool get isPublished => status == 'published';
  bool get isDraft => status == 'draft';
  bool get isArchived => status == 'archived';

  McqQuestionSet copyWith({
    String? id,
    String? chapterId,
    String? mediumId,
    int? version,
    String? status,
    int? questionCount,
    DateTime? createdAt,
    DateTime? publishedAt,
  }) {
    return McqQuestionSet(
      id: id ?? this.id,
      chapterId: chapterId ?? this.chapterId,
      mediumId: mediumId ?? this.mediumId,
      version: version ?? this.version,
      status: status ?? this.status,
      questionCount: questionCount ?? this.questionCount,
      createdAt: createdAt ?? this.createdAt,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }

  factory McqQuestionSet.fromJson(Map<String, dynamic> json) {
    return McqQuestionSet(
      id: json['id']?.toString() ?? '',
      chapterId: json['chapter_id']?.toString() ?? '',
      mediumId: json['medium_id']?.toString() ?? '',
      version: (json['version'] as num?)?.toInt() ?? 1,
      status: json['status']?.toString() ?? 'draft',
      questionCount: (json['question_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'].toString())
          : null,
    );
  }
}

class LmsMcqQuestion {
  final String id;
  final String questionSetId;
  final String? chapterId;
  final String questionKey;
  final String questionText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctOption; // 'A'|'B'|'C'|'D'
  final String explanation;
  final String language;
  final String difficulty;
  final int displayOrder;
  final String status;

  const LmsMcqQuestion({
    required this.id,
    required this.questionSetId,
    this.chapterId,
    this.questionKey = 'Q1',
    required this.questionText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctOption,
    this.explanation = '',
    this.language = 'en',
    this.difficulty = 'medium',
    this.displayOrder = 1,
    this.status = 'draft',
  });

  LmsMcqQuestion copyWith({
    String? id,
    String? questionSetId,
    String? chapterId,
    String? questionKey,
    String? questionText,
    String? optionA,
    String? optionB,
    String? optionC,
    String? optionD,
    String? correctOption,
    String? explanation,
    String? language,
    String? difficulty,
    int? displayOrder,
    String? status,
  }) {
    return LmsMcqQuestion(
      id: id ?? this.id,
      questionSetId: questionSetId ?? this.questionSetId,
      chapterId: chapterId ?? this.chapterId,
      questionKey: questionKey ?? this.questionKey,
      questionText: questionText ?? this.questionText,
      optionA: optionA ?? this.optionA,
      optionB: optionB ?? this.optionB,
      optionC: optionC ?? this.optionC,
      optionD: optionD ?? this.optionD,
      correctOption: correctOption ?? this.correctOption,
      explanation: explanation ?? this.explanation,
      language: language ?? this.language,
      difficulty: difficulty ?? this.difficulty,
      displayOrder: displayOrder ?? this.displayOrder,
      status: status ?? this.status,
    );
  }

  factory LmsMcqQuestion.fromJson(Map<String, dynamic> json) {
    return LmsMcqQuestion(
      id: json['id']?.toString() ?? '',
      questionSetId: json['question_set_id']?.toString() ?? '',
      chapterId: json['chapter_id']?.toString(),
      questionKey: json['question_key']?.toString() ?? 'Q1',
      questionText: json['question_text']?.toString() ?? '',
      optionA: json['option_a']?.toString() ?? '',
      optionB: json['option_b']?.toString() ?? '',
      optionC: json['option_c']?.toString() ?? '',
      optionD: json['option_d']?.toString() ?? '',
      correctOption: json['correct_option']?.toString().toUpperCase() ?? 'A',
      explanation: json['explanation']?.toString() ?? '',
      language: json['language']?.toString() ?? 'en',
      difficulty: json['difficulty']?.toString() ?? 'medium',
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 1,
      status: json['status']?.toString() ?? 'draft',
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'question_set_id': questionSetId,
        'chapter_id': chapterId,
        'question_key': questionKey,
        'question_text': questionText,
        'option_a': optionA,
        'option_b': optionB,
        'option_c': optionC,
        'option_d': optionD,
        'correct_option': correctOption,
        'explanation': explanation,
        'language': language,
        'difficulty': difficulty,
        'display_order': displayOrder,
        'status': status,
      };
}

class McqImportLog {
  final String id;
  final String? topicId;
  final String? chapterId;
  final String? mediumId;
  final String fileName;
  final String fileType;
  final String status;
  final int totalRows;
  final int validRows;
  final int invalidRows;
  final String? errorSummary;
  final DateTime createdAt;

  const McqImportLog({
    required this.id,
    this.topicId,
    this.chapterId,
    this.mediumId,
    required this.fileName,
    required this.fileType,
    required this.status,
    this.totalRows = 0,
    this.validRows = 0,
    this.invalidRows = 0,
    this.errorSummary,
    required this.createdAt,
  });

  factory McqImportLog.fromJson(Map<String, dynamic> json) {
    return McqImportLog(
      id: json['id']?.toString() ?? '',
      topicId: json['topic_id']?.toString(),
      chapterId: json['chapter_id']?.toString(),
      mediumId: json['medium_id']?.toString(),
      fileName: json['file_name']?.toString() ?? '',
      fileType: json['file_type']?.toString() ?? 'csv',
      status: json['status']?.toString() ?? 'success',
      totalRows: (json['total_rows'] as num?)?.toInt() ?? 0,
      validRows: (json['valid_rows'] as num?)?.toInt() ?? 0,
      invalidRows: (json['invalid_rows'] as num?)?.toInt() ?? 0,
      errorSummary: json['error_summary']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class McqAttemptRecord {
  final String id;
  final String userId;
  final String? questionSetId;
  final int questionSetVersion;
  final int totalQuestions;
  final int attemptedCount;
  final int correctCount;
  final double score;
  final DateTime submittedAt;

  const McqAttemptRecord({
    required this.id,
    required this.userId,
    this.questionSetId,
    this.questionSetVersion = 1,
    this.totalQuestions = 0,
    this.attemptedCount = 0,
    this.correctCount = 0,
    this.score = 0,
    required this.submittedAt,
  });

  factory McqAttemptRecord.fromJson(Map<String, dynamic> json) {
    return McqAttemptRecord(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      questionSetId: json['question_set_id']?.toString(),
      questionSetVersion: (json['question_set_version'] as num?)?.toInt() ?? 1,
      totalQuestions: (json['total_questions'] as num?)?.toInt() ?? 0,
      attemptedCount: (json['attempted_count'] as num?)?.toInt() ?? 0,
      correctCount: (json['correct_count'] as num?)?.toInt() ?? 0,
      score: (json['score'] as num?)?.toDouble() ?? 0,
      submittedAt: json['submitted_at'] != null
          ? DateTime.tryParse(json['submitted_at'].toString()) ??
              DateTime.tryParse(json['attempted_at']?.toString() ?? '') ??
              DateTime.now()
          : DateTime.now(),
    );
  }
}

class LmsLiveTest {
  final String id;
  final String title;
  final String description;
  final DateTime testDate;
  final String status; // 'draft' | 'published' | 'closed'
  final int questionCount;
  final bool answersReleased;
  final int attemptsCount;
  final DateTime createdAt;

  const LmsLiveTest({
    required this.id,
    required this.title,
    this.description = '',
    required this.testDate,
    this.status = 'draft',
    this.questionCount = 0,
    this.answersReleased = false,
    this.attemptsCount = 0,
    required this.createdAt,
  });

  bool get isDraft => status == 'draft';
  bool get isPublished => status == 'published';
  bool get isClosed => status == 'closed';

  LmsLiveTest copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? testDate,
    String? status,
    int? questionCount,
    bool? answersReleased,
    int? attemptsCount,
    DateTime? createdAt,
  }) {
    return LmsLiveTest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      testDate: testDate ?? this.testDate,
      status: status ?? this.status,
      questionCount: questionCount ?? this.questionCount,
      answersReleased: answersReleased ?? this.answersReleased,
      attemptsCount: attemptsCount ?? this.attemptsCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory LmsLiveTest.fromJson(Map<String, dynamic> json) {
    return LmsLiveTest(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      testDate: json['test_date'] != null
          ? DateTime.tryParse(json['test_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: json['status']?.toString() ?? 'draft',
      questionCount: (json['question_count'] as num?)?.toInt() ?? 0,
      answersReleased: json['answers_released'] as bool? ?? false,
      attemptsCount: (json['attempts_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class LmsLiveTestQuestion {
  final String id;
  final String testId;
  final String questionKey;
  final String questionText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String? correctOption; // Null for active untimed student view
  final String? explanation; // Null until answers_released == true
  final int displayOrder;

  const LmsLiveTestQuestion({
    required this.id,
    required this.testId,
    this.questionKey = 'Q1',
    required this.questionText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    this.correctOption,
    this.explanation,
    this.displayOrder = 1,
  });

  LmsLiveTestQuestion copyWith({
    String? id,
    String? testId,
    String? questionKey,
    String? questionText,
    String? optionA,
    String? optionB,
    String? optionC,
    String? optionD,
    String? correctOption,
    String? explanation,
    int? displayOrder,
  }) {
    return LmsLiveTestQuestion(
      id: id ?? this.id,
      testId: testId ?? this.testId,
      questionKey: questionKey ?? this.questionKey,
      questionText: questionText ?? this.questionText,
      optionA: optionA ?? this.optionA,
      optionB: optionB ?? this.optionB,
      optionC: optionC ?? this.optionC,
      optionD: optionD ?? this.optionD,
      correctOption: correctOption ?? this.correctOption,
      explanation: explanation ?? this.explanation,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  factory LmsLiveTestQuestion.fromJson(Map<String, dynamic> json) {
    return LmsLiveTestQuestion(
      id: json['id']?.toString() ?? '',
      testId: json['test_id']?.toString() ?? '',
      questionKey: json['question_key']?.toString() ?? 'Q1',
      questionText: json['question_text']?.toString() ?? '',
      optionA: json['option_a']?.toString() ?? '',
      optionB: json['option_b']?.toString() ?? '',
      optionC: json['option_c']?.toString() ?? '',
      optionD: json['option_d']?.toString() ?? '',
      correctOption: json['correct_option']?.toString().toUpperCase(),
      explanation: json['explanation']?.toString(),
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 1,
    );
  }
}

class LmsLiveTestSubmission {
  final String id;
  final String testId;
  final String? userId;
  final String studentName;
  final String phoneNumber;
  final String location;
  final String email;
  final int totalQuestions;
  final int attemptedCount;
  final int correctCount;
  final int wrongCount;
  final double marksObtained;
  final double percentage;
  final Map<String, String> answers;
  final DateTime submittedAt;
  final int rank;

  const LmsLiveTestSubmission({
    required this.id,
    required this.testId,
    this.userId,
    required this.studentName,
    required this.phoneNumber,
    required this.location,
    required this.email,
    required this.totalQuestions,
    required this.attemptedCount,
    required this.correctCount,
    required this.wrongCount,
    required this.marksObtained,
    required this.percentage,
    required this.answers,
    required this.submittedAt,
    this.rank = 0,
  });

  LmsLiveTestSubmission copyWith({int? rank}) {
    return LmsLiveTestSubmission(
      id: id,
      testId: testId,
      userId: userId,
      studentName: studentName,
      phoneNumber: phoneNumber,
      location: location,
      email: email,
      totalQuestions: totalQuestions,
      attemptedCount: attemptedCount,
      correctCount: correctCount,
      wrongCount: wrongCount,
      marksObtained: marksObtained,
      percentage: percentage,
      answers: answers,
      submittedAt: submittedAt,
      rank: rank ?? this.rank,
    );
  }

  factory LmsLiveTestSubmission.fromJson(Map<String, dynamic> json, {int rank = 0}) {
    final parsedAnswers = <String, String>{};
    if (json['answers'] is Map) {
      (json['answers'] as Map).forEach((k, v) {
        parsedAnswers[k.toString()] = v.toString();
      });
    }
    return LmsLiveTestSubmission(
      id: json['id']?.toString() ?? '',
      testId: json['test_id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      studentName: json['student_name']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      totalQuestions: (json['total_questions'] as num?)?.toInt() ?? 0,
      attemptedCount: (json['attempted_count'] as num?)?.toInt() ?? 0,
      correctCount: (json['correct_count'] as num?)?.toInt() ?? 0,
      wrongCount: (json['wrong_count'] as num?)?.toInt() ?? 0,
      marksObtained: (json['marks_obtained'] as num?)?.toDouble() ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
      answers: parsedAnswers,
      submittedAt: json['submitted_at'] != null
          ? DateTime.tryParse(json['submitted_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      rank: rank,
    );
  }
}

class NoteFolder {
  final String id;
  final String name;
  final String? parentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NoteFolder({
    required this.id,
    required this.name,
    this.parentId,
    required this.createdAt,
    required this.updatedAt,
  });

  NoteFolder copyWith({
    String? id,
    String? name,
    String? parentId,
    bool clearParentId = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: clearParentId ? null : (parentId ?? this.parentId),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory NoteFolder.fromJson(Map<String, dynamic> json) {
    return NoteFolder(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      parentId: json['parent_id']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class PdfMaterial {
  final String id;
  final String title;
  final String description;
  final String categoryCode;
  final String storagePath;
  final String pdfUrl;
  final String fileSize;
  final int pagesCount;
  final bool isFree;
  final int downloadCount;
  final bool allowDownload;
  final bool isPreviewable;
  final String? folderId;
  final DateTime createdAt;

  const PdfMaterial({
    required this.id,
    required this.title,
    this.description = '',
    this.categoryCode = 'NOTES',
    this.storagePath = '',
    this.pdfUrl = '',
    this.fileSize = '0 KB',
    this.pagesCount = 1,
    this.isFree = true,
    this.downloadCount = 0,
    this.allowDownload = false,
    this.isPreviewable = true,
    this.folderId,
    required this.createdAt,
  });

  PdfMaterial copyWith({
    String? id,
    String? title,
    String? description,
    String? categoryCode,
    String? storagePath,
    String? pdfUrl,
    String? fileSize,
    int? pagesCount,
    bool? isFree,
    int? downloadCount,
    bool? allowDownload,
    bool? isPreviewable,
    String? folderId,
    bool clearFolderId = false,
    DateTime? createdAt,
  }) {
    return PdfMaterial(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryCode: categoryCode ?? this.categoryCode,
      storagePath: storagePath ?? this.storagePath,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      fileSize: fileSize ?? this.fileSize,
      pagesCount: pagesCount ?? this.pagesCount,
      isFree: isFree ?? this.isFree,
      downloadCount: downloadCount ?? this.downloadCount,
      allowDownload: allowDownload ?? this.allowDownload,
      isPreviewable: isPreviewable ?? this.isPreviewable,
      folderId: clearFolderId ? null : (folderId ?? this.folderId),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory PdfMaterial.fromJson(Map<String, dynamic> json) {
    return PdfMaterial(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      categoryCode: json['category_code']?.toString() ?? 'NOTES',
      storagePath: json['storage_path']?.toString() ?? '',
      pdfUrl: json['pdf_url']?.toString() ?? '',
      fileSize: json['file_size']?.toString() ?? '0 KB',
      pagesCount: (json['pages_count'] as num?)?.toInt() ?? 1,
      isFree: json['is_free'] as bool? ?? true,
      downloadCount: (json['download_count'] as num?)?.toInt() ?? 0,
      allowDownload: json['allow_download'] as bool? ?? false,
      isPreviewable: json['is_previewable'] as bool? ?? true,
      folderId: json['folder_id']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class LmsStudentSummary {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final DateTime createdAt;
  final List<McqAttemptRecord> mcqAttempts;
  final List<LmsLiveTestSubmission> liveTestSubmissions;
  final int bookmarkCount;

  const LmsStudentSummary({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.role = 'customer',
    required this.createdAt,
    this.mcqAttempts = const [],
    this.liveTestSubmissions = const [],
    this.bookmarkCount = 0,
  });

  factory LmsStudentSummary.fromJson(
    Map<String, dynamic> json, {
    List<McqAttemptRecord> mcqAttempts = const [],
    List<LmsLiveTestSubmission> liveTestSubmissions = const [],
    int bookmarkCount = 0,
  }) {
    return LmsStudentSummary(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Student',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? 'customer',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      mcqAttempts: mcqAttempts,
      liveTestSubmissions: liveTestSubmissions,
      bookmarkCount: bookmarkCount,
    );
  }
}
