import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../core/constants.dart';
import '../core/utils/mcq_import_parser.dart';
import '../core/utils/size_formatter.dart';
import '../models/lms_models.dart';
import 'auth_service.dart';
import 'supabase_service.dart';

class LmsAdminService {
  static final LmsAdminService _instance = LmsAdminService._internal();
  factory LmsAdminService() => _instance;
  LmsAdminService._internal() {
    _seedInitialLocalData();
  }

  final _uuid = const Uuid();
  SupabaseClient? get _client => SupabaseService().client;
  bool get _hasLiveAuthSession {
    final c = _client;
    return c != null && !AuthService().isLocalSession && c.auth.currentSession != null;
  }

  // Local resilient state (used offline/demo or when Supabase host is unreachable)
  LmsSettings _settings = const LmsSettings();

  final List<LmsAuditLog> _auditLogs = [];
  final List<McqTopic> _topics = [];
  final List<McqChapter> _chapters = [];
  final List<McqMedium> _mediums = [];
  final List<McqQuestionSet> _questionSets = [];
  final List<LmsMcqQuestion> _mcqQuestions = [];
  final List<McqImportLog> _importLogs = [];
  final List<McqAttemptRecord> _mcqAttempts = [];
  final Map<String, Set<String>> _bookmarksByUser = {};

  final List<LmsLiveTest> _liveTests = [];
  final List<LmsLiveTestQuestion> _liveTestQuestions = [];
  final List<LmsLiveTestSubmission> _liveTestSubmissions = [];

  final List<NoteFolder> _noteFolders = [];
  final List<PdfMaterial> _pdfMaterials = [];
  final Map<String, Uint8List> _localPdfBytes = {};

  final List<Map<String, dynamic>> _localUsers = [];

