import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/mcq_import_parser.dart';
import '../core/utils/size_formatter.dart';
import '../models/lms_models.dart';
import '../services/auth_service.dart';
import '../services/lms_admin_service.dart';
import '../services/supabase_service.dart';

class LmsAdminProvider extends ChangeNotifier {
  final LmsAdminService _service = LmsAdminService();
  RealtimeChannel? _realtimeChannel;
  Timer? _realtimeDebounce;

  LmsSettings _settings = const LmsSettings();
  List<LmsAuditLog> _auditLogs = [];

  List<McqTopic> _topics = [];
  List<McqMedium> _mediums = [];
  List<McqImportLog> _importLogs = [];

  List<LmsLiveTest> _liveTests = [];
  List<NoteFolder> _noteFolders = [];
  List<PdfMaterial> _notes = [];
  List<LmsStudentSummary> _students = [];

  bool _isLoading = false;
  String? _errorMessage;

  LmsSettings get settings => _settings;
  List<LmsAuditLog> get auditLogs => _auditLogs;
  List<McqTopic> get topics => _topics;
  List<McqMedium> get mediums => _mediums;
  List<McqImportLog> get importLogs => _importLogs;
  List<LmsLiveTest> get liveTests => _liveTests;
  List<NoteFolder> get noteFolders => _noteFolders;
  List<PdfMaterial> get notes => _notes;
  List<LmsStudentSummary> get students => _students;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalMcqQuestionsCount =>
      _topics.fold<int>(0, (sum, t) => sum + t.questionCount);
  int get activeLiveTestsCount => _liveTests.where((t) => t.isPublished).length;
  int get totalLiveTestSubmissionsCount =>
      _liveTests.fold<int>(0, (sum, t) => sum + t.attemptsCount);

