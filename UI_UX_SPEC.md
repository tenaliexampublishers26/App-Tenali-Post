# UI_UX_SPEC.md — Tenali Post UI/UX Specification

This specification documents the user interface design system, branding guidelines, color palette, typography, and screen specifications for the **Tenali Post** native Android application.

---

## 1. Official Brand Identity & Artwork

### Verified Logo Asset
- **Asset Path:** `assets/images/tenali_post_logo.png`
- **Artwork Description:** Official circular crest seal featuring:
  - Outer golden beaded border with star accents.
  - Dark Navy circular banner with gold-embossed serif typography: `TENALI`.
  - Centerpiece: Open academic textbook with golden fountain pen nib.
  - Three-dimensional red-and-gold central emblem: `POSTAL ACADEMY`.
  - Red ribbon banner with motto: `LEARN • PREPARE • SUCCEED`.
  - Bottom rocker banner: `Excellence in Postal & Competitive Exams`.
- **Integrity Rule:** The logo artwork must NEVER be modified, distorted, or replaced by AI-generated assets.

---

## 2. Derived Color Palette & Design Tokens (Matched to Uploaded Reference)

| Token Name | Hex Code | Visual Swatch Role |
| :--- | :--- | :--- |
| `primaryNavy` | `#0B2545` | Title text, exam icons, branding accents |
| `primaryDark` | `#07182C` | Deep gradients, drawer headers, splash screen |
| `secondaryMaroon` | `#C81D25` | Vibrant Postal Crimson, Live Test banner, active bottom tab icon |
| `goldBorder` | `#C89B3C` | Outer golden border of the Welcome/Plaque Card, official seal rim |
| `goldInnerBorder`| `#DFBC69` | Inner accent border on gold greeting card |
| `goldGradientStart`| `#FAF2DC`| Top-left champagne gold fill for candidate greeting card |
| `goldGradientEnd`| `#F5E4B5` | Bottom-right gold shimmer fill |
| `goldChipBg` | `#DCA938` | "SESSION 2026" badge pill background |
| `goldBell` | `#D97706` | Top app bar notification bell amber/gold |
| `bgWarm` | `#FAF7EE` | Warm parchment / cream backdrop for page scaffolds |
| `surfaceWarmWhite`| `#FFFDF8` | Card backgrounds, top AppBar, bottom navigation |
| `surfaceCream` | `#F4EFE6` | Exam card icon container fill |
| `borderWarmSubtle`| `#EADBBE` | Delicate warm borders on cards and navigation dividers |
| `textPrimary` | `#0F172A` | High-contrast deep slate for question text and titles |
| `textSecondary` | `#475569` | Subtitles, explanation text, descriptions |
| `textMuted` | `#94A3B8` | Subtle hints, chevrons, unattempted counters |
| `successGreen` | `#059669` | Correct answers, accuracy score, "FREE" pill badge on MCQs |
| `successGreenBg`| `#ECFDF5` | Soft green background for correct options |
| `errorRed` | `#EF4444` | Incorrect answers, timer alert (<5m), exit warning |
| `errorRedBg` | `#FEF2F2` | Soft red background for incorrect options |
| `viewAllRed` | `#B91C1C` | "View All" action text on home screen |

---

## 3. Typography Hierarchy
- **Primary Body Font:** Inter / System Default Sans
- **Headings Font:** Outfit / Semi-Bold System Sans
- **Scale:**
  - App Bar Title: 18sp, Bold (w700)
  - Screen Headings: 22sp - 26sp, Extra Bold (w800)
  - Question Text: 16sp, Bold (w700), Line Height 1.45
  - Option Text: 14sp, Medium (w500)
  - Explanation Body: 12.5sp, Regular (w400)
  - Badges & Pills: 9sp - 11sp, Extra Bold (w800/w900)

---

## 4. Navigation Architecture

### Persistent Bottom Navigation (5 Items)
1. **Home:** Icon: `Icons.home_outlined` / `Icons.home_rounded`
2. **MCQs:** Icon: `Icons.quiz_outlined` / `Icons.quiz_rounded` with green `FREE` pill badge
3. **Videos:** Icon: `Icons.play_circle_outline_rounded` / `Icons.play_circle_fill_rounded`
4. **Live Tests:** Icon: `Icons.timer_outlined` / `Icons.timer_rounded` with red live beacon dot
5. **Notes:** Icon: `Icons.menu_book_outlined` / `Icons.menu_book_rounded`

### Navigation Drawer
- Gradient Navy header featuring user avatar, candidate name, postal circle, and `ADMINISTRATOR` badge when authorized.
- Navigation links: Home, MCQs (`FREE`), Videos, Live Tests (`LIVE`), Notes, My Profile, Test History, Notifications, Settings, Help & Support.
- Protected `Admin Panel` tile (visible only to verified administrators).
- Dedicated `Log Out` button with red accent.

---

## 5. Screen Specifications

### 1. Splash Screen (`SplashScreen`)
- Fullscreen navy background with subtle golden circular glow.
- Animated scaling & fading official Tenali Postal Academy logo.
- Application title and maroon tagline badge (`LEARN • PREPARE • SUCCEED`).
- Session verification indicator directing to `/home` or `/login`.

### 2. Login Screen (`LoginScreen`)
- Prominent official logo badge.
- Google Sign-In with Supabase Auth.
- Fast Demo Candidate Login (for offline/local demonstration).
- Administrator Sign-In shortcut (`tenaliexamspublishers26@gmail.com`).
- Departmental examination preparation notice.

### 3. Home Dashboard (`HomeScreen`)
- Custom branded App Bar with logo, title, and notification bell.
- Welcome candidate greeting card with postal circle affiliation.
- Live test alert banner with "JOIN NOW" shortcut.
- Departmental Exams list (MTS, Postman/Mail Guard, PA/SA, LGO).
- Daily Postal Rule card with PO Guide citations.

### 4. Exam & Chapter Selection (`ExamListScreen` & `ChapterListScreen`)
- Exam card with total chapters, questions, and code badge.
- Language selector chips (English, Telugu `తెలుగు`, Hindi `हिन्दी`).
- Chapter cards with syllabus breakdown and question counts.

### 5. MCQ Practice Mode (`McqPracticeScreen`)
- Real-time progress bar (e.g. `Question 1 of 40`).
- Real-time score pills: Correct (Green `[✓]`), Incorrect (Red `[✕]`).
- Instant Feedback upon option selection:
  - Correct selection: Green fill, green border, checkmark icon.
  - Incorrect selection: Red fill, red border, X icon, plus correct answer revealed in green.
  - Detailed Explanation Card with postal rule reference.
- Bottom navigation with `Previous` and `Next` buttons.

### 6. Live Mock Examination (`LiveTestRunnerScreen`)
- Live countdown timer with auto-submit upon reaching `00:00`.
- Timer turns red when less than 5 minutes remain.
- Zero answer leaks: answer keys and explanations are omitted on the client during testing.
- Question palette and option clearing.
- Submission confirmation dialog displaying attempted and unattempted counts.

### 7. Examination Results (`LiveTestResultScreen`)
- Hero Scorecard with total marks, marks obtained, and percentage.
- Correct, Wrong, and Skipped stat cards.
- Complete question-by-question answer key and solution review unlocked post-submission.

### 8. Admin Management Console (`AdminDashboardScreen`)
- Metrics cards for total exams, active live tests, and questions.
- CSV/JSON question import with Unicode Telugu/Hindi validation and duplicate checking.
- Live test scheduler dialog.
- Student ranking export to PDF/Excel.
- Audit log monitor.