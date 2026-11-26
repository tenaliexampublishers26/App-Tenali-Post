import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../admin/announcements/admin_announcements_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  Future<void> _refresh() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final notifications = Provider.of<NotificationProvider>(context, listen: false);
    await notifications.loadAnnouncements(
      userId: auth.user?.id,
      isAdmin: auth.isAdmin,
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) {
      return diff.inMinutes <= 1 ? "Just now" : "${diff.inMinutes} mins ago";
    } else if (diff.inHours < 24) {
      return '${diff.inHours} ${diff.inHours == 1 ? "hour" : "hours"} ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ${diff.inDays == 1 ? "day" : "days"} ago';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final announcements = notificationProvider.announcements.where((a) => a.isPublished || auth.isAdmin).toList();
    final unreadCount = notificationProvider.unreadCount;

    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      appBar: AppBar(
        title: const Text('Announcements'),
        backgroundColor: AppTheme.surfaceWarmWhite,
        actions: [
          if (announcements.isNotEmpty && unreadCount > 0)
            TextButton(
              onPressed: () async {
                await notificationProvider.markAllAsRead(auth.user?.id);
              },
              child: const Text(
                'Mark All Read',
                style: TextStyle(
                  color: AppTheme.primaryNavy,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          if (auth.isAdmin)
            IconButton(
              tooltip: 'Manage Announcements (Admin)',
              icon: const Icon(Icons.tune_rounded, color: AppTheme.secondaryMaroon),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminAnnouncementsScreen()),
                );
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: notificationProvider.isLoading && announcements.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : announcements.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryNavy.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_none_rounded,
                              size: 52,
                              color: AppTheme.primaryNavy,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Announcements Yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryNavy,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Important departmental updates, exam schedules, and alerts will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                          ),
                          if (auth.isAdmin) ...[
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Post First Announcement'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryNavy,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const AdminAnnouncementsScreen()),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: announcements.length,
                    itemBuilder: (context, index) {
                      final item = announcements[index];
                      final isRead = item.isRead;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: isRead ? 0 : 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isRead
                                ? AppTheme.borderWarmSubtle
                                : AppTheme.secondaryMaroon.withValues(alpha: 0.35),
                            width: isRead ? 1.0 : 1.5,
                          ),
                        ),
                        color: isRead ? Colors.white : const Color(0xFFFFFBFB),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            if (!isRead) {
                              notificationProvider.markAsRead(item.id, auth.user?.id);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isRead
                                            ? AppTheme.primaryNavy.withValues(alpha: 0.08)
                                            : AppTheme.secondaryMaroon.withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isRead ? Icons.notifications_none_rounded : Icons.campaign_rounded,
                                        size: 20,
                                        color: isRead ? AppTheme.primaryNavy : AppTheme.secondaryMaroon,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item.title,
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: isRead ? FontWeight.w700 : FontWeight.w900,
                                                    color: AppTheme.primaryNavy,
                                                  ),
                                                ),
                                              ),
                                              if (!isRead)
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  margin: const EdgeInsets.only(left: 6),
                                                  decoration: const BoxDecoration(
                                                    color: AppTheme.secondaryMaroon,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatDate(item.publishedAt),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.textMuted,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.only(left: 44.0),
                                  child: Text(
                                    item.message,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textPrimary,
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                                if (!isRead) ...[
                                  const SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      icon: const Icon(Icons.check_rounded, size: 16),
                                      label: const Text('Mark as Read', style: TextStyle(fontSize: 12)),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppTheme.secondaryMaroon,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      onPressed: () {
                                        notificationProvider.markAsRead(item.id, auth.user?.id);
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
