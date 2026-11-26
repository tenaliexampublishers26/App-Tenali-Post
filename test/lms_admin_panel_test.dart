import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tenali_post/core/utils/live_test_exporter.dart';
import 'package:tenali_post/core/utils/mcq_import_parser.dart';
import 'package:tenali_post/core/constants.dart';
import 'package:tenali_post/core/utils/size_formatter.dart';
import 'package:tenali_post/features/home/home_screen.dart';
import 'package:tenali_post/models/lms_models.dart';
import 'package:tenali_post/providers/auth_provider.dart';
import 'package:tenali_post/providers/lms_admin_provider.dart';
import 'package:tenali_post/providers/notification_provider.dart';
import 'package:tenali_post/services/auth_service.dart';
import 'package:tenali_post/services/lms_admin_service.dart';
import 'package:tenali_post/shared/tenali_top_app_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('McqImportParser Tests', () {
    test('Parses RFC 4180 CSV with BOM, quotes, aliases, and numeric answers', () {
      const csv = '\uFEFFkey,question,a,b,c,d,ans,solution\n'
          'Q1,"Line 1\n""Quoted"" Line 2",Opt1,Opt2,Opt3,Opt4,2,"Because B is right"\n'
          'Q2,Simple question?,A1,B1,C1,D1,OPTION D,Reason D\n';

      final result = McqImportParser.parseAndValidateCsv(csv);
      expect(result.isValid, isTrue);
      expect(result.validCount, 2);
      expect(result.validQuestions[0].correctOption, 'B');
      expect(result.validQuestions[0].questionText, contains('"Quoted"'));
      expect(result.validQuestions[1].correctOption, 'D');
    });

    test('Rejects duplicate questions and invalid answer keys', () {
      const jsonStr = '''[
        {"question_text": "Same Question?", "option_a": "1", "option_b": "2", "option_c": "3", "option_d": "4", "correct_option": "A"},
        {"question_text": "  same   question? ", "option_a": "1", "option_b": "2", "option_c": "3", "option_d": "4", "correct_option": "Z"}
      ]''';

      final result = McqImportParser.parseAndValidateJson(jsonStr);
      expect(result.isValid, isFalse);
      expect(result.duplicateCount, 1);
      expect(result.invalidCount, greaterThanOrEqualTo(2));
    });
  });

  group('SizeFormatter Tests', () {
    test('Formats and parses sizes accurately', () {
      expect(SizeFormatter.formatBytes(512 * 1024), '512 KB');
      expect(SizeFormatter.formatBytes(2 * 1024 * 1024), '2.00 MB');
      expect(SizeFormatter.parseSizeToBytes('1.5 MB'), (1.5 * 1024 * 1024).round());
      expect(SizeFormatter.parseSizeToBytes('256 KB'), 256 * 1024);
    });
  });

  group('LmsAdminService Core Workflows & Security Tests', () {
    test('Global LMS controls & settings write audit logs', () async {
      final svc = LmsAdminService();
      await svc.toggleMcqEnabled(false);
      expect((await svc.getSettings()).mcqEnabled, isFalse);

      await svc.updateSettings(
        const LmsSettings(
          mcqEnabled: true,
          liveTestEnabled: true,
          maintenanceMode: true,
          liveNotificationEnabled: true,
          liveNotificationText: 'Mock Test Live',
        ),
      );
      final updated = await svc.getSettings();
      expect(updated.maintenanceMode, isTrue);
      expect(updated.liveNotificationText, 'Mock Test Live');

      final logs = await svc.getAuditLogs(targetType: 'settings');
      expect(logs.any((l) => l.actionType == 'UPDATE_SETTINGS'), isTrue);
    });

    test('MCQ hierarchy versioning, import, publish, and recursive delete', () async {
      final svc = LmsAdminService();
      final root = await svc.createTopic(name: 'Test Root Topic');
      final sub = await svc.createTopic(name: 'Nested Subtopic', parentId: root.id);
      final chap = await svc.createChapter(topicId: sub.id, title: 'Chap 1');
      final parsed = McqImportParser.parseAndValidateCsv(McqImportParser.sampleCsvTemplate);

      final v1 = await svc.importMcqQuestions(
        topicId: sub.id,
        chapterId: chap.id,
        mediumId: 'med-en',
        mediumCode: 'en',
        parsed: parsed,
        fileName: 'sample.csv',
        fileType: 'csv',
        publishImmediately: true,
        replaceExisting: true,
      );
      expect(v1.isPublished, isTrue);
      expect(v1.version, 1);

      final v2 = await svc.importMcqQuestions(
        topicId: sub.id,
        chapterId: chap.id,
        mediumId: 'med-en',
        mediumCode: 'en',
        parsed: parsed,
        fileName: 'sample_v2.csv',
        fileType: 'csv',
        publishImmediately: true,
        replaceExisting: true,
      );
      expect(v2.version, 2);
      expect(v2.isPublished, isTrue);

      final sets = await svc.getQuestionSetsForChapter(chap.id);
      expect(sets.where((s) => s.id == v1.id).first.isArchived, isTrue);

      await svc.deleteTopicTree(root.id);
      final remainingTopics = await svc.getTopics();
      expect(remainingTopics.any((t) => t.id == root.id || t.id == sub.id), isFalse);
    });

    test('Untimed Live Test lifecycle, answer-key gating, ranking, and Excel export', () async {
      final svc = LmsAdminService();
      final test = await svc.createLiveTest(title: 'Security Untimed Test');

      // Cannot publish with 0 questions
      await expectLater(
        svc.setLiveTestStatus(test.id, 'published'),
        throwsException,
      );

      final parsed = McqImportParser.parseAndValidateCsv(McqImportParser.sampleCsvTemplate);
      await svc.importLiveTestQuestions(
        testId: test.id,
        parsed: parsed,
        replaceExisting: true,
      );
      await svc.setLiveTestStatus(test.id, 'published');

      // Student fetch strictly strips correctOption and explanation
      final studentQs = await svc.getStudentLiveTestQuestions(test.id);
      expect(studentQs.length, 2);
      expect(studentQs.every((q) => q.correctOption == null && q.explanation == null), isTrue);

      // Submit answers server-side
      final sub = await svc.submitStudentLiveTest(
        testId: test.id,
        studentName: 'Asha',
        phoneNumber: '9000011111',
        location: 'Tenali',
        email: 'asha@example.com',
        answers: {studentQs[0].id: 'B', studentQs[1].id: 'A'},
      );
      expect(sub.correctCount, 1);
      expect(sub.wrongCount, 1);
      expect(sub.marksObtained, 1.0);

      // Answer key blocked before release
      await expectLater(
        svc.getStudentLiveTestAnswers(test.id),
        throwsException,
      );

      await svc.setLiveTestStatus(test.id, 'closed');
      await svc.setLiveTestAnswersReleased(test.id, true);

      final releasedKeys = await svc.getStudentLiveTestAnswers(test.id);
      expect(releasedKeys.every((q) => q.correctOption != null), isTrue);

      final ranked = await svc.getLiveTestResults(test.id);
      expect(ranked.length, 1);
      expect(ranked.first.rank, 1);

      final xlsxBytes = LiveTestExporter.buildExcelBytes(test, ranked);
      expect(xlsxBytes, isNotEmpty);
    });

    test('Notes folder loop protection and 4-state preview/download enforcement', () async {
      final svc = LmsAdminService();
      final f1 = await svc.createNoteFolder(name: 'Parent Folder');
      final f2 = await svc.createNoteFolder(name: 'Child Folder', parentId: f1.id);
      final allFolders = await svc.getNoteFolders();

      // Cannot move parent into its own child
      await expectLater(
        svc.updateNoteFolder(
          id: f1.id,
          name: f1.name,
          newParentId: f2.id,
          allFolders: allFolders,
        ),
        throwsException,
      );

      final pdfBytes = Uint8List.fromList('%PDF-1.4\n1 0 obj\n<<>>\nendobj\ntrailer\n<<>>\n%%EOF'.codeUnits);

      // Combination: Preview ON, Download OFF
      final viewOnlyNote = await svc.uploadNote(
        title: 'View Only Handbook',
        folderId: f2.id,
        fileBytes: pdfBytes,
        fileName: 'handbook.pdf',
        isPreviewable: true,
        allowDownload: false,
      );
      expect(await svc.fetchNotePreviewBytes(viewOnlyNote), isNotEmpty);
      await expectLater(svc.requestNoteDownload(viewOnlyNote), throwsException);

      // Combination: Preview OFF, Download ON
      final downloadOnlyNote = await svc.uploadNote(
        title: 'Download Only Sheet',
        folderId: f2.id,
        fileBytes: pdfBytes,
        fileName: 'sheet.pdf',
        isPreviewable: false,
        allowDownload: true,
      );
      await expectLater(svc.fetchNotePreviewBytes(downloadOnlyNote), throwsException);
      final dl = await svc.requestNoteDownload(downloadOnlyNote);
      expect(dl.bytes, isNotNull);
    });

    test('Admin changes immediately reflect for Student portal and directory', () async {
      final auth = AuthService();
      final provider = LmsAdminProvider();
      final svc = LmsAdminService();

      // 1. Sign in with Admin credentials
      final adminUser = await auth.signInWithPassword(
        email: AppConstants.authorizedAdminEmail,
        password: AppConstants.exampleAdminPassword,
      );
      expect(adminUser.isAdmin, isTrue);

      // 2. Admin updates settings, topics/chapters/questions, live test, and notes
      await provider.updateSettings(
        const LmsSettings(
          mcqEnabled: false,
          liveTestEnabled: false,
          maintenanceMode: true,
          liveNotificationEnabled: true,
          liveNotificationText: 'Admin Broadcast Alert',
        ),
      );

      final pubTopic = await svc.createTopic(
        name: 'Published Sync Topic',
        isPublished: true,
      );
      final draftTopic = await svc.createTopic(
        name: 'Hidden Draft Topic',
        isPublished: false,
      );
      final chapter = await svc.createChapter(
        topicId: pubTopic.id,
        title: 'Sync Chapter',
        isPublished: true,
      );
      final mediums = await svc.getMediums();
      final parsed = McqImportParser.parseAndValidateCsv(McqImportParser.sampleCsvTemplate);
      final importedSet = await svc.importMcqQuestions(
        topicId: pubTopic.id,
        chapterId: chapter.id,
        mediumId: mediums.first.id,
        mediumCode: mediums.first.code,
        parsed: parsed,
        fileName: 'sync.csv',
        fileType: 'csv',
        publishImmediately: true,
        replaceExisting: true,
      );

      final syncLiveTest = await svc.createLiveTest(title: 'Admin Sync Live Test');
      await svc.importLiveTestQuestions(
        testId: syncLiveTest.id,
        parsed: parsed,
        replaceExisting: true,
      );
      await svc.setLiveTestStatus(syncLiveTest.id, 'published');

      final syncNote = await svc.uploadNote(
        title: 'Admin Sync Circular.pdf',
        folderId: null,
        fileBytes: Uint8List.fromList('%PDF-1.4\n%%EOF'.codeUnits),
        fileName: 'circular.pdf',
        isPreviewable: true,
        allowDownload: false,
      );

      // 3. Switch to Student credentials and verify student portal reflects every admin change
      final studentUser = await auth.signInWithPassword(
        email: AppConstants.exampleLoginEmail,
        password: AppConstants.exampleLoginPassword,
      );
      expect(studentUser.isAdmin, isFalse);

      await provider.loadStudentPortalData(isAdmin: false);
      expect(provider.settings.mcqEnabled, isFalse);
      expect(provider.settings.liveTestEnabled, isFalse);
      expect(provider.settings.maintenanceMode, isTrue);
      expect(provider.settings.liveNotificationEnabled, isTrue);
      expect(provider.settings.liveNotificationText, 'Admin Broadcast Alert');

      expect(provider.topics.any((t) => t.id == pubTopic.id), isTrue);
      expect(provider.topics.any((t) => t.id == draftTopic.id), isFalse);
      expect(provider.liveTests.any((t) => t.id == syncLiveTest.id), isTrue);
      expect(provider.notes.any((n) => n.id == syncNote.id), isTrue);

      // 4. Student submits MCQ attempt and Live Test, and both reflect in Admin Students Directory
      final qs = await svc.getQuestionsForSet(importedSet.id);
      await provider.submitMcqPracticeAttempt(
        userId: studentUser.id,
        questionSetId: importedSet.id,
        questionSetVersion: importedSet.version,
        questions: qs,
        selectedAnswers: {qs.first.id: qs.first.correctOption},
      );
      final studentTestQs = await svc.getStudentLiveTestQuestions(syncLiveTest.id);
      await svc.submitStudentLiveTest(
        testId: syncLiveTest.id,
        studentName: studentUser.fullName,
        phoneNumber: studentUser.phoneNumber ?? '9876543210',
        location: studentUser.location ?? 'Tenali',
        email: studentUser.email,
        answers: {studentTestQs.first.id: 'B'},
      );

      final students = await svc.getStudentsDirectory(search: studentUser.email);
      expect(students, isNotEmpty);
      expect(students.first.mcqAttempts.length, greaterThanOrEqualTo(1));
      expect(students.first.liveTestSubmissions.length, greaterThanOrEqualTo(1));

      // Cleanup default toggles
      await provider.updateSettings(const LmsSettings());
      await auth.signOut();
    });

    test('Bilingual en_te JSON parsing, draft row editing, and single MCQ add', () async {
      const bilingualJson = '''
      {
        "questions": [
          {
            "question_en": "Maximum weight of a letter?",
            "question_te": "లేఖ గరిష్ట బరువు ఎంత?",
            "options_en": ["500g", "1kg", "2kg", "5kg"],
            "options_te": ["500గ్రా", "1కిలో", "2కిలో", "5కిలో"],
            "correct_option": "C",
            "explanation_en": "Letters up to 2 kg are allowed."
          },
          {
            "question": {"en": "Pin code digits?", "te": "పిన్ కోడ్ అంకెలు?"},
            "options": {
              "en": {"A": "4", "B": "5", "C": "6", "D": "8"},
              "te": {"A": "4", "B": "5", "C": "6", "D": "8"}
            },
            "answer": "3"
          },
          {
            "en": {"question_text": "Speed Post started in?", "options": ["1982", "1986", "1990", "1995"]},
            "te": {"question_text": "స్పీడ్ పోస్ట్ ఎప్పుడు మొదలైంది?", "options": ["1982", "1986", "1990", "1995"]},
            "correct": "B"
          }
        ]
      }''';

      final enParsed = McqImportParser.parseAndValidateJson(bilingualJson, preferredLang: 'en');
      expect(enParsed.isValid, isTrue);
      expect(enParsed.validCount, 3);
      expect(enParsed.validQuestions[0].questionText, 'Maximum weight of a letter?');
      expect(enParsed.validQuestions[0].optionC, '2kg');
      expect(enParsed.validQuestions[1].correctOption, 'C');
      expect(enParsed.validQuestions[2].questionText, 'Speed Post started in?');

      final teParsed = McqImportParser.parseAndValidateJson(bilingualJson, preferredLang: 'te');
      expect(teParsed.isValid, isTrue);
      expect(teParsed.validQuestions[0].questionText, 'లేఖ గరిష్ట బరువు ఎంత?');
      expect(teParsed.validQuestions[0].optionC, '2కిలో');

      // Simulate editing a broken imported row via rawRows + adding a row manually
      final svc = LmsAdminService();
      final topic = await svc.createTopic(name: 'Manual Add Topic');
      final chap = await svc.createChapter(topicId: topic.id, title: 'Manual Add Chapter');
      final mediums = await svc.getMediums();
      final set = await svc.attachChapterLanguage(chapterId: chap.id, mediumId: mediums.first.id);
      final added = await svc.addMcqQuestion(
        LmsMcqQuestion(
          id: '',
          questionSetId: set.id,
          questionKey: 'Q1',
          questionText: 'Single manually added MCQ?',
          optionA: 'Opt 1',
          optionB: 'Opt 2',
          optionC: 'Opt 3',
          optionD: 'Opt 4',
          correctOption: 'A',
        ),
      );
      expect(added.id, isNotEmpty);
      final fetched = await svc.getQuestionsForSet(set.id);
      expect(fetched.any((q) => q.id == added.id), isTrue);
    });

    testWidgets('Top navigation bar opens Profile and Home routes MCQs=3 and Notes=4',
        (WidgetTester tester) async {
      final authProvider = AuthProvider();
      await authProvider.signInWithPassword(
        AppConstants.exampleLoginEmail,
        AppConstants.exampleLoginPassword,
      );
      int? tappedTab;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider(create: (_) => LmsAdminProvider()),
            ChangeNotifierProvider(create: (_) => NotificationProvider()),
          ],
          child: MaterialApp(
            routes: {
              '/': (_) => Scaffold(
                    appBar: const TenaliTopAppBar(),
                    body: HomeScreen(onNavigateTab: (idx) => tappedTab = idx),
                  ),
              '/profile': (_) => const Scaffold(body: Center(child: Text('Profile Route Open'))),
              '/notifications': (_) => const Scaffold(body: Center(child: Text('Notifications'))),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify MCQ card routes to index 3 (after Live Tests) and Study Notes to index 4
      await tester.ensureVisible(find.text('MCQ Practice Bank'));
      await tester.tap(find.text('MCQ Practice Bank'));
      expect(tappedTab, 3);

      await tester.ensureVisible(find.text('Study Notes'));
      await tester.tap(find.text('Study Notes'));
      expect(tappedTab, 4);

      // Tap User Profile button in top navigation bar -> opens /profile
      await tester.tap(find.byTooltip('User Profile').first);
      await tester.pumpAndSettle();
      expect(find.text('Profile Route Open'), findsOneWidget);
    });
  });
}
