import 'package:flutter/material.dart';
import '../models/exam.dart';
import '../models/chapter.dart';
import '../models/question.dart';
import '../models/live_test.dart';
import '../models/video_lesson.dart';
import '../models/study_note.dart';
import '../models/admin_audit_log.dart';
import '../models/student_record.dart';
import '../services/admin_service.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _service = AdminService();

  AdminStats? _stats;
  List<Question> _questions = [];
  List<Exam> _exams = [];
  List<Chapter> _chapters = [];
  List<StudentRecord> _students = [];
  List<LiveTest> _liveTests = [];
  List<VideoLesson> _videos = [];
  List<StudyNote> _notes = [];
  List<AdminAuditLog> _auditLogs = [];

  // Question Filters
  String _mcqSearchQuery = '';
  String? _mcqExamFilter;
  String? _mcqChapterFilter;
  String _mcqLanguageFilter = 'all';
  String _mcqDifficultyFilter = 'all';
  String _mcqStatusFilter = 'all'; // 'all', 'published', 'draft'

  // Student Filters
  String _studentSearchQuery = '';
  String _studentCircleFilter = 'All Circles';
  String _studentStatusFilter = 'All Status';

  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  AdminStats? get stats => _stats;
  List<Question> get questions => _questions;
  List<Exam> get exams => _exams;
  List<Chapter> get chapters => _chapters;
  List<StudentRecord> get students => _students;
  List<LiveTest> get liveTests => _liveTests;
  List<VideoLesson> get videos => _videos;
  List<StudyNote> get notes => _notes;
  List<AdminAuditLog> get auditLogs => _auditLogs;

  String get mcqSearchQuery => _mcqSearchQuery;
  String? get mcqExamFilter => _mcqExamFilter;
  String? get mcqChapterFilter => _mcqChapterFilter;
  String get mcqLanguageFilter => _mcqLanguageFilter;
  String get mcqDifficultyFilter => _mcqDifficultyFilter;
  String get mcqStatusFilter => _mcqStatusFilter;

  String get studentSearchQuery => _studentSearchQuery;
  String get studentCircleFilter => _studentCircleFilter;
  String get studentStatusFilter => _studentStatusFilter;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Initial dashboard load
  Future<void> loadDashboardOverview() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _stats = await _service.getAdminStats();
      _exams = await _service.getExams();
      _chapters = await _service.getChapters();
      _auditLogs = await _service.getAuditLogs();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- MCQ METHODS ---
  Future<void> loadQuestions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      bool? pub;
      if (_mcqStatusFilter == 'published') pub = true;
      if (_mcqStatusFilter == 'draft') pub = false;

      _questions = await _service.getQuestions(
        examId: _mcqExamFilter,
        chapterId: _mcqChapterFilter,
        languageCode: _mcqLanguageFilter,
        difficulty: _mcqDifficultyFilter,
        isPublished: pub,
        searchQuery: _mcqSearchQuery,
      );
      if (_exams.isEmpty) _exams = await _service.getExams();
      if (_chapters.isEmpty) _chapters = await _service.getChapters();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setMcqSearch(String query) {
    _mcqSearchQuery = query;
    loadQuestions();
  }

  void setMcqExamFilter(String? examId) {
    _mcqExamFilter = examId;
    _mcqChapterFilter = null;
    loadQuestions();
  }

  void setMcqChapterFilter(String? chapterId) {
    _mcqChapterFilter = chapterId;
    loadQuestions();
  }

  void setMcqLanguageFilter(String lang) {
    _mcqLanguageFilter = lang;
    loadQuestions();
  }

  void setMcqDifficultyFilter(String diff) {
    _mcqDifficultyFilter = diff;
    loadQuestions();
  }

  void setMcqStatusFilter(String status) {
    _mcqStatusFilter = status;
    loadQuestions();
  }

  Future<void> saveQuestion(Question question, {required String adminEmail}) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.saveQuestion(question, adminEmail: adminEmail);
      await loadQuestions();
      _stats = await _service.getAdminStats();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteQuestion(String questionId, {required String adminEmail}) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.deleteQuestion(questionId, adminEmail: adminEmail);
      await loadQuestions();
      _stats = await _service.getAdminStats();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Question> duplicateQuestion(String questionId, {required String adminEmail}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final q = await _service.duplicateQuestion(questionId, adminEmail: adminEmail);
      await loadQuestions();
      _stats = await _service.getAdminStats();
      return q;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleQuestionPublish(Question question, {required String adminEmail}) async {
    final updated = question.copyWith(isPublished: !question.isPublished);
    await saveQuestion(updated, adminEmail: adminEmail);
  }

  ImportValidationResult validateCsv(String text) => _service.validateCsvContent(text);
  ImportValidationResult validateJson(String text) => _service.validateJsonContent(text);

  Future<int> batchImportQuestions(List<Question> list, {required String adminEmail}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final count = await _service.batchImportQuestions(list, adminEmail: adminEmail);
      await loadQuestions();
      _stats = await _service.getAdminStats();
      return count;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String exportQuestionsCsv() => _service.exportQuestionsToCsv(_questions);
  String exportQuestionsJson() => _service.exportQuestionsToJson(_questions);

  // --- EXAM & CHAPTER METHODS ---
  Future<void> loadExamsAndChapters() async {
    _isLoading = true;
    notifyListeners();
    try {
      _exams = await _service.getExams();
      _chapters = await _service.getChapters();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveExam(Exam exam, {required String adminEmail}) async {
    await _service.saveExam(exam, adminEmail: adminEmail);
    await loadExamsAndChapters();
    _stats = await _service.getAdminStats();
  }

  Future<void> deleteExam(String examId, {required String adminEmail}) async {
    await _service.deleteExam(examId, adminEmail: adminEmail);
    await loadExamsAndChapters();
    _stats = await _service.getAdminStats();
  }

  Future<void> saveChapter(Chapter chapter, {required String adminEmail}) async {
    await _service.saveChapter(chapter, adminEmail: adminEmail);
    await loadExamsAndChapters();
    _stats = await _service.getAdminStats();
  }

  Future<void> deleteChapter(String chapterId, {required String adminEmail}) async {
    await _service.deleteChapter(chapterId, adminEmail: adminEmail);
    await loadExamsAndChapters();
    _stats = await _service.getAdminStats();
  }

  // --- STUDENT MANAGEMENT ---
  Future<void> loadStudents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _students = await _service.getStudents(
        searchQuery: _studentSearchQuery,
        circle: _studentCircleFilter,
        status: _studentStatusFilter,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setStudentSearch(String query) {
    _studentSearchQuery = query;
    loadStudents();
  }

  void setStudentCircle(String circle) {
    _studentCircleFilter = circle;
    loadStudents();
  }

  void setStudentStatus(String status) {
    _studentStatusFilter = status;
    loadStudents();
  }

  Future<void> toggleStudentStatus(String studentId, {required String adminEmail}) async {
    await _service.toggleStudentStatus(studentId, adminEmail: adminEmail);
    await loadStudents();
  }

  Future<void> updateStudentProfile(
    String studentId, {
    String? fullName,
    String? postalCircle,
    String? targetExam,
    String? status,
    required String adminEmail,
  }) async {
    await _service.updateStudentProfile(
      studentId,
      fullName: fullName,
      postalCircle: postalCircle,
      targetExam: targetExam,
      status: status,
      adminEmail: adminEmail,
    );
    await loadStudents();
  }

  String exportStudentsCsv() => _service.exportStudentsCsv();

  // --- CONTENT: VIDEOS & NOTES ---
  Future<void> loadVideos({String? examId}) async {
    _videos = await _service.getVideos(examId: examId);
    notifyListeners();
  }

  Future<void> saveVideo(VideoLesson video, {required String adminEmail}) async {
    await _service.saveVideo(video, adminEmail: adminEmail);
    await loadVideos();
  }

  Future<void> deleteVideo(String id, {required String adminEmail}) async {
    await _service.deleteVideo(id, adminEmail: adminEmail);
    await loadVideos();
  }

  Future<void> loadNotes({String? examId}) async {
    _notes = await _service.getNotes(examId: examId);
    notifyListeners();
  }

  Future<void> saveNote(StudyNote note, {required String adminEmail}) async {
    await _service.saveNote(note, adminEmail: adminEmail);
    await loadNotes();
  }

  Future<void> deleteNote(String id, {required String adminEmail}) async {
    await _service.deleteNote(id, adminEmail: adminEmail);
    await loadNotes();
  }

  // --- LIVE TESTS ---
  Future<void> loadLiveTests() async {
    _liveTests = await _service.getLiveTests();
    notifyListeners();
  }

  Future<void> saveLiveTest(LiveTest test, {required String adminEmail}) async {
    await _service.saveLiveTest(test, adminEmail: adminEmail);
    await loadLiveTests();
    _stats = await _service.getAdminStats();
  }

  Future<void> deleteLiveTest(String id, {required String adminEmail}) async {
    await _service.deleteLiveTest(id, adminEmail: adminEmail);
    await loadLiveTests();
    _stats = await _service.getAdminStats();
  }

  Future<List<LiveTestSubmission>> getTestSubmissions(String testId) => _service.getTestSubmissions(testId);
  String exportTestSubmissionsCsv(String testId) => _service.exportTestSubmissionsCsv(testId);

  // --- AUDIT LOGS ---
  Future<void> loadAuditLogs() async {
    _auditLogs = await _service.getAuditLogs();
    notifyListeners();
  }
}
