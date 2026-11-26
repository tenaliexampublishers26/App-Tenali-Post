import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/widgets/admin_ui.dart';
import '../../models/lms_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lms_admin_provider.dart';
import '../../shared/tenali_top_app_bar.dart';

class ExamListScreen extends StatefulWidget {
  final bool asTab;
  const ExamListScreen({super.key, this.asTab = false});

  @override
  State<ExamListScreen> createState() => _ExamListScreenState();
}

class _ExamListScreenState extends State<ExamListScreen> {
  final List<McqTopic> _topicBreadcrumb = [];
  McqChapter? _selectedChapter;
  List<McqChapter> _chapters = [];
  List<McqQuestionSet> _publishedSets = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lms = Provider.of<LmsAdminProvider>(context, listen: false);
      lms.loadPublicSettings();
      lms.loadTopics(publishedOnly: true);
    });
  }

  McqTopic? get _currentTopic =>
      _topicBreadcrumb.isNotEmpty ? _topicBreadcrumb.last : null;

  Future<void> _enterTopic(McqTopic topic) async {
    setState(() {
      _topicBreadcrumb.add(topic);
      _selectedChapter = null;
      _loading = true;
    });
    final chaps = await Provider.of<LmsAdminProvider>(context, listen: false)
        .getChapters(topic.id, publishedOnly: true);
    if (!mounted) return;
    setState(() {
      _chapters = chaps;
      _loading = false;
    });
  }

  Future<void> _enterChapter(McqChapter chapter) async {
    setState(() {
      _selectedChapter = chapter;
      _loading = true;
    });
    final sets = await Provider.of<LmsAdminProvider>(context, listen: false)
        .getQuestionSetsForChapter(chapter.id, publishedOnly: true);
    if (!mounted) return;
    setState(() {
      _publishedSets = sets;
      _loading = false;
    });
  }

  Future<void> _popToIndex(int index) async {
    if (index < 0) {
      setState(() {
        _topicBreadcrumb.clear();
        _selectedChapter = null;
        _chapters = [];
      });
      await Provider.of<LmsAdminProvider>(context, listen: false)
          .loadTopics(publishedOnly: true);
      return;
    }
    setState(() {
      _topicBreadcrumb.removeRange(index + 1, _topicBreadcrumb.length);
      _selectedChapter = null;
      _loading = true;
    });
    final chaps = await Provider.of<LmsAdminProvider>(context, listen: false)
        .getChapters(_topicBreadcrumb.last.id, publishedOnly: true);
    if (!mounted) return;
    setState(() {
      _chapters = chaps;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lms = Provider.of<LmsAdminProvider>(context);

    final PreferredSizeWidget appBar = widget.asTab
        ? TenaliTopAppBar(
            title: 'MCQs Practice',
            extraActions: [
              IconButton(
                tooltip: 'Refresh MCQs',
                icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryNavy),
                onPressed: () => lms.loadTopics(publishedOnly: true),
              ),
            ],
          )
        : AppBar(
            title: Text(
              _selectedChapter != null
                  ? _selectedChapter!.title
                  : _currentTopic != null
                      ? _currentTopic!.name
                      : 'MCQ Practice Bank',
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => lms.loadTopics(publishedOnly: true),
              ),
            ],
          );

    if (!lms.settings.mcqEnabled) {
      return Scaffold(
        backgroundColor: AppTheme.bgLight,
        appBar: appBar,
        body: const EmptyStateView(
          icon: Icons.hourglass_top_rounded,
          title: 'MCQ Practice Coming Soon',
          subtitle:
              'Practice quizzes are temporarily paused by the administrator. Please check back shortly.',
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: appBar,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppTheme.surfaceCream,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _crumbChip('Topics', () => _popToIndex(-1),
                      active: _topicBreadcrumb.isEmpty),
                  for (var i = 0; i < _topicBreadcrumb.length; i++) ...[
                    const Icon(Icons.chevron_right_rounded, size: 16),
                    _crumbChip(
                      _topicBreadcrumb[i].name,
                      () => _popToIndex(i),
                      active: i == _topicBreadcrumb.length - 1 &&
                          _selectedChapter == null,
                    ),
                  ],
                  if (_selectedChapter != null) ...[
                    const Icon(Icons.chevron_right_rounded, size: 16),
                    _crumbChip(_selectedChapter!.title, () {}, active: true),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _selectedChapter != null
                    ? _buildMediumPicker(lms)
                    : _buildTopicsAndChapters(lms),
          ),
        ],
      ),
    );
  }

  Widget _crumbChip(String label, VoidCallback onTap, {bool active = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? AppTheme.primaryNavy : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderWarmSubtle),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : AppTheme.primaryNavy,
          ),
        ),
      ),
    );
  }

  Widget _buildTopicsAndChapters(LmsAdminProvider lms) {
    final parentId = _currentTopic?.id;
    final subtopics =
        lms.topics.where((t) => t.isPublished && t.parentId == parentId).toList();

    if (subtopics.isEmpty && _chapters.isEmpty) {
      return const EmptyStateView(
        icon: Icons.quiz_outlined,
        title: 'No Published MCQs Yet',
        subtitle: 'Published topics and chapters added by administrators will appear here.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final t in subtopics)
          AdminCard(
            margin: const EdgeInsets.only(bottom: 10),
            onTap: () => _enterTopic(t),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppTheme.surfaceCream,
                  child: Icon(Icons.folder_rounded, color: AppTheme.primaryNavy),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(
                        '${t.chapterCount} chapters • ${t.questionCount} MCQs',
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
              ],
            ),
          ),
        for (final ch in _chapters)
          AdminCard(
            margin: const EdgeInsets.only(bottom: 10),
            onTap: () => _enterChapter(ch),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.secondaryMaroon.withValues(alpha: 0.1),
                  child: Text(
                    '${ch.displayOrder}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppTheme.secondaryMaroon),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ch.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14)),
                      Text(
                        '${ch.questionCount} MCQs • ${ch.publishedSetsCount} language(s)',
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.play_arrow_rounded, color: AppTheme.primaryNavy),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMediumPicker(LmsAdminProvider lms) {
    if (_publishedSets.isEmpty) {
      return const EmptyStateView(
        icon: Icons.translate_rounded,
        title: 'No Published Language Sets',
        subtitle: 'No language sets have been published for this chapter yet.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _publishedSets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, idx) {
        final set = _publishedSets[idx];
        final medium = lms.mediums.where((m) => m.id == set.mediumId).firstOrNull;
        return AdminCard(
          onTap: () async {
            final qs = await lms.getQuestionsForSet(set.id);
            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _LmsMcqPracticeRunner(
                  chapterTitle: _selectedChapter!.title,
                  mediumName: medium?.displayName ?? 'Practice',
                  questionSet: set,
                  questions: qs,
                ),
              ),
            );
          },
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppTheme.surfaceCream,
                child: Icon(Icons.language_rounded, color: AppTheme.primaryNavy),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medium?.displayName ?? 'Language Set',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    Text(
                      '${set.questionCount} Questions • Version ${set.version}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryNavy,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final qs = await lms.getQuestionsForSet(set.id);
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _LmsMcqPracticeRunner(
                        chapterTitle: _selectedChapter!.title,
                        mediumName: medium?.displayName ?? 'Practice',
                        questionSet: set,
                        questions: qs,
                      ),
                    ),
                  );
                },
                child: const Text('Start'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LmsMcqPracticeRunner extends StatefulWidget {
  final String chapterTitle;
  final String mediumName;
  final McqQuestionSet questionSet;
  final List<LmsMcqQuestion> questions;

  const _LmsMcqPracticeRunner({
    required this.chapterTitle,
    required this.mediumName,
    required this.questionSet,
    required this.questions,
  });

  @override
  State<_LmsMcqPracticeRunner> createState() => _LmsMcqPracticeRunnerState();
}

class _LmsMcqPracticeRunnerState extends State<_LmsMcqPracticeRunner> {
  int _index = 0;
  final Map<String, String> _selected = {};
  Set<String> _bookmarks = {};
  McqAttemptRecord? _submitted;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uid = Provider.of<AuthProvider>(context, listen: false).user?.id;
      if (uid != null) {
        final bms = await Provider.of<LmsAdminProvider>(context, listen: false)
            .getUserBookmarks(uid);
        if (mounted) setState(() => _bookmarks = bms);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.chapterTitle)),
        body: const EmptyStateView(
          icon: Icons.quiz_outlined,
          title: 'Empty Question Set',
          subtitle: 'This question set has no questions yet.',
        ),
      );
    }

    if (_submitted != null) {
      return Scaffold(
        backgroundColor: AppTheme.bgWarm,
        appBar: AppBar(title: const Text('Practice Complete')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: AdminCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events_rounded, size: 52, color: AppTheme.goldBell),
                const SizedBox(height: 12),
                Text(
                  '${_submitted!.correctCount} / ${_submitted!.totalQuestions} Correct',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  'Attempted: ${_submitted!.attemptedCount} • Score: ${_submitted!.score.toInt()}',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to Chapters'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final q = widget.questions[_index];
    final chosen = _selected[q.id];
    final isLocked = chosen != null;
    final uid = Provider.of<AuthProvider>(context, listen: false).user?.id;
    final isBookmarked = _bookmarks.contains(q.id);

    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      appBar: AppBar(
        title: Text('${widget.mediumName} • Q${_index + 1}/${widget.questions.length}'),
        actions: [
          if (uid != null)
            IconButton(
              icon: Icon(
                isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                color: AppTheme.goldBell,
              ),
              onPressed: () async {
                final added = await Provider.of<LmsAdminProvider>(context, listen: false)
                    .toggleMcqBookmark(uid, q.id);
                if (!mounted) return;
                setState(() {
                  if (added) {
                    _bookmarks.add(q.id);
                  } else {
                    _bookmarks.remove(q.id);
                  }
                });
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AdminCard(
            child: Text(
              q.questionText,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, height: 1.4),
            ),
          ),
          const SizedBox(height: 12),
          for (final opt in [
            ('A', q.optionA),
            ('B', q.optionB),
            ('C', q.optionC),
            ('D', q.optionD),
          ])
            Builder(builder: (_) {
              final isRight = opt.$1 == q.correctOption;
              final isChosen = opt.$1 == chosen;
              Color border = AppTheme.borderWarmSubtle;
              Color fill = AppTheme.surfaceWarmWhite;
              if (isLocked) {
                if (isRight) {
                  border = AppTheme.successGreen;
                  fill = AppTheme.successGreenBg;
                } else if (isChosen) {
                  border = AppTheme.errorRed;
                  fill = AppTheme.errorRedBg;
                }
              }
              return GestureDetector(
                onTap: isLocked ? null : () => setState(() => _selected[q.id] = opt.$1),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border, width: isLocked && (isRight || isChosen) ? 1.5 : 1),
                  ),
                  child: Row(
                    children: [
                      Text('${opt.$1}. ', style: const TextStyle(fontWeight: FontWeight.w900)),
                      Expanded(child: Text(opt.$2)),
                    ],
                  ),
                ),
              );
            }),
          if (isLocked && q.explanation.isNotEmpty) ...[
            const SizedBox(height: 6),
            AdminCard(
              child: Text(
                'Explanation: ${q.explanation}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              if (_index > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _index--),
                    child: const Text('Previous'),
                  ),
                ),
              if (_index > 0) const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryNavy,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (_index < widget.questions.length - 1) {
                      setState(() => _index++);
                    } else {
                      final rec = await Provider.of<LmsAdminProvider>(context, listen: false)
                          .submitMcqPracticeAttempt(
                        userId: uid ?? 'anonymous',
                        questionSetId: widget.questionSet.id,
                        questionSetVersion: widget.questionSet.version,
                        questions: widget.questions,
                        selectedAnswers: _selected,
                      );
                      if (mounted) setState(() => _submitted = rec);
                    }
                  },
                  child: Text(
                    _index < widget.questions.length - 1 ? 'Next' : 'Finish & Save',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
