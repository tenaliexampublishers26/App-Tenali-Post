import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/live_test_provider.dart';
import '../../providers/auth_provider.dart';
import 'live_test_runner_screen.dart';

class LiveTestsScreen extends StatelessWidget {
  const LiveTestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final liveTestProvider = Provider.of<LiveTestProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Live Mock Examinations'),
      ),
      body: liveTestProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : liveTestProvider.liveTests.isEmpty
              ? const Center(
                  child: Text(
                    'No live tests currently scheduled. Check back soon!',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: liveTestProvider.liveTests.length,
                  itemBuilder: (context, index) {
                    final test = liveTestProvider.liveTests[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: test.isOngoing ? AppTheme.secondaryMaroon : AppTheme.primaryNavy,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      if (test.isOngoing) ...[
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                      Text(
                                        test.isOngoing ? 'LIVE NOW' : 'UPCOMING',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${test.durationMinutes} Mins',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              test.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              test.description,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                            ),
                            const SizedBox(height: 14),
                            const Divider(color: AppTheme.borderSubtle, height: 1),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Questions: ${test.totalQuestions}',
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Total Marks: ${test.totalMarks.toInt()}',
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: test.isOngoing ? AppTheme.secondaryMaroon : AppTheme.primaryNavy,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  ),
                                  onPressed: () {
                                    _showTestInstructionsDialog(context, test, liveTestProvider, authProvider);
                                  },
                                  child: Text(
                                    test.isOngoing ? 'START TEST' : 'VIEW RULES',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _showTestInstructionsDialog(
    BuildContext context,
    dynamic test,
    LiveTestProvider provider,
    AuthProvider auth,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(test.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Examination Instructions:',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            SizedBox(height: 8),
            Text('• Duration: 60 minutes with auto-submission timer.'),
            Text('• Correct Answer: +1.0 Mark.'),
            Text('• Negative Marking: None (MTS/Postman rules).'),
            Text('• Answer keys are locked until final test submission.'),
            Text('• Do not minimize or close the app during testing.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondaryMaroon),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await provider.startLiveTest(test);
              if (success && context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LiveTestRunnerScreen()),
                );
              }
            },
            child: const Text('I Agree & Start Test'),
          ),
        ],
      ),
    );
  }
}
