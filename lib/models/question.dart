class Question {
  final String id;
  final String chapterId;
  final String examId;
  final String languageCode; // 'en', 'te', 'hi'
  final String questionText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String? correctOption; // 'A', 'B', 'C', 'D' — NULL in active live tests!
  final String? explanation;
  final String? postalRuleRef;
  final int questionNumber;
  final String difficulty; // 'Easy', 'Medium', 'Hard'
  final bool isPublished;

  const Question({
    required this.id,
    required this.chapterId,
    required this.examId,
    required this.languageCode,
    required this.questionText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    this.correctOption,
    this.explanation,
    this.postalRuleRef,
    this.questionNumber = 1,
    this.difficulty = 'Medium',
    this.isPublished = true,
  });

  bool get hasAnswerKey => correctOption != null && correctOption!.isNotEmpty;
  String? get citation => postalRuleRef;

  Question copyWith({
    String? id,
    String? chapterId,
    String? examId,
    String? languageCode,
    String? questionText,
    String? optionA,
    String? optionB,
    String? optionC,
    String? optionD,
    String? correctOption,
    String? explanation,
    String? postalRuleRef,
    int? questionNumber,
    String? difficulty,
    bool? isPublished,
  }) {
    return Question(
      id: id ?? this.id,
      chapterId: chapterId ?? this.chapterId,
      examId: examId ?? this.examId,
      languageCode: languageCode ?? this.languageCode,
      questionText: questionText ?? this.questionText,
      optionA: optionA ?? this.optionA,
      optionB: optionB ?? this.optionB,
      optionC: optionC ?? this.optionC,
      optionD: optionD ?? this.optionD,
      correctOption: correctOption ?? this.correctOption,
      explanation: explanation ?? this.explanation,
      postalRuleRef: postalRuleRef ?? this.postalRuleRef,
      questionNumber: questionNumber ?? this.questionNumber,
      difficulty: difficulty ?? this.difficulty,
      isPublished: isPublished ?? this.isPublished,
    );
  }

  String getOptionText(String optionKey) {
    switch (optionKey.toUpperCase()) {
      case 'A':
        return optionA;
      case 'B':
        return optionB;
      case 'C':
        return optionC;
      case 'D':
        return optionD;
      default:
        return '';
    }
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String? ?? '',
      chapterId: json['chapter_id'] as String? ?? '',
      examId: json['exam_id'] as String? ?? '',
      languageCode: json['language_code'] as String? ?? 'en',
      questionText: json['question_text'] as String? ?? '',
      optionA: json['option_a'] as String? ?? '',
      optionB: json['option_b'] as String? ?? '',
      optionC: json['option_c'] as String? ?? '',
      optionD: json['option_d'] as String? ?? '',
      correctOption: json['correct_option'] as String?,
      explanation: json['explanation'] as String?,
      postalRuleRef: json['postal_rule_ref'] as String?,
      questionNumber: json['question_number'] as int? ?? 1,
      difficulty: json['difficulty'] as String? ?? 'Medium',
      isPublished: json['is_published'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson({bool includeAnswer = true}) {
    final Map<String, dynamic> map = <String, dynamic>{
      'id': id,
      'chapter_id': chapterId,
      'exam_id': examId,
      'language_code': languageCode,
      'question_text': questionText,
      'option_a': optionA,
      'option_b': optionB,
      'option_c': optionC,
      'option_d': optionD,
      'question_number': questionNumber,
      'difficulty': difficulty,
      'is_published': isPublished,
    };
    if (includeAnswer) {
      map['correct_option'] = correctOption;
      map['explanation'] = explanation;
      map['postal_rule_ref'] = postalRuleRef;
    }
    return map;
  }
}
