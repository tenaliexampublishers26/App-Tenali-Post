import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/live_test_provider.dart';
import '../../providers/auth_provider.dart';
import 'live_test_result_screen.dart';

class LiveTestRunnerScreen extends StatelessWidget {
  const LiveTestRunnerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final liveTestProvider = Provider.of<LiveTestProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final question = liveTestProvider.currentQuestion;

    if (liveTestProvider.isSubmitted && liveTestProvider.lastSubmission != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LiveTestResultScreen(submission: liveTestProvider.lastSubmission!),
          ),
        );
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showExitWarningDialog(context, liveTestProvider, authProvider);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.bgLight,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(liveTestProvider.currentTest?.title ?? 'Live Examination'),
          actions: [
            // Timer Badge
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: liveTestProvider.remainingSeconds < 300
                    ? AppTheme.errorRed
                    : AppTheme.secondaryMaroon,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    liveTestProvider.formattedTimeRemaining,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: question == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Palette & Question Index Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    color: AppTheme.surfaceWhite,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Question ${liveTestProvider.currentIndex + 1} of ${liveTestProvider.questions.length}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryNavy,
                          ),
                        ),
                        Text(
                          'Attempted: ${liveTestProvider.selectedAnswers.length}/${liveTestProvider.questions.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Question & Options
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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

                          _buildLiveOption(context, liveTestProvider, question.id, 'A', question.optionA),
                          const SizedBox(height: 10),
                          _buildLiveOption(context, liveTestProvider, question.id, 'B', question.optionB),
                          const SizedBox(height: 10),
                          _buildLiveOption(context, liveTestProvider, question.id, 'C', question.optionC),
                          const SizedBox(height: 10),
                          _buildLiveOption(context, liveTestProvider, question.id, 'D', question.optionD),

                          const SizedBox(height: 20),

                          if (liveTestProvider.selectedAnswers.containsKey(question.id))
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                icon: const Icon(Icons.clear_rounded, size: 16),
                                label: const Text('Clear Choice'),
                                style: TextButton.styleFrom(foregroundColor: AppTheme.textMuted),
                                onPressed: () {
                                  liveTestProvider.clearOption(question.id);
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action Navigation Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: AppTheme.surfaceWhite,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.arrow_back_ios_rounded, size: 14),
                          label: const Text('Prev'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryNavy,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          onPressed: liveTestProvider.currentIndex > 0
                              ? () => liveTestProvider.previousQuestion()
                              : null,
                        ),
                        OutlinedButton(
                          onPressed: () {
                            _showSubmitConfirmationDialog(context, liveTestProvider, authProvider);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.secondaryMaroon,
                            side: const BorderSide(color: AppTheme.secondaryMaroon, width: 1.5),
                          ),
                          child: const Text('SUBMIT TEST', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                        ElevatedButton.icon(
                          label: const Text('Next'),
                          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryNavy,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          onPressed: liveTestProvider.currentIndex < liveTestProvider.questions.length - 1
                              ? () => liveTestProvider.nextQuestion()
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLiveOption(
    BuildContext context,
    LiveTestProvider provider,
    String questionId,
    String optionKey,
    String optionText,
  ) {
    final bool isSelected = provider.selectedAnswers[questionId] == optionKey;

    return Card(
      color: isSelected ? AppTheme.primaryNavy.withValues(alpha: 0.08) : AppTheme.surfaceWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryNavy : AppTheme.borderSubtle,
          width: isSelected ? 2.0 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          provider.selectOption(questionId, optionKey);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppTheme.primaryNavy : AppTheme.bgLight,
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryNavy : AppTheme.borderSubtle,
                  ),
                ),
                child: Center(
                  child: Text(
                    optionKey,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
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
                    color: isSelected ? AppTheme.primaryNavy : AppTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle_rounded, color: AppTheme.primaryNavy, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubmitConfirmationDialog(
    BuildContext context,
    LiveTestProvider provider,
    AuthProvider auth,
  ) {
    final total = provider.questions.length;
    final attempted = provider.selectedAnswers.length;
    final unattempted = total - attempted;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Examination?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Questions: $total'),
            const SizedBox(height: 4),
            Text('Questions Attempted: $attempted', style: const TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Unattempted: $unattempted', style: const TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            const Text(
              'Once submitted, your answers cannot be altered. Official results will be evaluated immediately.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Answering'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondaryMaroon),
            onPressed: () async {
              Navigator.pop(ctx);
              final submission = await provider.submitTest(
                studentName: auth.user?.fullName ?? 'Candidate',
                phoneNumber: auth.user?.phoneNumber ?? '9876543210',
              );
              if (submission != null && context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => LiveTestResultScreen(submission: submission)),
                );
              }
            },
            child: const Text('Confirm & Submit'),
          ),
        ],
      ),
    );
  }

  void _showExitWarningDialog(
    BuildContext context,
    LiveTestProvider provider,
    AuthProvider auth,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit Examination?', style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.w800)),
        content: const Text(
          'Leaving the active test runner will forfeit remaining time. Do you want to submit your current answers before leaving?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Resume Test'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.submitTest(
                studentName: auth.user?.fullName ?? 'Candidate',
                phoneNumber: auth.user?.phoneNumber ?? '0000000000',
              );
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Submit & Exit'),
          ),
        ],
      ),
    );
  }
}
