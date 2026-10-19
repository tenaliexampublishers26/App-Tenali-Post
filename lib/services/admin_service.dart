import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/exam.dart';
import '../models/chapter.dart';
import '../models/question.dart';
import '../models/live_test.dart';
import '../models/video_lesson.dart';
import '../models/study_note.dart';
import '../models/admin_audit_log.dart';
import '../models/student_record.dart';
import 'mock_data.dart';
import 'supabase_service.dart';

class RowValidationError {
  final int rowIndex;
  final String field;
  final String message;
  final Map<String, String> rowData;

  const RowValidationError({
    required this.rowIndex,
    required this.field,
    required this.message,
    required this.rowData,
  });

  @override
  String toString() => 'Row $rowIndex: $message';
}

class ImportValidationResult {
  final List<Question> validQuestions;
  final List<RowValidationError> errors;
  final int totalRows;
  final int duplicateCount;

  const ImportValidationResult({
    required this.validQuestions,
    required this.errors,
    required this.totalRows,
    required this.duplicateCount,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get isValid => errors.isEmpty && validQuestions.isNotEmpty;
  int get validCount => validQuestions.length;
  List<Question> get parsedQuestions => validQuestions;
  List<String> get errorMessages => errors.map((e) => e.message).toList();
}

class AdminStats {
  final int totalExams;
  final int totalChapters;
  final int totalQuestions;
  final int activeLiveTests;
  final int totalStudents;
  final int totalSubmissions;
  final double translationCoveragePercent;

  const AdminStats({
    required this.totalExams,
    required this.totalChapters,
    required this.totalQuestions,
    required this.activeLiveTests,
    required this.totalStudents,
    required this.totalSubmissions,
    required this.translationCoveragePercent,
  });
}

class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal() {
    _initLocalStores();
  }

  static bool isAuthorizedAdmin(String? email) {
    if (email == null) return false;
    return email.trim().toLowerCase() == 'tenaliexamspublishers26@gmail.com';
  }

  final SupabaseService _supabase = SupabaseService();

  // In-memory persistent caches (synchronized with MockData & Supabase fallback)
  final List<Exam> _exams = [];
  final List<Chapter> _chapters = [];
  final List<Question> _questions = [];
  final List<LiveTest> _liveTests = [];
  final List<VideoLesson> _videos = [];
  final List<StudyNote> _notes = [];
  final List<StudentRecord> _students = [];
  final List<AdminAuditLog> _auditLogs = [];
  final List<LiveTestSubmission> _submissions = [];

  void _initLocalStores() {
    _exams.addAll(MockData.exams);
    _chapters.addAll(MockData.chapters);
    _questions.addAll(MockData.sampleQuestions);
    _liveTests.addAll(MockData.liveTests);
    _videos.addAll(MockData.videoLessons);
    _notes.addAll(MockData.studyNotes);

    _students.addAll([
      StudentRecord(
        id: 'stu-01',
        email: 'srikanth.verma@postal.gov.in',
        fullName: 'Srikanth Verma',
        phoneNumber: '+91 98765 43210',
        postalCircle: 'Andhra Pradesh Circle',
        targetExam: 'MTS Examination',
        status: 'Active',
        registeredAt: DateTime.now().subtract(const Duration(days: 45)),
        lastActiveAt: DateTime.now().subtract(const Duration(hours: 2)),
        totalTestsAttempted: 0,
        averagePercentage: 0.0,
        testAttempts: const [],
      ),
      StudentRecord(
        id: 'stu-02',
        email: 'priya.sharma@postal.gov.in',
        fullName: 'Priya Sharma',
        phoneNumber: '+91 98111 22334',
        postalCircle: 'Telangana Circle',
        targetExam: 'Postman & Mail Guard',
        status: 'Active',
        registeredAt: DateTime.now().subtract(const Duration(days: 30)),
        lastActiveAt: DateTime.now().subtract(const Duration(hours: 5)),
        totalTestsAttempted: 3,
        averagePercentage: 86.0,
      ),
      StudentRecord(
        id: 'stu-03',
        email: 'rajesh.kumar@postal.gov.in',
        fullName: 'Rajesh Kumar',
        phoneNumber: '+91 97222 33445',
        postalCircle: 'Karnataka Circle',
        targetExam: 'PA / SA Examination',
        status: 'Active',
        registeredAt: DateTime.now().subtract(const Duration(days: 60)),
        lastActiveAt: DateTime.now().subtract(const Duration(days: 3)),
        totalTestsAttempted: 5,
        averagePercentage: 79.4,
      ),
      StudentRecord(
        id: 'stu-04',
        email: 'ananya.reddy@postal.gov.in',
        fullName: 'Ananya Reddy',
        phoneNumber: '+91 96333 44556',
        postalCircle: 'Andhra Pradesh Circle',
        targetExam: 'LGO Examination',
        status: 'Suspended',
        registeredAt: DateTime.now().subtract(const Duration(days: 90)),
        lastActiveAt: DateTime.now().subtract(const Duration(days: 14)),
        totalTestsAttempted: 1,
        averagePercentage: 45.0,
      ),
      StudentRecord(
        id: 'stu-05',
        email: 'manoj.patel@postal.gov.in',
        fullName: 'Manoj Patel',
        phoneNumber: '+91 95444 55667',
        postalCircle: 'Maharashtra Circle',
        targetExam: 'MTS Examination',
        status: 'Active',
        registeredAt: DateTime.now().subtract(const Duration(days: 12)),
        lastActiveAt: DateTime.now().subtract(const Duration(minutes: 30)),
        totalTestsAttempted: 2,
        averagePercentage: 88.0,
      ),
    ]);

    // Initial audit log
    _auditLogs.add(
      AdminAuditLog(
        id: 'log-01',
        adminEmail: 'tenaliexamspublishers26@gmail.com',
        actionType: 'SYSTEM_INIT',
        targetEntity: 'SYSTEM',
        targetId: 'tenali-post-admin',
        description: 'Tenali Post Production Admin Management Console initialized.',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
    );
  }

  // --- OVERVIEW STATS ---
  Future<AdminStats> getAdminStats() async {
    int totalQ = _questions.length;
    int teCount = _questions.where((q) => q.languageCode == 'te').length;
    int hiCount = _questions.where((q) => q.languageCode == 'hi').length;
    int enCount = _questions.where((q) => q.languageCode == 'en').length;

    double coverage = enCount > 0 ? ((teCount + hiCount) / (enCount * 2)) * 100 : 0.0;
    if (coverage > 100) coverage = 100;

    return AdminStats(
      totalExams: _exams.length,
      totalChapters: _chapters.length,
      totalQuestions: totalQ,
      activeLiveTests: _liveTests.where((t) => t.isOngoing).length,
      totalStudents: _students.length,
      totalSubmissions: _submissions.length,
      translationCoveragePercent: double.parse(coverage.toStringAsFixed(1)),
    );
  }

  // --- MCQ MANAGEMENT ---
  Future<List<Question>> getQuestions({
    String? examId,
    String? chapterId,
    String? languageCode,
    String? difficulty,
    bool? isPublished,
    String? searchQuery,
  }) async {
    if (_supabase.isInitialized && _supabase.client != null) {
      try {
        var query = _supabase.client!.from('questions').select();
        if (examId != null && examId.isNotEmpty) query = query.eq('exam_id', examId);
        if (chapterId != null && chapterId.isNotEmpty) query = query.eq('chapter_id', chapterId);
        if (languageCode != null && languageCode.isNotEmpty && languageCode != 'all') {
          query = query.eq('language_code', languageCode);
        }
        if (difficulty != null && difficulty.isNotEmpty && difficulty != 'all') {
          query = query.eq('difficulty', difficulty);
        }
        if (isPublished != null) query = query.eq('is_published', isPublished);

        final res = await query.order('created_at', ascending: false);
        return (res as List).map((e) => Question.fromJson(e)).toList();
      } catch (e) {
        if (kDebugMode) print('[AdminService] Supabase getQuestions error: $e');
      }
    }

    // Local / In-memory filter
    return _questions.where((q) {
      if (examId != null && examId.isNotEmpty && q.examId != examId) return false;
      if (chapterId != null && chapterId.isNotEmpty && q.chapterId != chapterId) return false;
      if (languageCode != null && languageCode.isNotEmpty && languageCode != 'all' && q.languageCode != languageCode) return false;
      if (difficulty != null && difficulty.isNotEmpty && difficulty != 'all' && q.difficulty.toLowerCase() != difficulty.toLowerCase()) return false;
      if (isPublished != null && q.isPublished != isPublished) return false;
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final query = searchQuery.toLowerCase().trim();
        final matchText = q.questionText.toLowerCase().contains(query);
        final matchRule = (q.postalRuleRef ?? '').toLowerCase().contains(query);
        final matchOpt = q.optionA.toLowerCase().contains(query) || q.optionB.toLowerCase().contains(query);
        if (!matchText && !matchRule && !matchOpt) return false;
      }
      return true;
    }).toList();
  }

  Future<List<Question>> fetchQuestions({
    String? examId,
    String? chapterId,
    String? languageCode,
    String? difficulty,
    bool? isPublished,
    String? searchQuery,
  }) => getQuestions(
    examId: examId,
    chapterId: chapterId,
    languageCode: languageCode,
    difficulty: difficulty,
    isPublished: isPublished,
    searchQuery: searchQuery,
  );

  Future<void> saveQuestion(Question question, {String adminEmail = 'tenaliexamspublishers26@gmail.com'}) async {
    final bool isUpdate = _questions.any((q) => q.id == question.id);

    if (_supabase.isInitialized && _supabase.client != null) {
      try {
        if (isUpdate) {
          await _supabase.client!.from('questions').update(question.toJson()).eq('id', question.id);
        } else {
          await _supabase.client!.from('questions').insert(question.toJson());
        }
      } catch (e) {
        if (kDebugMode) print('[AdminService] Supabase saveQuestion error: $e');
      }
    }

    if (isUpdate) {
      final index = _questions.indexWhere((q) => q.id == question.id);
      if (index != -1) _questions[index] = question;

      final mockIndex = MockData.sampleQuestions.indexWhere((q) => q.id == question.id);
      if (mockIndex != -1) MockData.sampleQuestions[mockIndex] = question;
    } else {
      _questions.insert(0, question);
      MockData.sampleQuestions.insert(0, question);
    }

    await recordAuditLog(
      adminEmail: adminEmail,
      actionType: isUpdate ? 'UPDATE' : 'CREATE',
      targetEntity: 'QUESTION',
      targetId: question.id,
      description: '${isUpdate ? 'Updated' : 'Created'} question: "${question.questionText.substring(0, question.questionText.length > 40 ? 40 : question.questionText.length)}..." (${question.languageCode.toUpperCase()})',
    );
  }

  Future<void> deleteQuestion(String questionId, {String adminEmail = 'tenaliexamspublishers26@gmail.com'}) async {
    if (_supabase.isInitialized && _supabase.client != null) {
      try {
        await _supabase.client!.from('questions').delete().eq('id', questionId);
      } catch (e) {
        if (kDebugMode) print('[AdminService] Supabase deleteQuestion error: $e');
      }
    }

    _questions.removeWhere((q) => q.id == questionId);
    MockData.sampleQuestions.removeWhere((q) => q.id == questionId);

    await recordAuditLog(
      adminEmail: adminEmail,
      actionType: 'DELETE',
      targetEntity: 'QUESTION',
      targetId: questionId,
      description: 'Deleted question ID: $questionId',
    );
  }

  Future<Question> duplicateQuestion(String questionId, {String adminEmail = 'tenaliexamspublishers26@gmail.com'}) async {
    final original = _questions.firstWhere(
      (q) => q.id == questionId,
      orElse: () => throw Exception('Question not found'),
    );

    final newId = '${original.id}_copy_${DateTime.now().millisecondsSinceEpoch}';
    final duplicated = original.copyWith(
      id: newId,
      questionText: '${original.questionText} (Copy)',
      questionNumber: original.questionNumber + 1,
      isPublished: false, // Default to draft for duplicated questions
    );

    await saveQuestion(duplicated, adminEmail: adminEmail);
    return duplicated;
  }

  Future<void> toggleQuestionStatus(String questionId, bool isPublished, {String adminEmail = 'tenaliexamspublishers26@gmail.com'}) async {
    final idx = _questions.indexWhere((q) => q.id == questionId);
    if (idx != -1) {
      final updated = _questions[idx].copyWith(isPublished: isPublished);
      await saveQuestion(updated, adminEmail: adminEmail);
    }
  }

  // --- CSV / JSON IMPORT & EXPORT ---
  ImportValidationResult validateCsvContent(String csvText) {
    final lines = const LineSplitter().convert(csvText.trim());
    if (lines.isEmpty) {
      return const ImportValidationResult(validQuestions: [], errors: [], totalRows: 0, duplicateCount: 0);
    }

    final headers = _parseCsvRow(lines.first).map((h) => h.toLowerCase().trim()).toList();

    final List<RowValidationError> errors = [];
    final List<Question> validQuestions = [];
    int duplicateCount = 0;
    final Set<String> seenFingerprints = {};
    final Set<String> seenIds = {};

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final values = _parseCsvRow(line);
      final Map<String, String> rowMap = {};
      for (int h = 0; h < headers.length; h++) {
        if (h < values.length) {
          rowMap[headers[h]] = values[h].trim();
        } else {
          rowMap[headers[h]] = '';
        }
      }

      final qId = rowMap['id'] ?? rowMap['question_id'] ?? '';
      if (qId.isNotEmpty) {
        if (seenIds.contains(qId)) {
          errors.add(RowValidationError(
            rowIndex: i + 1,
            field: 'id',
            message: 'Duplicate question ID "$qId" found in import file.',
            rowData: rowMap,
          ));
          continue;
        }
        seenIds.add(qId);
      }

      // 1. Required fields validation
      final examCode = (rowMap['exam_code'] ?? rowMap['exam_id'] ?? 'mts').toUpperCase();
      final chapterNum = int.tryParse(rowMap['chapter_number'] ?? rowMap['chapter_id'] ?? '1') ?? 1;
      final langCode = (rowMap['lang_code'] ?? rowMap['language_code'] ?? 'en').toLowerCase();
      final questionText = rowMap['question_text'] ?? '';
      final optA = rowMap['option_a'] ?? '';
      final optB = rowMap['option_b'] ?? '';
      final optC = rowMap['option_c'] ?? '';
      final optD = rowMap['option_d'] ?? '';
      final correctOpt = (rowMap['correct_option'] ?? rowMap['correct_answer'] ?? '').toUpperCase();
      final explanation = rowMap['explanation'] ?? '';
      final postalRuleRef = rowMap['postal_rule_ref'] ?? rowMap['citation'] ?? '';
      final difficulty = rowMap['difficulty'] ?? 'Medium';

      if (questionText.isEmpty) {
        errors.add(RowValidationError(rowIndex: i + 1, field: 'question_text', message: 'Row is missing question text.', rowData: rowMap));
        continue;
      }

      if (optA.isEmpty || optB.isEmpty || optC.isEmpty || optD.isEmpty) {
        errors.add(RowValidationError(rowIndex: i + 1, field: 'options', message: 'All four options (A, B, C, D) are required.', rowData: rowMap));
        continue;
      }

      if (!['A', 'B', 'C', 'D'].contains(correctOpt)) {
        errors.add(RowValidationError(rowIndex: i + 1, field: 'correct_option', message: "Correct option must be 'A', 'B', 'C', or 'D' (found: '$correctOpt').", rowData: rowMap));
        continue;
      }

      if (!['en', 'te', 'hi'].contains(langCode)) {
        errors.add(RowValidationError(rowIndex: i + 1, field: 'lang_code', message: 'Language code must be en, te, or hi (found: "$langCode").', rowData: rowMap));
        continue;
      }

      // Exam code check
      final matchedExam = _exams.firstWhere(
        (e) => e.code.toUpperCase() == examCode || e.id.toLowerCase() == examCode.toLowerCase(),
        orElse: () => _exams.first,
      );

      // Chapter check
      final matchedChapter = _chapters.firstWhere(
        (c) => c.examId == matchedExam.id && c.chapterNumber == chapterNum,
        orElse: () => _chapters.firstWhere(
          (c) => c.examId == matchedExam.id || c.id.toLowerCase() == (rowMap['chapter_id'] ?? '').toLowerCase(),
          orElse: () => _chapters.first,
        ),
      );

      // Duplicate detection via fingerprint
      final fingerprint = '$examCode-$chapterNum-$langCode-${questionText.toLowerCase().trim()}';
      if (seenFingerprints.contains(fingerprint)) {
        duplicateCount++;
        continue;
      }
      seenFingerprints.add(fingerprint);

      validQuestions.add(
        Question(
          id: qId.isNotEmpty ? qId : 'q-imp-${DateTime.now().millisecondsSinceEpoch}-$i',
          chapterId: matchedChapter.id,
          examId: matchedExam.id,
          languageCode: langCode,
          questionText: questionText,
          optionA: optA,
          optionB: optB,
          optionC: optC,
          optionD: optD,
          correctOption: correctOpt,
          explanation: explanation.isNotEmpty ? explanation : null,
          postalRuleRef: postalRuleRef.isNotEmpty ? postalRuleRef : null,
          questionNumber: validQuestions.length + 1,
          difficulty: difficulty,
          isPublished: true,
        ),
      );
    }

    return ImportValidationResult(
      validQuestions: validQuestions,
      errors: errors,
      totalRows: lines.length - 1,
      duplicateCount: duplicateCount,
    );
  }

