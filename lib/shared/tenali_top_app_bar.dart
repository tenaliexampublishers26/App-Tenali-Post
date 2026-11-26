import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../providers/notification_provider.dart';

class TenaliTopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? extraActions;
  final bool showNotificationBell;
  final bool showHamburger;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onHamburgerTap;

  const TenaliTopAppBar({
    super.key,
    this.title,
    this.extraActions,
    this.showNotificationBell = true,
    this.showHamburger = true,
    this.onNotificationTap,
    this.onHamburgerTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final unreadCount = notificationProvider.unreadCount;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: AppTheme.surfaceWarmWhite,
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: const Border(
        bottom: BorderSide(color: AppTheme.borderWarmSubtle, width: 1.0),
      ),
      titleSpacing: 16,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Official Academy Logo
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.accentGold, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryNavy.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                AppConstants.logoAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.local_post_office_rounded,
                  size: 20,
                  color: AppTheme.primaryNavy,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Horizontally aligned branding text
          Flexible(
            child: Text(
              title ?? AppConstants.appName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.primaryNavy,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
      actions: [
        if (extraActions != null) ...extraActions!,
        IconButton(
          tooltip: 'User Profile',
          icon: const Icon(
            Icons.account_circle_outlined,
            color: AppTheme.primaryNavy,
            size: 24,
          ),
          onPressed: () {
            Navigator.pushNamed(context, '/profile');
          },
        ),

        // Notification bell icon with unread badge
        if (showNotificationBell)
          IconButton(
            tooltip: 'Announcements & Notifications',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  color: AppTheme.primaryNavy,
                  size: 24,
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppTheme.secondaryMaroon,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              if (onNotificationTap != null) {
                onNotificationTap!();
              } else {
                Navigator.pushNamed(context, '/notifications');
              }
            },
          ),

        // Hamburger menu icon (three horizontal lines)
        if (showHamburger)
          Builder(
            builder: (innerContext) => IconButton(
              tooltip: 'Navigation Menu',
              icon: const Icon(
                Icons.menu_rounded,
                color: AppTheme.primaryNavy,
                size: 26,
              ),
              onPressed: () {
                if (onHamburgerTap != null) {
                  onHamburgerTap!();
                } else {
                  final nearest = Scaffold.maybeOf(innerContext);
                  if (nearest != null && nearest.hasDrawer) {
                    nearest.openDrawer();
                  } else {
                    innerContext
                        .findRootAncestorStateOfType<ScaffoldState>()
                        ?.openDrawer();
                  }
                }
              },
            ),
          ),
        const SizedBox(width: 6),
      ],
    );
  }
}
