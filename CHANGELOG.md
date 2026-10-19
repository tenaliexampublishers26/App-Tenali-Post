# CHANGELOG.md — Tenali Post

All notable changes to the **Tenali Post** project are documented here in reverse chronological order.

---

## 2026-10-19 — Production-Ready Complete Admin Panel Upgrade

### Added
- **Home Screen Minimalist Refinement:**
  - Removed starting promotional banner, candidate greeting cards, logo image box, live test banners, and sample exam cards from the home screen body.
  - Kept a clean canvas with the warm brand theme, top app bar with drawer access, and bottom navigation bar.
- **Central Admin Dashboard Console (`AdminDashboardScreen`):**
  - Real-time database-backed telemetry: Total Exams, Chapters, Question Bank Count, Active Live Tests, Registered Aspirants, and Live Test Submissions.
  - Multilingual translation coverage meter (English, Telugu, Hindi).
  - Quick action shortcuts to all 10 management modules.
  - Role-based security gate: Non-admin users attempting to open admin routes are immediately blocked with a secure "Access Denied" screen.
- **Complete MCQ Management Suite:**
  - `AdminMcqListScreen`: Searchable question list with multi-parameter filtering (Exam Cadre, Chapter, Language, Difficulty, Draft/Published Status), question duplicate action, publish/unpublish toggle, and destructive delete confirmations.
  - `AdminMcqEditorScreen`: Full multilingual editor featuring tabbed interface (English, Telugu, Hindi), 4 options (A, B, C, D), answer key selector, explanation fields per language, postal rule / PO Guide citations, completeness indicators, and draft/published state toggles.
  - `AdminMcqImportExportScreen`: In-app CSV and JSON parser and validator supporting UTF-8 Telugu and Hindi. Performs header checks, validates all 4 options, validates answer keys (`A`, `B`, `C`, `D`), prevents duplicate IDs, gives row-level line-numbered error reports, and previews before batch commit. Also supports full CSV/JSON export with language filtering.
- **Student Profile Management (`AdminStudentManagementScreen`):**
  - Aspirant roster with search by name, email, and phone number, filtered by Postal Circle and Account Status.
  - Profile inspection sheet showing registration date, last active timestamp, average exam percentage, and test attempts count.
  - Permitted profile fields editor (Postal Circle and Target Cadre).
  - Secure account suspension and reactivation toggle with audit logging.
  - CSV export of student performance rosters.
- **Exam, Chapter & Language Management:**
  - `AdminExamListScreen`: Create, edit, and safely delete exams. Contains foreign reference safety checks that block deletion if chapters or questions exist.
  - `AdminChapterListScreen`: Manage syllabus chapters with language coverage badges per chapter (EN, TE, HI) and safety deletion checks against active questions.
  - `AdminLanguageMatrixScreen`: Visual syllabus matrix highlighting translation coverage percentages and identifying missing Telugu and Hindi question translations.
- **Content Management Modules:**
  - `AdminVideoManagementScreen`: YouTube and video stream URL management with URL validation, exam/chapter association, language selection, and edit/delete capabilities.
  - `AdminNotesManagementScreen`: PDF study handbook metadata management with file URL, storage bucket path, page count, and language tagging.
- **Live Test Management:**
  - `AdminLiveTestScreen`: Schedule live test windows (start time, end time, duration minutes, total marks, questions count), question bank association, and draft/published toggles.
  - `AdminLiveTestResultsScreen`: View real student submissions, rankings, marks obtained, percentage scores, and one-click CSV scorecard export.
- **Audit & Settings:**
  - `AdminAuditLogScreen`: Immutable audit trail showing timestamped records of all administrative actions (creations, edits, deletions, suspensions).
  - `AdminSettingsScreen`: Supabase backend connection diagnostics, admin account verification, and database RLS checklist.
- **Database Infrastructure (`supabase/migrations/20261019_001_admin_schema.sql`):**
  - Created tables: `admin_users`, `student_profiles`, `exams`, `chapters`, `questions`, `live_tests`, `live_test_submissions`, `videos`, `notes`, and `admin_audit_logs`.
  - Configured RLS policies for public, authenticated students, and verified admins.
  - Implemented `is_admin()` security definer function and initial provisioning trigger for `tenaliexamspublishers26@gmail.com`.
  - Implemented `get_live_test_questions_safe()` server function hiding answer keys until test completion.
  - Implemented `submit_live_test_secure()` server-side scoring function.
