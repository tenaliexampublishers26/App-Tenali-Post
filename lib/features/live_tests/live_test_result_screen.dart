import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/live_test.dart';
import '../../services/mock_data.dart';

class LiveTestResultScreen extends StatelessWidget {
  final LiveTestSubmission submission;

  const LiveTestResultScreen({super.key, required this.submission});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Examination Result'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Hero Score Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryNavy, AppTheme.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryNavy.withValues(alpha: 0.2),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.emoji_events_rounded, color: AppTheme.accentGold, size: 40),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    submission.studentName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Examination Recorded Successfully',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        submission.marksObtained.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        ' / ${submission.totalMarks.toInt()} Marks',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryMaroon,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Percentage: ${submission.percentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Performance Breakdown Row
            Row(
              children: [
                Expanded(
                  child: _statPill(
                    title: 'Correct',
                    value: '${submission.correctCount}',
                    color: AppTheme.successGreen,
                    bgColor: AppTheme.successGreenBg,
                    icon: Icons.check_circle_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statPill(
                    title: 'Wrong',
                    value: '${submission.wrongCount}',
                    color: AppTheme.errorRed,
                    bgColor: AppTheme.errorRedBg,
                    icon: Icons.cancel_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statPill(
                    title: 'Skipped',
                    value: '${submission.skippedCount}',
                    color: AppTheme.textMuted,
                    bgColor: AppTheme.surfaceWhite,
                    icon: Icons.remove_circle_outline_rounded,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Question Review Section Header
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Answer Key & Solutions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Review List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: MockData.sampleQuestions.length,
              itemBuilder: (context, idx) {
                final q = MockData.sampleQuestions[idx];
                final studentChoice = submission.answers[q.id]?.toUpperCase();
                final correctChoice = q.correctOption?.toUpperCase();
                final bool isAttempted = studentChoice != null && studentChoice.isNotEmpty;
                final bool isCorrect = isAttempted && studentChoice == correctChoice;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Q${idx + 1}',
                              style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primaryNavy),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isCorrect
                                    ? AppTheme.successGreenBg
                                    : (isAttempted ? AppTheme.errorRedBg : AppTheme.bgLight),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isCorrect
                                    ? 'CORRECT (+1)'
                                    : (isAttempted ? 'INCORRECT (0)' : 'SKIPPED (0)'),
                                style: TextStyle(
                                  color: isCorrect
                                      ? AppTheme.successGreen
                                      : (isAttempted ? AppTheme.errorRed : AppTheme.textMuted),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          q.questionText,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (isAttempted && !isCorrect)
                          Text(
                            'Your Choice: Option $studentChoice (Incorrect)',
                            style: const TextStyle(
                              color: AppTheme.errorRed,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        Text(
                          'Correct Answer: Option $correctChoice — ${q.getOptionText(correctChoice ?? '')}',
                          style: const TextStyle(
                            color: AppTheme.successGreen,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        if (q.explanation != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            q.explanation!,
                            style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNavy,
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text('Back to Home Dashboard'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statPill({
    required String title,
    required String value,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
