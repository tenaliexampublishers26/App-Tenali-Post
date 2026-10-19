import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../models/exam.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/auth_provider.dart';
import 'admin_chapter_list_screen.dart';
import 'admin_language_matrix_screen.dart';

class AdminExamListScreen extends StatefulWidget {
  const AdminExamListScreen({super.key});

  @override
  State<AdminExamListScreen> createState() => _AdminExamListScreenState();
}

class _AdminExamListScreenState extends State<AdminExamListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).loadExamsAndChapters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final adminEmail = auth.user?.email ?? 'admin@tenalipost.gov.in';

    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      appBar: AppBar(
        title: const Text('Departmental Exam Management'),
        backgroundColor: AppTheme.surfaceWarmWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.language_rounded, color: AppTheme.primaryNavy),
            tooltip: 'Language Coverage Matrix',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminLanguageMatrixScreen()),
              );
            },
          ),
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
        label: const Text('Create New Exam', style: TextStyle(fontWeight: FontWeight.w800)),
        onPressed: () => _showExamDialog(context, admin, adminEmail),
      ),
      body: admin.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.secondaryMaroon))
          : admin.exams.isEmpty
              ? const Center(child: Text('No exams found in database.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: admin.exams.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, idx) {
                    final exam = admin.exams[idx];
                    final chaptersCount = admin.chapters.where((c) => c.examId == exam.id).length;
                    final questionsCount = admin.questions.where((q) => q.examId == exam.id).length;

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
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryNavy.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              exam.code,
                              style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryNavy, fontSize: 13),
                            ),
                          ),
                        ),
                        title: Text(exam.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(exam.subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _metaPill('$chaptersCount Chapters', Icons.menu_book_rounded),
                                const SizedBox(width: 8),
                                _metaPill('$questionsCount Questions', Icons.quiz_rounded),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.primaryNavy),
                              onPressed: () => _showExamDialog(context, admin, adminEmail, examToEdit: exam),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppTheme.errorRed),
                              onPressed: () => _confirmDeleteExam(context, admin, exam, adminEmail),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminChapterListScreen(exam: exam),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }

  Widget _metaPill(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.bgWarm,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderWarmSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  void _showExamDialog(BuildContext context, AdminProvider admin, String adminEmail, {Exam? examToEdit}) {
    final titleController = TextEditingController(text: examToEdit?.title ?? '');
    final subtitleController = TextEditingController(text: examToEdit?.subtitle ?? '');
    final codeController = TextEditingController(text: examToEdit?.code ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(examToEdit != null ? 'Edit Exam' : 'Create New Exam'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeController,
              decoration: const InputDecoration(labelText: 'Exam Code (e.g. MTS, PMG, PASA) *'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Exam Title *'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: subtitleController,
              decoration: const InputDecoration(labelText: 'Subtitle / Description'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryNavy),
            onPressed: () async {
              final code = codeController.text.trim();
              final title = titleController.text.trim();
              final sub = subtitleController.text.trim();
              if (code.isEmpty || title.isEmpty) return;

              final exam = Exam(
                id: examToEdit?.id ?? code.toLowerCase(),
                title: title,
                subtitle: sub,
                code: code.toUpperCase(),
                totalChapters: examToEdit?.totalChapters ?? 0,
                totalQuestions: examToEdit?.totalQuestions ?? 0,
              );

              await admin.saveExam(exam, adminEmail: adminEmail);
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Exam ${examToEdit != null ? 'updated' : 'created'} successfully.')),
                );
              }
            },
            child: const Text('Save Exam'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteExam(BuildContext context, AdminProvider admin, Exam exam, String adminEmail) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Exam?'),
        content: Text('Are you sure you want to delete ${exam.title} (${exam.code})? This will fail if questions or chapters still reference it.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await admin.deleteExam(exam.id, adminEmail: adminEmail);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exam deleted successfully.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Delete failed: $e'), backgroundColor: AppTheme.errorRed),
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
