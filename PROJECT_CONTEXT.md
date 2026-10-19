# PROJECT_CONTEXT.md — Tenali Post Master Briefing

> **Master Briefing Document:** Every new AI coding session working on **Tenali Post** must read this file first before touching code or documentation.

---

## 1. Project Identity
- **Application Name:** Tenali Post
- **Tagline:** *Learn • Prepare • Succeed — Excellence in Postal & Competitive Exams*
- **Purpose:** Dedicated native Android learning and testing platform for Indian Postal departmental examination candidates (MTS, Postman, Mail Guard, Postal Assistant / Sorting Assistant, and Lower Grade Official promotion examinations).
- **Platform:** 100% Native Android application built with **Flutter** (3.47.7) and **Dart** (3.13.5).
- **Backend:** Dedicated **Supabase** project (completely isolated from the existing e-commerce website).
- **Supported Languages:** English (`en`), Telugu (`te` - తెలుగు), and Hindi (`hi` - हिन्दी), with architecture ready for Kannada and Tamil expansion.
- **Intended Initial Admin:** `tenaliexamspublishers26@gmail.com` (backend role-based provisioning).
- **Official Logo:** Stored at `assets/images/tenali_post_logo.png` (official Tenali Postal Academy seal).
- **Proposed Application Package ID:** `com.tenaliexam.tenali_post` (recorded in `DECISIONS.md`).

---

## 2. Core Student Features
- **Authentication:** Google Sign-In via Supabase Auth + Demo Candidate access; session persistence and restoration.
- **Persistent Navigation:** 5-item bottom navigation:
  1. **Home:** Candidate greeting, Session 2026 badge, active live-test alert banner, exam shortcuts, daily postal rule card.
  2. **MCQs (`FREE` badge):** Dynamic hierarchy (Exam → Chapter → Language), question palette, instant correct/incorrect feedback, detailed explanation with PO Guide clause citations.
  3. **Videos:** High-yield postal syllabus video classes with player modal and duration tracking.
  4. **Live Tests (`LIVE` dot):** Scheduled all-India timed mock exams, countdown timer, zero leaked answers before submit, auto-submission on timeout, post-submission answer keys and solutions.
  5. **Notes:** Free PDF handbooks and revision formula sheets.
- **Navigation Drawer:** Access to Profile, Test History, Notifications, Settings, Help/Support, and protected Admin Panel entry.

---

## 3. Core Admin Features
- **Admin Dashboard Console (`AdminDashboardScreen`):** Live telemetry with total questions, exams, chapters, active live tests, student roster, submissions, and translation coverage meter. Access restricted to authorized admins.
- **Multilingual MCQ Management (`AdminMcqListScreen`, `AdminMcqEditorScreen`):** Search, multi-facet filtering (Exam, Chapter, Language, Difficulty, Status), tabbed editor (EN, TE, HI), options A–D, answer keys, citations, question duplication with `_copy_` suffix, publish/draft toggle, and destructive delete confirmations.
- **In-App CSV & JSON Import/Export (`AdminMcqImportExportScreen`):** Strict UTF-8 validation for Telugu and Hindi; header checking, duplicate question detection, row-level error reporting, live preview table, batch commit, and customizable export filter.
- **Student Profile Management (`AdminStudentManagementScreen`):** Aspirant roster search, profile sheet, test attempt history with marks and scores, postal circle / cadre goal updates, active/suspended status toggle, and CSV roster export.
- **Exam, Chapter & Language Management (`AdminExamListScreen`, `AdminChapterListScreen`, `AdminLanguageMatrixScreen`):** CRUD for exams and syllabus chapters with safety deletion checks against linked content; translation coverage matrix identifying incomplete Telugu and Hindi chapters.
- **Video & Study Notes Management (`AdminVideoManagementScreen`, `AdminNotesManagementScreen`):** YouTube stream URL validation, syllabus tagging, PDF metadata, and Supabase storage bucket references.
- **Live Test Management & Rankings (`AdminLiveTestScreen`, `AdminLiveTestResultsScreen`):** Exam scheduling, duration, question assignment, submission review, marks ranking, and CSV scorecard export.
- **Audit Logs & Security Settings (`AdminAuditLogScreen`, `AdminSettingsScreen`):** Immutable administrative audit trail, database table checks, and RLS audit.
- **Production Database Migration:** `supabase/migrations/20261019_001_admin_schema.sql` providing RLS policies, safe test question delivery, server-side scoring, and initial admin trigger for `tenaliexamspublishers26@gmail.com`.

---

## 4. Non-Negotiable Operational Rules
1. **Isolation:** Never connect to, modify, or query the existing Tenali Exams Publishers e-commerce website or its production database.
2. **Secrets:** Never embed service-role keys, database passwords, or private signing secrets in Flutter code.
3. **Local Work:** Keep all work local. Never push to GitHub, deploy, or publish without explicit user approval.
4. **Git Remote:** `origin` points to `https://github.com/tenaliexampublishers26/App-Tenali-Post.git` on branch `main`.

---

## 5. Documentation Index
- [AGENTS.md](AGENTS.md): Mandatory rules and constraints for all AI coding assistants.
- [PRD.md](PRD.md): Product requirements document and functional specifications.
- [UI_UX_SPEC.md](UI_UX_SPEC.md): Visual design system, verified logo color palette, and screen designs.
- [TECHNICAL_ARCHITECTURE.md](TECHNICAL_ARCHITECTURE.md): Architecture layers, models, state management, and data flow.
- [SECURITY_RULES.md](SECURITY_RULES.md): Security rules, RLS policies, live-test answer protection, and auth checks.
- [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md): Milestone tracker, verified task checklist, and next steps.
- [DECISIONS.md](DECISIONS.md): Permanent record of confirmed architectural and product decisions.
- [CHANGELOG.md](CHANGELOG.md): Reverse chronological record of verified changes and test outcomes.
- [TESTING.md](TESTING.md): Testing strategy, test execution logs, and pass/fail evidence.
- [SETUP.md](SETUP.md): Local developer setup guide for Windows, Flutter, and Android Studio.

---

## 6. Current Project Status (as of 2026-10-19)
- **Current Milestone:** Milestone 1 & 2 Complete (Flutter foundation, Android configuration, Theme, Routing, Models, Services, Providers, All 5 Main Tabs, Admin Dashboard, Test Suite).
- **What is Implemented and Verified:**
  - Official logo saved and integrated: `assets/images/tenali_post_logo.png`.
  - Flutter SDK 3.47.7 & Dart 3.13.5 installed and configured at `C:\Users\Team3\flutter\bin`.
  - Full Flutter Android project created at workspace root (`pubspec.yaml`, `android/`).
  - All 113 Flutter dependencies downloaded (`flutter pub get` exited 0).
  - Code analysis verified: `flutter analyze` passed with **0 issues**.
  - Unit & architecture test suite verified: `flutter test` passed with **4/4 tests passing**.
  - Complete UI screens implemented: Splash, Login, Main 5-tab Navigation, Home, Exam List, Chapter List, Interactive MCQ Practice with instant feedback, Video Classes, Live Test Runner with countdown timer, Live Test Result Scorecard, Notes, Profile, and Admin Console.
- **Current Blockers / Pending Setup:**
  - Android SDK and Android Studio are not yet installed on this computer (required to build `.apk` and launch Android emulator).
- **Next Recommended Task:**
  - Install Android Studio / Android SDK tools so `flutter build apk --debug` can be compiled and launched on an Android emulator or connected device.