  void _seedInitialLocalData() {
    if (_mediums.isNotEmpty) return;

    _mediums.addAll(const [
      McqMedium(id: 'med-en', code: 'en', displayName: 'English'),
      McqMedium(id: 'med-te', code: 'te', displayName: 'Telugu'),
      McqMedium(id: 'med-hi', code: 'hi', displayName: 'Hindi'),
    ]);

    _topics.addAll(const [
      McqTopic(
        id: 'topic-po-guide',
        slug: 'post-office-guide-part-1',
        name: 'Post Office Guide Part I',
        category: 'Departmental Rules',
        description: 'Organization, business hours, postage stamps, and inland postal rules.',
        displayOrder: 1,
        isPublished: true,
      ),
      McqTopic(
        id: 'topic-po-manual',
        slug: 'postal-manual-volume-v',
        name: 'Postal Manual Volume V',
        category: 'Departmental Rules',
        description: 'Definitions, sorting offices, mail bags, and delivery guidelines.',
        displayOrder: 2,
        isPublished: true,
      ),
    ]);

    _chapters.addAll(const [
      McqChapter(
        id: 'chap-org',
        topicId: 'topic-po-guide',
        title: 'Chapter 1: Organization & Control',
        slug: 'organization-control',
        displayOrder: 1,
        isPublished: true,
      ),
      McqChapter(
        id: 'chap-mail',
        topicId: 'topic-po-guide',
        title: 'Chapter 2: Inland Mail & Weight Limits',
        slug: 'inland-mail-weight',
        displayOrder: 2,
        isPublished: true,
      ),
    ]);

    _questionSets.add(
      McqQuestionSet(
        id: 'set-org-en-v1',
        chapterId: 'chap-org',
        mediumId: 'med-en',
        version: 1,
        status: 'published',
        questionCount: 2,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        publishedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    );

    _mcqQuestions.addAll(const [
      LmsMcqQuestion(
        id: 'q-seed-1',
        questionSetId: 'set-org-en-v1',
        chapterId: 'chap-org',
        questionKey: 'Q1',
        questionText: 'Who is the administrative head of a Postal Circle in India Post?',
        optionA: 'Superintendent of Post Offices (SPO)',
        optionB: 'Chief Postmaster General (CPMG)',
        optionC: 'Director General (Posts)',
        optionD: 'Inspector of Posts (IP)',
        correctOption: 'B',
        explanation: 'Each Postal Circle is headed by a Chief Postmaster General (CPMG).',
        language: 'en',
        displayOrder: 1,
        status: 'published',
      ),
      LmsMcqQuestion(
        id: 'q-seed-2',
        questionSetId: 'set-org-en-v1',
        chapterId: 'chap-org',
        questionKey: 'Q2',
        questionText: 'What is the maximum permissible weight for an Inland Letter Card?',
        optionA: '3 grams',
        optionB: '5 grams',
        optionC: '10 grams',
        optionD: '15 grams',
        correctOption: 'B',
        explanation: 'An Inland Letter Card has a maximum permissible weight limit of 5 grams.',
        language: 'en',
        displayOrder: 2,
        status: 'published',
      ),
    ]);

    _liveTests.add(
      LmsLiveTest(
        id: 'lt-demo-1',
        title: 'All-India Postal MTS Weekly Mock Test',
        description: 'Untimed departmental live mock test covering PO Guide Part I.',
        testDate: DateTime.now(),
        status: 'published',
        questionCount: 2,
        answersReleased: false,
        attemptsCount: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    );

    _liveTestQuestions.addAll(const [
      LmsLiveTestQuestion(
        id: 'ltq-1',
        testId: 'lt-demo-1',
        questionKey: 'Q1',
        questionText: 'Which article of the Indian Constitution deals with the Right to Equality?',
        optionA: 'Article 12',
        optionB: 'Article 14',
        optionC: 'Article 19',
        optionD: 'Article 21',
        correctOption: 'B',
        explanation: 'Article 14 guarantees equality before law and equal protection of laws.',
        displayOrder: 1,
      ),
      LmsLiveTestQuestion(
        id: 'ltq-2',
        testId: 'lt-demo-1',
        questionKey: 'Q2',
        questionText: 'How many Postal Circles exist in India Post (excluding APS)?',
        optionA: '21',
        optionB: '22',
        optionC: '23',
        optionD: '24',
        correctOption: 'C',
        explanation: 'India is divided into 23 Postal Circles.',
        displayOrder: 2,
      ),
    ]);

    _liveTestSubmissions.add(
      LmsLiveTestSubmission(
        id: 'sub-demo-1',
        testId: 'lt-demo-1',
        userId: 'example-student-01',
        studentName: 'Example Candidate',
        phoneNumber: '9876543210',
        location: 'Tenali, AP',
        email: 'student@example.com',
        totalQuestions: 2,
        attemptedCount: 2,
        correctCount: 2,
        wrongCount: 0,
        marksObtained: 2,
        percentage: 100.0,
        answers: const {'ltq-1': 'B', 'ltq-2': 'C'},
        submittedAt: DateTime.now().subtract(const Duration(hours: 3)),
        rank: 1,
      ),
    );

    _noteFolders.addAll([
      NoteFolder(
        id: 'nf-root-1',
        name: 'PO Guide Part I',
        parentId: null,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      NoteFolder(
        id: 'nf-sub-1',
        name: 'Clause Summaries',
        parentId: 'nf-root-1',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ]);

    _localUsers.addAll([
      {
        'id': 'example-student-01',
        'name': 'Example Candidate',
        'email': AppConstants.exampleLoginEmail,
        'phone': '9876543210',
        'role': 'customer',
        'created_at': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
      },
      {
        'id': 'stu-02',
        'name': 'Priya Sharma',
        'email': 'priya.sharma@example.com',
        'phone': '9123456780',
        'role': 'customer',
        'created_at': DateTime.now().subtract(const Duration(days: 6)).toIso8601String(),
      },
    ]);

    _auditLogs.add(
      LmsAuditLog(
        id: 'audit-init-1',
        adminId: 'admin-01',
        adminName: 'Tenali Postal Admin',
        adminEmail: AppConstants.authorizedAdminEmail,
        actionType: 'INITIALIZE_LMS',
        targetType: 'settings',
        targetName: 'Global LMS Controls',
        newValue: const {'mcq_enabled': 'true', 'live_test_enabled': 'true'},
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
    );
  }

  void _recordLocalAudit({
    required String actionType,
    required String targetType,
    required String targetName,
    Map<String, dynamic>? previousValue,
    Map<String, dynamic>? newValue,
  }) {
    final user = AuthService().currentUser;
    _auditLogs.insert(
      0,
      LmsAuditLog(
        id: _uuid.v4(),
        adminId: user?.id ?? 'admin-01',
        adminName: user?.fullName ?? 'Tenali Postal Admin',
        adminEmail: user?.email ?? AppConstants.authorizedAdminEmail,
        actionType: actionType,
        targetType: targetType,
        targetName: targetName,
        previousValue: previousValue,
        newValue: newValue,
        createdAt: DateTime.now(),
      ),
    );
  }

  // ===========================================================================
  // 1. GLOBAL SETTINGS & AUDIT LOGS
  // ===========================================================================

  Future<LmsSettings> getSettings() async {
    if (_hasLiveAuthSession) {
      try {
        final rows = await _client!.from('settings').select('key, value');
        _settings = LmsSettings.fromKeyValueRows(rows as List);
        return _settings;
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] getSettings fallback: $e');
      }
    }
    return _settings;
  }

  Future<void> toggleMcqEnabled(bool enabled) async {
    final prev = {'mcq_enabled': _settings.mcqEnabled.toString()};
    if (_hasLiveAuthSession) {
      try {
        await _client!.from('settings').upsert({
          'key': 'mcq_enabled',
          'value': enabled.toString(),
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'key');
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] toggleMcqEnabled fallback: $e');
      }
    }
    _settings = _settings.copyWith(mcqEnabled: enabled);
    _recordLocalAudit(
      actionType: 'TOGGLE_MCQ',
      targetType: 'settings',
      targetName: 'mcq_enabled',
      previousValue: prev,
      newValue: {'mcq_enabled': enabled.toString()},
    );
  }

  Future<void> toggleLiveTestEnabled(bool enabled) async {
    final prev = {'live_test_enabled': _settings.liveTestEnabled.toString()};
    if (_hasLiveAuthSession) {
      try {
        await _client!.from('settings').upsert({
          'key': 'live_test_enabled',
          'value': enabled.toString(),
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'key');
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] toggleLiveTestEnabled fallback: $e');
      }
    }
    _settings = _settings.copyWith(liveTestEnabled: enabled);
    _recordLocalAudit(
      actionType: 'TOGGLE_LIVE_TESTS',
      targetType: 'settings',
      targetName: 'live_test_enabled',
      previousValue: prev,
      newValue: {'live_test_enabled': enabled.toString()},
    );
  }

  Future<void> updateSettings(LmsSettings next) async {
    final prev = _settings.toJson();
    if (_hasLiveAuthSession) {
      final res = await _client!.functions.invoke(
        'admin-settings-and-profile',
        method: HttpMethod.put,
        body: {
          'action': 'update_settings',
          'maintenanceMode': next.maintenanceMode,
          'mcqEnabled': next.mcqEnabled,
          'liveTestEnabled': next.liveTestEnabled,
          'liveNotificationEnabled': next.liveNotificationEnabled,
          'liveNotificationText': next.liveNotificationText,
          'liveNotificationLink': next.liveNotificationLink,
        },
      );
      if (res.status >= 400) {
        throw Exception(res.data?['error'] ?? 'Failed to update settings');
      }
    }
    _settings = next;
    _recordLocalAudit(
      actionType: 'UPDATE_SETTINGS',
      targetType: 'settings',
      targetName: 'Global LMS Settings',
      previousValue: prev,
      newValue: next.toJson(),
    );
  }

  Future<void> updateAdminProfile({
    required String name,
    required String phone,
    String? newPassword,
  }) async {
    if (_hasLiveAuthSession) {
      final res = await _client!.functions.invoke(
        'admin-settings-and-profile',
        method: HttpMethod.put,
        body: {
          'action': 'update_profile',
          'name': name,
          'phone': phone,
          if (newPassword != null && newPassword.isNotEmpty) 'newPassword': newPassword,
        },
      );
      if (res.status >= 400) {
        throw Exception(res.data?['error'] ?? 'Failed to update admin profile');
      }
    }

    final current = AuthService().currentUser;
    if (current != null) {
      final prev = {'name': current.fullName, 'phone': current.phoneNumber};
      final updated = current.copyWith(fullName: name.trim(), phoneNumber: phone.trim());
      await AuthService().saveProfile(updated);
      _recordLocalAudit(
        actionType: 'UPDATE_PROFILE',
        targetType: 'profile',
        targetName: current.email,
        previousValue: prev,
        newValue: {'name': name.trim(), 'phone': phone.trim()},
      );
    }
  }

  Future<List<LmsAuditLog>> getAuditLogs({
    String targetType = 'all',
    String search = '',
  }) async {
    List<LmsAuditLog> list = List.of(_auditLogs);
    if (_hasLiveAuthSession) {
      try {
        final rows = await _client!
            .from('admin_audit_logs')
            .select()
            .order('created_at', ascending: false)
            .limit(100);
        list = (rows as List)
            .map((r) => LmsAuditLog.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList();
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] getAuditLogs fallback: $e');
      }
    }

    return list.where((l) {
      final typeOk = targetType == 'all' || l.targetType.toLowerCase() == targetType.toLowerCase();
      final q = search.trim().toLowerCase();
      final searchOk = q.isEmpty ||
          l.actionType.toLowerCase().contains(q) ||
          l.targetName.toLowerCase().contains(q) ||
          l.adminEmail.toLowerCase().contains(q);
      return typeOk && searchOk;
    }).toList();
  }

  // ===========================================================================
  // 2. MCQ HIERARCHY, VERSIONED SETS, BULK IMPORTER & PRACTICE
  // ===========================================================================

  Future<List<McqTopic>> getTopics({bool publishedOnly = false}) async {
    if (_hasLiveAuthSession) {
      try {
        var q = _client!.from('mcq_topics').select();
        if (publishedOnly) q = q.eq('is_published', true);
        final rows = await q.order('display_order', ascending: true);
        final list = (rows as List)
            .map((r) => McqTopic.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList();
        return list;
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] getTopics fallback: $e');
      }
    }

    return _topics
        .where((t) => !publishedOnly || t.isPublished)
        .map((t) {
          final directChaps = _chapters.where((c) => c.topicId == t.id).toList();
          final setIds = _questionSets
              .where((s) => directChaps.any((c) => c.id == s.chapterId))
              .map((s) => s.id)
              .toSet();
          final qCount = _mcqQuestions.where((q) => setIds.contains(q.questionSetId)).length;
          return t.copyWith(chapterCount: directChaps.length, questionCount: qCount);
        })
        .toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  }

  Future<McqTopic> createTopic({
    required String name,
    String? parentId,
    String category = 'General',
    String? description,
    int displayOrder = 1,
    bool isPublished = true,
  }) async {
    final slug = '${SizeFormatter.slugify(name)}-${DateTime.now().millisecondsSinceEpoch % 10000}';
    if (_hasLiveAuthSession) {
      try {
        final inserted = await _client!
            .from('mcq_topics')
            .insert({
              'name': name.trim(),
              'slug': slug,
              'category': category.trim(),
              'description': description?.trim(),
              'display_order': displayOrder,
              'is_published': isPublished,
              'is_active': true,
              'parent_id': parentId,
            })
            .select()
            .single();
        return McqTopic.fromJson(Map<String, dynamic>.from(inserted));
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] createTopic fallback: $e');
      }
    }

    final topic = McqTopic(
      id: _uuid.v4(),
      slug: slug,
      name: name.trim(),
      category: category.trim(),
      description: description?.trim(),
      displayOrder: displayOrder,
      isPublished: isPublished,
      parentId: parentId,
    );
    _topics.add(topic);
    _recordLocalAudit(
      actionType: 'CREATE_TOPIC',
      targetType: 'mcq',
      targetName: topic.name,
      newValue: {'id': topic.id, 'parent_id': parentId},
    );
    return topic;
  }

  Future<void> updateTopic(McqTopic topic) async {
    if (topic.parentId == topic.id) {
      throw Exception('A topic cannot be its own parent.');
    }
    if (_hasLiveAuthSession) {
      try {
        await _client!.from('mcq_topics').update({
          'name': topic.name.trim(),
          'category': topic.category.trim(),
          'description': topic.description?.trim(),
          'display_order': topic.displayOrder,
          'is_published': topic.isPublished,
          'parent_id': topic.parentId,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', topic.id);
        return;
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] updateTopic fallback: $e');
      }
    }

    final idx = _topics.indexWhere((t) => t.id == topic.id);
    if (idx != -1) _topics[idx] = topic;
  }

  Future<void> deleteTopicTree(String topicId) async {
    if (_hasLiveAuthSession) {
      await _client!.rpc('delete_mcq_topic_tree', params: {'p_topic_id': topicId});
      return;
    }

    final toDelete = <String>{topicId};
    final queue = <String>[topicId];
    while (queue.isNotEmpty) {
      final cur = queue.removeAt(0);
      for (final child in _topics.where((t) => t.parentId == cur)) {
        if (toDelete.add(child.id)) queue.add(child.id);
      }
    }

    final chapterIds = _chapters.where((c) => toDelete.contains(c.topicId)).map((c) => c.id).toSet();
    final setIds = _questionSets.where((s) => chapterIds.contains(s.chapterId)).map((s) => s.id).toSet();
    _mcqQuestions.removeWhere((q) => setIds.contains(q.questionSetId));
    _questionSets.removeWhere((s) => setIds.contains(s.id));
    _importLogs.removeWhere((l) => chapterIds.contains(l.chapterId) || toDelete.contains(l.topicId));
    _chapters.removeWhere((c) => chapterIds.contains(c.id));
    _topics.removeWhere((t) => toDelete.contains(t.id));

    _recordLocalAudit(
      actionType: 'DELETE_TOPIC_TREE',
      targetType: 'mcq',
      targetName: topicId,
      previousValue: {'deletedTopics': toDelete.length},
    );
  }

  Future<List<McqChapter>> getChapters(String topicId, {bool publishedOnly = false}) async {
    if (_hasLiveAuthSession) {
      try {
        var q = _client!.from('mcq_chapters').select().eq('topic_id', topicId);
        if (publishedOnly) q = q.eq('is_published', true);
        final rows = await q.order('display_order', ascending: true);
        return (rows as List)
            .map((r) => McqChapter.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList();
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] getChapters fallback: $e');
      }
    }

    return _chapters
        .where((c) => c.topicId == topicId && (!publishedOnly || c.isPublished))
        .map((c) {
          final sets = _questionSets.where((s) => s.chapterId == c.id).toList();
          final publishedCount = sets.where((s) => s.isPublished).length;
          final setIds = sets.map((s) => s.id).toSet();
          final qCount = _mcqQuestions.where((q) => setIds.contains(q.questionSetId)).length;
          return c.copyWith(questionCount: qCount, publishedSetsCount: publishedCount);
        })
        .toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  }

  Future<McqChapter> createChapter({
    required String topicId,
    required String title,
    String? description,
    int displayOrder = 1,
    bool isPublished = true,
  }) async {
    final slug = SizeFormatter.slugify(title);
    if (_hasLiveAuthSession) {
      try {
        final inserted = await _client!
            .from('mcq_chapters')
            .insert({
              'topic_id': topicId,
              'title': title.trim(),
              'name': title.trim(),
              'slug': slug,
              'description': description?.trim(),
              'display_order': displayOrder,
              'order_index': displayOrder,
              'is_published': isPublished,
              'is_active': isPublished,
            })
            .select()
            .single();
        return McqChapter.fromJson(Map<String, dynamic>.from(inserted));
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] createChapter fallback: $e');
      }
    }

    final chap = McqChapter(
      id: _uuid.v4(),
      topicId: topicId,
      title: title.trim(),
      slug: slug,
      description: description?.trim(),
      displayOrder: displayOrder,
      isPublished: isPublished,
    );
    _chapters.add(chap);
    return chap;
  }

  Future<void> updateChapter(McqChapter chapter) async {
    if (_hasLiveAuthSession) {
      try {
        await _client!.from('mcq_chapters').update({
          'title': chapter.title.trim(),
          'name': chapter.title.trim(),
          'description': chapter.description?.trim(),
          'display_order': chapter.displayOrder,
          'order_index': chapter.displayOrder,
          'is_published': chapter.isPublished,
          'is_active': chapter.isPublished,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', chapter.id);
        return;
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] updateChapter fallback: $e');
      }
    }

    final idx = _chapters.indexWhere((c) => c.id == chapter.id);
    if (idx != -1) _chapters[idx] = chapter;
  }

  Future<void> deleteChapter(String chapterId) async {
    if (_hasLiveAuthSession) {
      try {
        final sets = await _client!
            .from('mcq_question_sets')
            .select('id')
            .eq('chapter_id', chapterId);
        final setIds = (sets as List).map((e) => e['id'].toString()).toList();
        if (setIds.isNotEmpty) {
          await _client!.from('mcq_attempts').delete().inFilter('question_set_id', setIds);
          await _client!.from('mcq_questions').delete().inFilter('question_set_id', setIds);
          await _client!.from('mcq_question_sets').delete().inFilter('id', setIds);
        }
        await _client!.from('mcq_import_logs').delete().eq('chapter_id', chapterId);
        await _client!.from('mcq_chapters').delete().eq('id', chapterId);
        return;
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] deleteChapter fallback: $e');
      }
    }

    final setIds = _questionSets.where((s) => s.chapterId == chapterId).map((s) => s.id).toSet();
    _mcqQuestions.removeWhere((q) => setIds.contains(q.questionSetId));
    _questionSets.removeWhere((s) => setIds.contains(s.id));
    _importLogs.removeWhere((l) => l.chapterId == chapterId);
    _chapters.removeWhere((c) => c.id == chapterId);
  }

  Future<List<McqMedium>> getMediums({bool activeOnly = false}) async {
    if (_hasLiveAuthSession) {
      try {
        var q = _client!.from('mcq_mediums').select();
        if (activeOnly) q = q.eq('is_active', true);
        final rows = await q.order('display_name');
        return (rows as List)
            .map((r) => McqMedium.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList();
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] getMediums fallback: $e');
      }
    }
    return _mediums.where((m) => !activeOnly || m.isActive).toList();
  }

  Future<McqMedium> createMedium({required String code, required String displayName}) async {
    final normalizedCode = code.trim().toLowerCase();
    if (_hasLiveAuthSession) {
      try {
        final inserted = await _client!
            .from('mcq_mediums')
            .insert({
              'code': normalizedCode,
              'display_name': displayName.trim(),
              'is_active': true,
            })
            .select()
            .single();
        return McqMedium.fromJson(Map<String, dynamic>.from(inserted));
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] createMedium fallback: $e');
      }
    }

    if (_mediums.any((m) => m.code.toLowerCase() == normalizedCode)) {
      throw Exception('Medium code "$normalizedCode" already exists.');
    }
    final med = McqMedium(
      id: _uuid.v4(),
      code: normalizedCode,
      displayName: displayName.trim(),
    );
    _mediums.add(med);
    return med;
  }

  Future<List<McqQuestionSet>> getQuestionSetsForChapter(
    String chapterId, {
    bool publishedOnly = false,
  }) async {
    if (_hasLiveAuthSession) {
      try {
        var q = _client!.from('mcq_question_sets').select().eq('chapter_id', chapterId);
        if (publishedOnly) q = q.eq('status', 'published');
        final rows = await q.order('version', ascending: false);
        return (rows as List)
            .map((r) => McqQuestionSet.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList();
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] getQuestionSets fallback: $e');
      }
    }

    return _questionSets
        .where((s) => s.chapterId == chapterId && (!publishedOnly || s.isPublished))
        .toList()
      ..sort((a, b) => b.version.compareTo(a.version));
  }

  Future<McqQuestionSet> attachChapterLanguage({
    required String chapterId,
    required String mediumId,
  }) async {
    final existing = await getQuestionSetsForChapter(chapterId);
    final match = existing.where((s) => s.mediumId == mediumId).toList();
    if (match.isNotEmpty) return match.first;

    if (_hasLiveAuthSession) {
      try {
        final inserted = await _client!
            .from('mcq_question_sets')
            .insert({
              'chapter_id': chapterId,
              'medium_id': mediumId,
              'version': 1,
              'status': 'draft',
              'question_count': 0,
            })
            .select()
            .single();
        return McqQuestionSet.fromJson(Map<String, dynamic>.from(inserted));
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] attachChapterLanguage fallback: $e');
      }
    }

    final set = McqQuestionSet(
      id: _uuid.v4(),
      chapterId: chapterId,
      mediumId: mediumId,
      version: 1,
      status: 'draft',
      questionCount: 0,
      createdAt: DateTime.now(),
    );
    _questionSets.add(set);
    return set;
  }

  Future<void> deleteChapterLanguage({
    required String chapterId,
    required String mediumId,
  }) async {
    if (_hasLiveAuthSession) {
      try {
        final sets = await _client!
            .from('mcq_question_sets')
            .select('id')
            .eq('chapter_id', chapterId)
            .eq('medium_id', mediumId);
        final setIds = (sets as List).map((e) => e['id'].toString()).toList();
        if (setIds.isNotEmpty) {
          await _client!.from('mcq_questions').delete().inFilter('question_set_id', setIds);
          await _client!.from('mcq_question_sets').delete().inFilter('id', setIds);
        }
        return;
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] deleteChapterLanguage fallback: $e');
      }
    }

    final setIds = _questionSets
        .where((s) => s.chapterId == chapterId && s.mediumId == mediumId)
        .map((s) => s.id)
        .toSet();
    _mcqQuestions.removeWhere((q) => setIds.contains(q.questionSetId));
    _questionSets.removeWhere((s) => setIds.contains(s.id));
  }

