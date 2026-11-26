import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/admin_ui.dart';
import '../../../models/lms_models.dart';
import '../../../providers/lms_admin_provider.dart';
import '../widgets/bulk_mcq_importer_sheet.dart';
import '../widgets/mcq_question_form_sheet.dart';

class LmsMcqAdminScreen extends StatefulWidget {
  const LmsMcqAdminScreen({super.key});

  @override
  State<LmsMcqAdminScreen> createState() => _LmsMcqAdminScreenState();
}

class _LmsMcqAdminScreenState extends State<LmsMcqAdminScreen> {
  final List<McqTopic> _topicBreadcrumb = [];
  McqChapter? _selectedChapter;
  McqMedium? _selectedMedium;
  McqQuestionSet? _selectedSet;

  List<McqChapter> _chapters = [];
  List<McqQuestionSet> _chapterSets = [];
  List<LmsMcqQuestion> _questions = [];
  bool _loadingLevel = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LmsAdminProvider>(context, listen: false).loadTopics();
    });
  }

  McqTopic? get _currentTopic =>
      _topicBreadcrumb.isNotEmpty ? _topicBreadcrumb.last : null;

  Future<void> _enterTopic(McqTopic topic) async {
    setState(() {
      _topicBreadcrumb.add(topic);
      _selectedChapter = null;
      _selectedMedium = null;
      _selectedSet = null;
      _loadingLevel = true;
    });
    final lms = Provider.of<LmsAdminProvider>(context, listen: false);
    final chaps = await lms.getChapters(topic.id);
    if (!mounted) return;
    setState(() {
      _chapters = chaps;
      _loadingLevel = false;
    });
  }

  Future<void> _popToTopicIndex(int index) async {
    if (index < 0) {
      setState(() {
        _topicBreadcrumb.clear();
        _selectedChapter = null;
        _selectedMedium = null;
        _selectedSet = null;
        _chapters = [];
      });
      await Provider.of<LmsAdminProvider>(context, listen: false).loadTopics();
      return;
    }

    setState(() {
      _topicBreadcrumb.removeRange(index + 1, _topicBreadcrumb.length);
      _selectedChapter = null;
      _selectedMedium = null;
      _selectedSet = null;
      _loadingLevel = true;
    });
    final lms = Provider.of<LmsAdminProvider>(context, listen: false);
    final chaps = await lms.getChapters(_topicBreadcrumb.last.id);
    if (!mounted) return;
    setState(() {
      _chapters = chaps;
      _loadingLevel = false;
    });
  }

  Future<void> _enterChapter(McqChapter chapter) async {
    setState(() {
      _selectedChapter = chapter;
      _selectedMedium = null;
      _selectedSet = null;
      _loadingLevel = true;
    });
    final lms = Provider.of<LmsAdminProvider>(context, listen: false);
    final sets = await lms.getQuestionSetsForChapter(chapter.id);
    if (!mounted) return;
    setState(() {
      _chapterSets = sets;
      _loadingLevel = false;
    });
  }

  Future<void> _enterMediumSet(McqMedium medium, McqQuestionSet set) async {
    setState(() {
      _selectedMedium = medium;
      _selectedSet = set;
      _loadingLevel = true;
    });
    final lms = Provider.of<LmsAdminProvider>(context, listen: false);
    final qs = await lms.getQuestionsForSet(set.id);
    if (!mounted) return;
    setState(() {
      _questions = qs;
      _loadingLevel = false;
    });
  }

  Future<void> _refreshCurrentLevel() async {
    final lms = Provider.of<LmsAdminProvider>(context, listen: false);
    await lms.loadTopics();
    if (_selectedSet != null && _selectedChapter != null && _selectedMedium != null) {
      final sets = await lms.getQuestionSetsForChapter(_selectedChapter!.id);
      final updatedSet = sets.where((s) => s.mediumId == _selectedMedium!.id).firstOrNull;
      final qs = updatedSet != null
          ? await lms.getQuestionsForSet(updatedSet.id)
          : <LmsMcqQuestion>[];
      if (!mounted) return;
      setState(() {
        _chapterSets = sets;
        _selectedSet = updatedSet;
        _questions = qs;
      });
    } else if (_selectedChapter != null) {
      final sets = await lms.getQuestionSetsForChapter(_selectedChapter!.id);
      if (!mounted) return;
      setState(() => _chapterSets = sets);
    } else if (_currentTopic != null) {
      final chaps = await lms.getChapters(_currentTopic!.id);
      if (!mounted) return;
      setState(() => _chapters = chaps);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lms = Provider.of<LmsAdminProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      appBar: AppBar(
        title: Text(
          _selectedSet != null
              ? '${_selectedMedium?.displayName ?? ''} Questions'
              : _selectedChapter != null
                  ? _selectedChapter!.title
                  : _currentTopic != null
                      ? _currentTopic!.name
                      : 'MCQ Hierarchy & Importer',
        ),
        backgroundColor: AppTheme.surfaceWarmWhite,
        actions: [
          IconButton(
            tooltip: 'Manage Mediums',
            icon: const Icon(Icons.translate_rounded),
            onPressed: _showMediumsSheet,
          ),
          IconButton(
            tooltip: 'Import Logs',
            icon: const Icon(Icons.receipt_long_rounded),
            onPressed: _showImportLogsSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Global MCQ Toggle Banner
          Container(
            color: AppTheme.surfaceWarmWhite,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    lms.settings.mcqEnabled
                        ? 'MCQ Practice: ENABLED for students'
                        : 'MCQ Practice: PAUSED ("Coming Soon")',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: lms.settings.mcqEnabled
                          ? AppTheme.successGreen
                          : AppTheme.secondaryMaroon,
                    ),
                  ),
                ),
                Switch(
                  value: lms.settings.mcqEnabled,
                  onChanged: (v) => lms.toggleMcqEnabled(v),
                ),
              ],
            ),
          ),

          // Mobile Breadcrumb Strip
          Container(
            width: double.infinity,
            color: AppTheme.surfaceCream,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _crumbChip('Topics', () => _popToTopicIndex(-1),
                      active: _topicBreadcrumb.isEmpty),
                  for (var i = 0; i < _topicBreadcrumb.length; i++) ...[
                    const Icon(Icons.chevron_right_rounded, size: 16),
                    _crumbChip(
                      _topicBreadcrumb[i].name,
                      () => _popToTopicIndex(i),
                      active: i == _topicBreadcrumb.length - 1 && _selectedChapter == null,
                    ),
                  ],
                  if (_selectedChapter != null) ...[
                    const Icon(Icons.chevron_right_rounded, size: 16),
                    _crumbChip(
                      _selectedChapter!.title,
                      () => _enterChapter(_selectedChapter!),
                      active: _selectedSet == null,
                    ),
                  ],
                  if (_selectedMedium != null) ...[
                    const Icon(Icons.chevron_right_rounded, size: 16),
                    _crumbChip(_selectedMedium!.displayName, () {}, active: true),
                  ],
                ],
              ),
            ),
          ),

          Expanded(
            child: _loadingLevel
                ? const Center(child: CircularProgressIndicator())
                : _selectedSet != null
                    ? _buildQuestionsLevel(lms)
                    : _selectedChapter != null
                        ? _buildLanguagesLevel(lms)
                        : _buildTopicsAndChaptersLevel(lms),
          ),
        ],
      ),
      floatingActionButton: _buildFab(lms),
    );
  }

  Widget? _buildFab(LmsAdminProvider lms) {
    if (_selectedSet != null) {
      return FloatingActionButton.extended(
        backgroundColor: AppTheme.secondaryMaroon,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.upload_file_rounded),
        label: const Text('Bulk Import'),
        onPressed: _openBulkImporterSheet,
      );
    }
    if (_selectedChapter != null) {
      return FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Attach Medium'),
        onPressed: _showAttachMediumDialog,
      );
    }
    if (_currentTopic != null) {
      return FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryNavy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Chapter / Subtopic'),
        onPressed: () => _showAddInsideTopicSheet(_currentTopic!.id),
      );
    }
    return FloatingActionButton.extended(
      backgroundColor: AppTheme.primaryNavy,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.create_new_folder_rounded),
      label: const Text('New Topic'),
      onPressed: () => _showTopicFormSheet(),
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

  Widget _buildTopicsAndChaptersLevel(LmsAdminProvider lms) {
    final parentId = _currentTopic?.id;
    final subtopics = lms.topics.where((t) => t.parentId == parentId).toList();

    if (subtopics.isEmpty && _chapters.isEmpty) {
      return EmptyStateView(
        icon: Icons.folder_open_rounded,
        title: parentId == null ? 'No Topics Yet' : 'Empty Topic Folder',
        subtitle: parentId == null
            ? 'Create a root MCQ topic to start organizing chapters.'
            : 'Add a nested subtopic or a chapter inside this topic.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
      children: [
        if (subtopics.isNotEmpty) ...[
          Text(
            parentId == null ? 'Topics' : 'Subtopics',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
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
                        Text(t.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(
                          '${t.chapterCount} chapters • ${t.questionCount} MCQs',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: t.isPublished,
                    onChanged: (v) async {
                      await lms.updateTopic(t.copyWith(isPublished: v));
                    },
                  ),
                  PopupMenuButton<String>(
                    onSelected: (action) async {
                      if (action == 'edit') {
                        _showTopicFormSheet(existing: t);
                      } else if (action == 'delete') {
                        await _confirmDeleteTopicTree(t);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit Topic')),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete Subtree', style: TextStyle(color: AppTheme.errorRed)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
        if (parentId != null && _chapters.isNotEmpty) ...[
          const SizedBox(height: 10),
          const Text(
            'Chapters',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
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
                        color: AppTheme.secondaryMaroon,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ch.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        Text(
                          '${ch.questionCount} MCQs • ${ch.publishedSetsCount} live language(s)',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: ch.isPublished,
                    onChanged: (v) async {
                      await lms.updateChapter(ch.copyWith(isPublished: v));
                      await _refreshCurrentLevel();
                    },
                  ),
                  PopupMenuButton<String>(
                    onSelected: (action) async {
                      if (action == 'edit') {
                        _showChapterFormSheet(topicId: ch.topicId, existing: ch);
                      } else if (action == 'delete') {
                        await lms.deleteChapter(ch.id);
                        await _refreshCurrentLevel();
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit Chapter')),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete Chapter', style: TextStyle(color: AppTheme.errorRed)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildLanguagesLevel(LmsAdminProvider lms) {
    final byMedium = <String, List<McqQuestionSet>>{};
    for (final s in _chapterSets) {
      byMedium.putIfAbsent(s.mediumId, () => []).add(s);
    }

    if (byMedium.isEmpty) {
      return const EmptyStateView(
        icon: Icons.translate_rounded,
        title: 'No Languages Attached',
        subtitle: 'Tap "Attach Medium" to add English, Telugu, Hindi, or another language.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
      children: byMedium.entries.map((entry) {
        final medium = lms.mediums.where((m) => m.id == entry.key).firstOrNull ??
            McqMedium(id: entry.key, code: 'en', displayName: entry.key);
        final sets = entry.value..sort((a, b) => b.version.compareTo(a.version));
        final latest = sets.first;
        final statusColor = latest.isPublished
            ? AppTheme.successGreen
            : latest.isArchived
                ? AppTheme.textMuted
                : AppTheme.goldBell;

        return AdminCard(
          margin: const EdgeInsets.only(bottom: 12),
          onTap: () => _enterMediumSet(medium, latest),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${medium.displayName} (${medium.code.toUpperCase()})',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                  ),
                  StatusBadge(text: 'v${latest.version} ${latest.status}', color: statusColor),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${latest.questionCount} questions • ${sets.length} version(s)',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.list_alt_rounded, size: 16),
                    label: const Text('Questions / Import', style: TextStyle(fontSize: 12)),
                    onPressed: () => _enterMediumSet(medium, latest),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          latest.isPublished ? AppTheme.goldBell : AppTheme.successGreen,
                      foregroundColor: Colors.white,
                    ),
                    icon: Icon(
                      latest.isPublished ? Icons.unpublished_rounded : Icons.publish_rounded,
                      size: 16,
                    ),
                    label: Text(
                      latest.isPublished ? 'Unpublish' : 'Publish',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () async {
                      try {
                        await lms.publishQuestionSet(latest.id, publish: !latest.isPublished);
                        await _refreshCurrentLevel();
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
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuestionsLevel(LmsAdminProvider lms) {
    final set = _selectedSet!;
    return Column(
      children: [
        Container(
          color: AppTheme.surfaceWarmWhite,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              StatusBadge(
                text: 'v${set.version} • ${set.status}',
                color: set.isPublished ? AppTheme.successGreen : AppTheme.goldBell,
              ),
              const SizedBox(width: 8),
              Text('${_questions.length} Qs', style: const TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add MCQ', style: TextStyle(fontSize: 12)),
                onPressed: () => _showQuestionFormSheet(),
              ),
              if (_questions.isNotEmpty)
                TextButton.icon(
                  icon: const Icon(Icons.delete_sweep_rounded, color: AppTheme.errorRed, size: 18),
                  label: const Text('Clear All', style: TextStyle(color: AppTheme.errorRed, fontSize: 12)),
                  onPressed: () async {
                    await lms.clearMcqQuestionSet(set.id);
                    await _refreshCurrentLevel();
                  },
                ),
            ],
          ),
        ),
        Expanded(
          child: _questions.isEmpty
              ? EmptyStateView(
                  icon: Icons.upload_file_rounded,
                  title: 'No Questions in Set',
                  subtitle: 'Add MCQs manually or use Bulk Import (.csv, .xlsx, .json, or JSON paste).',
                  actionLabel: 'Open Bulk Importer',
                  onAction: _openBulkImporterSheet,
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
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
                                tooltip: 'Edit Question',
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                onPressed: () => _showQuestionFormSheet(existing: q),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    size: 18, color: AppTheme.errorRed),
                                onPressed: () async {
                                  await lms.deleteMcqQuestion(q.id, set.id);
                                  await _refreshCurrentLevel();
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            q.questionText,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
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
                                      await lms.updateMcqQuestion(
                                        q.copyWith(correctOption: opt.$1),
                                      );
                                      await _refreshCurrentLevel();
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
                                  Expanded(
                                    child: Text(
                                      opt.$2,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: q.correctOption == opt.$1
                                            ? FontWeight.w700
                                            : FontWeight.w400,
                                        color: q.correctOption == opt.$1
                                            ? AppTheme.successGreen
                                            : AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (q.explanation.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Explanation: ${q.explanation}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- DIALOGS & SHEETS ---

  Future<void> _confirmDeleteTopicTree(McqTopic topic) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Topic Subtree?'),
        content: Text(
          'Deletes "${topic.name}", all nested subtopics, chapters, question sets, and questions.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await Provider.of<LmsAdminProvider>(context, listen: false).deleteTopicTree(topic.id);
    await _refreshCurrentLevel();
  }

  void _showTopicFormSheet({McqTopic? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              existing == null ? 'Create Topic / Subtopic' : 'Edit Topic',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Topic Name *')),
            const SizedBox(height: 10),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final lms = Provider.of<LmsAdminProvider>(context, listen: false);
                if (existing == null) {
                  await lms.createTopic(
                    name: nameCtrl.text.trim(),
                    parentId: _currentTopic?.id,
                    description: descCtrl.text.trim(),
                  );
                } else {
                  await lms.updateTopic(
                    existing.copyWith(
                      name: nameCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                    ),
                  );
                }
                if (ctx.mounted) Navigator.pop(ctx);
                await _refreshCurrentLevel();
              },
              child: Text(existing == null ? 'Create' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddInsideTopicSheet(String topicId) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.create_new_folder_rounded, color: AppTheme.primaryNavy),
              title: const Text('Create Nested Subtopic'),
              onTap: () {
                Navigator.pop(ctx);
                _showTopicFormSheet();
              },
            ),
            ListTile(
              leading: const Icon(Icons.menu_book_rounded, color: AppTheme.secondaryMaroon),
              title: const Text('Create Chapter in This Topic'),
              onTap: () {
                Navigator.pop(ctx);
                _showChapterFormSheet(topicId: topicId);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showChapterFormSheet({required String topicId, McqChapter? existing}) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final orderCtrl = TextEditingController(text: '${existing?.displayOrder ?? (_chapters.length + 1)}');
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
              existing == null ? 'Create Chapter' : 'Edit Chapter',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Chapter Title *')),
            const SizedBox(height: 10),
            TextField(
              controller: orderCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Display Order'),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                final lms = Provider.of<LmsAdminProvider>(context, listen: false);
                final order = int.tryParse(orderCtrl.text.trim()) ?? 1;
                if (existing == null) {
                  await lms.createChapter(
                    topicId: topicId,
                    title: titleCtrl.text.trim(),
                    displayOrder: order,
                  );
                } else {
                  await lms.updateChapter(
                    existing.copyWith(title: titleCtrl.text.trim(), displayOrder: order),
                  );
                }
                if (ctx.mounted) Navigator.pop(ctx);
                await _refreshCurrentLevel();
              },
              child: Text(existing == null ? 'Create Chapter' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachMediumDialog() {
    final lms = Provider.of<LmsAdminProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Select Language Medium', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
            for (final med in lms.mediums)
              ListTile(
                leading: const Icon(Icons.language_rounded, color: AppTheme.primaryNavy),
                title: Text('${med.displayName} (${med.code.toUpperCase()})'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await lms.attachChapterLanguage(_selectedChapter!.id, med.id);
                  await _refreshCurrentLevel();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showMediumsSheet() {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final lms = Provider.of<LmsAdminProvider>(ctx);
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Global Language Mediums', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: lms.mediums
                    .map((m) => Chip(label: Text('${m.displayName} (${m.code})')))
                    .toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Code (ta)')),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Display Name (Tamil)')),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  if (codeCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) return;
                  try {
                    await lms.createMedium(codeCtrl.text.trim(), nameCtrl.text.trim());
                    codeCtrl.clear();
                    nameCtrl.clear();
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                    );
                  }
                },
                child: const Text('Add Medium'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showQuestionFormSheet({LmsMcqQuestion? existing}) async {
    final set = _selectedSet;
    if (set == null) return;
    final values = await showMcqQuestionFormSheet(
      context,
      title: existing == null ? 'Add Question' : 'Edit Question',
      initialKey: existing?.questionKey ?? 'Q${_questions.length + 1}',
      initialQuestion: existing?.questionText ?? '',
      initialOptionA: existing?.optionA ?? '',
      initialOptionB: existing?.optionB ?? '',
      initialOptionC: existing?.optionC ?? '',
      initialOptionD: existing?.optionD ?? '',
      initialCorrectOption: existing?.correctOption ?? 'A',
      initialExplanation: existing?.explanation ?? '',
      submitLabel: existing == null ? 'Add Question' : 'Save Question',
    );
    if (values == null || !mounted) return;
    final lms = Provider.of<LmsAdminProvider>(context, listen: false);
    if (existing == null) {
      await lms.addMcqQuestion(
        LmsMcqQuestion(
          id: '',
          questionSetId: set.id,
          chapterId: _selectedChapter?.id,
          questionKey: values.questionKey.isEmpty
              ? 'Q${_questions.length + 1}'
              : values.questionKey,
          questionText: values.questionText,
          optionA: values.optionA,
          optionB: values.optionB,
          optionC: values.optionC,
          optionD: values.optionD,
          correctOption: values.correctOption,
          explanation: values.explanation,
          language: _selectedMedium?.code ?? 'en',
          displayOrder: _questions.length + 1,
          status: set.status,
        ),
      );
    } else {
      await lms.updateMcqQuestion(
        existing.copyWith(
          questionKey: values.questionKey.isEmpty
              ? existing.questionKey
              : values.questionKey,
          questionText: values.questionText,
          optionA: values.optionA,
          optionB: values.optionB,
          optionC: values.optionC,
          optionD: values.optionD,
          correctOption: values.correctOption,
          explanation: values.explanation,
        ),
      );
    }
    await _refreshCurrentLevel();
  }

  void _openBulkImporterSheet() {
    showBulkMcqImporterSheet(
      context,
      preferredLang: _selectedMedium?.code ?? 'en',
      showPublishToggle: true,
      replaceLabel: 'Replace existing (creates new version)',
      onCommit: ({
        required parsed,
        required fileName,
        required fileType,
        required publishImmediately,
        required replaceExisting,
      }) async {
        final lms = Provider.of<LmsAdminProvider>(context, listen: false);
        await lms.importMcqQuestions(
          topicId: _currentTopic!.id,
          chapterId: _selectedChapter!.id,
          mediumId: _selectedMedium!.id,
          mediumCode: _selectedMedium!.code,
          parsed: parsed,
          fileName: fileName,
          fileType: fileType,
          publishImmediately: publishImmediately,
          replaceExisting: replaceExisting,
        );
        await _refreshCurrentLevel();
      },
    );
  }

  void _showImportLogsSheet() async {
    final lms = Provider.of<LmsAdminProvider>(context, listen: false);
    await lms.loadImportLogs(chapterId: _selectedChapter?.id);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Import Logs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          if (lms.importLogs.isEmpty)
            const Text('No import history yet.')
          else
            for (final log in lms.importLogs)
              ListTile(
                title: Text('${log.fileName} (${log.fileType.toUpperCase()})'),
                subtitle: Text('Rows: ${log.validRows}/${log.totalRows} • ${log.errorSummary ?? 'Success'}'),
                trailing: StatusBadge(
                  text: log.status,
                  color: log.status == 'success' ? AppTheme.successGreen : AppTheme.errorRed,
                ),
              ),
        ],
      ),
    );
  }
}
