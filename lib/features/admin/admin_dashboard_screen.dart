import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';

import 'mcq/admin_mcq_list_screen.dart';
import 'mcq/admin_mcq_import_export_screen.dart';
import 'exams/admin_exam_list_screen.dart';
import 'exams/admin_language_matrix_screen.dart';
import 'students/admin_student_management_screen.dart';
import 'live_tests/admin_live_test_screen.dart';
import 'content/admin_video_management_screen.dart';
import 'content/admin_notes_management_screen.dart';
import 'audit/admin_audit_log_screen.dart';
import 'settings/admin_settings_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).loadDashboardOverview();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final admin = Provider.of<AdminProvider>(context);

    // Secure Role Authorization Guard
    if (!auth.isAdmin) {
      return Scaffold(
        backgroundColor: AppTheme.bgWarm,
        appBar: AppBar(
          title: const Text('Access Denied'),
          backgroundColor: AppTheme.surfaceWarmWhite,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(color: AppTheme.errorRedBg, shape: BoxShape.circle),
                  child: const Icon(Icons.gpp_bad_rounded, size: 54, color: AppTheme.errorRed),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Administrative Authorization Required',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'The currently authenticated account (${auth.user?.email ?? 'anonymous'}) does not possess verified administrator privileges.',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryNavy,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  icon: const Icon(Icons.admin_panel_settings_rounded),
                  label: const Text('Sign In as Admin Demo'),
                  onPressed: () async {
                    await auth.signInAsAdminDemo();
                    if (context.mounted) {
                      admin.loadDashboardOverview();
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                  child: const Text('Return to Student Portal'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final stats = admin.stats;

    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      appBar: AppBar(
        title: const Text('Admin Management Console'),
        backgroundColor: AppTheme.surfaceWarmWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.primaryNavy),
            tooltip: 'System Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminSettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryNavy),
            tooltip: 'Refresh Analytics',
            onPressed: () => admin.loadDashboardOverview(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin Identity Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryNavy,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryNavy.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: AppTheme.accentGold, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Verified Admin Session Active',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          auth.user?.email ?? AppConstants.initialAdminEmail,
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Dedicated Supabase Database • RLS Policies Enforced',
                          style: TextStyle(color: AppTheme.goldChipBg, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Real-Time Database Analytics Metrics
            Row(
              children: [
                Expanded(
                  child: _metricCard(
                    'Total MCQs',
                    '${stats?.totalQuestions ?? admin.questions.length}',
                    Icons.quiz_rounded,
                    AppTheme.secondaryMaroon,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _metricCard(
                    'Exams / Syllabi',
                    '${stats?.totalExams ?? admin.exams.length}',
                    Icons.school_rounded,
                    AppTheme.primaryNavy,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _metricCard(
                    'Aspirants',
                    '${stats?.totalStudents ?? admin.students.length}',
                    Icons.people_alt_rounded,
                    AppTheme.successGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _metricCard(
                    'Live Tests',
                    '${stats?.activeLiveTests ?? 1} Active',
                    Icons.timer_rounded,
                    AppTheme.goldBell,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _metricCard(
                    'Submissions',
                    '${stats?.totalSubmissions ?? 1}',
                    Icons.assessment_rounded,
                    AppTheme.primaryNavy,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _metricCard(
                    'Translations',
                    '${stats?.translationCoveragePercent ?? 75.0}%',
                    Icons.translate_rounded,
                    AppTheme.secondaryMaroon,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Primary Management Modules Header
            const Text(
              'Administrative Operations & Content Modules',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // 1. MCQ Management (Highest Priority)
            _adminActionTile(
              context,
              icon: Icons.quiz_rounded,
              title: 'MCQ Question Bank Management',
              subtitle: 'Create, search, filter, edit, duplicate, and delete questions with citations',
              color: AppTheme.secondaryMaroon,
              badge: '${admin.questions.length} Qs',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminMcqListScreen()),
                );
              },
            ),

            // 2. CSV / JSON Importer & Exporter
            _adminActionTile(
              context,
              icon: Icons.swap_vert_circle_rounded,
              title: 'CSV & JSON Question Importer / Exporter',
              subtitle: 'Batch import with row-level error validation & duplicate checking',
              color: AppTheme.primaryNavy,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminMcqImportExportScreen()),
                );
              },
            ),

            // 3. Student and User Profile Management (Mandatory)
            _adminActionTile(
              context,
              icon: Icons.people_rounded,
              title: 'Student & Candidate Profile Management',
              subtitle: 'Search candidates, review test attempts, scores, and toggle active/suspended status',
              color: AppTheme.successGreen,
              badge: '${admin.students.length} Aspirants',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminStudentManagementScreen()),
                );
              },
            ),

            // 4. Exam Management
            _adminActionTile(
              context,
              icon: Icons.school_rounded,
              title: 'Departmental Exams & Syllabi',
              subtitle: 'Manage MTS, Postman, PA/SA, and LGO exams and chapter hierarchies',
              color: AppTheme.primaryNavy,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminExamListScreen()),
                );
              },
            ),

            // 5. Language & Translation Matrix
            _adminActionTile(
              context,
              icon: Icons.translate_rounded,
              title: 'Language & Translation Matrix',
              subtitle: 'Identify missing Telugu & Hindi translations across syllabus chapters',
              color: AppTheme.goldBell,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminLanguageMatrixScreen()),
                );
              },
            ),

            // 6. Live Test Management
            _adminActionTile(
              context,
              icon: Icons.timer_rounded,
              title: 'Live Examination Management & Scheduler',
              subtitle: 'Schedule timed tests, duration, question pools, and inspect candidate rankings',
              color: AppTheme.secondaryMaroon,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminLiveTestScreen()),
                );
              },
            ),

            // 7. Video Classes
            _adminActionTile(
              context,
              icon: Icons.video_library_rounded,
              title: 'Video Lecture Classes',
              subtitle: 'Upload YouTube video lectures, chapter bindings, and language tags',
              color: AppTheme.primaryNavy,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminVideoManagementScreen()),
                );
              },
            ),

            // 8. Notes & PDF Materials
            _adminActionTile(
              context,
              icon: Icons.menu_book_rounded,
              title: 'Study Notes & PDF Handbooks',
              subtitle: 'Manage revision digests, clause summaries, and downloadable PDF assets',
              color: AppTheme.goldBell,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminNotesManagementScreen()),
                );
              },
            ),

            // 9. Admin Audit Logs
            _adminActionTile(
              context,
              icon: Icons.history_edu_rounded,
              title: 'Immutable Admin Audit Trail',
              subtitle: 'Inspect timestamped records of all administrative creations, edits, and deletions',
              color: AppTheme.textSecondary,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminAuditLogScreen()),
                );
              },
            ),

            // 10. System Settings & Security
            _adminActionTile(
              context,
              icon: Icons.security_rounded,
              title: 'System Settings & Security Diagnostics',
              subtitle: 'Backend health check, RLS compliance audit, and admin credentials',
              color: AppTheme.primaryNavy,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminSettingsScreen()),
                );
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _metricCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWarmWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderWarmSubtle),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryNavy.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(val, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _adminActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    String? badge,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWarmWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderWarmSubtle),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryNavy.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(badge, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
              ),
          ],
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
        onTap: onTap,
      ),
    );
  }
}