  Future<List<LmsMcqQuestion>> getQuestionsForSet(String setId) async {
    if (_hasLiveAuthSession) {
      try {
        final rows = await _client!
            .from('mcq_questions')
            .select()
            .eq('question_set_id', setId)
            .order('display_order', ascending: true);
        return (rows as List)
            .map((r) => LmsMcqQuestion.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList();
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] getQuestionsForSet fallback: $e');
      }
    }
    return _mcqQuestions.where((q) => q.questionSetId == setId).toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  }

  Future<void> updateMcqQuestion(LmsMcqQuestion question) async {
    if (_hasLiveAuthSession) {
      try {
        await _client!.from('mcq_questions').update({
          'question_text': question.questionText.trim(),
          'option_a': question.optionA.trim(),
          'option_b': question.optionB.trim(),
          'option_c': question.optionC.trim(),
          'option_d': question.optionD.trim(),
          'correct_option': question.correctOption.toUpperCase(),
          'explanation': question.explanation.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', question.id);
        return;
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] updateMcqQuestion fallback: $e');
      }
    }
    final idx = _mcqQuestions.indexWhere((q) => q.id == question.id);
    if (idx != -1) _mcqQuestions[idx] = question;
  }

  Future<LmsMcqQuestion> addMcqQuestion(LmsMcqQuestion question) async {
    final nextOrder = question.displayOrder > 0
        ? question.displayOrder
        : (_mcqQuestions.where((q) => q.questionSetId == question.questionSetId).length + 1);
    final qKey = question.questionKey.trim().isEmpty ? 'Q$nextOrder' : question.questionKey.trim();

    if (_hasLiveAuthSession) {
      try {
        final inserted = await _client!
            .from('mcq_questions')
            .insert({
              'question_set_id': question.questionSetId,
              if (question.chapterId != null) 'chapter_id': question.chapterId,
              'question_key': qKey,
              'question_text': question.questionText.trim(),
              'option_a': question.optionA.trim(),
              'option_b': question.optionB.trim(),
              'option_c': question.optionC.trim(),
              'option_d': question.optionD.trim(),
              'correct_option': question.correctOption.toUpperCase(),
              'explanation': question.explanation.trim(),
              'language': question.language,
              'difficulty': question.difficulty,
              'display_order': nextOrder,
              'status': question.status,
            })
            .select()
            .single();
        final countRows = await _client!
            .from('mcq_questions')
            .select('id')
            .eq('question_set_id', question.questionSetId);
        await _client!.from('mcq_question_sets').update({
          'question_count': (countRows as List).length,
        }).eq('id', question.questionSetId);
        return LmsMcqQuestion.fromJson(Map<String, dynamic>.from(inserted));
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] addMcqQuestion fallback: $e');
      }
    }

    final created = question.copyWith(
      id: _uuid.v4(),
      questionKey: qKey,
      displayOrder: nextOrder,
      correctOption: question.correctOption.toUpperCase(),
    );
    _mcqQuestions.add(created);
    final idx = _questionSets.indexWhere((s) => s.id == question.questionSetId);
    if (idx != -1) {
      final count = _mcqQuestions.where((q) => q.questionSetId == question.questionSetId).length;
      _questionSets[idx] = _questionSets[idx].copyWith(questionCount: count);
    }
    return created;
  }

