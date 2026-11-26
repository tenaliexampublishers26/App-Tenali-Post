import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/utils/mcq_import_parser.dart';
import '../../../core/widgets/admin_ui.dart';
import 'mcq_question_form_sheet.dart';

typedef CommitBulkImportCallback = Future<void> Function({
  required ImportParseResult parsed,
  required String fileName,
  required String fileType,
  required bool publishImmediately,
  required bool replaceExisting,
});

/// Reusable mobile Bulk MCQ Importer bottom sheet with Add/Edit/Delete row controls.
Future<void> showBulkMcqImporterSheet(
  BuildContext context, {
  String preferredLang = 'en',
  bool showPublishToggle = true,
  String replaceLabel = 'Replace existing (creates new version)',
  required CommitBulkImportCallback onCommit,
}) {
  final jsonCtrl = TextEditingController();
  ImportParseResult? previewResult;
  var draftRows = <Map<String, dynamic>>[];
  String fileName = 'pasted.json';
  String fileType = 'json';
  bool publishImmediately = true;
  bool replaceExisting = false;
  bool committing = false;

  void applyResult(ImportParseResult res, void Function(void Function()) setModalState) {
    setModalState(() {
      previewResult = res;
      draftRows = res.rawRows.map((e) => Map<String, dynamic>.from(e)).toList();
    });
  }

  void revalidateDrafts(void Function(void Function()) setModalState) {
    final res = McqImportParser.validateAndNormalize(
      draftRows,
      preferredLang: preferredLang,
    );
    applyResult(res, setModalState);
  }

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) {
        final errorsByRow = <int, List<ImportRowError>>{};
        for (final err in previewResult?.errors ?? const <ImportRowError>[]) {
          errorsByRow.putIfAbsent(err.rowNumber, () => []).add(err);
        }

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.88,
          maxChildSize: 0.95,
          builder: (_, scrollCtrl) => ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Bulk MCQ Importer (.csv, .xlsx, .json)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                    label: const Text('Add MCQ'),
                    onPressed: () async {
                      final added = await showMcqQuestionFormSheet(
                        ctx,
                        title: 'Add Question to Batch',
                        initialKey: 'Q${draftRows.length + 1}',
                        submitLabel: 'Add to Import Batch',
                      );
                      if (added == null) return;
                      draftRows.add(added.toRowMap());
                      if (draftRows.length == 1 && previewResult == null) {
                        fileName = 'manual_batch.json';
                        fileType = 'json';
                      }
                      revalidateDrafts(setModalState);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.attach_file_rounded),
                      label: const Text('Pick File'),
                      onPressed: () async {
                        final res = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['csv', 'json', 'xlsx', 'xls'],
                          withData: true,
                        );
                        if (res == null || res.files.isEmpty) return;
                        final file = res.files.first;
                        final bytes = file.bytes;
                        if (bytes == null) return;
                        final ext = (file.extension ?? 'csv').toLowerCase();
                        late final ImportParseResult parsed;
                        if (ext == 'xlsx' || ext == 'xls') {
                          parsed = McqImportParser.parseAndValidateExcel(
                            bytes,
                            preferredLang: preferredLang,
                          );
                        } else if (ext == 'json') {
                          parsed = McqImportParser.parseAndValidateJson(
                            utf8.decode(bytes, allowMalformed: true),
                            preferredLang: preferredLang,
                          );
                        } else {
                          parsed = McqImportParser.parseAndValidateCsv(
                            utf8.decode(bytes, allowMalformed: true),
                            preferredLang: preferredLang,
                          );
                        }
                        fileName = file.name;
                        fileType = ext == 'xls' ? 'xlsx' : ext;
                        applyResult(parsed, setModalState);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      jsonCtrl.text = McqImportParser.sampleJsonTemplate;
                      fileName = 'sample_template.json';
                      fileType = 'json';
                      applyResult(
                        McqImportParser.parseAndValidateJson(
                          jsonCtrl.text,
                          preferredLang: preferredLang,
                        ),
                        setModalState,
                      );
                    },
                    child: const Text('Load Sample'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: jsonCtrl,
                maxLines: 5,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                decoration: const InputDecoration(
                  labelText: 'Or Paste JSON Array',
                  hintText: '[{"question_text": "...", "option_a": "...", ...}]',
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  fileName = 'pasted.json';
                  fileType = 'json';
                  applyResult(
                    McqImportParser.parseAndValidateJson(
                      jsonCtrl.text,
                      preferredLang: preferredLang,
                    ),
                    setModalState,
                  );
                },
                child: const Text('Validate & Preview'),
              ),
              if (previewResult != null) ...[
                const SizedBox(height: 12),
                AdminCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'File: $fileName • Valid: ${previewResult!.validCount} • Errors: ${previewResult!.invalidCount} • Duplicates: ${previewResult!.duplicateCount}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: previewResult!.isValid
                              ? AppTheme.successGreen
                              : AppTheme.errorRed,
                        ),
                      ),
                      if (previewResult!.errors.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        for (final err in previewResult!.errors.take(6))
                          Text(
                            '• $err',
                            style: const TextStyle(fontSize: 11, color: AppTheme.errorRed),
                          ),
                        if (previewResult!.errors.length > 6)
                          Text(
                            '...and ${previewResult!.errors.length - 6} more. Tap Edit on any row below to fix.',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                if (draftRows.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        'Batch Questions (${draftRows.length}) — Tap Edit to modify',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  for (var i = 0; i < draftRows.length; i++) ...[
                    Builder(
                      builder: (_) {
                        final rowNum = i + 1;
                        final row = draftRows[i];
                        final rowErrors = errorsByRow[rowNum] ?? const <ImportRowError>[];
                        final hasError = rowErrors.isNotEmpty;
                        final qText = (row['question_text'] ?? '').toString();
                        final optA = (row['option_a'] ?? '').toString();
                        final optB = (row['option_b'] ?? '').toString();
                        final optC = (row['option_c'] ?? '').toString();
                        final optD = (row['option_d'] ?? '').toString();
                        final ans = (row['correct_option'] ?? '').toString();
                        final key = (row['question_key'] ?? 'Q$rowNum').toString();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: AdminCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    StatusBadge(
                                      text: hasError ? '$key • ERROR' : '$key • OK',
                                      color: hasError
                                          ? AppTheme.errorRed
                                          : AppTheme.successGreen,
                                    ),
                                    const SizedBox(width: 6),
                                    if (ans.isNotEmpty)
                                      StatusBadge(
                                        text: 'Ans: $ans',
                                        color: AppTheme.primaryNavy,
                                      ),
                                    const Spacer(),
                                    IconButton(
                                      tooltip: 'Edit Row',
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(Icons.edit_outlined, size: 18),
                                      onPressed: () async {
                                        final edited = await showMcqQuestionFormSheet(
                                          ctx,
                                          title: 'Edit Row $rowNum ($key)',
                                          initialKey: key,
                                          initialQuestion: qText,
                                          initialOptionA: optA,
                                          initialOptionB: optB,
                                          initialOptionC: optC,
                                          initialOptionD: optD,
                                          initialCorrectOption: ans.isEmpty ? 'A' : ans,
                                          initialExplanation:
                                              (row['explanation'] ?? '').toString(),
                                          submitLabel: 'Update Row',
                                        );
                                        if (edited == null) return;
                                        draftRows[i] = edited.toRowMap();
                                        revalidateDrafts(setModalState);
                                      },
                                    ),
                                    IconButton(
                                      tooltip: 'Delete Row',
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18,
                                        color: AppTheme.errorRed,
                                      ),
                                      onPressed: () {
                                        draftRows.removeAt(i);
                                        revalidateDrafts(setModalState);
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  qText.isEmpty ? '(Missing question text)' : qText,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: qText.isEmpty
                                        ? AppTheme.errorRed
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'A: ${optA.isEmpty ? '-' : optA} | B: ${optB.isEmpty ? '-' : optB} | C: ${optC.isEmpty ? '-' : optC} | D: ${optD.isEmpty ? '-' : optD}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                if (hasError) ...[
                                  const SizedBox(height: 4),
                                  for (final re in rowErrors)
                                    Text(
                                      '• ${re.message}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.errorRed,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ],
              if (showPublishToggle)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Publish immediately',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  value: publishImmediately,
                  onChanged: (v) => setModalState(() => publishImmediately = v),
                ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  replaceLabel,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                value: replaceExisting,
                onChanged: (v) => setModalState(() => replaceExisting = v),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: ((previewResult?.isValid ?? false) && !committing)
                    ? () async {
                        setModalState(() => committing = true);
                        try {
                          await onCommit(
                            parsed: previewResult!,
                            fileName: fileName,
                            fileType: fileType,
                            publishImmediately: publishImmediately,
                            replaceExisting: replaceExisting,
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                        } finally {
                          if (ctx.mounted) setModalState(() => committing = false);
                        }
                      }
                    : null,
                child: committing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Confirm & Import Questions'),
              ),
            ],
          ),
        );
      },
    ),
  );
}
