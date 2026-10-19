# DECISIONS.md — Tenali Post Architecture & Product Decisions

This document serves as the permanent record of all confirmed, proposed, and pending product, design, technical, and security decisions for the Tenali Post native Android application.

---

## Decision Status Legend
- **CONFIRMED**: Approved and active requirement or architectural choice.
- **PROPOSED**: Recommended by the engineering team; active for development pending explicit change.
- **PENDING CONFIRMATION**: Open requirement awaiting clarification from stakeholders.
- **SUPERSEDED**: Outdated decision replaced by a newer decision (linked).

---

## Confirmed Requirements & Architectural Decisions

### DEC-001: Product Identity
- **Date:** 2026-10-19
- **Status:** CONFIRMED
- **Decision:** The application is officially named **Tenali Post** (tagline: *"Learn • Prepare • Succeed — Excellence in Postal & Competitive Exams"*).
- **Reason:** Aligned with brand mission to prepare Indian postal departmental exam candidates (MTS, Postman, Mail Guard, PA/SA, and LGO).
- **Impact:** Used in app headers, Android label, splash screen, and documentation.
- **Related Files:** `pubspec.yaml`, `android/app/src/main/AndroidManifest.xml`, `PROJECT_CONTEXT.md`

### DEC-002: Native Android Platform via Flutter & Dart
- **Date:** 2026-10-19
- **Status:** CONFIRMED
- **Decision:** Build a 100% native Android application using Flutter and Dart. No WebView wrapper or website-in-a-box.
- **Reason:** Provides maximum performance, offline capability, smooth touch response, and native Android navigation (back button, system notifications).
- **Impact:** Entire codebase structured as a modular Flutter/Dart Android project.
- **Related Files:** `lib/`, `android/`, `TECHNICAL_ARCHITECTURE.md`

### DEC-003: Target Audience & Examination Scope
- **Date:** 2026-10-19
- **Status:** CONFIRMED
- **Decision:** Primary audience is Indian postal departmental exam candidates preparing for MTS, Postman, Mail Guard, Postal Assistant / Sorting Assistant (PA/SA), and LGO examinations.
- **Reason:** Core focus of Tenali Exam Publishers.
- **Impact:** MCQ hierarchy, categories, syllabus, and live tests are tailored to India Post departmental rules and syllabus.
- **Related Files:** `PRD.md`, `lib/models/exam.dart`

### DEC-004: Multilingual Hierarchy (English, Telugu, Hindi)
- **Date:** 2026-10-19
- **Status:** CONFIRMED
- **Decision:** The content hierarchy is strictly **Exam → Chapter → Language**. Supported languages are English, Telugu, and Hindi, with architecture extensible for Kannada and Tamil in future updates.
- **Reason:** Departmental candidates in postal circles across India study in their regional language or English/Hindi. Mixing languages within a single test session is prohibited unless explicitly specified.
- **Impact:** Database schema and UI language selector enforce clean language separation per question attempt.
- **Related Files:** `PRD.md`, `lib/models/question.dart`, `lib/features/mcq/`

### DEC-005: Navigation Architecture (5-Item Bottom Nav + Navigation Drawer)
- **Date:** 2026-10-19
- **Status:** CONFIRMED
- **Decision:** 
  1. Persistent bottom navigation bar containing exactly 5 items:
     - **Home** (`Icons.home_rounded`)
     - **MCQs** (`Icons.quiz_rounded`)
     - **Videos** (`Icons.play_circle_fill_rounded`)
     - **Live Tests** (`Icons.timer_rounded`)
     - **Notes** (`Icons.menu_book_rounded`)
  2. Navigation Drawer with student items (Profile, Test History, Notifications, Settings, Help/Support, Logout) and a protected **Admin Panel** entry visible only to authorized administrators.
- **Reason:** Standard thumb-friendly mobile navigation for rapid switching between key study modes.
- **Impact:** Implemented in `MainNavScreen`.
- **Related Files:** `UI_UX_SPEC.md`, `lib/features/navigation/`

### DEC-006: MCQ Practice Mode — Instant Feedback & Explanations
- **Date:** 2026-10-19
- **Status:** CONFIRMED
- **Decision:** In Practice mode, selecting an option triggers immediate visual validation (green for correct, red for incorrect with correct answer revealed) along with a detailed explanation and postal rule reference.
- **Reason:** Learning tool for candidate self-paced practice.
- **Impact:** Implemented in `McqPracticeScreen`.
- **Related Files:** `PRD.md`, `lib/features/mcq/mcq_practice_screen.dart`

### DEC-007: Live Tests — Zero Answer Key Exposure Before Submission
- **Date:** 2026-10-19
- **Status:** CONFIRMED
- **Decision:** Correct answers, answer keys, and explanations MUST NEVER be sent to or accessible on the client during an active live test. Answers are only revealed post-submission or upon scheduled result release.
- **Reason:** Preserves strict examination integrity and ranking validity.
- **Impact:** Live test question models strip `correct_option` and `explanation` before delivering payloads to student devices. Scoring is evaluated server-side / post-submission.
- **Related Files:** `SECURITY_RULES.md`, `lib/models/live_test.dart`