  Future<void> loadOverview() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.getSettings(),
        _service.getTopics(),
        _service.getMediums(),
        _service.getLiveTests(),
        _service.getNoteFolders(),
        _service.getNotes(),
        _service.getStudentsDirectory(),
        _service.getAuditLogs(),
      ]);
      _settings = results[0] as LmsSettings;
      _topics = results[1] as List<McqTopic>;
      _mediums = results[2] as List<McqMedium>;
      _liveTests = results[3] as List<LmsLiveTest>;
      _noteFolders = results[4] as List<NoteFolder>;
      _notes = results[5] as List<PdfMaterial>;
      _students = results[6] as List<LmsStudentSummary>;
      _auditLogs = results[7] as List<LmsAuditLog>;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPublicSettings() async {
    try {
      _settings = await _service.getSettings();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggleMcqEnabled(bool enabled) async {
    await _service.toggleMcqEnabled(enabled);
    _settings = _settings.copyWith(mcqEnabled: enabled);
    notifyListeners();
  }

  Future<void> toggleLiveTestEnabled(bool enabled) async {
    await _service.toggleLiveTestEnabled(enabled);
    _settings = _settings.copyWith(liveTestEnabled: enabled);
    notifyListeners();
  }

  Future<void> updateSettings(LmsSettings next) async {
    await _service.updateSettings(next);
    _settings = next;
    _auditLogs = await _service.getAuditLogs();
    notifyListeners();
  }

  Future<void> updateAdminProfile({
    required String name,
    required String phone,
    String? newPassword,
  }) async {
    await _service.updateAdminProfile(
      name: name,
      phone: phone,
      newPassword: newPassword,
    );
    _auditLogs = await _service.getAuditLogs();
    notifyListeners();
  }

  Future<void> loadAuditLogs({String targetType = 'all', String search = ''}) async {
    _auditLogs = await _service.getAuditLogs(targetType: targetType, search: search);
    notifyListeners();
  }

  // --- MCQ HIERARCHY ---
  Future<void> loadTopics({bool publishedOnly = false}) async {
    _topics = await _service.getTopics(publishedOnly: publishedOnly);
    _mediums = await _service.getMediums();
    notifyListeners();
  }

  Future<void> createTopic({
    required String name,
    String? parentId,
    String description = '',
    int displayOrder = 1,
    bool isPublished = true,
  }) async {
    await _service.createTopic(
      name: name,
      parentId: parentId,
      description: description,
      displayOrder: displayOrder,
      isPublished: isPublished,
    );
    await loadTopics();
  }

  Future<void> updateTopic(McqTopic topic) async {
    await _service.updateTopic(topic);
    await loadTopics();
  }

  Future<void> deleteTopicTree(String topicId) async {
    await _service.deleteTopicTree(topicId);
    await loadTopics();
  }

  Future<List<McqChapter>> getChapters(String topicId, {bool publishedOnly = false}) =>
      _service.getChapters(topicId, publishedOnly: publishedOnly);

  Future<void> createChapter({
    required String topicId,
    required String title,
    String? description,
    int displayOrder = 1,
    bool isPublished = true,
  }) async {
    await _service.createChapter(
      topicId: topicId,
      title: title,
      description: description,
      displayOrder: displayOrder,
      isPublished: isPublished,
    );
    await loadTopics();
  }

  Future<void> updateChapter(McqChapter chapter) async {
    await _service.updateChapter(chapter);
    notifyListeners();
  }

  Future<void> deleteChapter(String chapterId) async {
    await _service.deleteChapter(chapterId);
    await loadTopics();
  }

  Future<void> createMedium(String code, String displayName) async {
    await _service.createMedium(code: code, displayName: displayName);
    _mediums = await _service.getMediums();
    notifyListeners();
  }

  Future<List<McqQuestionSet>> getQuestionSetsForChapter(
    String chapterId, {
    bool publishedOnly = false,
  }) =>
      _service.getQuestionSetsForChapter(chapterId, publishedOnly: publishedOnly);

  Future<McqQuestionSet> attachChapterLanguage(String chapterId, String mediumId) =>
      _service.attachChapterLanguage(chapterId: chapterId, mediumId: mediumId);

  Future<void> deleteChapterLanguage(String chapterId, String mediumId) =>
      _service.deleteChapterLanguage(chapterId: chapterId, mediumId: mediumId);

  Future<List<LmsMcqQuestion>> getQuestionsForSet(String setId) =>
      _service.getQuestionsForSet(setId);

  Future<void> addMcqQuestion(LmsMcqQuestion q) async {
    await _service.addMcqQuestion(q);
    await loadTopics();
  }

  Future<void> updateMcqQuestion(LmsMcqQuestion q) => _service.updateMcqQuestion(q);

  Future<void> deleteMcqQuestion(String questionId, String setId) async {
    await _service.deleteMcqQuestion(questionId, setId);
    await loadTopics();
  }

  Future<void> clearMcqQuestionSet(String setId) async {
    await _service.clearMcqQuestionSet(setId);
    await loadTopics();
  }

  Future<McqQuestionSet> importMcqQuestions({
    required String topicId,
    required String chapterId,
    required String mediumId,
    required String mediumCode,
    required ImportParseResult parsed,
    required String fileName,
    required String fileType,
    required bool publishImmediately,
    required bool replaceExisting,
  }) async {
    final res = await _service.importMcqQuestions(
      topicId: topicId,
      chapterId: chapterId,
      mediumId: mediumId,
      mediumCode: mediumCode,
      parsed: parsed,
      fileName: fileName,
      fileType: fileType,
      publishImmediately: publishImmediately,
      replaceExisting: replaceExisting,
    );
    await loadTopics();
    return res;
  }

  Future<void> publishQuestionSet(String setId, {required bool publish}) async {
    await _service.publishQuestionSet(setId, publish: publish);
    await loadTopics();
  }

  Future<void> loadImportLogs({String? chapterId}) async {
    _importLogs = await _service.getImportLogs(chapterId: chapterId);
    notifyListeners();
  }

  // --- LIVE TESTS ---
  Future<void> loadLiveTests({bool studentOnly = false}) async {
    _liveTests = await _service.getLiveTests(studentOnly: studentOnly);
    notifyListeners();
  }

  Future<LmsLiveTest> createLiveTest({
    required String title,
    String description = '',
    DateTime? testDate,
  }) async {
    final t = await _service.createLiveTest(
      title: title,
      description: description,
      testDate: testDate,
    );
    await loadLiveTests();
    return t;
  }

  Future<void> updateLiveTest(LmsLiveTest test) async {
    await _service.updateLiveTest(test);
    await loadLiveTests();
  }

  Future<void> deleteLiveTest(String testId) async {
    await _service.deleteLiveTest(testId);
    await loadLiveTests();
  }

  Future<List<LmsLiveTestQuestion>> getAdminLiveTestQuestions(String testId) =>
      _service.getAdminLiveTestQuestions(testId);

  Future<List<LmsLiveTestQuestion>> getStudentLiveTestQuestions(String testId) =>
      _service.getStudentLiveTestQuestions(testId);

  Future<void> addLiveTestQuestion(LmsLiveTestQuestion q) async {
    await _service.addLiveTestQuestion(q);
    await loadLiveTests();
  }

  Future<void> updateLiveTestQuestion(LmsLiveTestQuestion q) =>
      _service.updateLiveTestQuestion(q);

  Future<void> deleteLiveTestQuestion(String questionId, String testId) async {
    await _service.deleteLiveTestQuestion(questionId, testId);
    await loadLiveTests();
  }

  Future<void> clearLiveTestQuestions(String testId) async {
    await _service.clearLiveTestQuestions(testId);
    await loadLiveTests();
  }

  Future<int> importLiveTestQuestions({
    required String testId,
    required ImportParseResult parsed,
    required bool replaceExisting,
  }) async {
    final count = await _service.importLiveTestQuestions(
      testId: testId,
      parsed: parsed,
      replaceExisting: replaceExisting,
    );
    await loadLiveTests();
    return count;
  }

  Future<void> setLiveTestStatus(String testId, String status) async {
    await _service.setLiveTestStatus(testId, status);
    await loadLiveTests();
  }

  Future<void> setLiveTestAnswersReleased(
    String testId,
    bool released,
  ) async {
    await _service.setLiveTestAnswersReleased(testId, released);
    await loadLiveTests();
  }

  Future<LmsLiveTestSubmission> submitStudentLiveTest({
    required String testId,
    required String studentName,
    required String phoneNumber,
    required String location,
    required String email,
    required Map<String, String> answers,
  }) async {
    final sub = await _service.submitStudentLiveTest(
      testId: testId,
      studentName: studentName,
      phoneNumber: phoneNumber,
      location: location,
      email: email,
      answers: answers,
    );
    await loadLiveTests(studentOnly: true);
    return sub;
  }

  Future<List<LmsLiveTestQuestion>> getStudentLiveTestAnswers(String testId) =>
      _service.getStudentLiveTestAnswers(testId);

  Future<List<LmsLiveTestSubmission>> getLiveTestResults(String testId) =>
      _service.getLiveTestResults(testId);

  // --- NOTES & FOLDERS ---
  Future<void> loadNotesAndFolders() async {
    final res = await Future.wait([
      _service.getNoteFolders(),
      _service.getNotes(),
    ]);
    _noteFolders = res[0] as List<NoteFolder>;
    _notes = res[1] as List<PdfMaterial>;
    notifyListeners();
  }

  Future<void> createNoteFolder(String name, String? parentId) async {
    await _service.createNoteFolder(name: name, parentId: parentId);
    await loadNotesAndFolders();
  }

  Future<void> updateNoteFolder(String id, String name, String? newParentId) async {
    await _service.updateNoteFolder(
      id: id,
      name: name,
      newParentId: newParentId,
      allFolders: _noteFolders,
    );
    await loadNotesAndFolders();
  }

  Future<void> deleteNoteFolderTree(String folderId) async {
    await _service.deleteNoteFolderTree(folderId);
    await loadNotesAndFolders();
  }

  Future<void> uploadNote({
    required String title,
    String description = '',
    required String? folderId,
    required Uint8List fileBytes,
    required String fileName,
    bool isPreviewable = true,
    bool allowDownload = false,
  }) async {
    await _service.uploadNote(
      title: title,
      description: description,
      folderId: folderId,
      fileBytes: fileBytes,
      fileName: fileName,
      isPreviewable: isPreviewable,
      allowDownload: allowDownload,
    );
    await loadNotesAndFolders();
  }

  Future<void> updateNote(
    PdfMaterial note, {
    Uint8List? replacementBytes,
    String? replacementFileName,
  }) async {
    await _service.updateNote(
      note,
      replacementBytes: replacementBytes,
      replacementFileName: replacementFileName,
    );
    await loadNotesAndFolders();
  }

  Future<void> deleteNote(String noteId) async {
    await _service.deleteNote(noteId);
    await loadNotesAndFolders();
  }

  Future<Uint8List> fetchNotePreviewBytes(PdfMaterial note) =>
      _service.fetchNotePreviewBytes(note);

  Future<({Uint8List? bytes, String? signedUrl, String fileName})> requestNoteDownload(
    PdfMaterial note,
  ) =>
      _service.requestNoteDownload(note);

  List<NoteFolder> getFolderBreadcrumb(String? folderId) {
    final byId = {for (final f in _noteFolders) f.id: f};
    final path = <NoteFolder>[];
    final visited = <String>{};
    var cur = folderId;
    while (cur != null && visited.add(cur)) {
      final f = byId[cur];
      if (f == null) break;
      path.insert(0, f);
      cur = f.parentId;
    }
    return path;
  }

  int getRecursiveNoteCount(String folderId) {
    final ids = _collectDescendantFolderIds(folderId);
    return _notes.where((n) => ids.contains(n.folderId)).length;
  }

  int getRecursiveFolderBytes(String folderId) {
    final ids = _collectDescendantFolderIds(folderId);
    return _notes
        .where((n) => ids.contains(n.folderId))
        .fold<int>(0, (sum, n) => sum + SizeFormatter.parseSizeToBytes(n.fileSize));
  }

  Set<String> _collectDescendantFolderIds(String folderId) {
    final ids = <String>{folderId};
    final queue = <String>[folderId];
    while (queue.isNotEmpty) {
      final cur = queue.removeAt(0);
      for (final child in _noteFolders.where((f) => f.parentId == cur)) {
        if (ids.add(child.id)) queue.add(child.id);
      }
    }
    return ids;
  }

  // --- STUDENTS DIRECTORY & PRACTICE ---
  Future<void> loadStudentsDirectory({String search = ''}) async {
    _students = await _service.getStudentsDirectory(search: search);
    notifyListeners();
  }

  Future<void> loadStudentPortalData({bool isAdmin = false}) async {
    await Future.wait([
      loadPublicSettings(),
      loadTopics(publishedOnly: !isAdmin),
      loadLiveTests(studentOnly: !isAdmin),
      loadNotesAndFolders(),
    ]);
  }

  Future<McqAttemptRecord> submitMcqPracticeAttempt({
    required String userId,
    required String questionSetId,
    required int questionSetVersion,
    required List<LmsMcqQuestion> questions,
    required Map<String, String> selectedAnswers,
  }) async {
    final rec = await _service.submitMcqPracticeAttempt(
      userId: userId,
      questionSetId: questionSetId,
      questionSetVersion: questionSetVersion,
      questions: questions,
      selectedAnswers: selectedAnswers,
    );
    notifyListeners();
    return rec;
  }

  Future<Set<String>> getUserBookmarks(String userId) =>
      _service.getUserBookmarks(userId);

  Future<bool> toggleMcqBookmark(String userId, String questionId) async {
    final res = await _service.toggleMcqBookmark(userId, questionId);
    notifyListeners();
    return res;
  }

  // --- SUPABASE REALTIME SYNC FOR ADMIN -> USER UPDATES ---
  void startRealtimeSync({bool isAdmin = false}) {
    final client = SupabaseService().client;
    if (client == null || AuthService().isLocalSession || _realtimeChannel != null) {
      return;
    }

    final channel = client.channel('lms-live-sync');
    const tables = [
      'settings',
      'mcq_topics',
      'mcq_chapters',
      'mcq_mediums',
      'mcq_question_sets',
      'mcq_questions',
      'live_tests',
      'note_folders',
      'pdf_materials',
    ];

    for (final table in tables) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: (_) => _scheduleSyncRefresh(isAdmin: isAdmin),
      );
    }

    _realtimeChannel = channel..subscribe();
  }

  void _scheduleSyncRefresh({bool isAdmin = false}) {
    _realtimeDebounce?.cancel();
    _realtimeDebounce = Timer(const Duration(milliseconds: 350), () async {
      await loadPublicSettings();
      await loadTopics(publishedOnly: !isAdmin);
      await loadLiveTests(studentOnly: !isAdmin);
      await loadNotesAndFolders();
    });
  }

  Future<void> stopRealtimeSync() async {
    _realtimeDebounce?.cancel();
    final ch = _realtimeChannel;
    _realtimeChannel = null;
    if (ch != null) {
      try {
        await SupabaseService().client?.removeChannel(ch);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _realtimeDebounce?.cancel();
    super.dispose();
  }
}
