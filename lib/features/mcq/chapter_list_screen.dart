import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/exam.dart';
import '../../providers/mcq_provider.dart';
import 'mcq_practice_screen.dart';

class ChapterListScreen extends StatelessWidget {
  final Exam exam;

  const ChapterListScreen({super.key, required this.exam});

  @override
  Widget build(BuildContext context) {
    final mcqProvider = Provider.of<McqProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text(exam.title),
      ),
      body: Column(
        children: [
          // Language Selector Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppTheme.surfaceWhite,
            child: Row(
              children: [
                const Icon(Icons.language_rounded, color: AppTheme.primaryNavy, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Select Medium:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: AppConstants.languages.map((lang) {
                        final bool isSelected = mcqProvider.selectedLanguage == lang['code'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(lang['nativeName'] ?? lang['name']!),
                            selected: isSelected,
                            selectedColor: AppTheme.primaryNavy,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                            onSelected: (_) {
                              mcqProvider.setLanguage(lang['code']!);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppTheme.borderSubtle),

          // Chapters List
          Expanded(
            child: mcqProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : mcqProvider.chapters.isEmpty
                    ? const Center(
                        child: Text(
                          'No chapters available for this exam yet.',
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: mcqProvider.chapters.length,
                        itemBuilder: (context, index) {
                          final chapter = mcqProvider.chapters[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.accentGold.withValues(alpha: 0.2),
                                foregroundColor: AppTheme.primaryNavy,
                                child: Text(
                                  '${chapter.chapterNumber}',
                                  style: const TextStyle(fontWeight: FontWeight.w900),
                                ),
                              ),
                              title: Text(
                                chapter.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (chapter.description != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      chapter.description!,
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.bgLight,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppTheme.borderSubtle),
                                        ),
                                        child: Text(
                                          '${chapter.totalQuestions} Questions',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.primaryNavy,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
                              onTap: () async {
                                await mcqProvider.selectChapterAndLanguage(
                                  chapter,
                                  mcqProvider.selectedLanguage,
                                );
                                if (context.mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => McqPracticeScreen(chapter: chapter),
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
