import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/exam.dart';
import '../models/chapter.dart';
import '../models/question.dart';
import '../models/live_test.dart';
import '../models/video_lesson.dart';
import '../models/study_note.dart';
import '../core/constants.dart';
import 'mock_data.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> initialize({String? supabaseUrl, String? supabaseAnonKey}) async {
    String url = supabaseUrl ?? const String.fromEnvironment('SUPABASE_URL');
    if (url.isEmpty) {
      url = AppConstants.supabaseUrl;
    }

    String anonKey = supabaseAnonKey ?? const String.fromEnvironment('SUPABASE_ANON_KEY');
    if (anonKey.isEmpty) {
      anonKey = AppConstants.supabaseAnonKey;
    }

    if (url.isNotEmpty && anonKey.isNotEmpty && !url.contains('placeholder') && !url.contains('your-tenali-post')) {
      try {
        await Supabase.initialize(url: url.trim(), publishableKey: anonKey.trim());
        _isInitialized = true;
        if (kDebugMode) {
          print('[SupabaseService] Connected to dedicated Supabase project: $url');
        }
      } catch (e) {
        _isInitialized = false;
        if (kDebugMode) {
          print('[SupabaseService] Initialization warning, operating in local mock mode: $e');
        }
      }
    } else {
      _isInitialized = false;
      if (kDebugMode) {
        print('[SupabaseService] Operating in local offline/mock mode until credentials are provided.');
      }
    }
  }

  Future<bool> connectWithKeys({required String url, required String anonKey}) async {
    try {
      final cleanUrl = url.trim();
      final cleanKey = anonKey.trim();
      if (cleanUrl.isEmpty || cleanKey.isEmpty) return false;

      await Supabase.initialize(url: cleanUrl, publishableKey: cleanKey);
      _isInitialized = true;
      return true;
    } catch (e) {
      if (kDebugMode) print('[SupabaseService] Manual connect error: $e');
      return false;
    }
  }

  SupabaseClient? get client => _isInitialized ? Supabase.instance.client : null;

  // Exams
  Future<List<Exam>> getExams() async {
    if (_isInitialized && client != null) {
      try {
        final response = await client!.from('exams').select().order('created_at');
        return (response as List).map((json) => Exam.fromJson(json)).toList();
      } catch (e) {
        if (kDebugMode) print('[SupabaseService] Error loading exams, using fallback: $e');
      }
    }
    return MockData.exams;
  }

  // Chapters
  Future<List<Chapter>> getChapters(String examId) async {
    if (_isInitialized && client != null) {
      try {
        final response = await client!
            .from('chapters')
            .select()
            .eq('exam_id', examId)
            .order('chapter_number');
        return (response as List).map((json) => Chapter.fromJson(json)).toList();
      } catch (e) {
        if (kDebugMode) print('[SupabaseService] Error loading chapters, using fallback: $e');
      }
    }
    return MockData.chapters.where((c) => c.examId == examId).toList();
  }

  // Questions for Practice
  Future<List<Question>> getPracticeQuestions({
    required String chapterId,
    required String languageCode,
  }) async {
    if (_isInitialized && client != null) {
      try {
        final response = await client!
            .from('questions')
            .select()
            .eq('chapter_id', chapterId)
            .eq('language_code', languageCode)
            .order('question_number');
        return (response as List).map((json) => Question.fromJson(json)).toList();
      } catch (e) {
        if (kDebugMode) print('[SupabaseService] Error loading questions, using fallback: $e');
      }
    }
    return MockData.sampleQuestions
        .where((q) => q.chapterId == chapterId && q.languageCode == languageCode)
        .toList();
  }

  // Live Tests
  Future<List<LiveTest>> getLiveTests() async {
    if (_isInitialized && client != null) {
      try {
        final response = await client!
            .from('live_tests')
            .select()
            .eq('is_published', true)
            .order('start_time', ascending: false);
        return (response as List).map((json) => LiveTest.fromJson(json)).toList();
      } catch (e) {
        if (kDebugMode) print('[SupabaseService] Error loading live tests, using fallback: $e');
      }
    }
    return MockData.liveTests;
  }

  // Secure Live Test Question Retrieval (Never leaks answer key)
  Future<List<Question>> getLiveTestQuestions(String testId) async {
    if (_isInitialized && client != null) {
      try {
        // RPC or view that excludes correct_option and explanation
        final response = await client!
            .from('live_test_questions_safe')
            .select()
            .eq('test_id', testId)
            .order('question_number');
        return (response as List).map((json) => Question.fromJson(json)).toList();
      } catch (e) {
        if (kDebugMode) print('[SupabaseService] Error loading live test questions: $e');
      }
    }
    // Return sample questions with answer keys stripped
    return MockData.sampleQuestions.map((q) => Question(
      id: q.id,
      chapterId: q.chapterId,
      examId: q.examId,
      languageCode: q.languageCode,
      questionText: q.questionText,
      optionA: q.optionA,
      optionB: q.optionB,
      optionC: q.optionC,
      optionD: q.optionD,
      questionNumber: q.questionNumber,
      correctOption: null, // Protected!
      explanation: null,   // Protected!
    )).toList();
  }

  // Submit Live Test
  Future<LiveTestSubmission> submitLiveTest({
    required String testId,
    required String studentName,
    required String phoneNumber,
    required Map<String, String> answers,
  }) async {
    // Client-side scoring calculation for local mock demonstration
    // On production backend, this is evaluated server-side via Supabase Edge Function
    int correct = 0;
    int wrong = 0;
    int skipped = 0;

    for (var q in MockData.sampleQuestions) {
      if (answers.containsKey(q.id)) {
        final chosen = answers[q.id]?.toUpperCase();
        if (chosen != null && chosen.isNotEmpty) {
          if (chosen == q.correctOption?.toUpperCase()) {
            correct++;
          } else {
            wrong++;
          }
        } else {
          skipped++;
        }
      } else {
        skipped++;
      }
    }

    final double marks = (correct * 1.0) - (wrong * 0.0);
    final double totalMarks = MockData.sampleQuestions.length * 1.0;
    final double percentage = totalMarks > 0 ? (marks / totalMarks) * 100 : 0.0;

    final submission = LiveTestSubmission(
      id: 'sub-${DateTime.now().millisecondsSinceEpoch}',
      testId: testId,
      studentName: studentName,
      phoneNumber: phoneNumber,
      marksObtained: marks,
      totalMarks: totalMarks,
      correctCount: correct,
      wrongCount: wrong,
      skippedCount: skipped,
      percentage: percentage,
      rank: 1,
      answers: answers,
      submittedAt: DateTime.now(),
    );

    if (_isInitialized && client != null) {
      try {
        await client!.from('live_test_submissions').insert(submission.toJson());
      } catch (e) {
        if (kDebugMode) print('[SupabaseService] Remote submission error: $e');
      }
    }

    return submission;
  }

  // Videos
  Future<List<VideoLesson>> getVideos(String examId) async {
    if (_isInitialized && client != null) {
      try {
        final response = await client!.from('videos').select().eq('exam_id', examId);
        return (response as List).map((json) => VideoLesson.fromJson(json)).toList();
      } catch (e) {
        if (kDebugMode) print('[SupabaseService] Error loading videos: $e');
      }
    }
    return MockData.videoLessons.where((v) => v.examId == examId).toList();
  }

  // Notes
  Future<List<StudyNote>> getNotes(String examId) async {
    if (_isInitialized && client != null) {
      try {
        final response = await client!.from('notes').select().eq('exam_id', examId);
        return (response as List).map((json) => StudyNote.fromJson(json)).toList();
      } catch (e) {
        if (kDebugMode) print('[SupabaseService] Error loading notes: $e');
      }
    }
    return MockData.studyNotes.where((n) => n.examId == examId).toList();
  }
}