  ImportValidationResult validateJsonContent(String jsonText) {
    try {
      final dynamic decoded = jsonDecode(jsonText);
      if (decoded is! List && (decoded is! Map || !decoded.containsKey('questions'))) {
        return const ImportValidationResult(
          validQuestions: [],
          errors: [
            RowValidationError(
              rowIndex: 0,
              field: 'json_root',
              message: 'JSON root must be an array of questions or contain a "questions" key.',
              rowData: {},
            ),
          ],
          totalRows: 0,
          duplicateCount: 0,
        );
      }
      final List<dynamic> list = decoded is List ? decoded : (decoded['questions'] as List<dynamic>? ?? []);
      final List<RowValidationError> errors = [];
      final List<Question> validQuestions = [];
      int duplicateCount = 0;

      for (int i = 0; i < list.length; i++) {
        final item = list[i] as Map<String, dynamic>;
        final qText = item['question_text']?.toString() ?? '';
        final optA = item['option_a']?.toString() ?? '';
        final optB = item['option_b']?.toString() ?? '';
        final optC = item['option_c']?.toString() ?? '';
        final optD = item['option_d']?.toString() ?? '';
        final correct = (item['correct_option'] ?? item['correct_answer'])?.toString().toUpperCase() ?? '';

        if (qText.isEmpty || optA.isEmpty || optB.isEmpty || optC.isEmpty || optD.isEmpty) {
          errors.add(RowValidationError(rowIndex: i + 1, field: 'fields', message: 'Missing question text or options.', rowData: item.map((k, v) => MapEntry(k, v.toString()))));
          continue;
        }

        if (!['A', 'B', 'C', 'D'].contains(correct)) {
          errors.add(RowValidationError(rowIndex: i + 1, field: 'correct_option', message: "Correct option must be 'A', 'B', 'C', or 'D'.", rowData: item.map((k, v) => MapEntry(k, v.toString()))));
          continue;
        }

        validQuestions.add(Question(
          id: item['id']?.toString() ?? 'q-json-${DateTime.now().millisecondsSinceEpoch}-$i',
          chapterId: item['chapter_id']?.toString() ?? _chapters.first.id,
          examId: item['exam_id']?.toString() ?? _exams.first.id,
          languageCode: item['language_code']?.toString() ?? 'en',
          questionText: qText,
          optionA: optA,
          optionB: optB,
          optionC: optC,
          optionD: optD,
          correctOption: correct,
          explanation: item['explanation']?.toString(),
          postalRuleRef: (item['postal_rule_ref'] ?? item['citation'])?.toString(),
          questionNumber: validQuestions.length + 1,
          difficulty: item['difficulty']?.toString() ?? 'Medium',
          isPublished: true,
        ));
      }

      return ImportValidationResult(validQuestions: validQuestions, errors: errors, totalRows: list.length, duplicateCount: duplicateCount);
    } catch (e) {
      return ImportValidationResult(
        validQuestions: [],
        errors: [RowValidationError(rowIndex: 0, field: 'json_syntax', message: 'Malformed JSON: $e', rowData: const {})],
        totalRows: 0,
        duplicateCount: 0,
      );
    }
  }

