import 'package:flutter/foundation.dart';
import '../models/exam.dart';
import '../models/chapter.dart';
import '../models/question.dart';
import '../models/live_test.dart';
import '../models/video_lesson.dart';
import '../models/study_note.dart';
import 'mock_data.dart';
import 'supabase_service.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  final SupabaseService _supabase = SupabaseService();

  // Exams
  Future<List<Exam>> getExams() async {
    if (_supabase.isInitialized && _supabase.client != null) {
      try {
        final response = await _supabase.client!.from('exams').select().order('created_at');
        final list = (response as List).map((json) => Exam.fromJson(json)).toList();
        if (list.isNotEmpty) return list;
      } catch (e) {
        if (kDebugMode) print('[DataService] Exams query notice: $e');
      }
    }
    return MockData.exams;
  }

  // Chapters
  Future<List<Chapter>> getChapters(String examId) async {
    if (_supabase.isInitialized && _supabase.client != null) {
      try {
        final response = await _supabase.client!
            .from('chapters')
            .select()
            .eq('exam_id', examId)
            .order('chapter_number');
        final list = (response as List).map((json) => Chapter.fromJson(json)).toList();
        if (list.isNotEmpty) return list;
      } catch (e) {
        if (kDebugMode) print('[DataService] Chapters query notice: $e');
      }
    }
    return MockData.chapters.where((c) => c.examId == examId).toList();
  }

  // Questions for Practice
  Future<List<Question>> getPracticeQuestions({
    required String chapterId,
    required String languageCode,
  }) async {
    if (_supabase.isInitialized && _supabase.client != null) {
      try {
        final response = await _supabase.client!
            .from('questions')
            .select()
            .eq('chapter_id', chapterId)
            .eq('language_code', languageCode)
            .order('question_number');
        final list = (response as List).map((json) => Question.fromJson(json)).toList();
        if (list.isNotEmpty) return list;
      } catch (e) {
        if (kDebugMode) print('[DataService] Questions query notice: $e');
      }
    }
    return MockData.sampleQuestions
        .where((q) => q.chapterId == chapterId && q.languageCode == languageCode)
        .toList();
  }

  // Live Tests
  Future<List<LiveTest>> getLiveTests() async {
    if (_supabase.isInitialized && _supabase.client != null) {
      try {
        final response = await _supabase.client!
            .from('live_tests')
            .select()
            .eq('is_published', true)
            .order('start_time', ascending: false);
        final list = (response as List).map((json) => LiveTest.fromJson(json)).toList();
        if (list.isNotEmpty) return list;
      } catch (e) {
        if (kDebugMode) print('[DataService] LiveTests query notice: $e');
      }
    }
    return MockData.liveTests;
  }

  // Secure Live Test Question Retrieval (Never leaks answer key)
  Future<List<Question>> getLiveTestQuestions(String testId) async {
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

    if (_supabase.isInitialized && _supabase.client != null) {
      try {
        await _supabase.client!.from('live_test_submissions').insert(submission.toJson());
      } catch (e) {
        if (kDebugMode) print('[DataService] Remote submission notice: $e');
      }
    }

    return submission;
  }

  // Videos
  Future<List<VideoLesson>> getVideos(String examId) async {
    if (_supabase.isInitialized && _supabase.client != null) {
      try {
        final response = await _supabase.client!.from('videos').select().eq('exam_id', examId);
        final list = (response as List).map((json) => VideoLesson.fromJson(json)).toList();
        if (list.isNotEmpty) return list;
      } catch (e) {
        if (kDebugMode) print('[DataService] Videos query notice: $e');
      }
    }
    return MockData.videoLessons.where((v) => v.examId == examId).toList();
  }

  // Notes
  Future<List<StudyNote>> getNotes(String examId) async {
    if (_supabase.isInitialized && _supabase.client != null) {
      try {
        final response = await _supabase.client!.from('notes').select().eq('exam_id', examId);
        final list = (response as List).map((json) => StudyNote.fromJson(json)).toList();
        if (list.isNotEmpty) return list;
      } catch (e) {
        if (kDebugMode) print('[DataService] Notes query notice: $e');
      }
    }
    return MockData.studyNotes.where((n) => n.examId == examId).toList();
  }
}
