import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/admin_service.dart';

class AdminMcqImportExportScreen extends StatefulWidget {
  const AdminMcqImportExportScreen({super.key});

  @override
  State<AdminMcqImportExportScreen> createState() => _AdminMcqImportExportScreenState();
}

class _AdminMcqImportExportScreenState extends State<AdminMcqImportExportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Importer state
  String _importFormat = 'CSV'; // 'CSV', 'JSON'
  final TextEditingController _importTextController = TextEditingController();
  ImportValidationResult? _validationResult;
  bool _isImporting = false;

  // Exporter state
  String _exportFormat = 'CSV'; // 'CSV', 'JSON'
  String? _exportExamId;
  String? _exportLanguage;
  String _exportedContent = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _importTextController.dispose();
    super.dispose();
  }

  void _loadSampleTemplate() {
    if (_importFormat == 'CSV') {
      _importTextController.text = '''exam_code,chapter_number,lang_code,question_text,option_a,option_b,option_c,option_d,correct_option,explanation,postal_rule_ref
MTS,1,en,What is the minimum working hours of a Night Post Office on Sundays?,5 Hours,6 Hours,7 Hours,8 Hours,B,PO Guide Part 1 Clause 3 prescribes Night Post Offices function up to 8:30 PM on weekdays and 10:00 to 17:00 on Sundays.,PO Guide Part 1 Clause 3
MTS,1,te,రాత్రి పోస్ట్ ఆఫీస్ ఆదివారాలలో పనిచేసే సమయం ఎంత?,5 గంటలు,6 గంటలు,7 గంటలు,8 గంటలు,B,పీఓ గైడ్ పార్ట్ 1 క్లాజ్ 3 ప్రకారం ఆదివారం 10:00 నుండి 17:00 వరకు పనిచేస్తుంది.,PO Guide Part 1 Clause 3
MTS,1,hi,रात्रि डाकघर रविवार को कितने घंटे कार्य करता है?,5 घंटे,6 घंटे,7 घंटे,8 घंटे,B,पीओ गाइड भाग 1 खंड 3 के अनुसार रविवार को कार्य समय 10:00 से 17:00 बजे तक है।,PO Guide Part 1 Clause 3
PMG,2,en,What is the maximum weight limit of a Book Packet containing periodicals?,2 kg,4 kg,5 kg,10 kg,C,The maximum permissible weight of a book packet containing printed books or periodicals is 5 kg.,PO Guide Part 1 Clause 124
PASA,1,en,Which postal manual volume deals with General Sorting Office rules and mail forwarding?,Postal Manual Volume IV,Postal Manual Volume V,Postal Manual Volume VI,Postal Manual Volume VII,B,Postal Manual Volume V regulates the Railway Mail Service and sorting office operations.,Postal Manual Volume V Rule 12''';
    } else {
      _importTextController.text = '''[
  {
    "exam_id": "mts",
    "chapter_id": "ch-po-guide-1",
    "language_code": "en",
    "question_text": "What is the fee for registration of a postal article?",
    "option_a": "Rs 15",
    "option_b": "Rs 17",
    "option_c": "Rs 20",
    "option_d": "Rs 25",
    "correct_option": "B",
    "explanation": "Standard inland registration fee is Rs 17 per article.",
    "postal_rule_ref": "PO Guide Part 1 Clause 36",
    "difficulty": "Easy"
  }
]''';
    }
    setState(() => _validationResult = null);
  }

  void _validateInput(AdminProvider admin) {
    final text = _importTextController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paste or type CSV/JSON content to validate.')),
      );
      return;
    }

    setState(() {
      if (_importFormat == 'CSV') {
        _validationResult = admin.validateCsv(text);
      } else {
        _validationResult = admin.validateJson(text);
      }
    });
  }

  Future<void> _commitImport(AdminProvider admin, String adminEmail) async {
    if (_validationResult == null || _validationResult!.validQuestions.isEmpty) return;

    setState(() => _isImporting = true);
    try {
      final count = await admin.batchImportQuestions(_validationResult!.validQuestions, adminEmail: adminEmail);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported $count questions into the question bank!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        setState(() {
          _importTextController.clear();
          _validationResult = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  void _generateExport(AdminProvider admin) {
    var list = admin.questions;
    if (_exportExamId != null && _exportExamId!.isNotEmpty) {
      list = list.where((q) => q.examId == _exportExamId).toList();
    }
    if (_exportLanguage != null && _exportLanguage!.isNotEmpty && _exportLanguage != 'all') {
      list = list.where((q) => q.languageCode == _exportLanguage).toList();
    }

    setState(() {
      if (_exportFormat == 'CSV') {
        _exportedContent = admin.exportQuestionsCsv();
      } else {
        _exportedContent = admin.exportQuestionsJson();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final adminEmail = auth.user?.email ?? 'admin@tenalipost.gov.in';

    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      appBar: AppBar(
        title: const Text('Question Importer & Exporter'),
        backgroundColor: AppTheme.surfaceWarmWhite,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.secondaryMaroon,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.secondaryMaroon,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.file_upload_outlined, size: 20), text: 'Bulk Import'),
            Tab(icon: Icon(Icons.file_download_outlined, size: 20), text: 'Export Questions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildImportTab(admin, adminEmail),
          _buildExportTab(admin),
        ],
      ),
    );
  }

  Widget _buildImportTab(AdminProvider admin, String adminEmail) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Format selection and Template Loader
          Row(
            children: [
              ChoiceChip(
                label: const Text('CSV Format', style: TextStyle(fontWeight: FontWeight.w800)),
                selected: _importFormat == 'CSV',
                selectedColor: AppTheme.primaryNavy,
                labelStyle: TextStyle(color: _importFormat == 'CSV' ? Colors.white : AppTheme.textPrimary),
                onSelected: (_) => setState(() {
                  _importFormat = 'CSV';
                  _validationResult = null;
                }),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('JSON Format', style: TextStyle(fontWeight: FontWeight.w800)),
                selected: _importFormat == 'JSON',
                selectedColor: AppTheme.primaryNavy,
                labelStyle: TextStyle(color: _importFormat == 'JSON' ? Colors.white : AppTheme.textPrimary),
                onSelected: (_) => setState(() {
                  _importFormat = 'JSON';
                  _validationResult = null;
                }),
              ),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                label: const Text('Load Demo Template', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                onPressed: _loadSampleTemplate,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Textarea for pasting or typing
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceWarmWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderWarmSubtle),
            ),
            child: TextField(
              controller: _importTextController,
              maxLines: 8,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: InputDecoration(
                hintText: _importFormat == 'CSV'
                    ? 'Paste CSV records with headers:\nexam_code,chapter_number,lang_code,question_text,option_a,option_b,option_c,option_d,correct_option,explanation,postal_rule_ref'
                    : 'Paste JSON array of questions:\n[{"question_text": "...", "option_a": "...", "correct_option": "A"}]',
                contentPadding: const EdgeInsets.all(14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Action Buttons: Validate & Clear
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryNavy,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.fact_check_outlined, size: 18),
                  label: const Text('Parse & Validate Records', style: TextStyle(fontWeight: FontWeight.w800)),
                  onPressed: () => _validateInput(admin),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  _importTextController.clear();
                  setState(() => _validationResult = null);
                },
                child: const Text('Clear'),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Validation Results Callout
          if (_validationResult != null) ...[
            _buildValidationSummaryCard(admin, adminEmail),
          ],
        ],
      ),
    );
  }

  Widget _buildValidationSummaryCard(AdminProvider admin, String adminEmail) {
    final res = _validationResult!;
    final bool hasValid = res.validCount > 0;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWarmWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: res.hasErrors ? AppTheme.warningAmber : AppTheme.successGreen, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryNavy.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                res.hasErrors ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                color: res.hasErrors ? AppTheme.warningAmber : AppTheme.successGreen,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text('Import Validation Report', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),

          // Stat Pills
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _statPill('Valid Records', '${res.validCount}', AppTheme.successGreen),
              _statPill('Errors Found', '${res.errors.length}', res.hasErrors ? AppTheme.errorRed : AppTheme.textSecondary),
              _statPill('Duplicates Skipped', '${res.duplicateCount}', AppTheme.textMuted),
            ],
          ),

          if (res.hasErrors) ...[
            const SizedBox(height: 16),
            const Text('Row-Level Errors (Must be resolved before import):', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.errorRed)),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(
                color: AppTheme.errorRedBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.3)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(10),
                itemCount: res.errors.length,
                separatorBuilder: (_, __) => const Divider(height: 12),
                itemBuilder: (ctx, idx) {
                  final err = res.errors[idx];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.errorRed,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Row ${err.rowIndex}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${err.field.toUpperCase()}: ${err.message}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],

          if (hasValid) ...[
            const SizedBox(height: 16),
            const Text('Valid Questions Preview (Ready to Commit):', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: AppTheme.bgWarm,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderWarmSubtle),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(10),
                itemCount: res.validQuestions.length,
                separatorBuilder: (_, __) => const Divider(height: 12),
                itemBuilder: (ctx, idx) {
                  final q = res.validQuestions[idx];
                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppTheme.primaryNavy,
                        child: Text('${idx + 1}', style: const TextStyle(fontSize: 10, color: Colors.white)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          q.questionText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.successGreenBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Ans: ${q.correctOption}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.successGreen),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Commit Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryMaroon,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isImporting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.cloud_upload_rounded),
                label: Text(
                  _isImporting ? 'Importing...' : 'Commit ${res.validCount} Valid Questions to Database',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                onPressed: _isImporting ? null : () => _commitImport(admin, adminEmail),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExportTab(AdminProvider admin) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Export Questions Bank', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          const Text(
            'Export your questions in standard UTF-8 CSV or JSON format for backups, offline editing, or publishing.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),

          // Format & Filter Options Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWarmWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderWarmSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Format Choice
                Row(
                  children: [
                    const Text('Export Format: ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ChoiceChip(
                      label: const Text('CSV'),
                      selected: _exportFormat == 'CSV',
                      onSelected: (_) => setState(() => _exportFormat = 'CSV'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('JSON'),
                      selected: _exportFormat == 'JSON',
                      onSelected: (_) => setState(() => _exportFormat = 'JSON'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Exam Filter Dropdown
                DropdownButtonFormField<String?>(
                  initialValue: _exportExamId,
                  decoration: const InputDecoration(labelText: 'Filter by Exam (Optional)'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Exams')),
                    ...admin.exams.map((e) => DropdownMenuItem(value: e.id, child: Text('${e.code} — ${e.title}'))),
                  ],
                  onChanged: (val) => setState(() => _exportExamId = val),
                ),
                const SizedBox(height: 12),

                // Language Filter Dropdown
                DropdownButtonFormField<String?>(
                  initialValue: _exportLanguage,
                  decoration: const InputDecoration(labelText: 'Filter by Language (Optional)'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Languages (EN, TE, HI)')),
                    DropdownMenuItem(value: 'en', child: Text('English Only')),
                    DropdownMenuItem(value: 'te', child: Text('Telugu (తెలుగు) Only')),
                    DropdownMenuItem(value: 'hi', child: Text('Hindi (हिन्दी) Only')),
                  ],
                  onChanged: (val) => setState(() => _exportLanguage = val),
                ),
                const SizedBox(height: 16),

                // Generate Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryNavy,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Generate Export Data', style: TextStyle(fontWeight: FontWeight.w800)),
                    onPressed: () => _generateExport(admin),
                  ),
                ),
              ],
            ),
          ),

          if (_exportedContent.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Exported Content Preview:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                TextButton.icon(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy to Clipboard', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _exportedContent));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Exported questions copied to clipboard!')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWarmWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderWarmSubtle),
              ),
              child: SelectableText(
                _exportedContent,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                maxLines: 15,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statPill(String title, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$title: ', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          Text(count, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}
