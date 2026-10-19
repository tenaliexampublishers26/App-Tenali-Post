# SECURITY_RULES.md — Tenali Post Security Specifications

This document defines mandatory security controls and validation requirements for the **Tenali Post** application and its dedicated backend.

---

## 1. Authentication Security
- **Primary Mechanism:** Supabase Auth utilizing Google OAuth provider (`tenalipost://login-callback`).
- **Session Tokens:** Securely stored using `flutter_secure_storage` on device keychain/keystore.
- **Session Restoration:** Validated on app startup with graceful token refresh; expired sessions redirect safely to the login screen.
- **Client Assertion Prohibition:** The server must never trust a client-supplied role, user ID, or email as proof of administrative authorization.

---

## 2. Administrator Access Controls
- **Initial Administrator:** `tenaliexamspublishers26@gmail.com`.
- **Server-Side Enforcement:** Administrative operations (creating exams, publishing tests, deleting questions, importing CSVs) are authorized exclusively via PostgreSQL Row Level Security (RLS) policies and trusted server-side functions.
- **Tamper Protection:** Ordinary students cannot alter their own role, change test scores, or view other students' private records.

---

## 3. Dedicated Backend Isolation
- **E-Commerce Isolation:** Tenali Post MUST operate in a separate, dedicated Supabase project. It must NEVER connect to, alter, or share keys with the existing Tenali Exams Publishers e-commerce database.
- **Secret Protection:** Service-role keys and database passwords must NEVER be embedded in Flutter Dart code, assets, or Git history. Use only the public client key (`publishableKey` / `anonKey`) protected by RLS.

---

## 4. Live Test Integrity & Anti-Cheating
1. **Zero Answer Key Leaks:** Correct options (`correct_option`) and explanations (`explanation`) MUST NEVER be transmitted to student devices prior to official test submission or scheduled result release.
2. **Server-Side Scoring:** Candidate submissions record student choices (`answers`); final scores and percentages are verified server-side.
3. **Timer & Auto-Submit:** Client enforces an auto-submission trigger when the countdown expires; server records submission timestamps and rejects late attempts.
4. **Duplicate Submission Prevention:** Live test submissions enforce a unique constraint on `(test_id, user_id)` to prevent replay attacks or multiple submissions.

---

## 5. CSV/JSON Import Validation
- All bulk question imports must validate:
  - Required fields (`exam_code`, `chapter_number`, `lang_code`, `question_text`, options A-D, `correct_option`).
  - Answer keys strictly within `['A', 'B', 'C', 'D']`.
  - UTF-8 encoding integrity for Telugu and Hindi characters.
  - Duplicate detection by hashing `(exam_code, chapter_number, lang_code, question_text)`.

---

## 6. Security Audit Checklist
- [x] No hardcoded service-role secrets in Flutter code or repository.
- [x] `assets/images/tenali_post_logo.png` verified and preserved.
- [x] Live test question model excludes `correct_option` and `explanation` by default.
- [x] Local-first Git workflow enforced (no commits or pushes without explicit user approval).
- [x] Application package ID configured: `com.tenaliexam.tenali_post`.