import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../providers/admin_provider.dart';
import '../mcq/admin_mcq_list_screen.dart';

class AdminLanguageMatrixScreen extends StatelessWidget {
  const AdminLanguageMatrixScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      appBar: AppBar(
        title: const Text('Language & Translation Matrix'),
        backgroundColor: AppTheme.surfaceWarmWhite,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informational Overview Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryNavy,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.translate_rounded, color: AppTheme.accentGold, size: 28),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Multilingual Translation Coverage',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Monitor Telugu (తెలుగు) and Hindi (हिन्दी) translation completeness across all syllabus chapters.',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Chapter Matrix List
            ...admin.exams.map((exam) {
              final examChapters = admin.chapters.where((c) => c.examId == exam.id).toList();

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Exam Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        color: AppTheme.surfaceCream,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                      ),
                      child: Row(
                        children: [
                          Text(exam.code, style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryNavy, fontSize: 14)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              exam.title,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (examChapters.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No chapters configured.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: examChapters.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.borderWarmSubtle),
                        itemBuilder: (ctx, chIdx) {
                          final ch = examChapters[chIdx];
                          final qList = admin.questions.where((q) => q.chapterId == ch.id).toList();
                          final en = qList.where((q) => q.languageCode == 'en').length;
                          final te = qList.where((q) => q.languageCode == 'te').length;
                          final hi = qList.where((q) => q.languageCode == 'hi').length;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text('Ch ${ch.chapterNumber}:', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppTheme.primaryNavy)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        ch.title,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.textPrimary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    TextButton(
                                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                      onPressed: () {
                                        admin.setMcqExamFilter(exam.id);
                                        admin.setMcqChapterFilter(ch.id);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const AdminMcqListScreen()),
                                        );
                                      },
                                      child: const Text('Manage', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Language Columns
                                Row(
                                  children: [
                                    Expanded(child: _langScore('English (EN)', en, isBase: true)),
                                    const SizedBox(width: 8),
                                    Expanded(child: _langScore('Telugu (తెలుగు)', te, baseCount: en)),
                                    const SizedBox(width: 8),
                                    Expanded(child: _langScore('Hindi (हिन्दी)', hi, baseCount: en)),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _langScore(String title, int count, {bool isBase = false, int baseCount = 0}) {
    bool isComplete = isBase ? count > 0 : (baseCount > 0 && count >= baseCount);
    bool isPartial = !isBase && count > 0 && count < baseCount;
    Color statusColor = isComplete
        ? AppTheme.successGreen
        : isPartial
            ? AppTheme.warningAmber
            : AppTheme.errorRed;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.textSecondary), maxLines: 1),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$count Qs', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: statusColor)),
              Icon(
                isComplete ? Icons.check_circle_rounded : (isPartial ? Icons.timelapse_rounded : Icons.cancel_outlined),
                size: 13,
                color: statusColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
