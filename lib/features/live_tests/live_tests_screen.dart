import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/widgets/admin_ui.dart';
import '../../models/lms_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lms_admin_provider.dart';
import '../../shared/tenali_top_app_bar.dart';

class LiveTestsScreen extends StatefulWidget {
  const LiveTestsScreen({super.key});

  @override
  State<LiveTestsScreen> createState() => _LiveTestsScreenState();
}

class _LiveTestsScreenState extends State<LiveTestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lms = Provider.of<LmsAdminProvider>(context, listen: false);
      lms.loadPublicSettings();
      lms.loadLiveTests(studentOnly: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lms = Provider.of<LmsAdminProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final df = DateFormat('dd MMM yyyy');

    final topBar = TenaliTopAppBar(
      title: 'Live Tests',
      extraActions: [
        IconButton(
          tooltip: 'Refresh Live Tests',
          icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryNavy),
          onPressed: () => lms.loadLiveTests(studentOnly: true),
        ),
      ],
    );

    if (!lms.settings.liveTestEnabled) {
      return Scaffold(
        backgroundColor: AppTheme.bgLight,
        appBar: topBar,
        body: const EmptyStateView(
          icon: Icons.timer_off_rounded,
          title: 'Live Tests Coming Soon',
          subtitle:
              'Live examinations are currently paused by the administrator. Please check back later.',
        ),
      );
    }

    final visibleTests =
        lms.liveTests.where((t) => t.isPublished || t.isClosed).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: topBar,
      body: visibleTests.isEmpty
          ? const EmptyStateView(
              icon: Icons.assignment_outlined,
              title: 'No Active Live Tests',
              subtitle: 'Published live tests from the administrator will appear here immediately.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: visibleTests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, idx) {
                final test = visibleTests[idx];
                return AdminCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          StatusBadge(
                            text: test.isPublished ? 'LIVE NOW' : 'CLOSED',
                            color: test.isPublished
                                ? AppTheme.successGreen
                                : AppTheme.secondaryMaroon,
                          ),
                          const SizedBox(width: 6),
                          if (test.answersReleased)
                            const StatusBadge(
                              text: 'ANSWER KEY RELEASED',
                              color: AppTheme.infoBlue,
                            ),
                          const Spacer(),
                          Text(
                            df.format(test.testDate),
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        test.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      if (test.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          test.description,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        '${test.questionCount} Questions • Untimed until closed • ${test.attemptsCount} participants',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      if (test.isPublished)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondaryMaroon,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Start Live Test'),
                            onPressed: () => _openAttemptFlow(test, auth),
                          ),
                        )
                      else if (test.answersReleased)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.key_rounded),
                            label: const Text('View Official Answer Key'),
                            onPressed: () => _openAnswerKey(test),
                          ),
                        )
                      else
                        const Text(
                          'Test closed — official answer key has not been released yet.',
                          style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Future<void> _openAttemptFlow(LmsLiveTest test, AuthProvider auth) async {
    final nameCtrl = TextEditingController(text: auth.user?.fullName ?? '');
    final phoneCtrl = TextEditingController(text: auth.user?.phoneNumber ?? '');
    final locCtrl = TextEditingController(text: auth.user?.location ?? '');
    final emailCtrl = TextEditingController(text: auth.user?.email ?? '');

    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(test.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Confirm your details before starting. Answer keys stay hidden until released by admin.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 10),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name *')),
              const SizedBox(height: 8),
              TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: '10-Digit Phone *')),
              const SizedBox(height: 8),
              TextField(controller: locCtrl, decoration: const InputDecoration(labelText: 'Location / Circle *')),
              const SizedBox(height: 8),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email *')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().length < 10) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Begin Test'),
          ),
        ],
      ),
    );

    if (proceed != true || !mounted) return;

    try {
      final qs = await Provider.of<LmsAdminProvider>(context, listen: false)
          .getStudentLiveTestQuestions(test.id);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _UntimedLiveTestRunner(
            test: test,
            questions: qs,
            studentName: nameCtrl.text.trim(),
            phoneNumber: phoneCtrl.text.trim(),
            location: locCtrl.text.trim(),
            email: emailCtrl.text.trim(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  Future<void> _openAnswerKey(LmsLiveTest test) async {
    try {
      final qs = await Provider.of<LmsAdminProvider>(context, listen: false)
          .getStudentLiveTestAnswers(test.id);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            backgroundColor: AppTheme.bgWarm,
            appBar: AppBar(title: Text('${test.title} • Answer Key')),
            body: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: qs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final q = qs[i];
                return AdminCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Q${i + 1}. ${q.questionText}',
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(
                        'Correct Answer: Option ${q.correctOption ?? ''}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.successGreen),
                      ),
                      if (q.explanation != null && q.explanation!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(q.explanation!,
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }
}

class _UntimedLiveTestRunner extends StatefulWidget {
  final LmsLiveTest test;
  final List<LmsLiveTestQuestion> questions;
  final String studentName;
  final String phoneNumber;
  final String location;
  final String email;

  const _UntimedLiveTestRunner({
    required this.test,
    required this.questions,
    required this.studentName,
    required this.phoneNumber,
    required this.location,
    required this.email,
  });

  @override
  State<_UntimedLiveTestRunner> createState() => _UntimedLiveTestRunnerState();
}

class _UntimedLiveTestRunnerState extends State<_UntimedLiveTestRunner> {
  final Map<String, String> _answers = {};
  bool _submitting = false;
  LmsLiveTestSubmission? _result;

  @override
  Widget build(BuildContext context) {
    if (_result != null) {
      return Scaffold(
        backgroundColor: AppTheme.bgWarm,
        appBar: AppBar(title: const Text('Submission Recorded')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: AdminCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 54, color: AppTheme.successGreen),
                const SizedBox(height: 12),
                Text(
                  'Score: ${_result!.marksObtained.toStringAsFixed(0)} / ${_result!.totalQuestions}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_result!.percentage.toStringAsFixed(1)}% • Correct: ${_result!.correctCount} • Wrong: ${_result!.wrongCount}',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      appBar: AppBar(title: Text(widget.test.title)),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        itemCount: widget.questions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, idx) {
          final q = widget.questions[idx];
          return AdminCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Q${idx + 1}. ${q.questionText}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(height: 8),
                RadioGroup<String>(
                  groupValue: _answers[q.id],
                  onChanged: (val) {
                    if (val != null) setState(() => _answers[q.id] = val);
                  },
                  child: Column(
                    children: [
                      for (final opt in [
                        ('A', q.optionA),
                        ('B', q.optionB),
                        ('C', q.optionC),
                        ('D', q.optionD),
                      ])
                        RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text('${opt.$1}. ${opt.$2}',
                              style: const TextStyle(fontSize: 13)),
                          value: opt.$1,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryMaroon,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _submitting
                ? null
                : () async {
                    setState(() => _submitting = true);
                    try {
                      final sub = await Provider.of<LmsAdminProvider>(context,
                              listen: false)
                          .submitStudentLiveTest(
                        testId: widget.test.id,
                        studentName: widget.studentName,
                        phoneNumber: widget.phoneNumber,
                        location: widget.location,
                        email: widget.email,
                        answers: _answers,
                      );
                      if (mounted) setState(() => _result = sub);
                    } catch (e) {
                      if (!mounted) return;
                      setState(() => _submitting = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString().replaceAll('Exception: ', '')),
                          backgroundColor: AppTheme.errorRed,
                        ),
                      );
                    }
                  },
            child: Text(_submitting
                ? 'Submitting...'
                : 'Submit Test (${_answers.length}/${widget.questions.length})'),
          ),
        ),
      ),
    );
  }
}
