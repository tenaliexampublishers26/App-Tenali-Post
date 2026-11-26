import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';

class CustomAppDrawer extends StatelessWidget {
  final Function(int) onSelectTab;

  const CustomAppDrawer({
    super.key,
    required this.onSelectTab,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final user = authProvider.user;
    final bool isAdmin = authProvider.isAdmin;
    final int unreadCount = notificationProvider.unreadCount;

    return Drawer(
      backgroundColor: AppTheme.surfaceWhite,
      child: Column(
        children: [
          // Header with Complete Candidate Profile Details
          Container(
            padding: const EdgeInsets.fromLTRB(18, 44, 18, 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryNavy, AppTheme.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Logo & Close Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.accentGold, width: 1.5),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              AppConstants.logoAsset,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.local_post_office_rounded,
                                color: AppTheme.accentGold,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Candidate Profile',
                          style: TextStyle(
                            color: AppTheme.accentGold,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Candidate Name & Role Badge
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      child: Text(
                        (user?.fullName.isNotEmpty == true)
                            ? user!.fullName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
                            : 'TP',
                        style: const TextStyle(
                          color: AppTheme.accentGold,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName.isNotEmpty == true ? user!.fullName : 'Postal Candidate',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isAdmin ? AppTheme.secondaryMaroon : AppTheme.accentGold.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isAdmin ? AppTheme.secondaryMaroon : AppTheme.accentGold,
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              isAdmin ? 'ADMINISTRATOR' : 'POSTAL CANDIDATE',
                              style: TextStyle(
                                color: isAdmin ? Colors.white : AppTheme.accentGold,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Candidate Details Box (Email, Phone, Location)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    children: [
                      _drawerProfileDetailRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: user?.email ?? 'Not Set',
                      ),
                      const SizedBox(height: 6),
                      _drawerProfileDetailRow(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        value: (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty)
                            ? user.phoneNumber!
                            : 'Not Set',
                      ),
                      const SizedBox(height: 6),
                      _drawerProfileDetailRow(
                        icon: Icons.location_on_outlined,
                        label: 'Location',
                        value: (user?.location != null && user!.location!.isNotEmpty)
                            ? user.location!
                            : (user?.postalCircle ?? 'Not Set'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Quick Edit Profile Action
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 14, color: AppTheme.accentGold),
                    label: const Text(
                      'View / Edit Profile Details',
                      style: TextStyle(color: AppTheme.accentGold, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/profile');
                    },
                  ),
                ),
              ],
            ),
          ),

          // Drawer Navigation List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // 1. Home
                _drawerTile(
                  icon: Icons.home_rounded,
                  title: 'Home',
                  onTap: () {
                    Navigator.pop(context);
                    onSelectTab(0);
                  },
                ),

                // 2. Live Tests
                _drawerTile(
                  icon: Icons.timer_rounded,
                  title: 'Live Tests',
                  badgeColor: AppTheme.secondaryMaroon,
                  badge: 'LIVE',
                  onTap: () {
                    Navigator.pop(context);
                    onSelectTab(2);
                  },
                ),

                // 3. MCQs Practice
                _drawerTile(
                  icon: Icons.quiz_rounded,
                  title: 'MCQ Practice',
                  onTap: () {
                    Navigator.pop(context);
                    onSelectTab(3);
                  },
                ),

                // 4. Video Lessons
                _drawerTile(
                  icon: Icons.play_circle_fill_rounded,
                  title: 'Video Lessons',
                  onTap: () {
                    Navigator.pop(context);
                    onSelectTab(1);
                  },
                ),

                // 5. Study Notes & PDFs
                _drawerTile(
                  icon: Icons.menu_book_rounded,
                  title: 'Notes & PDFs',
                  onTap: () {
                    Navigator.pop(context);
                    onSelectTab(4);
                  },
                ),

                // 5. Notifications & Announcements
                _drawerTile(
                  icon: Icons.notifications_rounded,
                  title: 'Announcements',
                  badge: unreadCount > 0 ? (unreadCount > 9 ? '9+' : '$unreadCount') : null,
                  badgeColor: AppTheme.secondaryMaroon,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/notifications');
                  },
                ),

                const Divider(color: AppTheme.borderSubtle, height: 16),

                // 6. My Profile
                _drawerTile(
                  icon: Icons.person_rounded,
                  title: 'My Profile',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/profile');
                  },
                ),

                // 7. Help & Support
                _drawerTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Contact Support: ${AppConstants.authorizedAdminEmail}'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),

                // Protected Admin Section (Strictly visible only to authorized administrators)
                if (isAdmin) ...[
                  const Divider(color: AppTheme.borderSubtle, height: 20),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNavy.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.primaryNavy.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      children: [
                        _drawerTile(
                          icon: Icons.admin_panel_settings_rounded,
                          title: 'Admin Dashboard',
                          titleColor: AppTheme.primaryNavy,
                          iconColor: AppTheme.primaryNavy,
                          badge: 'SECURE',
                          badgeColor: AppTheme.primaryNavy,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/admin');
                          },
                        ),
                        _drawerTile(
                          icon: Icons.campaign_rounded,
                          title: 'Announcements Mgmt',
                          titleColor: AppTheme.primaryNavy,
                          iconColor: AppTheme.primaryNavy,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/admin/announcements');
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Sign Out Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout_rounded, size: 18, color: AppTheme.errorRed),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.errorRed),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () async {
                  await authProvider.signOut();
                  if (context.mounted) {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerProfileDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppTheme.accentGold),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _drawerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
    String? badge,
    Color? badgeColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppTheme.textSecondary, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? AppTheme.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor ?? AppTheme.successGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: AppTheme.surfaceWhite,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          : null,
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }
}
