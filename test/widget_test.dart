import 'package:flutter_test/flutter_test.dart';
import 'package:tenali_post/models/question.dart';
import 'package:tenali_post/models/live_test.dart';
import 'package:tenali_post/models/exam.dart';
import 'package:tenali_post/services/mock_data.dart';
import 'package:tenali_post/services/data_service.dart';
import 'package:tenali_post/services/auth_service.dart';
import 'package:tenali_post/providers/auth_provider.dart';
import 'package:tenali_post/core/constants.dart';
import 'package:tenali_post/services/supabase_service.dart';

void main() {
  group('Tenali Post Architecture & Model Tests', () {
    test('Question model serializes and hides answer key when requested', () {
      const q = Question(
        id: 'q-test-1',
        chapterId: 'ch-1',
        examId: 'mts',
        languageCode: 'en',
        questionText: 'Test Postal Question?',
        optionA: 'Option 1',
        optionB: 'Option 2',
        optionC: 'Option 3',
        optionD: 'Option 4',
        correctOption: 'B',
        explanation: 'Detailed postal explanation',
      );

      expect(q.hasAnswerKey, true);
      expect(q.getOptionText('B'), 'Option 2');

      // Check security: when answer key is omitted for active live tests
      final safeJson = q.toJson(includeAnswer: false);
      expect(safeJson.containsKey('correct_option'), false);
      expect(safeJson.containsKey('explanation'), false);
    });

    test('LiveTest model correctly determines ongoing and upcoming status', () {
      final now = DateTime.now();
      final ongoingTest = LiveTest(
        id: 'test-1',
        title: 'Active Live Test',
        description: 'Test Description',
        examId: 'mts',
        startTime: now.subtract(const Duration(minutes: 10)),
        endTime: now.add(const Duration(minutes: 50)),
        durationMinutes: 60,
        totalMarks: 60,
        totalQuestions: 60,
        passMarks: 24,
        isPublished: true,
      );

      expect(ongoingTest.isOngoing, true);
      expect(ongoingTest.isEnded, false);
      expect(ongoingTest.isUpcoming, false);
    });

    test('Exam model contains valid India Post departmental data', () {
      expect(MockData.exams.isNotEmpty, true);
      final Exam mts = MockData.exams.firstWhere((e) => e.id == 'mts');
      expect(mts.title, contains('MTS'));
      expect(mts.code, 'MTS');
    });

    test('Mock data sample collections start empty for clean administrative slate', () {
      expect(MockData.sampleQuestions.isEmpty, true);
      expect(MockData.liveTests.isEmpty, true);
      expect(MockData.videoLessons.isEmpty, true);
      expect(MockData.studyNotes.isEmpty, true);
    });

    test('Question model supports English, Telugu, and Hindi languages', () {
      const enQ = Question(
        id: 'q-en',
        chapterId: 'ch-1',
        examId: 'mts',
        languageCode: 'en',
        questionText: 'Which official is the head of Postal Division?',
        optionA: 'SDI',
        optionB: 'SPO',
        optionC: 'CPMG',
        optionD: 'DG',
        correctOption: 'B',
      );
      const teQ = Question(
        id: 'q-te',
        chapterId: 'ch-1',
        examId: 'mts',
        languageCode: 'te',
        questionText: 'పోస్టల్ డివిజన్ యొక్క అధిపతి ఎవరు?',
        optionA: 'SDI',
        optionB: 'SSPO',
        optionC: 'CPMG',
        optionD: 'DG',
        correctOption: 'B',
      );
      const hiQ = Question(
        id: 'q-hi',
        chapterId: 'ch-1',
        examId: 'mts',
        languageCode: 'hi',
        questionText: 'डाक मंडल का प्रमुख कौन होता है?',
        optionA: 'SDI',
        optionB: 'SSPO',
        optionC: 'CPMG',
        optionD: 'DG',
        correctOption: 'B',
      );

      expect(enQ.languageCode, 'en');
      expect(teQ.languageCode, 'te');
      expect(hiQ.languageCode, 'hi');
    });

    test('DataService returns exams, chapters, and live tests', () async {
      final service = DataService();
      final exams = await service.getExams();
      expect(exams, isNotEmpty);

      final chapters = await service.getChapters('mts');
      expect(chapters, isA<List>());

      final liveTests = await service.getLiveTests();
      expect(liveTests, isA<List>());
    });

    test('AuthService separates candidate and admin testing methods', () async {
      final authService = AuthService();

      final demoCandidate = await authService.signInAsDemoCandidate();
      expect(demoCandidate.role, 'student');
      expect(demoCandidate.isAdmin, isFalse);

      final demoAdmin = await authService.signInAsAdminDemo();
      expect(demoAdmin.role, 'admin');
      expect(demoAdmin.isAdmin, isTrue);

      await authService.signOut();
      expect(authService.isAuthenticated, isFalse);
    });

    test('AuthProvider notifies listeners on candidate sign in and signOut', () async {
      final authProvider = AuthProvider();
      expect(authProvider.isAuthenticated, isFalse);

      bool notified = false;
      authProvider.addListener(() {
        notified = true;
      });

      await authProvider.signInAsDemoCandidate();
      expect(authProvider.isAuthenticated, isTrue);
      expect(notified, isTrue);

      await authProvider.signOut();
      expect(authProvider.isAuthenticated, isFalse);
    });

    test('Supabase project configuration uses the active project without old credentials', () {
      expect(AppConstants.supabaseUrl, 'https://nrlsqwvpbrinbagwzrfk.supabase.co');
      expect(AppConstants.supabaseAnonKey, 'sb_publishable_KY5GqZ_BF7glQXNvg53RvQ_wVt_pSe_');
      expect(AppConstants.supabaseUrl.contains('mndgfyvtklbzdrsluljz'), isFalse);
      expect(AppConstants.supabaseAnonKey.contains('sb_publishable_9CnsBHUM'), isFalse);
    });

    test('SupabaseService testConnection distinguishes initialization state', () async {
      final service = SupabaseService();
      final result = await service.testConnection();
      expect(result.status, isNotEmpty);
      expect(result.message, isNotEmpty);
    });
  });
}
