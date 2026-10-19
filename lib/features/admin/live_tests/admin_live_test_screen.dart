import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../models/live_test.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/auth_provider.dart';
import 'admin_live_test_results_screen.dart';

class AdminLiveTestScreen extends StatefulWidget {
  const AdminLiveTestScreen({super.key});

  @override
  State<AdminLiveTestScreen> createState() => _AdminLiveTestScreenState();
}

class _AdminLiveTestScreenState extends State<AdminLiveTestScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).loadLiveTests();
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
        title: const Text('Live Examination Scheduler'),
        backgroundColor: AppTheme.surfaceWarmWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryNavy),
            onPressed: () => admin.loadLiveTests(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.secondaryMaroon,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text('Schedule Live Test', style: TextStyle(fontWeight: FontWeight.w800)),
        onPressed: () => _showLiveTestDialog(context, admin, adminEmail),
      ),
      body: admin.liveTests.isEmpty
          ? const Center(child: Text('No live tests scheduled.'))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: admin.liveTests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, idx) {
                final t = admin.liveTests[idx];
                final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Title & Status
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              t.title,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppTheme.textPrimary),
                            ),
                          ),
                          _statusChip(t),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(t.description, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      const SizedBox(height: 12),

                      // Metadata Pills Row
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _pill(t.examId.toUpperCase(), Icons.school_rounded, AppTheme.primaryNavy),
                          _pill('${t.durationMinutes} mins', Icons.timer_outlined, AppTheme.secondaryMaroon),
                          _pill('${t.totalQuestions} Questions', Icons.quiz_outlined, AppTheme.goldBell),
                          _pill('${t.totalMarks.toInt()} Marks', Icons.grade_outlined, AppTheme.textSecondary),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Window Times
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.bgWarm,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.borderWarmSubtle),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.play_arrow_rounded, size: 14, color: AppTheme.successGreen),
                                const SizedBox(width: 4),
                                const Text('Window Opens: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                                Text(dateFormat.format(t.startTime), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.stop_rounded, size: 14, color: AppTheme.errorRed),
                                const SizedBox(width: 4),
                                const Text('Window Closes: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                                Text(dateFormat.format(t.endTime), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 20, color: AppTheme.borderWarmSubtle),

                      // Actions: Submissions, Edit, Delete, Toggle Publish
                      Row(
                        children: [
                          TextButton.icon(
                            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                            icon: const Icon(Icons.assessment_rounded, size: 16),
                            label: const Text('View Results & Rankings', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => AdminLiveTestResultsScreen(liveTest: t)),
                              );
                            },
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryNavy),
                            tooltip: 'Edit Schedule',
                            onPressed: () => _showLiveTestDialog(context, admin, adminEmail, testToEdit: t),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.errorRed),
                            tooltip: 'Delete Test',
                            onPressed: () => _confirmDeleteLiveTest(context, admin, t, adminEmail),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _statusChip(LiveTest t) {
    String label = 'DRAFT';
    Color color = AppTheme.textMuted;
    Color bg = AppTheme.bgWarm;

    if (t.isOngoing) {
      label = 'LIVE ACTIVE';
      color = Colors.white;
      bg = AppTheme.secondaryMaroon;
    } else if (t.isUpcoming) {
      label = 'SCHEDULED';
      color = AppTheme.goldBell;
      bg = AppTheme.goldChipBg.withValues(alpha: 0.2);
    } else if (t.isEnded) {
      label = 'COMPLETED';
      color = AppTheme.textSecondary;
      bg = AppTheme.surfaceCream;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.3),
      ),
    );
  }

  Widget _pill(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  void _showLiveTestDialog(BuildContext context, AdminProvider admin, String adminEmail, {LiveTest? testToEdit}) {
    final titleController = TextEditingController(text: testToEdit?.title ?? '');
    final descController = TextEditingController(text: testToEdit?.description ?? '');
    final durationController = TextEditingController(text: (testToEdit?.durationMinutes ?? 60).toString());
    final questionsController = TextEditingController(text: (testToEdit?.totalQuestions ?? 30).toString());
    final marksController = TextEditingController(text: (testToEdit?.totalMarks.toInt() ?? 30).toString());
    String examId = testToEdit?.examId ?? (admin.exams.isNotEmpty ? admin.exams.first.id : 'mts');
    bool isPublished = testToEdit?.isPublished ?? true;

    DateTime startTime = testToEdit?.startTime ?? DateTime.now().subtract(const Duration(hours: 1));
    DateTime endTime = testToEdit?.endTime ?? DateTime.now().add(const Duration(days: 2));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(testToEdit != null ? 'Edit Live Test' : 'Schedule Live Test'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: examId,
                  decoration: const InputDecoration(labelText: 'Exam Target *'),
                  items: admin.exams.map((e) => DropdownMenuItem(value: e.id, child: Text(e.title))).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => examId = val);
                  },
                ),
                const SizedBox(height: 10),
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Live Test Title *')),
                const SizedBox(height: 10),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Instructions / Syllabus')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: durationController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Duration (Mins) *'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: questionsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Questions Count *'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: marksController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Marks *'))),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Publish Immediately', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  value: isPublished,
                  activeThumbColor: AppTheme.secondaryMaroon,
                  onChanged: (val) => setDialogState(() => isPublished = val),
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
                if (title.isEmpty) return;

                final test = LiveTest(
                  id: testToEdit?.id ?? 'lt-${DateTime.now().millisecondsSinceEpoch}',
                  title: title,
                  description: descController.text.trim(),
                  examId: examId,
                  startTime: startTime,
                  endTime: endTime,
                  durationMinutes: int.tryParse(durationController.text.trim()) ?? 60,
                  totalQuestions: int.tryParse(questionsController.text.trim()) ?? 30,
                  totalMarks: double.tryParse(marksController.text.trim()) ?? 30.0,
                  passMarks: 12.0,
                  isPublished: isPublished,
                );

                await admin.saveLiveTest(test, adminEmail: adminEmail);
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Live test ${testToEdit != null ? 'updated' : 'scheduled'} successfully.')),
                  );
                }
              },
              child: const Text('Save Test'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteLiveTest(BuildContext context, AdminProvider admin, LiveTest t, String adminEmail) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Live Test?'),
        content: Text('Are you sure you want to cancel and remove "${t.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: () async {
              Navigator.pop(ctx);
              await admin.deleteLiveTest(t.id, adminEmail: adminEmail);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Live test removed.')),
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
