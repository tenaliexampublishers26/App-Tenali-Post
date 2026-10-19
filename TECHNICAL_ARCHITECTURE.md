# TECHNICAL_ARCHITECTURE.md — Tenali Post Architecture

This document specifies the technical architecture, development toolchain, data models, and component structure for the **Tenali Post** native Android application.

---

## 1. Verified Development Environment
- **Operating System:** Windows 11 (25H2, build 26200.9550)
- **Flutter SDK:** Flutter 3.47.7 (Channel `stable`) installed at `C:\Users\Team3\flutter\bin`
- **Dart SDK:** Dart 3.13.5
- **Android Target:** Android SDK 34 (compileSdk 34, targetSdkVersion 34, minSdkVersion 21)
- **Application Package ID:** `com.tenaliexam.tenali_post` (defined in `android/app/build.gradle`)
- **Backend Service:** Dedicated Supabase Project (PostgreSQL, Supabase Auth, Row Level Security, Storage)
- **Repository Remote:** `origin` -> `https://github.com/tenaliexampublishers26/App-Tenali-Post.git` (branch: `main`)

---

## 2. Layered Architecture

```
lib/
├── main.dart                      # Application entry point, theme & route registry
├── core/
│   ├── theme.dart                 # AppTheme & color tokens derived from official logo
│   └── constants.dart             # App constants, exam categories, languages
├── models/
│   ├── user_profile.dart          # UserProfile model with role validation
│   ├── exam.dart                  # Exam model (MTS, Postman, PA/SA, LGO)
│   ├── chapter.dart               # Chapter syllabus hierarchy
│   ├── question.dart              # Question model with secure answer key omission
│   ├── live_test.dart             # LiveTest & LiveTestSubmission models
│   ├── video_lesson.dart          # Video lesson metadata
│   └── study_note.dart            # PDF & revision study note metadata
├── services/
│   ├── supabase_service.dart      # Supabase client, queries, and offline fallbacks
│   ├── auth_service.dart          # Google Sign-In & session restoration
│   └── mock_data.dart             # Authentic India Post departmental mock data
├── providers/
│   ├── auth_provider.dart         # Authentication state management
│   ├── mcq_provider.dart          # Exam, chapter, language, and practice mode state
│   └── live_test_provider.dart    # Active test runner, timer, and submission state
├── shared/
│   ├── logo_header.dart           # Reusable logo presentation widget
│   └── custom_app_drawer.dart     # Navigation drawer with student & admin entries
└── features/
    ├── splash/                    # Animated splash screen
    ├── auth/                      # Google & Demo login screen
    ├── navigation/                # 5-item persistent bottom navigation bar
    ├── home/                      # Candidate dashboard & announcements
    ├── mcq/                       # Exam, chapter, and practice mode with instant feedback
    ├── videos/                    # Video lesson listings & player view
    ├── live_tests/                # Timed live test runner & scorecard review
    ├── notes/                     # PDF notes & study materials
    ├── profile/                   # Candidate profile & test statistics
    └── admin/                     # Admin management console & CSV import preview
```

---

## 3. State Management & Navigation Pattern
- **State Management:** Flutter `Provider` (`ChangeNotifierProvider`) for reactive, decoupled, and testable state management.
- **Navigation:** Declarative named routes in `main.dart` with `Navigator.push` for deep hierarchical flows (e.g. Exam → Chapter → Practice Mode).
- **Persistent Bottom Nav:** `IndexedStack` inside `MainNavScreen` preserving scroll position and state across the 5 core tabs.

---

## 4. Supabase Backend Integration
- **Client Configuration:** Managed through `SupabaseService`. When environment variables (`SUPABASE_URL`, `SUPABASE_ANON_KEY`) are present, live queries connect to the dedicated Supabase project. When offline or during local testing, it falls back to `MockData`.
- **Row Level Security (RLS):**
  - `exams`, `chapters`, `questions`, `videos`, `notes`: Public read access for authenticated candidates; write access strictly restricted to verified administrators (`auth.uid() IN (SELECT id FROM admin_users)`).
  - `live_test_questions_safe`: Secure view excluding `correct_option` and `explanation` for active tests.
  - `live_test_submissions`: Candidates can read and write only their own records (`auth.uid() = user_id`).
  - `admin_audit_logs`: Append-only table for administrator actions.

---

## 5. Security & Isolation Rules
- **Complete Isolation:** Under no circumstances should the mobile app connect to or share credentials with the e-commerce database (`tenali-app` / PostgreSQL).
- **Live Test Answer Protection:** Answers and explanations are never passed to the client during an ongoing live test. Scoring is evaluated server-side / post-submission.
- **Admin Verification:** Client-side role checks are visual conveniences only; all mutating operations enforce admin privileges in Supabase RLS and server-side RPC functions.