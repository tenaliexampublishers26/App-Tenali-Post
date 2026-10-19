# TESTING.md — Tenali Post Test Reports & Evidence

This document records the testing strategy, commands executed, and verified pass/fail results for the **Tenali Post** native Android application.

---

## 1. Static Analysis Report

- **Command:** `flutter analyze`
- **Working Directory:** `C:\Users\Team3\OneDrive\Desktop\tenali post`
- **Date:** 2026-10-19
- **Outcome:** **PASS (0 issues found)**
- **Console Evidence:**
  ```
  Analyzing tenali post...
  No issues found! (ran in 11.5s)
  ```

---

## 2. Automated Test Suite Report

- **Command:** `flutter test`
- **Working Directory:** `C:\Users\Team3\OneDrive\Desktop\tenali post`
- **Date:** 2026-10-19
- **Outcome:** **PASS (15/15 tests passed — 100% success rate)**
- **Console Evidence:**
  ```
  00:00 +0: loading C:/Users/Team3/OneDrive/Desktop/tenali post/test/admin_service_test.dart
  00:00 +0: C:/Users/Team3/OneDrive/Desktop/tenali post/test/widget_test.dart: Tenali Post Architecture & Model Tests Question model serializes and hides answer key when requested
  00:00 +1: C:/Users/Team3/OneDrive/Desktop/tenali post/test/admin_service_test.dart: Admin Authorization Tests Recognizes primary superadmin email
  00:00 +2: C:/Users/Team3/OneDrive/Desktop/tenali post/test/widget_test.dart: Tenali Post Architecture & Model Tests LiveTest model correctly determines ongoing and upcoming status
  00:00 +3: C:/Users/Team3/OneDrive/Desktop/tenali post/test/admin_service_test.dart: Admin Authorization Tests Rejects unauthorized student email
  00:00 +4: C:/Users/Team3/OneDrive/Desktop/tenali post/test/widget_test.dart: Tenali Post Architecture & Model Tests Exam model contains valid India Post departmental data
  00:00 +5: C:/Users/Team3/OneDrive/Desktop/tenali post/test/admin_service_test.dart: CSV & JSON Import Validation Tests Validates compliant CSV questions across EN, TE, and HI
  00:00 +6: C:/Users/Team3/OneDrive/Desktop/tenali post/test/widget_test.dart: Tenali Post Architecture & Model Tests Sample questions cover English, Telugu, and Hindi languages
  00:00 +7: C:/Users/Team3/OneDrive/Desktop/tenali post/test/admin_service_test.dart: CSV & JSON Import Validation Tests Detects invalid answer keys, missing fields, and duplicate IDs in CSV
  00:00 +8: C:/Users/Team3/OneDrive/Desktop/tenali post/test/admin_service_test.dart: CSV & JSON Import Validation Tests Validates compliant JSON question imports
  00:00 +9: C:/Users/Team3/OneDrive/Desktop/tenali post/test/admin_service_test.dart: CSV & JSON Import Validation Tests Rejects invalid JSON formatting
  00:00 +10: C:/Users/Team3/OneDrive/Desktop/tenali post/test/admin_service_test.dart: Question Bank CRUD & Duplication Tests Admin can create, duplicate, toggle status, and delete questions
  00:00 +11: C:/Users/Team3/OneDrive/Desktop/tenali post/test/admin_service_test.dart: Exam & Chapter Safety Deletion Tests Prevents accidental deletion of exam referenced by existing questions
  00:00 +12: C:/Users/Team3/OneDrive/Desktop/tenali post/test/admin_service_test.dart: Exam & Chapter Safety Deletion Tests Prevents accidental deletion of chapter referenced by existing questions
  00:00 +13: C:/Users/Team3/OneDrive/Desktop/tenali post/test/admin_service_test.dart: Student Profile Management Tests Admin can fetch, update cadre/circle, and suspend/activate students
  00:00 +14: C:/Users/Team3/OneDrive/Desktop/tenali post/test/admin_service_test.dart: Audit Log Logging Tests Logs administrative actions to immutable audit log
  00:00 +15: All tests passed!
  ```

---

## 3. Test Details

### Suite A: Core Architecture & Security Models (`test/widget_test.dart`)

#### Test 1: Question Model & Security Answer Key Hiding
- **Purpose:** Verifies that question options serialize properly and that calling `toJson(includeAnswer: false)` strips `correct_option` and `explanation` so no answers leak in active live tests.
- **Status:** **PASS**

#### Test 2: LiveTest Timing Status Calculation
- **Purpose:** Verifies that active live tests accurately determine `isOngoing`, `isEnded`, and `isUpcoming` against real timestamps.
- **Status:** **PASS**

#### Test 3: Departmental Exam Data Validation
- **Purpose:** Verifies that exam categories (MTS, Postman/Mail Guard, PA/SA, LGO) contain valid titles and departmental codes.
- **Status:** **PASS**

#### Test 4: Multilingual Hierarchy Validation
- **Purpose:** Verifies that question datasets support English (`en`), Telugu (`te`), and Hindi (`hi`) without cross-language contamination.
- **Status:** **PASS**

---

### Suite B: Production Admin Services & Operations (`test/admin_service_test.dart`)

#### Test 5 & 6: Admin Authorization Guard
- **Purpose:** Verifies `tenaliexamspublishers26@gmail.com` is granted administrative access while rejecting ordinary candidate emails or null sessions.
- **Status:** **PASS**

#### Test 7, 8, 9 & 10: CSV & JSON Import Validation & Error Handling
- **Purpose:** Validates UTF-8 Telugu/Hindi questions; asserts strict rejection of malformed CSVs (missing required question text, invalid answer keys like 'Z', duplicate question IDs); verifies compliant JSON array parsing; ensures syntax error reporting for invalid JSON root.
- **Status:** **PASS**

#### Test 11: Question Bank CRUD & Duplication
- **Purpose:** Verifies creating questions, duplicating into draft mode with `_copy_` suffix, toggling published/draft state, and deleting from synchronized store.
- **Status:** **PASS**

#### Test 12 & 13: Exam & Chapter Safety Deletion
- **Purpose:** Ensures destructive deletions throw user-facing exceptions when exams or chapters still contain active questions or child chapters, preventing accidental orphaned database rows.
- **Status:** **PASS**

#### Test 14: Student Profile Management & Suspension
- **Purpose:** Tests fetching student roster, updating postal circle and cadre promotion goals, and toggling active/suspended status.
- **Status:** **PASS**

#### Test 15: Immutable Audit Log Generation
- **Purpose:** Verifies that administrative operations create persistent timestamped audit records with target entity and admin email.
- **Status:** **PASS**

---

## 4. Environment & Device Availability Checks

- **Command:** `flutter doctor`
  - Flutter SDK 3.47.7: **VERIFIED**
  - Dart SDK 3.13.5: **VERIFIED**
  - Android SDK / Android Studio: **NOT INSTALLED ON HOST** (see `SETUP.md` for installation steps)
  - Visual Studio C++: Not installed (Windows desktop development disabled, targeting Android only)
  - Connected Devices: Windows, Chrome, Edge (Web/Desktop runtimes available; Android target awaits Android Studio installation).