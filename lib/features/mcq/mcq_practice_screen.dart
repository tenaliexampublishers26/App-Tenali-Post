import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/chapter.dart';
import '../../models/question.dart';
import '../../providers/mcq_provider.dart';

class McqPracticeScreen extends StatelessWidget {
  final Chapter chapter;

  const McqPracticeScreen({super.key, required this.chapter});

  @override
  Widget build(BuildContext context) {
    final mcqProvider = Provider.of<McqProvider>(context);
    final question = mcqProvider.currentQuestion;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text(chapter.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Restart Practice',
            onPressed: () {
              mcqProvider.resetPractice();
            },
          ),
        ],
      ),
      body: mcqProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : question == null
              ? const Center(
                  child: Text(
                    'No practice questions available in this language.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                )
              : Column(
                  children: [
                    // Top Progress & Score Tracker
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: AppTheme.surfaceWhite,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Question ${mcqProvider.currentIndex + 1} of ${mcqProvider.questions.length}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppTheme.primaryNavy,
                                ),
                              ),
                              Row(
                                children: [
                                  // Correct Pill
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.successGreenBg,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${mcqProvider.correctAnswersCount}',
                                          style: const TextStyle(
                                            color: AppTheme.successGreen,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Wrong Pill
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.errorRedBg,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.cancel_rounded, color: AppTheme.errorRed, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${mcqProvider.wrongAnswersCount}',
                                          style: const TextStyle(
                                            color: AppTheme.errorRed,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: (mcqProvider.currentIndex + 1) / mcqProvider.questions.length,
                            backgroundColor: AppTheme.borderSubtle,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.secondaryMaroon),
                            minHeight: 4,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ],
                      ),
                    ),

                    // Scrollable Question Content & Options
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Question Card
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(18.0),
                                child: Text(
                                  question.questionText,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Option A
                            _buildOptionCard(context, mcqProvider, question, 'A', question.optionA),
                            const SizedBox(height: 10),

                            // Option B
                            _buildOptionCard(context, mcqProvider, question, 'B', question.optionB),
                            const SizedBox(height: 10),

                            // Option C
                            _buildOptionCard(context, mcqProvider, question, 'C', question.optionC),
                            const SizedBox(height: 10),

                            // Option D
                            _buildOptionCard(context, mcqProvider, question, 'D', question.optionD),

                            // Instant Feedback & Explanation Card
                            if (mcqProvider.isCurrentLocked && question.explanation != null) ...[
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceWhite,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: (mcqProvider.selectedOptionForCurrent?.toUpperCase() ==
                                            question.correctOption?.toUpperCase())
                                        ? AppTheme.successGreen
                                        : AppTheme.secondaryMaroon,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          (mcqProvider.selectedOptionForCurrent?.toUpperCase() ==
                                                  question.correctOption?.toUpperCase())
                                              ? Icons.check_circle_outline_rounded
                                              : Icons.info_outline_rounded,
                                          color: (mcqProvider.selectedOptionForCurrent?.toUpperCase() ==
                                                  question.correctOption?.toUpperCase())
                                              ? AppTheme.successGreen
                                              : AppTheme.secondaryMaroon,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          (mcqProvider.selectedOptionForCurrent?.toUpperCase() ==
                                                  question.correctOption?.toUpperCase())
                                              ? 'Correct Answer! (+1 Mark)'
                                              : 'Incorrect! Correct Answer: Option ${question.correctOption}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: (mcqProvider.selectedOptionForCurrent?.toUpperCase() ==
                                                    question.correctOption?.toUpperCase())
                                                ? AppTheme.successGreen
                                                : AppTheme.secondaryMaroon,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      question.explanation!,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: AppTheme.textPrimary,
                                        height: 1.45,
                                      ),
                                    ),
                                    if (question.postalRuleRef != null) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppTheme.bgLight,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Postal Reference: ${question.postalRuleRef}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.primaryNavy,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Bottom Bar with Navigation Controls
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: AppTheme.surfaceWhite,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.arrow_back_ios_rounded, size: 14),
                            label: const Text('Previous'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryNavy,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            onPressed: mcqProvider.currentIndex > 0
                                ? () => mcqProvider.previousQuestion()
                                : null,
                          ),
                          ElevatedButton.icon(
                            label: const Text('Next'),
                            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondaryMaroon,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            ),
                            onPressed: mcqProvider.currentIndex < mcqProvider.questions.length - 1
                                ? () => mcqProvider.nextQuestion()
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context,
    McqProvider provider,
    Question question,
    String optionKey,
    String optionText,
  ) {
    final bool isLocked = provider.isCurrentLocked;
    final String? chosenOption = provider.selectedOptionForCurrent;
    final String? correctOption = question.correctOption;

    Color cardBg = AppTheme.surfaceWhite;
    Color borderColor = AppTheme.borderSubtle;
    Color textColor = AppTheme.textPrimary;
    Widget? trailingIcon;

    if (isLocked) {
      final bool isThisChosen = chosenOption?.toUpperCase() == optionKey.toUpperCase();
      final bool isThisCorrect = correctOption?.toUpperCase() == optionKey.toUpperCase();

      if (isThisCorrect) {
        cardBg = AppTheme.successGreenBg;
        borderColor = AppTheme.successGreen;
        textColor = const Color(0xFF065F46);
        trailingIcon = const Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 20);
      } else if (isThisChosen) {
        cardBg = AppTheme.errorRedBg;
        borderColor = AppTheme.errorRed;
        textColor = const Color(0xFF991B1B);
        trailingIcon = const Icon(Icons.cancel_rounded, color: AppTheme.errorRed, size: 20);
      }
    }

    return Card(
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: isLocked && (chosenOption == optionKey || correctOption == optionKey) ? 1.5 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isLocked ? null : () => provider.chooseOption(optionKey),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLocked && correctOption == optionKey
                      ? AppTheme.successGreen
                      : isLocked && chosenOption == optionKey
                          ? AppTheme.errorRed
                          : AppTheme.primaryNavy.withValues(alpha: 0.08),
                ),
                child: Center(
                  child: Text(
                    optionKey,
                    style: TextStyle(
                      color: isLocked && (correctOption == optionKey || chosenOption == optionKey)
                          ? Colors.white
                          : AppTheme.primaryNavy,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  optionText,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor,
                    fontWeight: isLocked && (correctOption == optionKey || chosenOption == optionKey)
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
              if (trailingIcon != null) trailingIcon,
            ],
          ),
        ),
      ),
    );
  }
}