  Future<void> deleteMcqQuestion(String questionId, String setId) async {
    if (_hasLiveAuthSession) {
      try {
        await _client!.from('mcq_questions').delete().eq('id', questionId);
        final countRows = await _client!
            .from('mcq_questions')
            .select('id')
            .eq('question_set_id', setId);
        await _client!.from('mcq_question_sets').update({
          'question_count': (countRows as List).length,
        }).eq('id', setId);
        return;
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] deleteMcqQuestion fallback: $e');
      }
    }
    _mcqQuestions.removeWhere((q) => q.id == questionId);
    final idx = _questionSets.indexWhere((s) => s.id == setId);
    if (idx != -1) {
      final count = _mcqQuestions.where((q) => q.questionSetId == setId).length;
      _questionSets[idx] = _questionSets[idx].copyWith(questionCount: count);
    }
  }

  Future<void> clearMcqQuestionSet(String setId) async {
    if (_hasLiveAuthSession) {
      try {
        await _client!.from('mcq_questions').delete().eq('question_set_id', setId);
        await _client!.from('mcq_question_sets').update({'question_count': 0}).eq('id', setId);
        return;
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] clearMcqQuestionSet fallback: $e');
      }
    }
    _mcqQuestions.removeWhere((q) => q.questionSetId == setId);
    final idx = _questionSets.indexWhere((s) => s.id == setId);
    if (idx != -1) {
      _questionSets[idx] = _questionSets[idx].copyWith(questionCount: 0);
    }
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
    if (!parsed.isValid) {
      final errSummary = parsed.errors.take(5).map((e) => e.toString()).join(' | ');
      _importLogs.insert(
        0,
        McqImportLog(
          id: _uuid.v4(),
          topicId: topicId,
          chapterId: chapterId,
          mediumId: mediumId,
          fileName: fileName,
          fileType: fileType,
          status: 'failed',
          totalRows: parsed.totalRows,
          validRows: parsed.validCount,
          invalidRows: parsed.invalidCount,
          errorSummary: errSummary,
          createdAt: DateTime.now(),
        ),
      );
      throw Exception('Import blocked: ${parsed.invalidCount} validation error(s).');
    }

    final sets = await getQuestionSetsForChapter(chapterId);
    final matchingSets = sets.where((s) => s.mediumId == mediumId).toList();
    McqQuestionSet targetSet;

    if (replaceExisting || matchingSets.isEmpty) {
      final nextVersion = matchingSets.isEmpty
          ? 1
          : (matchingSets.map((s) => s.version).reduce((a, b) => a > b ? a : b) + 1);

      if (_hasLiveAuthSession) {
        try {
          if (publishImmediately) {
            await _client!
                .from('mcq_question_sets')
                .update({'status': 'archived'})
                .eq('chapter_id', chapterId)
                .eq('medium_id', mediumId)
                .eq('status', 'published');
          }
          final insertedSet = await _client!
              .from('mcq_question_sets')
              .insert({
                'chapter_id': chapterId,
                'medium_id': mediumId,
                'version': nextVersion,
                'status': publishImmediately ? 'published' : 'draft',
                'question_count': parsed.validCount,
                if (publishImmediately) 'published_at': DateTime.now().toIso8601String(),
              })
              .select()
              .single();
          targetSet = McqQuestionSet.fromJson(Map<String, dynamic>.from(insertedSet));

          await _client!.from('mcq_questions').insert(
                parsed.validQuestions
                    .map((row) => {
                          'question_set_id': targetSet.id,
                          'chapter_id': chapterId,
                          'question_key': row.questionKey,
                          'question_text': row.questionText,
                          'option_a': row.optionA,
                          'option_b': row.optionB,
                          'option_c': row.optionC,
                          'option_d': row.optionD,
                          'correct_option': row.correctOption,
                          'explanation': row.explanation,
                          'language': mediumCode,
                          'display_order': row.displayOrder,
                          'status': publishImmediately ? 'published' : 'draft',
                        })
                    .toList(),
              );
          await _client!.from('mcq_import_logs').insert({
            'topic_id': topicId,
            'chapter_id': chapterId,
            'medium_id': mediumId,
            'file_name': fileName,
            'file_type': fileType,
            'status': 'success',
            'total_rows': parsed.totalRows,
            'valid_rows': parsed.validCount,
            'invalid_rows': 0,
          });
          return targetSet;
        } catch (e) {
          if (kDebugMode) print('[LmsAdminService] importMcqQuestions fallback: $e');
        }
      }

      if (publishImmediately) {
        for (var i = 0; i < _questionSets.length; i++) {
          final s = _questionSets[i];
          if (s.chapterId == chapterId && s.mediumId == mediumId && s.isPublished) {
            _questionSets[i] = s.copyWith(status: 'archived');
          }
        }
      }

      targetSet = McqQuestionSet(
        id: _uuid.v4(),
        chapterId: chapterId,
        mediumId: mediumId,
        version: nextVersion,
        status: publishImmediately ? 'published' : 'draft',
        questionCount: parsed.validCount,
        createdAt: DateTime.now(),
        publishedAt: publishImmediately ? DateTime.now() : null,
      );
      _questionSets.add(targetSet);

      for (final row in parsed.validQuestions) {
        _mcqQuestions.add(
          LmsMcqQuestion(
            id: _uuid.v4(),
            questionSetId: targetSet.id,
            chapterId: chapterId,
            questionKey: row.questionKey,
            questionText: row.questionText,
            optionA: row.optionA,
            optionB: row.optionB,
            optionC: row.optionC,
            optionD: row.optionD,
            correctOption: row.correctOption,
            explanation: row.explanation,
            language: mediumCode,
            displayOrder: row.displayOrder,
            status: publishImmediately ? 'published' : 'draft',
          ),
        );
      }
    } else {
      targetSet = matchingSets.first;
      final existingQs = await getQuestionsForSet(targetSet.id);
      final baseOrder = existingQs.length;

      for (var i = 0; i < parsed.validQuestions.length; i++) {
        final row = parsed.validQuestions[i];
        _mcqQuestions.add(
          LmsMcqQuestion(
            id: _uuid.v4(),
            questionSetId: targetSet.id,
            chapterId: chapterId,
            questionKey: row.questionKey,
            questionText: row.questionText,
            optionA: row.optionA,
            optionB: row.optionB,
            optionC: row.optionC,
            optionD: row.optionD,
            correctOption: row.correctOption,
            explanation: row.explanation,
            language: mediumCode,
            displayOrder: baseOrder + i + 1,
            status: targetSet.status,
          ),
        );
      }

      final newCount = baseOrder + parsed.validCount;
      final idx = _questionSets.indexWhere((s) => s.id == targetSet.id);
      if (idx != -1) {
        _questionSets[idx] = _questionSets[idx].copyWith(questionCount: newCount);
        targetSet = _questionSets[idx];
      }
    }

    _importLogs.insert(
      0,
      McqImportLog(
        id: _uuid.v4(),
        topicId: topicId,
        chapterId: chapterId,
        mediumId: mediumId,
        fileName: fileName,
        fileType: fileType,
        status: 'success',
        totalRows: parsed.totalRows,
        validRows: parsed.validCount,
        invalidRows: 0,
        createdAt: DateTime.now(),
      ),
    );
    _recordLocalAudit(
      actionType: 'IMPORT_MCQS',
      targetType: 'mcq',
      targetName: '$fileName (${parsed.validCount} Qs)',
      newValue: {'set_id': targetSet.id, 'version': targetSet.version},
    );
    return targetSet;
  }

  Future<void> publishQuestionSet(String setId, {required bool publish}) async {
    if (_hasLiveAuthSession) {
      try {
        await _client!.rpc('publish_mcq_question_set', params: {
          'p_set_id': setId,
          'p_action': publish ? 'publish' : 'unpublish',
        });
        return;
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] publishQuestionSet fallback: $e');
      }
    }

    final idx = _questionSets.indexWhere((s) => s.id == setId);
    if (idx == -1) throw Exception('Question set not found.');
    final target = _questionSets[idx];
    final qCount = _mcqQuestions.where((q) => q.questionSetId == setId).length;
    if (publish && qCount < 1) {
      throw Exception('Cannot publish an empty question set.');
    }

    if (publish) {
      for (var i = 0; i < _questionSets.length; i++) {
        final s = _questionSets[i];
        if (s.chapterId == target.chapterId &&
            s.mediumId == target.mediumId &&
            s.isPublished &&
            s.id != setId) {
          _questionSets[i] = s.copyWith(status: 'archived');
        }
      }
    }

    _questionSets[idx] = target.copyWith(
      status: publish ? 'published' : 'draft',
      questionCount: qCount,
      publishedAt: publish ? DateTime.now() : null,
    );
    for (var i = 0; i < _mcqQuestions.length; i++) {
      if (_mcqQuestions[i].questionSetId == setId) {
        _mcqQuestions[i] = _mcqQuestions[i].copyWith(status: publish ? 'published' : 'draft');
      }
    }
  }

  Future<List<McqImportLog>> getImportLogs({String? chapterId}) async {
    if (_hasLiveAuthSession) {
      try {
        var q = _client!.from('mcq_import_logs').select();
        if (chapterId != null) q = q.eq('chapter_id', chapterId);
        final rows = await q.order('created_at', ascending: false).limit(50);
        return (rows as List)
            .map((r) => McqImportLog.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList();
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] getImportLogs fallback: $e');
      }
    }
    return _importLogs
        .where((l) => chapterId == null || l.chapterId == chapterId)
        .toList();
  }

  Future<McqAttemptRecord> submitMcqPracticeAttempt({
    required String userId,
    required String questionSetId,
    required int questionSetVersion,
    required List<LmsMcqQuestion> questions,
    required Map<String, String> selectedAnswers,
  }) async {
    var attempted = 0;
    var correct = 0;
    for (final q in questions) {
      final chosen = selectedAnswers[q.id]?.toUpperCase();
      if (chosen != null && {'A', 'B', 'C', 'D'}.contains(chosen)) {
        attempted++;
        if (chosen == q.correctOption.toUpperCase()) {
          correct++;
        }
      }
    }

    final record = McqAttemptRecord(
      id: _uuid.v4(),
      userId: userId,
      questionSetId: questionSetId,
      questionSetVersion: questionSetVersion,
      totalQuestions: questions.length,
      attemptedCount: attempted,
      correctCount: correct,
      score: correct.toDouble(),
      submittedAt: DateTime.now(),
    );
    _mcqAttempts.insert(0, record);
    return record;
  }

  Future<Set<String>> getUserBookmarks(String userId) async {
    return Set.of(_bookmarksByUser[userId] ?? const <String>{});
  }

  Future<bool> toggleMcqBookmark(String userId, String questionId) async {
    final set = _bookmarksByUser.putIfAbsent(userId, () => <String>{});
    if (set.contains(questionId)) {
      set.remove(questionId);
      return false;
    }
    set.add(questionId);
    return true;
  }

  // ===========================================================================
  // 3. UNTIMED LIVE TESTS, SERVER-STYLE SCORING & LEADERBOARD
  // ===========================================================================

  Future<List<LmsLiveTest>> getLiveTests({bool studentOnly = false}) async {
    if (_hasLiveAuthSession) {
      try {
        var q = _client!.from('live_tests').select();
        if (studentOnly) {
          q = q.inFilter('status', ['published', 'closed']);
        }
        final rows = await q.order('test_date', ascending: false);
        return (rows as List)
            .map((r) => LmsLiveTest.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList();
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] getLiveTests fallback: $e');
      }
    }

    return _liveTests
        .where((t) => !studentOnly || t.isPublished || t.isClosed)
        .map((t) {
          final qCount = _liveTestQuestions.where((q) => q.testId == t.id).length;
          final aCount = _liveTestSubmissions.where((s) => s.testId == t.id).length;
          return t.copyWith(questionCount: qCount, attemptsCount: aCount);
        })
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<LmsLiveTest> createLiveTest({
    required String title,
    String description = '',
    DateTime? testDate,
  }) async {
    final date = testDate ?? DateTime.now();
    if (_hasLiveAuthSession) {
      try {
        final inserted = await _client!
            .from('live_tests')
            .insert({
              'title': title.trim(),
              'description': description.trim(),
              'test_date': date.toIso8601String().split('T').first,
              'status': 'draft',
              'question_count': 0,
              'answers_released': false,
            })
            .select()
            .single();
        return LmsLiveTest.fromJson(Map<String, dynamic>.from(inserted));
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] createLiveTest fallback: $e');
      }
    }

    final test = LmsLiveTest(
      id: _uuid.v4(),
      title: title.trim(),
      description: description.trim(),
      testDate: date,
      status: 'draft',
      createdAt: DateTime.now(),
    );
    _liveTests.insert(0, test);
    _recordLocalAudit(
      actionType: 'CREATE_LIVE_TEST',
      targetType: 'live_test',
      targetName: test.title,
    );
    return test;
  }

  Future<void> updateLiveTest(LmsLiveTest test) async {
    if (_hasLiveAuthSession) {
      try {
        await _client!.from('live_tests').update({
          'title': test.title.trim(),
          'description': test.description.trim(),
          'test_date': test.testDate.toIso8601String().split('T').first,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', test.id);
        return;
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] updateLiveTest fallback: $e');
      }
    }
    final idx = _liveTests.indexWhere((t) => t.id == test.id);
    if (idx != -1) _liveTests[idx] = test;
  }

  Future<void> deleteLiveTest(String testId) async {
    if (_hasLiveAuthSession) {
      try {
        await _client!.from('live_tests').delete().eq('id', testId);
        return;
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] deleteLiveTest fallback: $e');
      }
    }
    _liveTestQuestions.removeWhere((q) => q.testId == testId);
    _liveTestSubmissions.removeWhere((s) => s.testId == testId);
    _liveTests.removeWhere((t) => t.id == testId);
  }

  Future<List<LmsLiveTestQuestion>> getAdminLiveTestQuestions(String testId) async {
    if (_hasLiveAuthSession) {
      try {
        final rows = await _client!
            .from('live_test_questions')
            .select()
            .eq('test_id', testId)
            .order('display_order', ascending: true);
        return (rows as List)
            .map((r) => LmsLiveTestQuestion.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList();
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] getAdminLiveTestQuestions fallback: $e');
      }
    }
    return _liveTestQuestions.where((q) => q.testId == testId).toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  }

  /// Student-safe fetch: strictly omits correctOption and explanation while active!
  Future<List<LmsLiveTestQuestion>> getStudentLiveTestQuestions(String testId) async {
    if (_hasLiveAuthSession) {
      try {
        final rows = await _client!.rpc(
          'get_student_live_test_questions',
          params: {'p_test_id': testId},
        );
        return (rows as List).map((r) {
          final m = Map<String, dynamic>.from(r as Map);
          m.remove('correct_option');
          m.remove('explanation');
          return LmsLiveTestQuestion.fromJson(m);
        }).toList();
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] getStudentLiveTestQuestions fallback: $e');
      }
    }

    final test = _liveTests.firstWhere(
      (t) => t.id == testId,
      orElse: () => throw Exception('Live test not found.'),
    );
    if (!test.isPublished) {
      throw Exception('This live test is not accepting entries right now.');
    }
    return _liveTestQuestions
        .where((q) => q.testId == testId)
        .map((q) => LmsLiveTestQuestion(
              id: q.id,
              testId: q.testId,
              questionKey: q.questionKey,
              questionText: q.questionText,
              optionA: q.optionA,
              optionB: q.optionB,
              optionC: q.optionC,
              optionD: q.optionD,
              correctOption: null, // Strictly hidden!
              explanation: null, // Strictly hidden!
              displayOrder: q.displayOrder,
            ))
        .toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  }

  Future<void> addLiveTestQuestion(LmsLiveTestQuestion q) async {
    if (_hasLiveAuthSession) {
      try {
        await _client!.from('live_test_questions').insert({
          'test_id': q.testId,
          'question_key': q.questionKey,
          'question_text': q.questionText.trim(),
          'option_a': q.optionA.trim(),
          'option_b': q.optionB.trim(),
          'option_c': q.optionC.trim(),
          'option_d': q.optionD.trim(),
          'correct_option': (q.correctOption ?? 'A').toUpperCase(),
          'explanation': q.explanation?.trim(),
          'display_order': q.displayOrder,
        });
        final rows = await _client!
            .from('live_test_questions')
            .select('id')
            .eq('test_id', q.testId);
        await _client!
            .from('live_tests')
            .update({'question_count': (rows as List).length})
            .eq('id', q.testId);
        return;
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] addLiveTestQuestion fallback: $e');
      }
    }

    _liveTestQuestions.add(q.copyWith(id: q.id.isEmpty ? _uuid.v4() : q.id));
    final count = _liveTestQuestions.where((x) => x.testId == q.testId).length;
    final idx = _liveTests.indexWhere((t) => t.id == q.testId);
    if (idx != -1) _liveTests[idx] = _liveTests[idx].copyWith(questionCount: count);
  }

  Future<void> updateLiveTestQuestion(LmsLiveTestQuestion q) async {
    if (_hasLiveAuthSession) {
      try {
        await _client!.from('live_test_questions').update({
          'question_text': q.questionText.trim(),
          'option_a': q.optionA.trim(),
          'option_b': q.optionB.trim(),
          'option_c': q.optionC.trim(),
          'option_d': q.optionD.trim(),
          'correct_option': (q.correctOption ?? 'A').toUpperCase(),
          'explanation': q.explanation?.trim(),
        }).eq('id', q.id);
        return;
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] updateLiveTestQuestion fallback: $e');
      }
    }
    final idx = _liveTestQuestions.indexWhere((x) => x.id == q.id);
    if (idx != -1) _liveTestQuestions[idx] = q;
  }

  Future<void> deleteLiveTestQuestion(String questionId, String testId) async {
    if (_hasLiveAuthSession) {
      try {
        await _client!.from('live_test_questions').delete().eq('id', questionId);
        final rows = await _client!
            .from('live_test_questions')
            .select('id')
            .eq('test_id', testId);
        await _client!
            .from('live_tests')
            .update({'question_count': (rows as List).length})
            .eq('id', testId);
        return;
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] deleteLiveTestQuestion fallback: $e');
      }
    }

    _liveTestQuestions.removeWhere((x) => x.id == questionId);
    final count = _liveTestQuestions.where((x) => x.testId == testId).length;
    final idx = _liveTests.indexWhere((t) => t.id == testId);
    if (idx != -1) _liveTests[idx] = _liveTests[idx].copyWith(questionCount: count);
  }

  Future<void> clearLiveTestQuestions(String testId) async {
    if (_hasLiveAuthSession) {
      try {
        await _client!.from('live_test_questions').delete().eq('test_id', testId);
        await _client!.from('live_tests').update({'question_count': 0}).eq('id', testId);
        return;
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] clearLiveTestQuestions fallback: $e');
      }
    }
    _liveTestQuestions.removeWhere((x) => x.testId == testId);
    final idx = _liveTests.indexWhere((t) => t.id == testId);
    if (idx != -1) _liveTests[idx] = _liveTests[idx].copyWith(questionCount: 0);
  }

  Future<int> importLiveTestQuestions({
    required String testId,
    required ImportParseResult parsed,
    required bool replaceExisting,
  }) async {
    if (!parsed.isValid) {
      throw Exception('Import blocked: ${parsed.invalidCount} validation error(s).');
    }

    if (replaceExisting) {
      await clearLiveTestQuestions(testId);
    }

    final existingCount = (await getAdminLiveTestQuestions(testId)).length;
    for (var i = 0; i < parsed.validQuestions.length; i++) {
      final r = parsed.validQuestions[i];
      await addLiveTestQuestion(
        LmsLiveTestQuestion(
          id: _uuid.v4(),
          testId: testId,
          questionKey: r.questionKey,
          questionText: r.questionText,
          optionA: r.optionA,
          optionB: r.optionB,
          optionC: r.optionC,
          optionD: r.optionD,
          correctOption: r.correctOption,
          explanation: r.explanation,
          displayOrder: existingCount + i + 1,
        ),
      );
    }
    _recordLocalAudit(
      actionType: 'IMPORT_LIVE_TEST_QUESTIONS',
      targetType: 'live_test',
      targetName: '$testId (${parsed.validCount} Qs)',
    );
    return parsed.validCount;
  }

  Future<void> setLiveTestStatus(String testId, String status) async {
    final questions = await getAdminLiveTestQuestions(testId);
    if (status == 'published' && questions.isEmpty) {
      throw Exception('Cannot make live: add at least 1 question first.');
    }

    if (_hasLiveAuthSession) {
      try {
        await _client!.from('live_tests').update({
          'status': status,
          'question_count': questions.length,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', testId);
        return;
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] setLiveTestStatus fallback: $e');
      }
    }

    final idx = _liveTests.indexWhere((t) => t.id == testId);
    if (idx != -1) {
      _liveTests[idx] = _liveTests[idx].copyWith(
        status: status,
        questionCount: questions.length,
      );
    }
    _recordLocalAudit(
      actionType: 'LIVE_TEST_STATUS',
      targetType: 'live_test',
      targetName: testId,
      newValue: {'status': status},
    );
  }

  Future<void> setLiveTestAnswersReleased(
    String testId,
    bool released,
  ) async {
    if (_hasLiveAuthSession) {
      await _client!.from('live_tests').update({
        'answers_released': released,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', testId);
      return;
    }

    final idx = _liveTests.indexWhere((t) => t.id == testId);
    if (idx != -1) {
      _liveTests[idx] = _liveTests[idx].copyWith(answersReleased: released);
    }
    _recordLocalAudit(
      actionType: 'RELEASE_LIVE_TEST_ANSWERS',
      targetType: 'live_test',
      targetName: testId,
      newValue: {'answers_released': released},
    );
  }

  Future<LmsLiveTestSubmission> submitStudentLiveTest({
    required String testId,
    required String studentName,
    required String phoneNumber,
    required String location,
    required String email,
    required Map<String, String> answers,
  }) async {
    final cleanDigits = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final normalizedPhone = cleanDigits.length > 10
        ? cleanDigits.substring(cleanDigits.length - 10)
        : cleanDigits;
    if (normalizedPhone.length < 10) {
      throw Exception('A valid 10-digit phone number is required.');
    }

    if (_hasLiveAuthSession) {
      try {
        final result = await _client!.rpc('submit_live_test', params: {
          'p_test_id': testId,
          'p_student_name': studentName.trim(),
          'p_phone_number': normalizedPhone,
          'p_location': location.trim(),
          'p_email': email.trim(),
          'p_answers': answers,
        });
        final m = Map<String, dynamic>.from(result as Map);
        return LmsLiveTestSubmission(
          id: m['submission_id']?.toString() ?? _uuid.v4(),
          testId: testId,
          userId: AuthService().currentUser?.id,
          studentName: studentName.trim(),
          phoneNumber: normalizedPhone,
          location: location.trim(),
          email: email.trim(),
          totalQuestions: (m['total_questions'] as num?)?.toInt() ?? 0,
          attemptedCount: (m['attempted_count'] as num?)?.toInt() ?? 0,
          correctCount: (m['correct_count'] as num?)?.toInt() ?? 0,
          wrongCount: (m['wrong_count'] as num?)?.toInt() ?? 0,
          marksObtained: (m['marks_obtained'] as num?)?.toDouble() ?? 0,
          percentage: (m['percentage'] as num?)?.toDouble() ?? 0,
          answers: answers,
          submittedAt: DateTime.now(),
        );
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] submitStudentLiveTest fallback: $e');
      }
    }

    final test = _liveTests.firstWhere(
      (t) => t.id == testId,
      orElse: () => throw Exception('Live test not found.'),
    );
    if (!test.isPublished) {
      throw Exception('Submissions are closed for this test.');
    }

    final questions = _liveTestQuestions.where((q) => q.testId == testId).toList();
    var attempted = 0;
    var correct = 0;
    for (final q in questions) {
      final chosen = answers[q.id]?.toUpperCase();
      if (chosen != null && {'A', 'B', 'C', 'D'}.contains(chosen)) {
        attempted++;
        if (chosen == (q.correctOption ?? '').toUpperCase()) {
          correct++;
        }
      }
    }
    final wrong = attempted - correct;
    final pct = questions.isNotEmpty
        ? double.parse(((correct / questions.length) * 100).toStringAsFixed(2))
        : 0.0;

    final sub = LmsLiveTestSubmission(
      id: _uuid.v4(),
      testId: testId,
      userId: AuthService().currentUser?.id,
      studentName: studentName.trim(),
      phoneNumber: normalizedPhone,
      location: location.trim(),
      email: email.trim(),
      totalQuestions: questions.length,
      attemptedCount: attempted,
      correctCount: correct,
      wrongCount: wrong,
      marksObtained: correct.toDouble(),
      percentage: pct,
      answers: Map<String, String>.from(answers),
      submittedAt: DateTime.now(),
    );

    final existingIdx = _liveTestSubmissions.indexWhere(
      (s) => s.testId == testId && s.phoneNumber == normalizedPhone,
    );
    if (existingIdx != -1) {
      _liveTestSubmissions[existingIdx] = sub;
    } else {
      _liveTestSubmissions.add(sub);
    }
    return sub;
  }

  Future<List<LmsLiveTestQuestion>> getStudentLiveTestAnswers(String testId) async {
    if (_hasLiveAuthSession) {
      try {
        final rows = await _client!.rpc(
          'get_live_test_answers',
          params: {'p_test_id': testId},
        );
        return (rows as List)
            .map((r) => LmsLiveTestQuestion.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList();
      } catch (e) {
        if (e.toString().contains('ANSWERS_NOT_RELEASED')) {
          throw Exception('ANSWERS_NOT_RELEASED');
        }
        if (kDebugMode) print('[LmsAdminService] getStudentLiveTestAnswers fallback: $e');
      }
    }

    final test = _liveTests.firstWhere(
      (t) => t.id == testId,
      orElse: () => throw Exception('Live test not found.'),
    );
    if (!test.answersReleased) {
      throw Exception('ANSWERS_NOT_RELEASED: Answer key has not been released yet.');
    }
    return _liveTestQuestions.where((q) => q.testId == testId).toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  }

  Future<List<LmsLiveTestSubmission>> getLiveTestResults(String testId) async {
    List<LmsLiveTestSubmission> list;
    if (_hasLiveAuthSession) {
      try {
        final rows = await _client!
            .from('live_test_submissions')
            .select()
            .eq('test_id', testId)
            .order('marks_obtained', ascending: false)
            .order('submitted_at', ascending: true);
        list = (rows as List)
            .map((r) => LmsLiveTestSubmission.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList();
        return List.generate(list.length, (i) => list[i].copyWith(rank: i + 1));
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] getLiveTestResults fallback: $e');
      }
    }

    list = _liveTestSubmissions.where((s) => s.testId == testId).toList()
      ..sort((a, b) {
        final cmp = b.marksObtained.compareTo(a.marksObtained);
        if (cmp != 0) return cmp;
        return a.submittedAt.compareTo(b.submittedAt);
      });
    return List.generate(list.length, (i) => list[i].copyWith(rank: i + 1));
  }

  // ===========================================================================
  // 4. NOTES FOLDERS & PRIVATE 4-STATE PDF ACCESS CONTROL
  // ===========================================================================

  Future<List<NoteFolder>> getNoteFolders() async {
    if (_hasLiveAuthSession) {
      try {
        final rows = await _client!.from('note_folders').select().order('name');
        return (rows as List)
            .map((r) => NoteFolder.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList();
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] getNoteFolders fallback: $e');
      }
    }
    return List.of(_noteFolders)..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<NoteFolder> createNoteFolder({
    required String name,
    String? parentId,
  }) async {
    if (_hasLiveAuthSession) {
      try {
        final inserted = await _client!
            .from('note_folders')
            .insert({
              'name': name.trim(),
              'parent_id': parentId,
            })
            .select()
            .single();
        return NoteFolder.fromJson(Map<String, dynamic>.from(inserted));
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] createNoteFolder fallback: $e');
      }
    }

    final folder = NoteFolder(
      id: _uuid.v4(),
      name: name.trim(),
      parentId: parentId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _noteFolders.add(folder);
    return folder;
  }

  Future<void> updateNoteFolder({
    required String id,
    required String name,
    String? newParentId,
    required List<NoteFolder> allFolders,
  }) async {
    if (newParentId == id) {
      throw Exception('A folder cannot be moved inside itself.');
    }
    // Loop prevention: verify target id is not an ancestor of newParentId
    var cursor = newParentId;
    final visited = <String>{id};
    while (cursor != null) {
      if (!visited.add(cursor)) {
        throw Exception('Cannot move a folder into its own subfolder.');
      }
      final parent = allFolders.where((f) => f.id == cursor).firstOrNull;
      cursor = parent?.parentId;
    }

    if (_hasLiveAuthSession) {
      try {
        await _client!.from('note_folders').update({
          'name': name.trim(),
          'parent_id': newParentId,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', id);
        return;
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] updateNoteFolder fallback: $e');
      }
    }

    final idx = _noteFolders.indexWhere((f) => f.id == id);
    if (idx != -1) {
      _noteFolders[idx] = _noteFolders[idx].copyWith(
        name: name.trim(),
        parentId: newParentId,
        clearParentId: newParentId == null,
        updatedAt: DateTime.now(),
      );
    }
  }

  Future<void> deleteNoteFolderTree(String folderId) async {
    if (_hasLiveAuthSession) {
      final res = await _client!.functions.invoke(
        'admin-audit-ops',
        body: {'action': 'delete_folder_tree', 'folderId': folderId},
      );
      if (res.status < 400) return;
      await _client!.rpc('delete_note_folder_tree', params: {'p_folder_id': folderId});
      return;
    }

    final toDelete = <String>{folderId};
    final queue = <String>[folderId];
    while (queue.isNotEmpty) {
      final cur = queue.removeAt(0);
      for (final child in _noteFolders.where((f) => f.parentId == cur)) {
        if (toDelete.add(child.id)) queue.add(child.id);
      }
    }

    final removedNotes = _pdfMaterials.where((n) => toDelete.contains(n.folderId)).toList();
    for (final n in removedNotes) {
      _localPdfBytes.remove(n.id);
    }
    _pdfMaterials.removeWhere((n) => toDelete.contains(n.folderId));
    _noteFolders.removeWhere((f) => toDelete.contains(f.id));
    _recordLocalAudit(
      actionType: 'DELETE_NOTE_FOLDER_TREE',
      targetType: 'notes',
      targetName: folderId,
      previousValue: {'removedNotes': removedNotes.length},
    );
  }

  Future<List<PdfMaterial>> getNotes() async {
    if (_hasLiveAuthSession) {
      try {
        final rows = await _client!
            .from('pdf_materials')
            .select(
              'id, title, description, category_code, file_size, pages_count, is_free, download_count, allow_download, is_previewable, folder_id, created_at',
            )
            .order('created_at', ascending: false);
        return (rows as List)
            .map((r) => PdfMaterial.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList();
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] getNotes fallback: $e');
      }
    }
    return List.of(_pdfMaterials)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<PdfMaterial> uploadNote({
    required String title,
    String description = '',
    required String? folderId,
    required Uint8List fileBytes,
    required String fileName,
    bool isPreviewable = true,
    bool allowDownload = false,
  }) async {
    if (fileBytes.lengthInBytes > SizeFormatter.maxNoteBytes) {
      throw Exception('PDF exceeds maximum allowed size of 50 MB.');
    }
    if (!fileName.toLowerCase().endsWith('.pdf')) {
      throw Exception('Only .pdf files are supported.');
    }

    final storageKey = SizeFormatter.sanitizeStorageKey(fileName);
    final formattedSize = SizeFormatter.formatBytes(fileBytes.lengthInBytes);

    if (_hasLiveAuthSession) {
      try {
        await _client!.storage.from('notes').uploadBinary(
              storageKey,
              fileBytes,
              fileOptions: const FileOptions(contentType: 'application/pdf', upsert: true),
            );
        final inserted = await _client!
            .from('pdf_materials')
            .insert({
              'title': title.trim(),
              'description': description.trim(),
              'category_code': 'NOTES',
              'storage_path': storageKey,
              'pdf_url': storageKey,
              'file_size': formattedSize,
              'pages_count': 1,
              'is_free': true,
              'allow_download': allowDownload,
              'is_previewable': isPreviewable,
              'folder_id': folderId,
            })
            .select()
            .single();
        return PdfMaterial.fromJson(Map<String, dynamic>.from(inserted));
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] uploadNote fallback: $e');
      }
    }

    final id = _uuid.v4();
    _localPdfBytes[id] = fileBytes;
    final note = PdfMaterial(
      id: id,
      title: title.trim(),
      description: description.trim(),
      storagePath: storageKey,
      pdfUrl: storageKey,
      fileSize: formattedSize,
      allowDownload: allowDownload,
      isPreviewable: isPreviewable,
      folderId: folderId,
      createdAt: DateTime.now(),
    );
    _pdfMaterials.insert(0, note);
    _recordLocalAudit(
      actionType: 'UPLOAD_NOTE',
      targetType: 'notes',
      targetName: note.title,
      newValue: {
        'is_previewable': isPreviewable,
        'allow_download': allowDownload,
        'file_size': formattedSize,
      },
    );
    return note;
  }

  Future<void> updateNote(
    PdfMaterial note, {
    Uint8List? replacementBytes,
    String? replacementFileName,
  }) async {
    var updated = note;
    if (replacementBytes != null && replacementFileName != null) {
      if (replacementBytes.lengthInBytes > SizeFormatter.maxNoteBytes) {
        throw Exception('PDF exceeds maximum allowed size of 50 MB.');
      }
      final newKey = SizeFormatter.sanitizeStorageKey(replacementFileName);
      final newSize = SizeFormatter.formatBytes(replacementBytes.lengthInBytes);
      if (_hasLiveAuthSession) {
        await _client!.storage.from('notes').uploadBinary(
              newKey,
              replacementBytes,
              fileOptions: const FileOptions(contentType: 'application/pdf', upsert: true),
            );
      } else {
        _localPdfBytes[note.id] = replacementBytes;
      }
      updated = updated.copyWith(
        storagePath: newKey,
        pdfUrl: newKey,
        fileSize: newSize,
      );
    }

    if (_hasLiveAuthSession) {
      try {
        await _client!.from('pdf_materials').update({
          'title': updated.title.trim(),
          'description': updated.description.trim(),
          'folder_id': updated.folderId,
          'allow_download': updated.allowDownload,
          'is_previewable': updated.isPreviewable,
          if (replacementBytes != null) 'storage_path': updated.storagePath,
          if (replacementBytes != null) 'pdf_url': updated.pdfUrl,
          if (replacementBytes != null) 'file_size': updated.fileSize,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', updated.id);
        return;
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] updateNote fallback: $e');
      }
    }

    final idx = _pdfMaterials.indexWhere((n) => n.id == updated.id);
    if (idx != -1) _pdfMaterials[idx] = updated;
  }

  Future<void> deleteNote(String noteId) async {
    if (_hasLiveAuthSession) {
      try {
        final res = await _client!.functions.invoke(
          'admin-audit-ops',
          body: {'action': 'delete_note', 'noteId': noteId},
        );
        if (res.status < 400) return;
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] deleteNote edge fallback: $e');
      }
      await _client!.from('pdf_materials').delete().eq('id', noteId);
      return;
    }

    _localPdfBytes.remove(noteId);
    _pdfMaterials.removeWhere((n) => n.id == noteId);
  }

  /// Fetches PDF bytes strictly enforcing is_previewable.
  Future<Uint8List> fetchNotePreviewBytes(PdfMaterial note) async {
    if (!note.isPreviewable) {
      throw Exception('PREVIEW_DISABLED: Preview is disabled for this document.');
    }

    if (_hasLiveAuthSession) {
      final token = _client!.auth.currentSession?.accessToken ?? '';
      final uri = Uri.parse('${AppConstants.supabaseUrl}/functions/v1/notes-access?noteId=${note.id}&mode=preview');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'apikey': AppConstants.supabaseAnonKey,
        },
      );
      if (response.statusCode == 403) {
        throw Exception('PREVIEW_DISABLED: Preview is disabled by administrator.');
      }
      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'] ?? '';
        if (contentType.contains('application/pdf')) {
          return response.bodyBytes;
        }
        // Signed URL JSON response when allow_download == true
        final signedRes = await _client!.functions.invoke(
          'notes-access',
          body: {'noteId': note.id, 'mode': 'preview'},
        );
        final signedUrl = signedRes.data?['signedUrl']?.toString();
        if (signedUrl != null && signedUrl.isNotEmpty) {
          final fileRes = await http.get(Uri.parse(signedUrl));
          if (fileRes.statusCode == 200) return fileRes.bodyBytes;
        }
      }
      throw Exception('Unable to load protected PDF preview (${response.statusCode}).');
    }

    final bytes = _localPdfBytes[note.id];
    if (bytes != null) return bytes;
    throw Exception('Local preview bytes not available. Upload a PDF file to preview.');
  }

  /// Fetches downloadable PDF bytes/URL strictly enforcing allow_download.
  Future<({Uint8List? bytes, String? signedUrl, String fileName})> requestNoteDownload(
    PdfMaterial note,
  ) async {
    if (!note.allowDownload) {
      throw Exception('DOWNLOAD_DISABLED: Download is disabled for this document.');
    }

    if (_hasLiveAuthSession) {
      final res = await _client!.functions.invoke(
        'notes-access',
        body: {'noteId': note.id, 'mode': 'download'},
      );
      if (res.status == 403) {
        throw Exception('DOWNLOAD_DISABLED');
      }
      if (res.status >= 400 || res.data is! Map) {
        throw Exception('Could not authorize PDF download.');
      }
      final signedUrl = res.data['signedUrl']?.toString();
      final fileName = res.data['fileName']?.toString() ?? '${note.title}.pdf';
      return (bytes: null, signedUrl: signedUrl, fileName: fileName);
    }

    final idx = _pdfMaterials.indexWhere((n) => n.id == note.id);
    if (idx != -1) {
      _pdfMaterials[idx] =
          _pdfMaterials[idx].copyWith(downloadCount: _pdfMaterials[idx].downloadCount + 1);
    }
    final safeName = '${note.title.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}.pdf';
    return (bytes: _localPdfBytes[note.id], signedUrl: null, fileName: safeName);
  }

  // ===========================================================================
  // 5. STUDENTS DIRECTORY (LMS ATTEMPTS ONLY — NO E-COMMERCE)
  // ===========================================================================

  Future<List<LmsStudentSummary>> getStudentsDirectory({String search = ''}) async {
    final q = search.trim().toLowerCase();
    if (_hasLiveAuthSession) {
      try {
        final usersRows = await _client!
            .from('users')
            .select('id, name, email, phone, role, created_at')
            .order('created_at', ascending: false);
        final attemptsRows = await _client!.from('mcq_attempts').select();
        final subRows = await _client!.from('live_test_submissions').select();
        final bmRows = await _client!.from('mcq_bookmarks').select('user_id');

        final attemptsByUser = <String, List<McqAttemptRecord>>{};
        for (final r in attemptsRows as List) {
          final rec = McqAttemptRecord.fromJson(Map<String, dynamic>.from(r as Map));
          attemptsByUser.putIfAbsent(rec.userId, () => []).add(rec);
        }

        final subsByUser = <String, List<LmsLiveTestSubmission>>{};
        for (final r in subRows as List) {
          final sub = LmsLiveTestSubmission.fromJson(Map<String, dynamic>.from(r as Map));
          if (sub.userId != null) {
            subsByUser.putIfAbsent(sub.userId!, () => []).add(sub);
          }
        }

        final bmCounts = <String, int>{};
        for (final r in bmRows as List) {
          final uid = r['user_id']?.toString() ?? '';
          if (uid.isNotEmpty) bmCounts[uid] = (bmCounts[uid] ?? 0) + 1;
        }

        return (usersRows as List)
            .map((r) {
              final m = Map<String, dynamic>.from(r as Map);
              final id = m['id']?.toString() ?? '';
              return LmsStudentSummary.fromJson(
                m,
                mcqAttempts: attemptsByUser[id] ?? const [],
                liveTestSubmissions: subsByUser[id] ?? const [],
                bookmarkCount: bmCounts[id] ?? 0,
              );
            })
            .where((u) =>
                q.isEmpty ||
                u.name.toLowerCase().contains(q) ||
                u.email.toLowerCase().contains(q) ||
                u.phone.toLowerCase().contains(q))
            .toList();
      } catch (e) {
        if (kDebugMode) print('[LmsAdminService] getStudentsDirectory fallback: $e');
      }
    }

    return _localUsers
        .map((m) {
          final id = m['id']?.toString() ?? '';
          final email = m['email']?.toString() ?? '';
          final attempts = _mcqAttempts.where((a) => a.userId == id).toList();
          final subs = _liveTestSubmissions
              .where((s) => s.userId == id || s.email.toLowerCase() == email.toLowerCase())
              .toList();
          final bms = _bookmarksByUser[id]?.length ?? 0;
          return LmsStudentSummary.fromJson(
            m,
            mcqAttempts: attempts,
            liveTestSubmissions: subs,
            bookmarkCount: bms,
          );
        })
        .where((u) =>
            q.isEmpty ||
            u.name.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q) ||
            u.phone.toLowerCase().contains(q))
        .toList();
  }
}
