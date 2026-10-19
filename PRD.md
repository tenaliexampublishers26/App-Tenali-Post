# PRD.md — Product Requirements Document (Tenali Post)

---

## 1. Executive Summary & Product Overview
**Tenali Post** is a native Android mobile application designed to empower candidates preparing for Indian Postal departmental competitive examinations (MTS, Postman, Mail Guard, Postal Assistant / Sorting Assistant, and Lower Grade Official promotions). It delivers high-yield multilingual practice MCQs, structured video classes, revision study notes, and timed All-India Live Mock Examinations.

---

## 2. Target Audience & Roles
- **Student Candidate:** India Post departmental employees and aspirants seeking promotion; accesses exams, practice questions with instant feedback, video lessons, study PDFs, and live tests.
- **Administrator:** Tenali Exam Publishers team (`tenaliexamspublishers26@gmail.com`); manages exams, chapters, questions, imports, live test scheduling, and student ranking exports.

---

## 3. Supported Languages
- **English (`en`)**: Primary examination medium for Central questions.
- **Telugu (`te` - తెలుగు)**: Native regional language for AP and Telangana Postal circles.
- **Hindi (`hi` - हिन्दी)**: National official language for Northern and Central circles.
- *Architecture extensible for Kannada and Tamil.*

---

## 4. Feature Requirements

### 4.1 Authentication & Profile
- Google Sign-In with Supabase Auth (`tenalipost://login-callback`).
- Session restoration on app reopen.
- Candidate Profile displaying target cadre, postal circle, phone number, and performance metrics (MCQs solved, accuracy, live tests completed).
- Secure logout.

### 4.2 Home Dashboard
- Branded header featuring the official Tenali Postal Academy logo and notifications bell.
- Candidate welcome card with postal circle badge and Session 2026 tag.
- Active Live Test banner with prominent "JOIN NOW" CTA.
- Departmental Exams grid linking directly to MTS, Postman, PA/SA, and LGO syllabi.
- Postal Rule of the Day card with citations from PO Guide Part 1 and Postal Manuals.

### 4.3 Multilingual MCQ Practice
- **Hierarchy:** Exam → Chapter → Language.
- **Practice Mode:** 
  - Instant Feedback: Selecting an option immediately reveals whether it is correct (green) or incorrect (red).
  - Unlocked Explanation: Displays detailed rationale and official India Post rule clause citation.
  - Progress tracker and real-time correct/wrong pill counters.
  - Previous / Next navigation controls.

### 4.4 Live Mock Examinations
- Scheduled examinations with official start/end windows and duration countdown.
- Auto-submission when the timer expires (`00:00`).
- **Security Rule:** Answer keys and explanations are NEVER transmitted to the client before submission.
- Submit confirmation dialog displaying attempted and unattempted question counts.
- **Results:** Instant scorecard showing marks obtained, percentage, accuracy, and full question-by-question review with official solutions unlocked post-submission.

### 4.5 Video Classes & Study Notes
- High-yield syllabus video classes with player view and duration tracking.
- Study notes section offering free PDF handbooks and formula sheets.

### 4.6 Navigation
- **Bottom Navigation (5 items):** Home, MCQs (`FREE` badge), Videos, Live Tests (`LIVE` dot), Notes.
- **Drawer:** Home, MCQs, Videos, Live Tests, Notes, My Profile, Test History, Notifications, Settings, Help/Support, Logout, and protected Admin Panel entry.

### 4.7 Administrator Management Console
- Dashboard with real-time metrics (exams, tests, questions).
- CSV/JSON question import with UTF-8 Telugu/Hindi support and duplicate detection.
- Live test scheduler dialog.
- Student rankings and scorecard export.
- Audit logging.

---

## 5. Non-Functional & Acceptance Criteria
- **Platform:** Native Flutter on Android SDK 34 (minSdk 21).
- **Code Quality:** Zero errors or warnings on `flutter analyze`.
- **Test Coverage:** Automated unit and architecture test suite in `test/widget_test.dart` passing with 100% success rate.
- **Design Tokens:** Strict alignment with official logo color palette (Deep Navy Blue `#0B2545`, India Post Maroon `#C81D25`, Metallic Gold `#D4AF37`, Off-White `#F8F9FA`).
- **Security:** Complete isolation from the e-commerce website and zero live-test answer leaks.