### DEC-008: Admin Content Management & CSV/JSON Imports
- **Date:** 2026-10-19
- **Status:** CONFIRMED
- **Decision:** Admin panel must support manual question authoring and bulk CSV/JSON question import with row-by-row validation, duplicate detection, Unicode Telugu/Hindi preservation, and error previews.
- **Reason:** Hundreds of postal questions and previous papers need to be imported efficiently.
- **Impact:** Implemented in `CsvImportScreen` and admin question editor.
- **Related Files:** `PRD.md`, `lib/features/admin/`

### DEC-009: Official Logo & Color Palette
- **Date:** 2026-10-19
- **Status:** CONFIRMED
- **Decision:** Official supplied badge logo is stored at `assets/images/tenali_post_logo.png`. App design system is derived directly from the artwork colors:
  - **Primary Navy:** `#0B2545` (Deep Academic Blue)
  - **Secondary Crimson:** `#C81D25` (India Post Red / Maroon)
  - **Accent Gold:** `#D4AF37` / `#E5B80B` (Metallic Gold / Laurel)
  - **Background Page:** `#F8F9FA` (Soft Off-White)
  - **Card / Surface:** `#FFFFFF` (Pure White)
  - **Text High Contrast:** `#0F172A` (Deep Slate)
  - **Text Muted:** `#475569` (Slate Gray)
- **Reason:** Professional academic branding matching the official Tenali Postal Academy seal.
- **Impact:** Defined in `AppTheme` and `UI_UX_SPEC.md`.
- **Related Files:** `assets/images/tenali_post_logo.png`, `lib/core/theme.dart`, `UI_UX_SPEC.md`

### DEC-010: Backend Isolation from E-Commerce Production Database
- **Date:** 2026-10-19
- **Status:** CONFIRMED
- **Decision:** Tenali Post app uses a separate, dedicated Supabase project. It must NEVER connect to, alter, or share credentials with the existing Tenali Exams Publishers e-commerce database.
- **Reason:** Complete security and operational isolation prevents accidental data corruption or schema collisions.
- **Impact:** Clean Supabase schema with RLS designed specifically for the mobile learning platform.
- **Related Files:** `SECURITY_RULES.md`, `TECHNICAL_ARCHITECTURE.md`

### DEC-011: Initial Administrator Provisioning
- **Date:** 2026-10-19
- **Status:** CONFIRMED
- **Decision:** Intended initial administrator email is `tenaliexamspublishers26@gmail.com`. Admin authorization must be verified on the backend (via Supabase custom claims or `user_roles` table with RLS), never by client-side string comparisons alone.
- **Reason:** Client-side role checks are vulnerable to bypass.
- **Impact:** Security rules and auth service require server-validated role.
- **Related Files:** `SECURITY_RULES.md`, `lib/services/auth_service.dart`

### DEC-012: Local-First Workflow (No Unauthorized Git Push / Publish)
- **Date:** 2026-10-19
- **Status:** CONFIRMED
- **Decision:** Keep all development work local. No pushes to GitHub, deployments, or Play Store publishing without explicit user approval. Remote `origin` configured to `https://github.com/tenaliexampublishers26/App-Tenali-Post.git`.
- **Reason:** User maintains full governance over version control releases.
- **Impact:** All commits or pushes require prior approval.
- **Related Files:** `PROJECT_CONTEXT.md`, `AGENTS.md`

### DEC-013: Android Application Package ID
- **Date:** 2026-10-19
- **Status:** PROPOSED (ACTIVE)
- **Decision:** Use application ID `com.tenaliexam.tenali_post`.
- **Reason:** Uniquely identifies Tenali Exam Publishers and the Tenali Post application on the Google Play Store; conforms to Android reverse-domain naming conventions.
- **Impact:** Set in `android/app/build.gradle` and `MainActivity.kt`.
- **Related Files:** `android/app/build.gradle`, `TECHNICAL_ARCHITECTURE.md`

### DEC-014: State Management & Architecture
- **Date:** 2026-10-19
- **Status:** PROPOSED (ACTIVE)
- **Decision:** Use `Provider` (`ChangeNotifierProvider`) for application state management and clean service repositories for Supabase access.
- **Reason:** Lightweight, officially recommended by Flutter team, zero boilerplate, robust lifecycle, and easy for future developers to maintain.
- **Impact:** Services and providers organized in `lib/services/` and `lib/providers/`.
- **Related Files:** `TECHNICAL_ARCHITECTURE.md`, `lib/providers/`

---

## Pending Decisions (Tracked for Confirmation)
1. **Live Test Retake Policy:** Whether students can retake an expired live test in "Practice Mode" for learning after official ranks are published. (*Recommended: Yes, in practice mode without altering original rank*).
2. **Push Notifications Service:** Choice between Firebase Cloud Messaging (FCM) or Supabase Broadcast/OneSignal for scheduled exam alerts. (*Recommended: FCM with Supabase Edge Functions*).
3. **Offline Video Strategy:** Whether videos are streamed via YouTube unlisted player or self-hosted in Supabase Storage with HLS streaming. (*Recommended: Embedded YouTube/Vimeo player for bandwidth efficiency*).
4. **Data Retention:** Policy for archiving old test attempt logs older than 1 academic year.