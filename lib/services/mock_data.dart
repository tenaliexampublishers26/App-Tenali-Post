import '../models/exam.dart';
import '../models/chapter.dart';
import '../models/question.dart';
import '../models/live_test.dart';
import '../models/video_lesson.dart';
import '../models/study_note.dart';

class MockData {
  static final List<Exam> exams = [
    const Exam(
      id: 'mts',
      title: 'MTS Examination',
      subtitle: 'Multi-Tasking Staff Departmental Exam',
      code: 'MTS',
      totalChapters: 4,
      totalQuestions: 120,
      iconName: 'school',
    ),
    const Exam(
      id: 'postman',
      title: 'Postman & Mail Guard',
      subtitle: 'Postman Cadre Competitive & Departmental',
      code: 'PMG',
      totalChapters: 6,
      totalQuestions: 240,
      iconName: 'local_post_office',
    ),
    const Exam(
      id: 'pasa',
      title: 'PA / SA Examination',
      subtitle: 'Postal Assistant & Sorting Assistant Exam',
      code: 'PASA',
      totalChapters: 8,
      totalQuestions: 450,
      iconName: 'badge',
    ),
    const Exam(
      id: 'lgo',
      title: 'LGO Examination',
      subtitle: 'Lower Grade Official Promotion Exam',
      code: 'LGO',
      totalChapters: 5,
      totalQuestions: 180,
      iconName: 'workspace_premium',
    ),
  ];

  static final List<Chapter> chapters = [
    const Chapter(
      id: 'ch-po-guide-1',
      examId: 'mts',
      title: 'Post Office Guide Part 1 (Clause 1 to 50)',
      description: 'Organization, Types of Post Offices, Business Hours & Postage Stamp Rules',
      chapterNumber: 1,
      totalQuestions: 40,
      supportedLanguages: ['en', 'te', 'hi'],
    ),
    const Chapter(
      id: 'ch-domestic-mails',
      examId: 'mts',
      title: 'Domestic Mails — Letters, Postcards & Book Packets',
      description: 'Weight limits, dimension criteria, and postal rates for inland articles',
      chapterNumber: 2,
      totalQuestions: 35,
      supportedLanguages: ['en', 'te', 'hi'],
    ),
    const Chapter(
      id: 'ch-postal-manual-5',
      examId: 'postman',
      title: 'Postal Manual Volume V — Definitions & Head Office Rules',
      description: 'Definitions of Mail Offices, Transit Sections, Bag Accounting & Sorting',
      chapterNumber: 1,
      totalQuestions: 50,
      supportedLanguages: ['en', 'te', 'hi'],
    ),
    const Chapter(
      id: 'ch-delivery-rules',
      examId: 'postman',
      title: 'Delivery Rules & Beat Duties of Postman',
      description: 'Intimation of undelivered parcels, VP articles, and signature procedures',
      chapterNumber: 2,
      totalQuestions: 45,
      supportedLanguages: ['en', 'te', 'hi'],
    ),
    const Chapter(
      id: 'ch-pasa-volume-6',
      examId: 'pasa',
      title: 'Postal Manual Volume VI (Part 1 & 2)',
      description: 'Sub-Account Office, Cash Accounts, Summary & Treasury Transactions',
      chapterNumber: 1,
      totalQuestions: 60,
      supportedLanguages: ['en', 'te', 'hi'],
    ),
  ];

  static final List<Question> sampleQuestions = [];

  static final List<LiveTest> liveTests = [];

  static final List<VideoLesson> videoLessons = [];

  static final List<StudyNote> studyNotes = [];
}

