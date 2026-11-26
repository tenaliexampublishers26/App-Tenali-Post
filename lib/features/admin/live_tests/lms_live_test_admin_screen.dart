import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../core/utils/live_test_exporter.dart';
import '../../../core/widgets/admin_ui.dart';
import '../../../models/lms_models.dart';
import '../../../providers/lms_admin_provider.dart';
import '../widgets/bulk_mcq_importer_sheet.dart';

class LmsLiveTestAdminScreen extends StatefulWidget {
  const LmsLiveTestAdminScreen({super.key});

  @override
  State<LmsLiveTestAdminScreen> createState() => _LmsLiveTestAdminScreenState();
}

class _LmsLiveTestAdminScreenState extends State<LmsLiveTestAdminScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LmsAdminProvider>(context, listen: false).loadLiveTests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lms = Provider.of<LmsAdminProvider>(context);
    final df = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      appBar: AppBar(
        title: const Text('Live Tests (Untimed)'),
        backgroundColor: AppTheme.surfaceWarmWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => lms.loadLiveTests(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppTheme.surfaceWarmWhite,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    lms.settings.liveTestEnabled
                        ? 'Live Tests: ENABLED for students'
                        : 'Live Tests: DISABLED for students',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: lms.settings.liveTestEnabled
                          ? AppTheme.successGreen
                          : AppTheme.secondaryMaroon,
                    ),
                  ),
                ),
                Switch(
                  value: lms.settings.liveTestEnabled,
                  onChanged: (v) => lms.toggleLiveTestEnabled(v),
                ),
              ],
            ),
          ),
          Expanded(
            child: lms.liveTests.isEmpty
                ? EmptyStateView(
                    icon: Icons.timer_off_rounded,
                    title: 'No Live Tests Yet',
                    subtitle: 'Create an untimed live test, add questions, and publish when ready.',
                    actionLabel: 'Create Live Test',
                    onAction: () => _showTestFormSheet(),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
                    itemCount: lms.liveTests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, idx) {
                      final test = lms.liveTests[idx];
                      final statusColor = test.isPublished
                          ? AppTheme.successGreen
                          : test.isClosed
                              ? AppTheme.secondaryMaroon
                              : AppTheme.goldBell;

                      return AdminCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                StatusBadge(text: test.status, color: statusColor),
                                const SizedBox(width: 6),
                                if (test.answersReleased)
                                  const StatusBadge(
                                    text: 'KEYS RELEASED',
                                    color: AppTheme.infoBlue,
                                  ),
                                const Spacer(),
                                Text(
                                  df.format(test.testDate),
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (action) async {
                                    if (action == 'edit') {
                                      _showTestFormSheet(existing: test);
                                    } else if (action == 'delete') {
                                      await lms.deleteLiveTest(test.id);
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(value: 'edit', child: Text('Edit Details')),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete Test', style: TextStyle(color: AppTheme.errorRed)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              test.title,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                            ),
                            if (test.description.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                test.description,
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              '${test.questionCount} questions • ${test.attemptsCount} submissions • Untimed until closed',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.quiz_outlined, size: 16),
                                  label: const Text('Questions', style: TextStyle(fontSize: 12)),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => _LiveTestQuestionsScreen(test: test),
                                    ),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.leaderboard_rounded, size: 16),
                                  label: const Text('Results / Export', style: TextStyle(fontSize: 12)),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => _LiveTestResultsScreen(test: test),
                                    ),
                                  ),
                                ),
                                if (test.isDraft)
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.successGreen,
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: const Icon(Icons.campaign_rounded, size: 16),
                                    label: const Text('Make Live', style: TextStyle(fontSize: 12)),
                                    onPressed: () async {
                                      try {
                                        await lms.setLiveTestStatus(test.id, 'published');
                                      } catch (e) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(e.toString().replaceAll('Exception: ', '')),
                                            backgroundColor: AppTheme.errorRed,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                if (test.isPublished)
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.secondaryMaroon,
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: const Icon(Icons.lock_clock_rounded, size: 16),
                                    label: const Text('Close Test', style: TextStyle(fontSize: 12)),
                                    onPressed: () => lms.setLiveTestStatus(test.id, 'closed'),
                                  ),
                                if (test.isClosed) ...[
                                  OutlinedButton(
                                    onPressed: () => lms.setLiveTestStatus(test.id, 'draft'),
                                    child: const Text('To Draft', style: TextStyle(fontSize: 12)),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: test.answersReleased
                                          ? AppTheme.goldBell
                                          : AppTheme.primaryNavy,
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: const Icon(Icons.key_rounded, size: 16),
                                    label: Text(
                                      test.answersReleased ? 'Hide Keys' : 'Release Answers',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    onPressed: () async {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: Text(
                                            test.answersReleased
                                                ? 'Hide Answer Keys?'
                                                : 'Release Official Answer Keys?',
                                          ),
                                          content: Text(
                                            test.answersReleased
                                                ? 'Students will no longer see the answer keys.'
                                                : 'Students will be able to view correct options and explanations.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, false),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () => Navigator.pop(ctx, true),
                                              child: const Text('Confirm'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirmed != true || !mounted) return;
                                      await lms.setLiveTestAnswersReleased(
                                        test.id,
                                        !test.answersReleased,
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Live Test'),
        onPressed: () => _showTestFormSheet(),
      ),
    );
  }

  void _showTestFormSheet({LmsLiveTest? existing}) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              existing == null ? 'Create Live Test' : 'Edit Live Test',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Test Title *')),
            const SizedBox(height: 10),
            TextField(
              controller: descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                final lms = Provider.of<LmsAdminProvider>(context, listen: false);
                if (existing == null) {
                  await lms.createLiveTest(
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                  );
                } else {
                  await lms.updateLiveTest(
                    existing.copyWith(
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                    ),
                  );
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(existing == null ? 'Create Draft' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveTestQuestionsScreen extends StatefulWidget {
  final LmsLiveTest test;
  const _LiveTestQuestionsScreen({required this.test});

  @override
  State<_LiveTestQuestionsScreen> createState() => _LiveTestQuestionsScreenState();
}

class _LiveTestQuestionsScreenState extends State<_LiveTestQuestionsScreen> {
  List<LmsLiveTestQuestion> _questions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final qs = await Provider.of<LmsAdminProvider>(context, listen: false)
        .getAdminLiveTestQuestions(widget.test.id);
    if (!mounted) return;
    setState(() {
      _questions = qs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lms = Provider.of<LmsAdminProvider>(context, listen: false);
    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      appBar: AppBar(
        title: Text('${widget.test.title} • Qs'),
        backgroundColor: AppTheme.surfaceWarmWhite,
        actions: [
          IconButton(
            tooltip: 'Bulk Import',
            icon: const Icon(Icons.upload_file_rounded),
            onPressed: _openBulkImport,
          ),
          if (_questions.isNotEmpty)
            IconButton(
              tooltip: 'Clear All',
              icon: const Icon(Icons.delete_sweep_rounded, color: AppTheme.errorRed),
              onPressed: () async {
                await lms.clearLiveTestQuestions(widget.test.id);
                await _load();
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _questions.isEmpty
              ? EmptyStateView(
                  icon: Icons.quiz_outlined,
                  title: 'No Questions Added',
                  subtitle: 'Add manually or bulk import CSV, Excel, or JSON questions.',
                  actionLabel: 'Bulk Import',
                  onAction: _openBulkImport,
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
                  itemCount: _questions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, idx) {
                    final q = _questions[idx];
                    return AdminCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              StatusBadge(text: q.questionKey, color: AppTheme.primaryNavy),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                onPressed: () => _showQuestionDialog(existing: q),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    size: 18, color: AppTheme.errorRed),
                                onPressed: () async {
                                  await lms.deleteLiveTestQuestion(q.id, widget.test.id);
                                  await _load();
                                },
                              ),
                            ],
                          ),
                          Text(q.questionText, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 8),
                          for (final opt in [
                            ('A', q.optionA),
                            ('B', q.optionB),
                            ('C', q.optionC),
                            ('D', q.optionD),
                          ])
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () async {
                                      await lms.updateLiveTestQuestion(
                                        q.copyWith(correctOption: opt.$1),
                                      );
                                      await _load();
                                    },
                                    child: Container(
                                      width: 26,
                                      height: 26,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: q.correctOption == opt.$1
                                            ? AppTheme.successGreen
                                            : AppTheme.surfaceCream,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        opt.$1,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: q.correctOption == opt.$1
                                              ? Colors.white
                                              : AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(opt.$2, style: const TextStyle(fontSize: 12))),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Question'),
        onPressed: () => _showQuestionDialog(),
      ),
    );
  }

  void _showQuestionDialog({LmsLiveTestQuestion? existing}) {
    final qCtrl = TextEditingController(text: existing?.questionText ?? '');
    final aCtrl = TextEditingController(text: existing?.optionA ?? '');
    final bCtrl = TextEditingController(text: existing?.optionB ?? '');
    final cCtrl = TextEditingController(text: existing?.optionC ?? '');
    final dCtrl = TextEditingController(text: existing?.optionD ?? '');
    final expCtrl = TextEditingController(text: existing?.explanation ?? '');
    var correct = existing?.correctOption ?? 'A';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  existing == null ? 'Add Live Test Question' : 'Edit Question',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                TextField(controller: qCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Question Text *')),
                const SizedBox(height: 8),
                TextField(controller: aCtrl, decoration: const InputDecoration(labelText: 'Option A *')),
                const SizedBox(height: 8),
                TextField(controller: bCtrl, decoration: const InputDecoration(labelText: 'Option B *')),
                const SizedBox(height: 8),
                TextField(controller: cCtrl, decoration: const InputDecoration(labelText: 'Option C *')),
                const SizedBox(height: 8),
                TextField(controller: dCtrl, decoration: const InputDecoration(labelText: 'Option D *')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: correct,
                  decoration: const InputDecoration(labelText: 'Correct Option'),
                  items: const ['A', 'B', 'C', 'D']
                      .map((o) => DropdownMenuItem(value: o, child: Text('Option $o')))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setModalState(() => correct = v);
                  },
                ),
                const SizedBox(height: 8),
                TextField(controller: expCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Explanation')),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    if (qCtrl.text.trim().isEmpty || aCtrl.text.trim().isEmpty) return;
                    final lms = Provider.of<LmsAdminProvider>(context, listen: false);
                    if (existing == null) {
                      await lms.addLiveTestQuestion(
                        LmsLiveTestQuestion(
                          id: '',
                          testId: widget.test.id,
                          questionKey: 'Q${_questions.length + 1}',
                          questionText: qCtrl.text.trim(),
                          optionA: aCtrl.text.trim(),
                          optionB: bCtrl.text.trim(),
                          optionC: cCtrl.text.trim(),
                          optionD: dCtrl.text.trim(),
                          correctOption: correct,
                          explanation: expCtrl.text.trim(),
                          displayOrder: _questions.length + 1,
                        ),
                      );
                    } else {
                      await lms.updateLiveTestQuestion(
                        existing.copyWith(
                          questionText: qCtrl.text.trim(),
                          optionA: aCtrl.text.trim(),
                          optionB: bCtrl.text.trim(),
                          optionC: cCtrl.text.trim(),
                          optionD: dCtrl.text.trim(),
                          correctOption: correct,
                          explanation: expCtrl.text.trim(),
                        ),
                      );
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    await _load();
                  },
                  child: Text(existing == null ? 'Add Question' : 'Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openBulkImport() {
    showBulkMcqImporterSheet(
      context,
      showPublishToggle: false,
      replaceLabel: 'Replace existing questions',
      onCommit: ({
        required parsed,
        required fileName,
        required fileType,
        required publishImmediately,
        required replaceExisting,
      }) async {
        await Provider.of<LmsAdminProvider>(context, listen: false)
            .importLiveTestQuestions(
          testId: widget.test.id,
          parsed: parsed,
          replaceExisting: replaceExisting,
        );
        await _load();
      },
    );
  }
}

class _LiveTestResultsScreen extends StatefulWidget {
  final LmsLiveTest test;
  const _LiveTestResultsScreen({required this.test});

  @override
  State<_LiveTestResultsScreen> createState() => _LiveTestResultsScreenState();
}

class _LiveTestResultsScreenState extends State<_LiveTestResultsScreen> {
  List<LmsLiveTestSubmission> _ranked = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await Provider.of<LmsAdminProvider>(context, listen: false)
        .getLiveTestResults(widget.test.id);
    if (!mounted) return;
    setState(() {
      _ranked = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      appBar: AppBar(
        title: Text('${widget.test.title} • Merit List'),
        backgroundColor: AppTheme.surfaceWarmWhite,
        actions: [
          IconButton(
            tooltip: 'Export Excel (.xlsx)',
            icon: const Icon(Icons.table_view_rounded, color: AppTheme.successGreen),
            onPressed: _ranked.isEmpty
                ? null
                : () => LiveTestExporter.shareExcel(widget.test, _ranked),
          ),
          IconButton(
            tooltip: 'Export PDF (.pdf)',
            icon: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.secondaryMaroon),
            onPressed: _ranked.isEmpty
                ? null
                : () => LiveTestExporter.shareOrPrintPdf(widget.test, _ranked),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _ranked.isEmpty
              ? const EmptyStateView(
                  icon: Icons.leaderboard_rounded,
                  title: 'No Submissions Yet',
                  subtitle: 'Student submissions ranked by marks and timestamp will appear here.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _ranked.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, idx) {
                    final s = _ranked[idx];
                    return AdminCard(
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: idx == 0
                                ? AppTheme.goldBell
                                : AppTheme.primaryNavy.withValues(alpha: 0.1),
                            child: Text(
                              '#${s.rank}',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                color: idx == 0 ? Colors.white : AppTheme.primaryNavy,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.studentName, style: const TextStyle(fontWeight: FontWeight.w800)),
                                Text(
                                  '${s.phoneNumber} • ${s.location}',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${s.marksObtained.toStringAsFixed(0)}/${s.totalQuestions}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  color: AppTheme.successGreen,
                                ),
                              ),
                              Text(
                                '${s.percentage.toStringAsFixed(1)}%',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
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
}