- **Automated Test Suite (`test/admin_service_test.dart`):**
  - Added 11 automated unit and integration tests covering admin authorization, CSV validation (valid & malformed), JSON validation, question bank CRUD, question duplication, safety deletion checks, student profile updates, status suspension, and audit logging.

### Verified
- `flutter analyze`: **0 issues found** (Clean run across entire codebase).
- `flutter test`: **15/15 tests passed** (100% pass rate).

### Fixed
- **Horizontal RenderFlex Overflow (12px):** Replaced rigid `Row` layout inside the gold candidate greeting card with a responsive `Wrap` layout for "SESSION 2026" and postal circle text, preventing horizontal layout clipping on narrow mobile screens.
- **Top AppBar Leading Arrow:** Added `automaticallyImplyLeading: false` on `HomeScreen` so an unintended back navigation arrow does not steal layout width from the primary brand title.

### Updated
- **Brand Palette Realignment:** Derived warm parchment (`#FAF7EE`), dual-gold plaque borders (`#C89B3C`, `#DFBC69`), and postal crimson (`#C81D25`) directly from user reference screenshot.
- **Splash & Pre-loader Screen:** Replaced dark blue background with warm parchment ivory theme with gold-rimmed seal and crimson progress indicator across both Flutter `SplashScreen` and HTML preloader `web/index.html`.

---

## 2026-10-19 — Master Project Initialization & Flutter Android Foundation

### Added
- **Official Brand Logo:** Saved uploaded seal to `assets/images/tenali_post_logo.png` (446 KB) and registered in `pubspec.yaml`.
- **Flutter SDK Installation:** Installed Flutter 3.47.7 and Dart 3.13.5 at `C:\Users\Team3\flutter\bin` and added to User environment PATH.
- **Android Native Project:** Configured Android build files with application package ID `com.tenaliexam.tenali_post` (minSdk 21, targetSdk 34, compileSdk 34) in `android/app/build.gradle` and `AndroidManifest.xml`.
- **Design System (`AppTheme`):** Extracted palette from official logo (Deep Navy Blue `#0B2545`, India Post Maroon `#C81D25`, Metallic Gold `#D4AF37`, Off-White `#F8F9FA`).
- **Core Architecture & Models:** Implemented `UserProfile`, `Exam`, `Chapter`, `Question`, `LiveTest`, `LiveTestSubmission`, `VideoLesson`, and `StudyNote`.
- **Services & Providers:** Implemented `SupabaseService` with offline fallback, `AuthService` with Google OAuth & demo sign-in, `McqProvider` with instant feedback and score tracking, and `LiveTestProvider` with real-time countdown timer.
- **Complete Screen Implementations:**
  - `SplashScreen`: Official logo animation and session check.
  - `LoginScreen`: Google Sign-In and Demo Candidate access.
  - `MainNavScreen`: 5-item persistent bottom navigation (Home, MCQs with `FREE` badge, Videos, Live Tests with `LIVE` beacon, Notes).
  - `HomeScreen`: Candidate welcome banner, live test alert, exam shortcuts, daily postal rule card.
  - `ExamListScreen` & `ChapterListScreen`: Multilingual hierarchy (English, Telugu, Hindi).
  - `McqPracticeScreen`: Question progress, real-time score pills, instant green/red feedback, unlocked PO Guide explanations.
  - `LiveTestRunnerScreen`: Timed examination runner, countdown timer, question palette, zero answer key leaks before submission.
  - `LiveTestResultScreen`: Marks scorecard, accuracy percentage, and full solution review.
  - `VideosScreen`: High-yield postal video classes with player modal.
  - `NotesScreen`: Revision PDF handbooks and formula sheets.
  - `ProfileScreen`: Candidate statistics, postal circle, and target cadre.
  - `AdminDashboardScreen`: Metrics, CSV question import validator preview, live test scheduler, and audit logs.
- **Automated Test Suite:** Created `test/widget_test.dart` covering model serialization, live test status calculation, and answer key security.

### Tests
- `flutter pub get`: Exited with code 0 (113 dependencies resolved and downloaded).
- `flutter analyze`: Exited with code 0 (**No issues found!**).
- `flutter test`: Exited with code 0 (**4/4 tests passed**).

### Deployment Status
- Local only. No commits or pushes made to GitHub (in compliance with security rules).