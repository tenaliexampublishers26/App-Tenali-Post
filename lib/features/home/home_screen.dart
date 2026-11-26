import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lms_admin_provider.dart';
import '../../providers/notification_provider.dart';
import '../../shared/tenali_top_app_bar.dart';

class HomeScreen extends StatelessWidget {
  final Function(int) onNavigateTab;

  const HomeScreen({super.key, required this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final lmsProvider = Provider.of<LmsAdminProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      appBar: const TenaliTopAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            notificationProvider.loadAnnouncements(
              userId: user?.id,
              isAdmin: authProvider.isAdmin,
            ),
            lmsProvider.loadStudentPortalData(isAdmin: authProvider.isAdmin),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Candidate Greeting & Postal Cadre Hero Banner
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryNavy, AppTheme.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryNavy.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.accentGold.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'DEPARTMENTAL EXAM PORTAL',
                              style: TextStyle(
                                color: AppTheme.accentGold,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Namaste, ${user?.fullName.split(' ').first ?? 'Candidate'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.location != null && user!.location!.isNotEmpty
                                ? 'Postal Circle: ${user.location}'
                                : 'Master your departmental exam syllabus',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: AppTheme.accentGold,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Admin Live Flash Notification Banner (from settings.live_notification_*)
              if (lmsProvider.settings.liveNotificationEnabled &&
                  lmsProvider.settings.liveNotificationText.trim().isNotEmpty) ...[
                InkWell(
                  onTap: () => onNavigateTab(2),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.goldGradientStart,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.goldBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active_rounded,
                            color: AppTheme.secondaryMaroon, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            lmsProvider.settings.liveNotificationText,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryNavy,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Recent Announcements Highlights Banner
              if (notificationProvider.announcements.isNotEmpty) ...[
                Builder(
                  builder: (context) {
                    final latest = notificationProvider.announcements.firstWhere(
                      (a) => a.isPublished,
                      orElse: () => notificationProvider.announcements.first,
                    );
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryMaroon.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.secondaryMaroon.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.campaign_rounded, color: AppTheme.secondaryMaroon, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  latest.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AppTheme.primaryNavy,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  latest.message,
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () => Navigator.pushNamed(context, '/notifications'),
                            child: const Text('View', style: TextStyle(color: AppTheme.secondaryMaroon, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),
              ],

              // Examination Tracks Header
              const Text(
                'Departmental Examination Tracks',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryNavy,
                ),
              ),
              const SizedBox(height: 12),

              // 1. Featured Live Tests Banner Card (Navigates to Live Tests Tab: 2)
              InkWell(
                onTap: () => onNavigateTab(2),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.secondaryMaroon.withValues(alpha: 0.06),
                        AppTheme.secondaryMaroon.withValues(alpha: 0.02),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.secondaryMaroon.withValues(alpha: 0.3), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.secondaryMaroon.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryMaroon.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.timer_rounded,
                          color: AppTheme.secondaryMaroon,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Live Tests & Mocks',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: AppTheme.primaryNavy,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: lmsProvider.settings.liveTestEnabled
                                        ? AppTheme.secondaryMaroon
                                        : Colors.grey.shade600,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    lmsProvider.settings.liveTestEnabled ? 'LIVE' : 'PAUSED',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lmsProvider.settings.liveTestEnabled
                                  ? '${lmsProvider.activeLiveTestsCount} active test(s) • Answer keys when released'
                                  : 'Live tests temporarily paused by admin',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: AppTheme.secondaryMaroon,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 2. MCQ Practice Bank, Video Lessons & Study Notes Tracks
              _actionCard(
                icon: Icons.quiz_rounded,
                title: 'MCQ Practice Bank',
                subtitle: lmsProvider.settings.mcqEnabled
                    ? '${lmsProvider.topics.where((t) => t.isPublished).length} Topics • Chapter-wise MCQs'
                    : 'Paused by administrator (Coming Soon)',
                badge: lmsProvider.settings.mcqEnabled ? 'PRACTICE' : 'PAUSED',
                color: lmsProvider.settings.mcqEnabled
                    ? AppTheme.primaryNavy
                    : AppTheme.textMuted,
                onTap: () => onNavigateTab(3),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _actionCard(
                      icon: Icons.play_circle_fill_rounded,
                      title: 'Video Lessons',
                      subtitle: 'PO Guide & Rules',
                      color: const Color(0xFF0F766E),
                      onTap: () => onNavigateTab(1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _actionCard(
                      icon: Icons.menu_book_rounded,
                      title: 'Study Notes',
                      subtitle: '${lmsProvider.notes.length} PDF(s) Available',
                      color: const Color(0xFFB45309),
                      onTap: () => onNavigateTab(4),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    String? badge,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderWarmSubtle),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
