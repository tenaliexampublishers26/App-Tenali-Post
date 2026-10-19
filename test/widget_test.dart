import 'package:flutter_test/flutter_test.dart';
import 'package:tenali_post/models/question.dart';
import 'package:tenali_post/models/live_test.dart';
import 'package:tenali_post/models/exam.dart';
import 'package:tenali_post/services/mock_data.dart';

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
  });
}
