import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../models/video_lesson.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/auth_provider.dart';

class AdminVideoManagementScreen extends StatefulWidget {
  const AdminVideoManagementScreen({super.key});

  @override
  State<AdminVideoManagementScreen> createState() => _AdminVideoManagementScreenState();
}

class _AdminVideoManagementScreenState extends State<AdminVideoManagementScreen> {
  String? _selectedExamId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).loadVideos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final adminEmail = auth.user?.email ?? 'admin@tenalipost.gov.in';

    final videos = _selectedExamId == null || _selectedExamId!.isEmpty
        ? admin.videos
        : admin.videos.where((v) => v.examId == _selectedExamId).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      appBar: AppBar(
        title: const Text('Video Class Management'),
        backgroundColor: AppTheme.surfaceWarmWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryNavy),
            onPressed: () => admin.loadVideos(examId: _selectedExamId),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.secondaryMaroon,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.video_call_rounded),
        label: const Text('Add Video Lecture', style: TextStyle(fontWeight: FontWeight.w800)),
        onPressed: () => _showVideoDialog(context, admin, adminEmail),
      ),
      body: Column(
        children: [
          // Filter Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppTheme.surfaceWarmWhite,
            child: Row(
              children: [
                const Text('Filter by Exam:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.bgWarm,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.borderWarmSubtle),
                    ),
                    child: DropdownButton<String?>(
                      value: _selectedExamId,
                      isExpanded: true,
                      underline: const SizedBox(),
                      hint: const Text('All Departmental Exams', style: TextStyle(fontSize: 12)),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Exams', style: TextStyle(fontSize: 12))),
                        ...admin.exams.map((e) => DropdownMenuItem(value: e.id, child: Text('${e.code} (${e.title})', style: const TextStyle(fontSize: 12)))),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedExamId = val);
                        admin.loadVideos(examId: val);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Total Count Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.bgWarm,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${videos.length} Video Classes Configured', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                const Text('Integrated YouTube Player', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),

          // Video List
          Expanded(
            child: videos.isEmpty
                ? const Center(child: Text('No videos found for this filter.'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    itemCount: videos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, idx) {
                      final v = videos[idx];
                      return Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceWarmWhite,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderWarmSubtle),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryNavy.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          leading: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: AppTheme.secondaryMaroon.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.play_circle_fill_rounded, color: AppTheme.secondaryMaroon, size: 28),
                              ),
                            ],
                          ),
                          title: Text(v.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text(v.description, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _badge(v.examId.toUpperCase(), AppTheme.primaryNavy),
                                  const SizedBox(width: 6),
                                  _badge(v.languageCode.toUpperCase(), AppTheme.goldBell),
                                  const SizedBox(width: 6),
                                  _badge(v.duration, AppTheme.textSecondary),
                                  const SizedBox(width: 6),
                                  _badge(v.isFree ? 'FREE' : 'PREMIUM', v.isFree ? AppTheme.successGreen : AppTheme.secondaryMaroon),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryNavy),
                                onPressed: () => _showVideoDialog(context, admin, adminEmail, videoToEdit: v),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.errorRed),
                                onPressed: () => _confirmDeleteVideo(context, admin, v, adminEmail),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }

  void _showVideoDialog(BuildContext context, AdminProvider admin, String adminEmail, {VideoLesson? videoToEdit}) {
    final titleController = TextEditingController(text: videoToEdit?.title ?? '');
    final descController = TextEditingController(text: videoToEdit?.description ?? '');
    final urlController = TextEditingController(text: videoToEdit?.videoUrl ?? '');
    final durationController = TextEditingController(text: videoToEdit?.duration ?? '20:00');
    String examId = videoToEdit?.examId ?? (admin.exams.isNotEmpty ? admin.exams.first.id : 'mts');
    String lang = videoToEdit?.languageCode ?? 'te';
    bool isFree = videoToEdit?.isFree ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(videoToEdit != null ? 'Edit Video Class' : 'Add Video Class'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: examId,
                  decoration: const InputDecoration(labelText: 'Exam Cadre *'),
                  items: admin.exams.map((e) => DropdownMenuItem(value: e.id, child: Text(e.title))).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => examId = val);
                  },
                ),
                const SizedBox(height: 10),
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Video Title *')),
                const SizedBox(height: 10),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 10),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    labelText: 'YouTube / Video Stream URL *',
                    hintText: 'https://youtube.com/watch?v=... or youtu.be/...',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(controller: durationController, decoration: const InputDecoration(labelText: 'Duration (MM:SS)')),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: lang,
                        decoration: const InputDecoration(labelText: 'Language'),
                        items: const [
                          DropdownMenuItem(value: 'te', child: Text('Telugu (తెలుగు)')),
                          DropdownMenuItem(value: 'en', child: Text('English')),
                          DropdownMenuItem(value: 'hi', child: Text('Hindi (हिन्दी)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => lang = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Free for all students', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  value: isFree,
                  onChanged: (val) => setDialogState(() => isFree = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondaryMaroon),
              onPressed: () async {
                final title = titleController.text.trim();
                final url = urlController.text.trim();
                if (title.isEmpty || url.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Title and Video URL are required.')),
                  );
                  return;
                }

                final video = VideoLesson(
                  id: videoToEdit?.id ?? 'v-${DateTime.now().millisecondsSinceEpoch}',
                  examId: examId,
                  title: title,
                  description: descController.text.trim(),
                  videoUrl: url,
                  duration: durationController.text.trim(),
                  languageCode: lang,
                  isFree: isFree,
                );

                await admin.saveVideo(video, adminEmail: adminEmail);
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Video ${videoToEdit != null ? 'updated' : 'added'} successfully.')),
                  );
                }
              },
              child: const Text('Save Video'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteVideo(BuildContext context, AdminProvider admin, VideoLesson v, String adminEmail) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Video Class?'),
        content: Text('Are you sure you want to remove "${v.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: () async {
              Navigator.pop(ctx);
              await admin.deleteVideo(v.id, adminEmail: adminEmail);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Video deleted successfully.')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
