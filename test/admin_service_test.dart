import 'package:flutter_test/flutter_test.dart';
import 'package:tenali_post/models/question.dart';
import 'package:tenali_post/services/admin_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AdminService adminService;

  setUp(() {
    adminService = AdminService();
  });

  group('Admin Authorization Tests', () {
    test('Recognizes primary superadmin email', () {
      expect(
        AdminService.isAuthorizedAdmin('tenaliexamspublishers26@gmail.com'),
        isTrue,
      );
      expect(
        AdminService.isAuthorizedAdmin('TENALIEXAMSPUBLISHERS26@GMAIL.COM'),
        isTrue,
      );
    });

    test('Rejects unauthorized student email', () {
      expect(
        AdminService.isAuthorizedAdmin('student_aspirant@gmail.com'),
        isFalse,
      );
      expect(
        AdminService.isAuthorizedAdmin(null),
        isFalse,
      );
    });
  });

  group('CSV & JSON Import Validation Tests', () {
    test('Validates compliant CSV questions across EN, TE, and HI', () {
      const validCsv = '''id,chapter_id,exam_id,language_code,question_text,option_a,option_b,option_c,option_d,correct_option,explanation,difficulty,citation
csv-test-01,post-office-guide-part-1,mts,en,What is the minimum weight of a letter?,20 grams,50 grams,10 grams,5 grams,A,Rule 12 PO Guide Part 1,easy,Clause 12
csv-test-02,post-office-guide-part-1,mts,te,ఉత్తరం కనీస బరువు ఎంత?,20 గ్రాములు,50 గ్రాములు,10 గ్రాములు,5 గ్రాములు,A,నిబంధన 12 పిఓ గైడ్,easy,క్లాజ్ 12''';

      final result = adminService.validateCsvContent(validCsv);

      expect(result.isValid, isTrue);
      expect(result.parsedQuestions.length, 2);
      expect(result.errors.isEmpty, isTrue);
      expect(result.parsedQuestions.first.correctOption, 'A');
      expect(result.parsedQuestions.last.languageCode, 'te');
    });

    test('Detects invalid answer keys, missing fields, and duplicate IDs in CSV', () {
      const malformedCsv = '''id,chapter_id,exam_id,language_code,question_text,option_a,option_b,option_c,option_d,correct_option,explanation,difficulty,citation
bad-01,ch-1,mts,en,Question with bad answer,A,B,C,D,Z,Exp,easy,Ref
bad-02,ch-1,mts,en,,A,B,C,D,B,Exp,easy,Ref
bad-01,ch-1,mts,en,Duplicate ID question,A,B,C,D,C,Exp,medium,Ref''';

      final result = adminService.validateCsvContent(malformedCsv);

      expect(result.isValid, isFalse);
      expect(result.errors.length, greaterThanOrEqualTo(3));
      expect(result.errors.any((e) => e.message.contains("must be 'A', 'B', 'C', or 'D'")), isTrue);
      expect(result.errors.any((e) => e.message.contains("missing question text")), isTrue);
      expect(result.errors.any((e) => e.message.contains("Duplicate question ID")), isTrue);
    });

    test('Validates compliant JSON question imports', () {
      const validJson = '''[
        {
          "id": "json-q-01",
          "chapter_id": "post-office-guide-part-1",
          "exam_id": "mts",
          "language_code": "en",
          "question_text": "Sample JSON postal question?",
          "option_a": "First Option",
          "option_b": "Second Option",
          "option_c": "Third Option",
          "option_d": "Fourth Option",
          "correct_option": "C",
          "explanation": "Official departmental citation",
          "difficulty": "medium"
        }
      ]''';

      final result = adminService.validateJsonContent(validJson);
      expect(result.isValid, isTrue);
      expect(result.parsedQuestions.length, 1);
      expect(result.parsedQuestions.first.correctOption, 'C');
    });

    test('Rejects invalid JSON formatting', () {
      const brokenJson = '{"not_a_list": true}';
      final result = adminService.validateJsonContent(brokenJson);
      expect(result.isValid, isFalse);
      expect(result.errors.first.message, contains('JSON root must be an array'));
    });
  });

  group('Question Bank CRUD & Duplication Tests', () {
    test('Admin can create, duplicate, toggle status, and delete questions', () async {
      const newQuestion = Question(
        id: 'admin-created-q1',
        chapterId: 'post-office-guide-part-1',
        examId: 'mts',
        languageCode: 'en',
        questionText: 'Which postal circle does Hyderabad belong to?',
        optionA: 'Telangana',
        optionB: 'Andhra Pradesh',
        optionC: 'Karnataka',
        optionD: 'Tamil Nadu',
        correctOption: 'A',
        explanation: 'Postal Division reorganization',
        difficulty: 'easy',
        postalRuleRef: 'Rule 3',
        isPublished: true,
      );

      // 1. Create
      await adminService.saveQuestion(newQuestion);
      var fetched = await adminService.fetchQuestions();
      expect(fetched.any((q) => q.id == 'admin-created-q1'), isTrue);

      // 2. Duplicate
      final duplicated = await adminService.duplicateQuestion('admin-created-q1');
      expect(duplicated.id, contains('admin-created-q1_copy'));
      expect(duplicated.isPublished, isFalse); // Duplicates start as draft

      // 3. Toggle publication status
      await adminService.toggleQuestionStatus('admin-created-q1', false);
      fetched = await adminService.fetchQuestions();
      final updated = fetched.firstWhere((q) => q.id == 'admin-created-q1');
      expect(updated.isPublished, isFalse);

      // 4. Delete
      await adminService.deleteQuestion('admin-created-q1');
      fetched = await adminService.fetchQuestions();
      expect(fetched.any((q) => q.id == 'admin-created-q1'), isFalse);
    });
  });

  group('Exam & Chapter Safety Deletion Tests', () {
    test('Prevents accidental deletion of exam referenced by existing questions', () async {
      // MTS exam has active questions in MockData
      expect(
        () async => await adminService.deleteExam('mts'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Cannot delete Exam'),
        )),
      );
    });

    test('Prevents accidental deletion of chapter referenced by existing questions', () async {
      expect(
        () async => await adminService.deleteChapter('post-office-guide-part-1'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Cannot delete chapter'),
        )),
      );
    });
  });

  group('Student Profile Management Tests', () {
    test('Admin can fetch, update cadre/circle, and suspend/activate students', () async {
      final students = await adminService.fetchStudents();
      expect(students.isNotEmpty, isTrue);

      final student = students.first;
      final originalStatus = student.status;

      // Toggle suspension
      final newStatus = originalStatus.toLowerCase() == 'active' ? 'Suspended' : 'Active';
      await adminService.updateStudentStatus(student.id, newStatus);

      final updatedStudents = await adminService.fetchStudents();
      final updatedStudent = updatedStudents.firstWhere((s) => s.id == student.id);
      expect(updatedStudent.status.toLowerCase(), newStatus.toLowerCase());

      // Update cadre and circle
      await adminService.updateStudentProfile(
        student.id,
        circle: 'Telangana Circle',
        cadre: 'Postman',
      );

      final refreshed = (await adminService.fetchStudents()).firstWhere((s) => s.id == student.id);
      expect(refreshed.circle, 'Telangana Circle');
      expect(refreshed.cadre, 'Postman');
    });
  });

  group('Audit Log Logging Tests', () {
    test('Logs administrative actions to immutable audit log', () async {
      await adminService.logAuditAction(
        actionType: 'TEST_ACTION',
        targetEntity: 'Question',
        targetId: 'audit-test-q1',
        description: 'Verified automated admin test runner audit entry',
      );

      final logs = await adminService.fetchAuditLogs();
      expect(logs.any((l) => l.actionType == 'TEST_ACTION' && l.targetId == 'audit-test-q1'), isTrue);
    });
  });
}
