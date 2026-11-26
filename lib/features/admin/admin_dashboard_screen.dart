import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/widgets/admin_ui.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lms_admin_provider.dart';
import 'announcements/admin_announcements_screen.dart';
import 'audit/admin_audit_log_screen.dart';
import 'live_tests/lms_live_test_admin_screen.dart';
import 'mcq/lms_mcq_admin_screen.dart';
import 'notes/lms_notes_admin_screen.dart';
import 'profile/admin_profile_screen.dart';
import 'settings/admin_settings_screen.dart';
import 'settings/lms_settings_screen.dart';
import 'students/admin_student_management_screen.dart';

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
      Provider.of<LmsAdminProvider>(context, listen: false).loadOverview();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final lms = Provider.of<LmsAdminProvider>(context);

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
                  decoration: const BoxDecoration(
                    color: AppTheme.errorRedBg,
                    shape: BoxShape.circle,
                  ),
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
                  'The authenticated account (${auth.user?.email ?? 'anonymous'}) does not have administrator privileges.',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryNavy,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Go to Login Screen'),
                  onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
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

    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      appBar: AppBar(
        automaticallyImplyLeading: Navigator.canPop(context),
        title: const Text('LMS Admin Console'),
        backgroundColor: AppTheme.surfaceWarmWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: AppTheme.primaryNavy),
            tooltip: 'My Profile',
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryNavy),
            tooltip: 'Refresh Dashboard',
            onPressed: () => lms.loadOverview(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => lms.loadOverview(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Admin Identity Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryNavy,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: AppTheme.accentGold, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'LMS Admin Session Active',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          auth.user?.email ?? AppConstants.initialAdminEmail,
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        if (lms.settings.maintenanceMode)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: StatusBadge(text: 'MAINTENANCE MODE ON', color: AppTheme.errorRed),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // LMS KPIs (No E-Commerce)
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    label: 'MCQ Topics',
                    value: '${lms.topics.length}',
                    icon: Icons.account_tree_rounded,
                    color: AppTheme.primaryNavy,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatTile(
                    label: 'Total MCQs',
                    value: '${lms.totalMcqQuestionsCount}',
                    icon: Icons.quiz_rounded,
                    color: AppTheme.secondaryMaroon,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatTile(
                    label: 'Students',
                    value: '${lms.students.length}',
                    icon: Icons.people_alt_rounded,
                    color: AppTheme.successGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    label: 'Active Tests',
                    value: '${lms.activeLiveTestsCount}',
                    icon: Icons.timer_off_rounded,
                    color: AppTheme.goldBell,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatTile(
                    label: 'Submissions',
                    value: '${lms.totalLiveTestSubmissionsCount}',
                    icon: Icons.assessment_rounded,
                    color: AppTheme.primaryNavy,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatTile(
                    label: 'Study PDFs',
                    value: '${lms.notes.length}',
                    icon: Icons.picture_as_pdf_rounded,
                    color: AppTheme.secondaryMaroon,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Quick Global Feature Switches (McqToggleCard + LiveTestToggle)
            AdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Global LMS Controls',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('MCQ Practice Enabled', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    value: lms.settings.mcqEnabled,
                    onChanged: (v) => lms.toggleMcqEnabled(v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('Live Tests Enabled', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    value: lms.settings.liveTestEnabled,
                    onChanged: (v) => lms.toggleLiveTestEnabled(v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'LMS Admin Modules',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 10),

            _moduleTile(
              context,
              icon: Icons.quiz_rounded,
              color: AppTheme.secondaryMaroon,
              title: 'MCQ Hierarchy & Bulk Importer',
              subtitle: 'Recursive topics, chapters, mediums, versioned sets, CSV/XLSX/JSON import',
              badge: '${lms.totalMcqQuestionsCount} Qs',
              screen: const LmsMcqAdminScreen(),
            ),
            _moduleTile(
              context,
              icon: Icons.leaderboard_rounded,
              color: AppTheme.primaryNavy,
              title: 'Live Tests (Untimed) & Exports',
              subtitle: 'Draft/Live/Closed lifecycle, answer key release, .xlsx & .pdf rank exports',
              badge: '${lms.liveTests.length} Tests',
              screen: const LmsLiveTestAdminScreen(),
            ),
            _moduleTile(
              context,
              icon: Icons.folder_special_rounded,
              color: AppTheme.goldBell,
              title: 'Notes Folders & PDF Controls',
              subtitle: 'Recursive folders, <=50MB upload, 4-state Preview/Download permissions',
              badge: '${lms.notes.length} PDFs',
              screen: const LmsNotesAdminScreen(),
            ),
            _moduleTile(
              context,
              icon: Icons.people_rounded,
              color: AppTheme.successGreen,
              title: 'Students & Attempt Inspector',
              subtitle: 'Search students and inspect MCQ attempts, Live Test scores & bookmarks',
              badge: '${lms.students.length}',
              screen: const AdminStudentManagementScreen(),
            ),
            _moduleTile(
              context,
              icon: Icons.tune_rounded,
              color: AppTheme.primaryNavy,
              title: 'Settings & Live Notification Banner',
              subtitle: 'Maintenance Mode, feature toggles, and flash notification banner',
              screen: const LmsSettingsScreen(),
            ),
            _moduleTile(
              context,
              icon: Icons.manage_accounts_rounded,
              color: AppTheme.secondaryMaroon,
              title: 'Admin Profile & Password',
              subtitle: 'Update administrator display name, phone, and password',
              screen: const AdminProfileScreen(),
            ),
            _moduleTile(
              context,
              icon: Icons.history_edu_rounded,
              color: AppTheme.textSecondary,
              title: 'Audit History (admin_audit_logs)',
              subtitle: 'Inspect admin actions with JSON before/after diffs',
              badge: '${lms.auditLogs.length}',
              screen: const AdminAuditLogScreen(),
            ),
            _moduleTile(
              context,
              icon: Icons.campaign_rounded,
              color: AppTheme.secondaryMaroon,
              title: 'Announcements & Broadcasts',
              subtitle: 'Create and publish announcements to the student portal',
              screen: const AdminAnnouncementsScreen(),
            ),
            _moduleTile(
              context,
              icon: Icons.security_rounded,
              color: AppTheme.primaryNavy,
              title: 'Supabase Diagnostics & RLS',
              subtitle: 'Test connectivity and review RLS hardening status',
              screen: const AdminSettingsScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moduleTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    String? badge,
    required Widget screen,
  }) {
    return AdminCard(
      margin: const EdgeInsets.only(bottom: 10),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                    ),
                    if (badge != null) StatusBadge(text: badge, color: color),
                  ],
                ),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
        ],
      ),
    );
  }
}
