import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../models/live_test.dart';
import '../../../providers/admin_provider.dart';

class AdminLiveTestResultsScreen extends StatefulWidget {
  final LiveTest liveTest;

  const AdminLiveTestResultsScreen({super.key, required this.liveTest});

  @override
  State<AdminLiveTestResultsScreen> createState() => _AdminLiveTestResultsScreenState();
}

class _AdminLiveTestResultsScreenState extends State<AdminLiveTestResultsScreen> {
  List<LiveTestSubmission> _submissions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final subs = await admin.getTestSubmissions(widget.liveTest.id);
    setState(() {
      _submissions = subs;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final dateFormat = DateFormat('dd MMM, hh:mm a');

    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      appBar: AppBar(
        title: const Text('Live Test Results & Scorecard'),
        backgroundColor: AppTheme.surfaceWarmWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: AppTheme.primaryNavy),
            tooltip: 'Export CSV Scorecard',
            onPressed: () {
              final csv = admin.exportTestSubmissionsCsv(widget.liveTest.id);
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Export Test Submissions (CSV)'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: SingleChildScrollView(
                      child: SelectableText(csv, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                    ),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryNavy),
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('CSV results ready for export.')),
                        );
                      },
                      child: const Text('Download / Copy'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.secondaryMaroon))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Test Header Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceWarmWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderWarmSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.liveTest.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(widget.liveTest.description, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _statBox('Submissions', '${_submissions.length}', AppTheme.primaryNavy),
                            const SizedBox(width: 8),
                            _statBox('Total Marks', '${widget.liveTest.totalMarks.toInt()}', AppTheme.goldBell),
                            const SizedBox(width: 8),
                            _statBox('Pass Marks', '${widget.liveTest.passMarks.toInt()}', AppTheme.successGreen),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Candidate Submissions & All India Rankings',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 10),

                  if (_submissions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppTheme.surfaceWarmWhite, borderRadius: BorderRadius.circular(14)),
                      child: const Column(
                        children: [
                          Icon(Icons.inbox_rounded, size: 44, color: AppTheme.textMuted),
                          SizedBox(height: 8),
                          Text('No candidate submissions recorded yet.', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                        ],
                      ),
                    )
                  else
                    ..._submissions.map((sub) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceWarmWhite,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.borderWarmSubtle),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: (sub.rank ?? 1) == 1
                                ? AppTheme.goldBorder
                                : (sub.rank ?? 1) <= 3
                                    ? AppTheme.secondaryMaroon
                                    : AppTheme.primaryNavy,
                            child: Text(
                              '#${sub.rank ?? 1}',
                              style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 12),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(sub.studentName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                              ),
                              Text(
                                '${sub.marksObtained} / ${sub.totalMarks}',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppTheme.primaryNavy),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text('Ph: ${sub.phoneNumber} • Submitted: ${dateFormat.format(sub.submittedAt)}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _miniBadge('${sub.correctCount} Correct', AppTheme.successGreen),
                                  const SizedBox(width: 4),
                                  _miniBadge('${sub.wrongCount} Wrong', AppTheme.errorRed),
                                  const SizedBox(width: 4),
                                  _miniBadge('${sub.skippedCount} Skipped', AppTheme.textMuted),
                                  const Spacer(),
                                  Text(
                                    '${sub.percentage.toStringAsFixed(1)}%',
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: sub.percentage >= 40 ? AppTheme.successGreen : AppTheme.errorRed),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _miniBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