  Future<int> batchImportQuestions(List<Question> questions, {required String adminEmail}) async {
    int imported = 0;
    for (final q in questions) {
      await saveQuestion(q, adminEmail: adminEmail);
      imported++;
    }

    await recordAuditLog(
      adminEmail: adminEmail,
      actionType: 'IMPORT',
      targetEntity: 'QUESTION',
      targetId: 'batch-${DateTime.now().millisecondsSinceEpoch}',
      description: 'Bulk imported $imported questions via In-App Importer.',
    );
    return imported;
  }

  String exportQuestionsToCsv(List<Question> list) {
    final sb = StringBuffer();
    sb.writeln('exam_code,chapter_number,lang_code,question_text,option_a,option_b,option_c,option_d,correct_option,explanation,postal_rule_ref');

    for (final q in list) {
      final exam = _exams.firstWhere((e) => e.id == q.examId, orElse: () => _exams.first);
      final chapter = _chapters.firstWhere((c) => c.id == q.chapterId, orElse: () => _chapters.first);

      final row = [
        exam.code,
        chapter.chapterNumber.toString(),
        q.languageCode,
        _csvEscape(q.questionText),
        _csvEscape(q.optionA),
        _csvEscape(q.optionB),
        _csvEscape(q.optionC),
        _csvEscape(q.optionD),
        q.correctOption ?? 'A',
        _csvEscape(q.explanation ?? ''),
        _csvEscape(q.postalRuleRef ?? ''),
      ];
      sb.writeln(row.join(','));
    }
    return sb.toString();
  }

