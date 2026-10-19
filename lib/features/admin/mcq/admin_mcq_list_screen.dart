import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../models/question.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/auth_provider.dart';
import 'admin_mcq_editor_screen.dart';
import 'admin_mcq_import_export_screen.dart';

class AdminMcqListScreen extends StatefulWidget {
  const AdminMcqListScreen({super.key});

  @override
  State<AdminMcqListScreen> createState() => _AdminMcqListScreenState();
}

class _AdminMcqListScreenState extends State<AdminMcqListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AdminProvider>(context, listen: false);
      provider.loadQuestions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final adminEmail = auth.user?.email ?? 'admin@tenalipost.gov.in';

    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      appBar: AppBar(
        title: const Text('MCQ Management'),
        backgroundColor: AppTheme.surfaceWarmWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: AppTheme.primaryNavy),
            tooltip: 'Import / Export Questions',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminMcqImportExportScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryNavy),
            tooltip: 'Refresh Question Bank',
            onPressed: () => admin.loadQuestions(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.secondaryMaroon,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create Question', style: TextStyle(fontWeight: FontWeight.w800)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminMcqEditorScreen(),
            ),
          );
        },
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            color: AppTheme.surfaceWarmWhite,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search questions, clauses, rule refs...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              admin.setMcqSearch('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    fillColor: AppTheme.bgWarm,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.borderWarmSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.borderWarmSubtle),
                    ),
                  ),
                  onChanged: (val) => admin.setMcqSearch(val),
                ),
                const SizedBox(height: 10),

                // Filters Row (Exam, Language, Difficulty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Exam Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.bgWarm,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.borderWarmSubtle),
                        ),
                        child: DropdownButton<String?>(
                          value: admin.mcqExamFilter,
                          hint: const Text('All Exams', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          underline: const SizedBox(),
                          isDense: true,
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('All Exams', style: TextStyle(fontSize: 12)),
                            ),
                            ...admin.exams.map(
                              (e) => DropdownMenuItem<String?>(
                                value: e.id,
                                child: Text('${e.code} (${e.title})', style: const TextStyle(fontSize: 12)),
                              ),
                            ),
                          ],
                          onChanged: (val) => admin.setMcqExamFilter(val),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Language Chips
                      _filterChip(
                        label: 'All Lang',
                        isSelected: admin.mcqLanguageFilter == 'all',
                        onSelected: () => admin.setMcqLanguageFilter('all'),
                      ),
                      const SizedBox(width: 4),
                      _filterChip(
                        label: 'EN',
                        isSelected: admin.mcqLanguageFilter == 'en',
                        onSelected: () => admin.setMcqLanguageFilter('en'),
                      ),
                      const SizedBox(width: 4),
                      _filterChip(
                        label: 'TE (తెలుగు)',
                        isSelected: admin.mcqLanguageFilter == 'te',
                        onSelected: () => admin.setMcqLanguageFilter('te'),
                      ),
                      const SizedBox(width: 4),
                      _filterChip(
                        label: 'HI (हिन्दी)',
                        isSelected: admin.mcqLanguageFilter == 'hi',
                        onSelected: () => admin.setMcqLanguageFilter('hi'),
                      ),
                      const SizedBox(width: 8),

                      // Difficulty Chips
                      _filterChip(
                        label: 'All Diff',
                        isSelected: admin.mcqDifficultyFilter == 'all',
                        onSelected: () => admin.setMcqDifficultyFilter('all'),
                      ),
                      const SizedBox(width: 4),
                      _filterChip(
                        label: 'Easy',
                        isSelected: admin.mcqDifficultyFilter == 'Easy',
                        onSelected: () => admin.setMcqDifficultyFilter('Easy'),
                      ),
                      const SizedBox(width: 4),
                      _filterChip(
                        label: 'Medium',
                        isSelected: admin.mcqDifficultyFilter == 'Medium',
                        onSelected: () => admin.setMcqDifficultyFilter('Medium'),
                      ),
                      const SizedBox(width: 4),
                      _filterChip(
                        label: 'Hard',
                        isSelected: admin.mcqDifficultyFilter == 'Hard',
                        onSelected: () => admin.setMcqDifficultyFilter('Hard'),
                      ),
                    ],
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
                Text(
                  '${admin.questions.length} Questions Displayed',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Row(
                  children: [
                    _statusDot(AppTheme.successGreen, 'Published'),
                    const SizedBox(width: 12),
                    _statusDot(AppTheme.warningAmber, 'Draft'),
                  ],
                ),
              ],
            ),
          ),

          // Questions List
          Expanded(
            child: admin.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.secondaryMaroon))
                : admin.questions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.quiz_outlined, size: 54, color: AppTheme.textMuted),
                            const SizedBox(height: 12),
                            const Text(
                              'No questions match your filter criteria.',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              icon: const Icon(Icons.clear_all_rounded),
                              label: const Text('Reset All Filters'),
                              onPressed: () {
                                _searchController.clear();
                                admin.setMcqSearch('');
                                admin.setMcqExamFilter(null);
                                admin.setMcqLanguageFilter('all');
                                admin.setMcqDifficultyFilter('all');
                              },
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: admin.questions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final q = admin.questions[index];
                          return _questionCard(context, q, admin, adminEmail);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _questionCard(BuildContext context, Question q, AdminProvider admin, String adminEmail) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWarmWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderWarmSubtle, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryNavy.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Exam / Chapter & Badges
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryNavy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  q.examId.toUpperCase(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.primaryNavy),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.goldChipBg.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  q.languageCode.toUpperCase(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.primaryNavy),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: q.difficulty == 'Easy'
                      ? AppTheme.successGreenBg
                      : q.difficulty == 'Hard'
                          ? AppTheme.errorRedBg
                          : AppTheme.surfaceCream,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  q.difficulty,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: q.difficulty == 'Easy'
                        ? AppTheme.successGreen
                        : q.difficulty == 'Hard'
                            ? AppTheme.errorRed
                            : AppTheme.primaryNavy,
                  ),
                ),
              ),
              const Spacer(),
              // Publish Switch
              InkWell(
                onTap: () => admin.toggleQuestionPublish(q, adminEmail: adminEmail),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      q.isPublished ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      size: 16,
                      color: q.isPublished ? AppTheme.successGreen : AppTheme.warningAmber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      q.isPublished ? 'Published' : 'Draft',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: q.isPublished ? AppTheme.successGreen : AppTheme.warningAmber,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Question Text
          Text(
            q.questionText,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              height: 1.35,
            ),
          ),

          const SizedBox(height: 8),

          // Options Preview
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _optionSnippet('A', q.optionA, q.correctOption == 'A'),
              _optionSnippet('B', q.optionB, q.correctOption == 'B'),
              _optionSnippet('C', q.optionC, q.correctOption == 'C'),
              _optionSnippet('D', q.optionD, q.correctOption == 'D'),
            ],
          ),

          if (q.postalRuleRef != null && q.postalRuleRef!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.menu_book_rounded, size: 13, color: AppTheme.goldBell),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    q.postalRuleRef!,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          const Divider(height: 20, color: AppTheme.borderWarmSubtle),

          // Action Buttons: Edit, Duplicate, Delete
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'ID: ${q.id}',
                style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontFamily: 'monospace'),
              ),
              const Spacer(),
              // Duplicate
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18, color: AppTheme.primaryNavy),
                tooltip: 'Duplicate Question',
                onPressed: () async {
                  await admin.duplicateQuestion(q.id, adminEmail: adminEmail);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Question duplicated as draft.')),
                    );
                  }
                },
              ),
              // Edit
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryNavy),
                tooltip: 'Edit Question',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminMcqEditorScreen(questionToEdit: q),
                    ),
                  );
                },
              ),
              // Delete
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.errorRed),
                tooltip: 'Delete Question',
                onPressed: () => _confirmDeleteQuestion(context, q, admin, adminEmail),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _optionSnippet(String letter, String text, bool isCorrect) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isCorrect ? AppTheme.successGreenBg : AppTheme.bgWarm,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isCorrect ? AppTheme.successGreen : AppTheme.borderWarmSubtle,
          width: isCorrect ? 1.2 : 0.8,
        ),
      ),
      child: Text(
        '$letter: ${text.length > 25 ? '${text.substring(0, 25)}...' : text}',
        style: TextStyle(
          fontSize: 11,
          fontWeight: isCorrect ? FontWeight.w800 : FontWeight.w500,
          color: isCorrect ? AppTheme.successGreen : AppTheme.textSecondary,
        ),
      ),
    );
  }

  void _confirmDeleteQuestion(BuildContext context, Question q, AdminProvider admin, String adminEmail) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Question?'),
        content: Text('Are you sure you want to permanently delete this question:\n\n"${q.questionText}"'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: () async {
              Navigator.pop(ctx);
              await admin.deleteQuestion(q.id, adminEmail: adminEmail);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Question deleted successfully.')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({required String label, required bool isSelected, required VoidCallback onSelected}) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryNavy : AppTheme.bgWarm,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppTheme.primaryNavy : AppTheme.borderWarmSubtle),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _statusDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
