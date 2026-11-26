import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/admin_ui.dart';
import '../../../models/lms_models.dart';
import '../../../providers/lms_admin_provider.dart';

class AdminStudentManagementScreen extends StatefulWidget {
  const AdminStudentManagementScreen({super.key});

  @override
  State<AdminStudentManagementScreen> createState() =>
      _AdminStudentManagementScreenState();
}

class _AdminStudentManagementScreenState
    extends State<AdminStudentManagementScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LmsAdminProvider>(context, listen: false).loadStudentsDirectory();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lms = Provider.of<LmsAdminProvider>(context);
    final students = lms.students;

    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      appBar: AppBar(
        title: const Text('Students Directory'),
        backgroundColor: AppTheme.surfaceWarmWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => lms.loadStudentsDirectory(search: _searchCtrl.text),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppTheme.surfaceWarmWhite,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by name, email, or phone...',
                prefixIcon: const Icon(Icons.search_rounded),
                isDense: true,
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          lms.loadStudentsDirectory();
                        },
                      )
                    : null,
              ),
              onChanged: (v) => lms.loadStudentsDirectory(search: v),
            ),
          ),
          Expanded(
            child: students.isEmpty
                ? const EmptyStateView(
                    icon: Icons.people_outline_rounded,
                    title: 'No Students Found',
                    subtitle: 'Registered students and their LMS practice attempts will appear here.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: students.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, idx) {
                      final s = students[idx];
                      return AdminCard(
                        onTap: () => _openAttemptInspector(s),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppTheme.primaryNavy.withValues(alpha: 0.1),
                              child: Text(
                                s.name.isNotEmpty ? s.name[0].toUpperCase() : 'S',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primaryNavy,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          s.name,
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      StatusBadge(
                                        text: s.role.toUpperCase(),
                                        color: s.role == 'admin'
                                            ? AppTheme.secondaryMaroon
                                            : AppTheme.primaryNavy,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${s.email} • ${s.phone.isEmpty ? 'No phone' : s.phone}',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      Text(
                                        'MCQs: ${s.mcqAttempts.length} attempts',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryNavy),
                                      ),
                                      Text(
                                        'Live Tests: ${s.liveTestSubmissions.length}',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.successGreen),
                                      ),
                                      Text(
                                        'Bookmarks: ${s.bookmarkCount}',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.goldBell),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _openAttemptInspector(LmsStudentSummary s) {
    final df = DateFormat('dd MMM yyyy, hh:mm a');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        maxChildSize: 0.92,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(16),
          children: [
            Text(s.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text('${s.email} • ${s.phone}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    label: 'MCQ Attempts',
                    value: '${s.mcqAttempts.length}',
                    icon: Icons.quiz_rounded,
                    color: AppTheme.primaryNavy,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatTile(
                    label: 'Live Tests',
                    value: '${s.liveTestSubmissions.length}',
                    icon: Icons.timer_rounded,
                    color: AppTheme.successGreen,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatTile(
                    label: 'Bookmarks',
                    value: '${s.bookmarkCount}',
                    icon: Icons.bookmark_rounded,
                    color: AppTheme.goldBell,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Live Test Submissions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            if (s.liveTestSubmissions.isEmpty)
              const Text('No live test submissions yet.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary))
            else
              for (final sub in s.liveTestSubmissions)
                AdminCard(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Test ID: ${sub.testId}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                            Text(
                              df.format(sub.submittedAt.toLocal()),
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${sub.marksObtained.toStringAsFixed(0)}/${sub.totalQuestions} (${sub.percentage.toStringAsFixed(1)}%)',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.successGreen, fontSize: 12),
                      ),
                    ],
                  ),
                ),
            const SizedBox(height: 14),
            const Text('MCQ Practice Attempts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            if (s.mcqAttempts.isEmpty)
              const Text('No MCQ practice attempts yet.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary))
            else
              for (final att in s.mcqAttempts)
                AdminCard(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Set v${att.questionSetVersion}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                            Text(df.format(att.submittedAt.toLocal()), style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                      Text(
                        '${att.correctCount}/${att.totalQuestions} correct',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primaryNavy, fontSize: 12),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