  String exportQuestionsToJson(List<Question> list) {
    return const JsonEncoder.withIndent('  ').convert(list.map((q) => q.toJson()).toList());
  }

  List<String> _parseCsvRow(String line) {
    final List<String> result = [];
    bool inQuotes = false;
    final sb = StringBuffer();

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          sb.write('"');
          i++; // skip escaped quote
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        result.add(sb.toString());
        sb.clear();
      } else {
        sb.write(char);
      }
    }
    result.add(sb.toString());
    return result;
  }

  String _csvEscape(String val) {
    if (val.contains(',') || val.contains('"') || val.contains('\n')) {
      return '"${val.replaceAll('"', '""')}"';
    }
    return val;
  }

  // --- EXAM MANAGEMENT ---
  Future<List<Exam>> getExams() async => List.unmodifiable(_exams);

  Future<void> saveExam(Exam exam, {String adminEmail = 'tenaliexamspublishers26@gmail.com'}) async {
    final idx = _exams.indexWhere((e) => e.id == exam.id);
    if (idx != -1) {
      _exams[idx] = exam;
    } else {
      _exams.add(exam);
    }
    await recordAuditLog(
      adminEmail: adminEmail,
      actionType: idx != -1 ? 'UPDATE' : 'CREATE',
      targetEntity: 'EXAM',
      targetId: exam.id,
      description: '${idx != -1 ? 'Updated' : 'Created'} Exam: ${exam.title} (${exam.code})',
    );
  }

  Future<void> deleteExam(String examId, {String adminEmail = 'tenaliexamspublishers26@gmail.com'}) async {
    // Safety check: prevent accidental deletion if questions or chapters exist
    final questionsCount = _questions.where((q) => q.examId == examId).length;
    final chaptersCount = _chapters.where((c) => c.examId == examId).length;

    if (questionsCount > 0 || chaptersCount > 0) {
      throw Exception(
        'Cannot delete Exam "$examId": It still contains $chaptersCount chapters and $questionsCount questions. Remove or reassign them first.',
      );
    }

    _exams.removeWhere((e) => e.id == examId);
    await recordAuditLog(
      adminEmail: adminEmail,
      actionType: 'DELETE',
      targetEntity: 'EXAM',
      targetId: examId,
      description: 'Deleted Exam: $examId',
    );
  }

  // --- CHAPTER MANAGEMENT ---
  Future<List<Chapter>> getChapters({String? examId}) async {
    if (examId != null && examId.isNotEmpty) {
      return _chapters.where((c) => c.examId == examId).toList();
    }
    return List.unmodifiable(_chapters);
  }

  Future<void> saveChapter(Chapter chapter, {String adminEmail = 'tenaliexamspublishers26@gmail.com'}) async {
    final idx = _chapters.indexWhere((c) => c.id == chapter.id);
    if (idx != -1) {
      _chapters[idx] = chapter;
    } else {
      _chapters.add(chapter);
    }
    await recordAuditLog(
      adminEmail: adminEmail,
      actionType: idx != -1 ? 'UPDATE' : 'CREATE',
      targetEntity: 'CHAPTER',
      targetId: chapter.id,
      description: '${idx != -1 ? 'Updated' : 'Created'} Chapter: ${chapter.title}',
    );
  }

  Future<void> deleteChapter(String chapterId, {String adminEmail = 'tenaliexamspublishers26@gmail.com'}) async {
    final qCount = _questions.where((q) => q.chapterId == chapterId).length;
    if (qCount > 0) {
      throw Exception('Cannot delete chapter "$chapterId": It has $qCount questions linked. Reassign or delete questions first.');
    }
    _chapters.removeWhere((c) => c.id == chapterId);
    await recordAuditLog(
      adminEmail: adminEmail,
      actionType: 'DELETE',
      targetEntity: 'CHAPTER',
      targetId: chapterId,
      description: 'Deleted Chapter: $chapterId',
    );
  }

  // --- VIDEO MANAGEMENT ---
  Future<List<VideoLesson>> getVideos({String? examId}) async {
    if (examId != null && examId.isNotEmpty) {
      return _videos.where((v) => v.examId == examId).toList();
    }
    return List.unmodifiable(_videos);
  }

  Future<void> saveVideo(VideoLesson video, {String adminEmail = 'tenaliexamspublishers26@gmail.com'}) async {
    final idx = _videos.indexWhere((v) => v.id == video.id);
    if (idx != -1) {
      _videos[idx] = video;
    } else {
      _videos.add(video);
    }
    await recordAuditLog(
      adminEmail: adminEmail,
      actionType: idx != -1 ? 'UPDATE' : 'CREATE',
      targetEntity: 'VIDEO',
      targetId: video.id,
      description: '${idx != -1 ? 'Updated' : 'Created'} Video: ${video.title}',
    );
  }

  Future<void> deleteVideo(String videoId, {String adminEmail = 'tenaliexamspublishers26@gmail.com'}) async {
    _videos.removeWhere((v) => v.id == videoId);
    await recordAuditLog(
      adminEmail: adminEmail,
      actionType: 'DELETE',
      targetEntity: 'VIDEO',
      targetId: videoId,
      description: 'Deleted Video ID: $videoId',
    );
  }

  // --- NOTES MANAGEMENT ---
  Future<List<StudyNote>> getNotes({String? examId}) async {
    if (examId != null && examId.isNotEmpty) {
      return _notes.where((n) => n.examId == examId).toList();
    }
    return List.unmodifiable(_notes);
  }

  Future<void> saveNote(StudyNote note, {String adminEmail = 'tenaliexamspublishers26@gmail.com'}) async {
    final idx = _notes.indexWhere((n) => n.id == note.id);
    if (idx != -1) {
      _notes[idx] = note;
    } else {
      _notes.add(note);
    }
    await recordAuditLog(
      adminEmail: adminEmail,
      actionType: idx != -1 ? 'UPDATE' : 'CREATE',
      targetEntity: 'NOTE',
      targetId: note.id,
      description: '${idx != -1 ? 'Updated' : 'Created'} Study Note: ${note.title}',
    );
  }

  Future<void> deleteNote(String noteId, {String adminEmail = 'tenaliexamspublishers26@gmail.com'}) async {
    _notes.removeWhere((n) => n.id == noteId);
    await recordAuditLog(
      adminEmail: adminEmail,
      actionType: 'DELETE',
      targetEntity: 'NOTE',
      targetId: noteId,
      description: 'Deleted Note ID: $noteId',
    );
  }

  // --- LIVE TEST MANAGEMENT ---
  Future<List<LiveTest>> getLiveTests() async => List.unmodifiable(_liveTests);

  Future<void> saveLiveTest(LiveTest test, {String adminEmail = 'tenaliexamspublishers26@gmail.com'}) async {
    final idx = _liveTests.indexWhere((t) => t.id == test.id);
    if (idx != -1) {
      _liveTests[idx] = test;
    } else {
      _liveTests.add(test);
    }
    await recordAuditLog(
      adminEmail: adminEmail,
      actionType: idx != -1 ? 'UPDATE' : 'CREATE',
      targetEntity: 'LIVE_TEST',
      targetId: test.id,
      description: '${idx != -1 ? 'Updated' : 'Created'} Live Test: ${test.title} (Published: ${test.isPublished})',
    );
  }

  Future<void> deleteLiveTest(String testId, {String adminEmail = 'tenaliexamspublishers26@gmail.com'}) async {
    _liveTests.removeWhere((t) => t.id == testId);
    await recordAuditLog(
      adminEmail: adminEmail,
      actionType: 'DELETE',
      targetEntity: 'LIVE_TEST',
      targetId: testId,
      description: 'Deleted Live Test ID: $testId',
    );
  }

  Future<List<LiveTestSubmission>> getTestSubmissions(String testId) async {
    return _submissions.where((s) => s.testId == testId).toList();
  }

  String exportTestSubmissionsCsv(String testId) {
    final subs = _submissions.where((s) => s.testId == testId).toList();
    final sb = StringBuffer();
    sb.writeln('rank,student_name,phone_number,marks_obtained,total_marks,percentage,correct,wrong,skipped,submitted_at');
    for (final s in subs) {
      sb.writeln('${s.rank},"${s.studentName}","${s.phoneNumber}",${s.marksObtained},${s.totalMarks},${s.percentage.toStringAsFixed(1)},${s.correctCount},${s.wrongCount},${s.skippedCount},"${s.submittedAt.toIso8601String()}"');
    }
    return sb.toString();
  }

  // --- STUDENT & PROFILE MANAGEMENT ---
  Future<List<StudentRecord>> getStudents({String? searchQuery, String? circle, String? status}) async {
    return _students.where((s) {
      if (circle != null && circle.isNotEmpty && circle != 'All Circles' && s.postalCircle != circle) return false;
      if (status != null && status.isNotEmpty && status != 'All Status' && s.status != status) return false;
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        final matchName = s.fullName.toLowerCase().contains(q);
        final matchEmail = s.email.toLowerCase().contains(q);
        final matchPhone = s.phoneNumber.contains(q);
        if (!matchName && !matchEmail && !matchPhone) return false;
      }
      return true;
    }).toList();
  }

  Future<List<StudentRecord>> fetchStudents({String? searchQuery, String? circle, String? status}) =>
      getStudents(searchQuery: searchQuery, circle: circle, status: status);

  Future<void> updateStudentProfile(
    String studentId, {
    String? fullName,
    String? circle,
    String? postalCircle,
    String? cadre,
    String? targetExam,
    String? status,
    String adminEmail = 'tenaliexamspublishers26@gmail.com',
  }) async {
    final idx = _students.indexWhere((s) => s.id == studentId);
    if (idx != -1) {
      final existing = _students[idx];
      _students[idx] = existing.copyWith(
        fullName: fullName,
        postalCircle: circle ?? postalCircle ?? existing.postalCircle,
        targetExam: cadre ?? targetExam ?? existing.targetExam,
        status: status,
      );

      await recordAuditLog(
        adminEmail: adminEmail,
        actionType: 'UPDATE',
        targetEntity: 'STUDENT',
        targetId: studentId,
        description: 'Updated profile for student: ${existing.fullName} (${status ?? existing.status})',
      );
    }
  }

  Future<void> updateStudentStatus(
    String studentId,
    String status, {
    String adminEmail = 'tenaliexamspublishers26@gmail.com',
  }) async {
    final idx = _students.indexWhere((s) => s.id == studentId);
    if (idx != -1) {
      final current = _students[idx];
      _students[idx] = current.copyWith(status: status);

      await recordAuditLog(
        adminEmail: adminEmail,
        actionType: status.toUpperCase(),
        targetEntity: 'STUDENT',
        targetId: studentId,
        description: 'Updated status of student ${current.fullName} to $status',
      );
    }
  }

  Future<void> toggleStudentStatus(String studentId, {String adminEmail = 'tenaliexamspublishers26@gmail.com'}) async {
    final idx = _students.indexWhere((s) => s.id == studentId);
    if (idx != -1) {
      final current = _students[idx];
      final newStatus = current.status == 'Active' ? 'Suspended' : 'Active';
      _students[idx] = current.copyWith(status: newStatus);

      await recordAuditLog(
        adminEmail: adminEmail,
        actionType: newStatus == 'Suspended' ? 'SUSPEND' : 'ACTIVATE',
        targetEntity: 'STUDENT',
        targetId: studentId,
        description: 'Changed status of student ${current.fullName} to $newStatus',
      );
    }
  }

  String exportStudentsCsv() {
    final sb = StringBuffer();
    sb.writeln('id,full_name,email,phone_number,postal_circle,target_exam,status,registered_at,total_tests,avg_percentage');
    for (final s in _students) {
      sb.writeln('"${s.id}","${s.fullName}","${s.email}","${s.phoneNumber}","${s.postalCircle}","${s.targetExam}","${s.status}","${s.registeredAt.toIso8601String()}",${s.totalTestsAttempted},${s.averagePercentage}');
    }
    return sb.toString();
  }

  // --- AUDIT LOGS ---
  Future<List<AdminAuditLog>> getAuditLogs() async {
    return List.unmodifiable(_auditLogs.reversed.toList());
  }

  Future<List<AdminAuditLog>> fetchAuditLogs() => getAuditLogs();

  Future<void> logAuditAction({
    required String actionType,
    required String targetEntity,
    required String targetId,
    required String description,
    String adminEmail = 'tenaliexamspublishers26@gmail.com',
  }) async {
    await recordAuditLog(
      adminEmail: adminEmail,
      actionType: actionType,
      targetEntity: targetEntity,
      targetId: targetId,
      description: description,
    );
  }

  Future<void> recordAuditLog({
    required String adminEmail,
    required String actionType,
    required String targetEntity,
    required String targetId,
    required String description,
  }) async {
    final entry = AdminAuditLog(
      id: 'log-${DateTime.now().millisecondsSinceEpoch}',
      adminEmail: adminEmail,
      actionType: actionType,
      targetEntity: targetEntity,
      targetId: targetId,
      description: description,
      timestamp: DateTime.now(),
    );

    if (_supabase.isInitialized && _supabase.client != null) {
      try {
        await _supabase.client!.from('admin_audit_logs').insert(entry.toJson());
      } catch (e) {
        if (kDebugMode) print('[AdminService] Supabase recordAuditLog error: $e');
      }
    }

    _auditLogs.add(entry);
  }
}
