import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../models/exam.dart';
import '../../../models/chapter.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/auth_provider.dart';
import '../mcq/admin_mcq_list_screen.dart';

class AdminChapterListScreen extends StatefulWidget {
  final Exam exam;

  const AdminChapterListScreen({super.key, required this.exam});

  @override
  State<AdminChapterListScreen> createState() => _AdminChapterListScreenState();
}

class _AdminChapterListScreenState extends State<AdminChapterListScreen> {
  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final adminEmail = auth.user?.email ?? 'admin@tenalipost.gov.in';

    final chapters = admin.chapters.where((c) => c.examId == widget.exam.id).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      appBar: AppBar(
        title: Text('${widget.exam.code} Chapters'),
        backgroundColor: AppTheme.surfaceWarmWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryNavy),
            onPressed: () => admin.loadExamsAndChapters(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Chapter', style: TextStyle(fontWeight: FontWeight.w800)),
        onPressed: () => _showChapterDialog(context, admin, adminEmail),
      ),
      body: chapters.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.menu_book_outlined, size: 50, color: AppTheme.textMuted),
                  const SizedBox(height: 12),
                  Text('No chapters configured for ${widget.exam.title}.', style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _showChapterDialog(context, admin, adminEmail),
                    child: const Text('Create First Chapter'),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: chapters.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, idx) {
                final ch = chapters[idx];
                final questions = admin.questions.where((q) => q.chapterId == ch.id).toList();
                final enCount = questions.where((q) => q.languageCode == 'en').length;
                final teCount = questions.where((q) => q.languageCode == 'te').length;
                final hiCount = questions.where((q) => q.languageCode == 'hi').length;

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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.primaryNavy.withValues(alpha: 0.08),
                      child: Text(
                        '${ch.chapterNumber}',
                        style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryNavy, fontSize: 14),
                      ),
                    ),
                    title: Text(ch.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text(ch.description ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _langCoverageBadge('EN', enCount),
                            const SizedBox(width: 4),
                            _langCoverageBadge('TE', teCount),
                            const SizedBox(width: 4),
                            _langCoverageBadge('HI', hiCount),
                            const Spacer(),
                            Text('${questions.length} total Qs', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryNavy),
                          onPressed: () => _showChapterDialog(context, admin, adminEmail, chapterToEdit: ch),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.errorRed),
                          onPressed: () => _confirmDeleteChapter(context, admin, ch, adminEmail),
                        ),
                      ],
                    ),
                    onTap: () {
                      admin.setMcqExamFilter(widget.exam.id);
                      admin.setMcqChapterFilter(ch.id);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminMcqListScreen()),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _langCoverageBadge(String lang, int count) {
    final bool hasQuestions = count > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: hasQuestions ? AppTheme.successGreenBg : AppTheme.errorRedBg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$lang: $count',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: hasQuestions ? AppTheme.successGreen : AppTheme.errorRed,
        ),
      ),
    );
  }

  void _showChapterDialog(BuildContext context, AdminProvider admin, String adminEmail, {Chapter? chapterToEdit}) {
    final titleController = TextEditingController(text: chapterToEdit?.title ?? '');
    final descController = TextEditingController(text: chapterToEdit?.description ?? '');
    final numController = TextEditingController(text: (chapterToEdit?.chapterNumber ?? (admin.chapters.where((c) => c.examId == widget.exam.id).length + 1)).toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(chapterToEdit != null ? 'Edit Chapter' : 'Add Chapter to ${widget.exam.code}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: numController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Chapter Sequence Number *'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Chapter Title (e.g. PO Guide Part 1) *'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Chapter Topics & Scope Description'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryNavy),
            onPressed: () async {
              final title = titleController.text.trim();
              final desc = descController.text.trim();
              final num = int.tryParse(numController.text.trim()) ?? 1;
              if (title.isEmpty) return;

              final ch = Chapter(
                id: chapterToEdit?.id ?? 'ch-${widget.exam.id}-$num',
                examId: widget.exam.id,
                title: title,
                description: desc,
                chapterNumber: num,
                supportedLanguages: const ['en', 'te', 'hi'],
              );

              await admin.saveChapter(ch, adminEmail: adminEmail);
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Chapter ${chapterToEdit != null ? 'updated' : 'added'} successfully.')),
                );
              }
            },
            child: const Text('Save Chapter'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteChapter(BuildContext context, AdminProvider admin, Chapter ch, String adminEmail) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Chapter?'),
        content: Text('Are you sure you want to delete Chapter ${ch.chapterNumber}: "${ch.title}"? Deletion will be blocked if questions are linked.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await admin.deleteChapter(ch.id, adminEmail: adminEmail);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chapter deleted successfully.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Cannot delete: $e'), backgroundColor: AppTheme.errorRed),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
