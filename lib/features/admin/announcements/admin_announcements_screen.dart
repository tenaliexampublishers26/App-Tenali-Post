import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../models/announcement.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/notification_provider.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  State<AdminAnnouncementsScreen> createState() => _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      Provider.of<NotificationProvider>(context, listen: false).loadAnnouncements(
        userId: auth.user?.id,
        isAdmin: true,
      );
    });
  }

  void _showAnnouncementDialog({Announcement? existing}) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final messageController = TextEditingController(text: existing?.message ?? '');
    bool isPublished = existing?.isPublished ?? true;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                existing == null ? 'Create Announcement' : 'Edit Announcement',
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primaryNavy),
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Title *',
                          hintText: 'e.g. MTS Examination Schedule Released',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Title is mandatory';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: messageController,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Message *',
                          hintText: 'Write the complete announcement details...',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Message is mandatory';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Publish Immediately', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Visible to students if enabled', style: TextStyle(fontSize: 12)),
                        value: isPublished,
                        activeTrackColor: AppTheme.successGreen,
                        onChanged: (val) {
                          setDialogState(() {
                            isPublished = val;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryNavy,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final auth = Provider.of<AuthProvider>(context, listen: false);
                    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

                    if (existing == null) {
                      await notificationProvider.createAnnouncement(
                        title: titleController.text.trim(),
                        message: messageController.text.trim(),
                        isPublished: isPublished,
                        createdBy: auth.user?.id,
                      );
                    } else {
                      await notificationProvider.updateAnnouncement(
                        id: existing.id,
                        title: titleController.text.trim(),
                        message: messageController.text.trim(),
                        isPublished: isPublished,
                      );
                    }

                    if (mounted) {
                      Navigator.pop(dialogCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(existing == null ? 'Announcement published!' : 'Announcement updated!'),
                          backgroundColor: AppTheme.successGreen,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: Text(existing == null ? 'Post' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(Announcement announcement) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Announcement?', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.errorRed)),
        content: Text('Are you sure you want to permanently delete "${announcement.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final notifications = Provider.of<NotificationProvider>(context, listen: false);
              await notifications.deleteAnnouncement(announcement.id);
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Announcement deleted.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);

    // Backend-backed Admin Authorization Guard
    if (!auth.isAdmin) {
      return Scaffold(
        backgroundColor: AppTheme.bgWarm,
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.gpp_bad_rounded, size: 56, color: AppTheme.errorRed),
                SizedBox(height: 16),
                Text(
                  'Administrative Privileges Required',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(height: 8),
                Text(
                  'Only authorized administrators may manage announcements and notices.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final list = notificationProvider.announcements;

    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      appBar: AppBar(
        title: const Text('Manage Announcements'),
        backgroundColor: AppTheme.surfaceWarmWhite,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Announcement'),
        onPressed: () => _showAnnouncementDialog(),
      ),
      body: notificationProvider.isLoading && list.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : list.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.campaign_outlined, size: 54, color: AppTheme.primaryNavy),
                        const SizedBox(height: 16),
                        const Text(
                          'No Announcements Found',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap below to broadcast notifications to all registered postal candidates.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryNavy),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Create Announcement'),
                          onPressed: () => _showAnnouncementDialog(),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: item.isPublished
                                        ? AppTheme.successGreen.withValues(alpha: 0.15)
                                        : Colors.grey.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.isPublished ? 'PUBLISHED' : 'DEACTIVATED / DRAFT',
                                    style: TextStyle(
                                      color: item.isPublished ? AppTheme.successGreen : AppTheme.textSecondary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Switch(
                                  value: item.isPublished,
                                  activeTrackColor: AppTheme.successGreen,
                                  onChanged: (val) async {
                                    await notificationProvider.togglePublish(item.id, val);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.title,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primaryNavy),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.message,
                              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.4),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Published: ${item.publishedAt.day}/${item.publishedAt.month}/${item.publishedAt.year}',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      tooltip: 'Edit Announcement',
                                      icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.primaryNavy),
                                      onPressed: () => _showAnnouncementDialog(existing: item),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete Announcement',
                                      icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.errorRed),
                                      onPressed: () => _confirmDelete(item),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
