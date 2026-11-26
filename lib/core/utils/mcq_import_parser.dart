import 'dart:convert';
import 'dart:typed_data';
import 'package:excel/excel.dart';

class ParsedMcqRow {
  final String questionKey;
  final String questionText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctOption; // 'A' | 'B' | 'C' | 'D'
  final String explanation;
  final int displayOrder;

  const ParsedMcqRow({
    required this.questionKey,
    required this.questionText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctOption,
    this.explanation = '',
    required this.displayOrder,
  });
}

class ImportRowError {
  final int rowNumber;
  final String field;
  final String message;

  const ImportRowError({
    required this.rowNumber,
    required this.field,
    required this.message,
  });

  @override
  String toString() => 'Row $rowNumber ($field): $message';
}

class ImportParseResult {
  final List<ParsedMcqRow> validQuestions;
  final List<ImportRowError> errors;
  final int totalRows;
  final int duplicateCount;
  final List<Map<String, dynamic>> rawRows;

  const ImportParseResult({
    required this.validQuestions,
    required this.errors,
    required this.totalRows,
    required this.duplicateCount,
    this.rawRows = const [],
  });

  int get validCount => validQuestions.length;
  int get invalidCount => errors.length;
  bool get isValid => errors.isEmpty && validQuestions.isNotEmpty;
}

/// Pure Dart port of src/lib/mcq-importer.ts (RFC 4180 CSV, JSON, Excel + strict validation),
/// extended to support nested/bilingual (`_en`, `_te`, `_hi`) JSON payloads and array/map options.
class McqImportParser {
  static const String sampleCsvTemplate =
      'question_key,question_text,option_a,option_b,option_c,option_d,correct_option,explanation\n'
      'Q1,"Which article of the Indian Constitution deals with the Right to Equality?",Article 12,Article 14,Article 19,Article 21,B,"Article 14 guarantees equality before law and equal protection of the laws."\n'
      'Q2,"What is the maximum weight limit for an Inland Letter Card in India Post?",3 grams,5 grams,10 grams,15 grams,B,"An Inland Letter Card has a maximum permissible weight limit of 5 grams."\n';

  static const String sampleJsonTemplate = '''[
  {
    "question_key": "Q1",
    "question_text": "Which article of the Indian Constitution deals with the Right to Equality?",
    "option_a": "Article 12",
    "option_b": "Article 14",
    "option_c": "Article 19",
    "option_d": "Article 21",
    "correct_option": "B",
    "explanation": "Article 14 guarantees equality before law and equal protection of the laws."
  }
]''';

  static const List<String> _questionAliases = [
    'question_text',
    'question',
    'q',
    'prompt',
    'text',
    'stem',
    'question_body',
    'ques',
    'title',
  ];
  static const List<String> _optAAliases = ['option_a', 'a', 'option1', 'opt_a', 'opt1'];
  static const List<String> _optBAliases = ['option_b', 'b', 'option2', 'opt_b', 'opt2'];
  static const List<String> _optCAliases = ['option_c', 'c', 'option3', 'opt_c', 'opt3'];
  static const List<String> _optDAliases = ['option_d', 'd', 'option4', 'opt_d', 'opt4'];
  static const List<String> _correctAliases = [
    'correct_option',
    'correct',
    'answer',
    'ans',
    'right_option',
    'correct_answer',
    'answer_key',
    'ans_key',
  ];
  static const List<String> _explanationAliases = [
    'explanation',
    'solution',
    'hint',
    'reason',
    'rationale',
    'note',
  ];
  static const List<String> _keyAliases = [
    'question_key',
    'key',
    'id',
    'qno',
    'q_no',
    'sr_no',
    'sno',
  ];

  /// RFC 4180 quote-aware CSV parser supporting multiline values and "" escaping.
  static List<List<String>> parseCsvMatrix(String rawText) {
    final text = rawText.replaceFirst(RegExp(r'^\uFEFF'), '');
    final rows = <List<String>>[];
    var currentRow = <String>[];
    final currentField = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < text.length; i++) {
      final ch = text[i];
      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < text.length && text[i + 1] == '"') {
            currentField.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          currentField.write(ch);
        }
      } else {
        if (ch == '"') {
          inQuotes = true;
        } else if (ch == ',') {
          currentRow.add(currentField.toString().trim());
          currentField.clear();
        } else if (ch == '\r' || ch == '\n') {
          if (ch == '\r' && i + 1 < text.length && text[i + 1] == '\n') {
            i++;
          }
          currentRow.add(currentField.toString().trim());
          currentField.clear();
          if (currentRow.any((cell) => cell.isNotEmpty)) {
            rows.add(currentRow);
          }
          currentRow = <String>[];
        } else {
          currentField.write(ch);
        }
      }
    }

    currentRow.add(currentField.toString().trim());
    if (currentRow.any((cell) => cell.isNotEmpty)) {
      rows.add(currentRow);
    }
    return rows;
  }

  static ImportParseResult parseAndValidateCsv(
    String csvText, {
    String preferredLang = 'en',
  }) {
    final matrix = parseCsvMatrix(csvText);
    if (matrix.length < 2) {
      return const ImportParseResult(
        validQuestions: [],
        errors: [
          ImportRowError(
            rowNumber: 1,
            field: 'file',
            message: 'CSV must include a header row and at least one question row.',
          ),
        ],
        totalRows: 0,
        duplicateCount: 0,
      );
    }

    final headers = matrix.first.map((h) => h.trim().toLowerCase()).toList();
    final records = <Map<String, dynamic>>[];
    for (var r = 1; r < matrix.length; r++) {
      final cells = matrix[r];
      final map = <String, dynamic>{};
      for (var c = 0; c < headers.length; c++) {
        if (headers[c].isEmpty) continue;
        map[headers[c]] = c < cells.length ? cells[c] : '';
      }
      records.add(map);
    }
    return validateAndNormalize(records, preferredLang: preferredLang);
  }

  static ImportParseResult parseAndValidateJson(
    String jsonText, {
    String preferredLang = 'en',
  }) {
    try {
      final decoded = jsonDecode(jsonText.replaceFirst(RegExp(r'^\uFEFF'), ''));
      List<dynamic>? list;
      if (decoded is List) {
        list = decoded;
      } else if (decoded is Map) {
        for (final key in ['questions', 'items', 'mcqs', 'data', 'records']) {
          if (decoded[key] is List) {
            list = decoded[key] as List;
            break;
          }
        }
      }

      if (list == null) {
        return const ImportParseResult(
          validQuestions: [],
          errors: [
            ImportRowError(
              rowNumber: 1,
              field: 'json',
              message:
                  'JSON root must be an array of question objects or contain a "questions" array.',
            ),
          ],
          totalRows: 0,
          duplicateCount: 0,
        );
      }

      final records = list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      return validateAndNormalize(records, preferredLang: preferredLang);
    } catch (e) {
      return ImportParseResult(
        validQuestions: const [],
        errors: [
          ImportRowError(
            rowNumber: 1,
            field: 'json',
            message: 'Invalid JSON syntax: $e',
          ),
        ],
        totalRows: 0,
        duplicateCount: 0,
      );
    }
  }

  static ImportParseResult parseAndValidateExcel(
    Uint8List bytes, {
    String preferredLang = 'en',
  }) {
    try {
      final excel = Excel.decodeBytes(bytes);
      if (excel.tables.isEmpty) {
        return const ImportParseResult(
          validQuestions: [],
          errors: [
            ImportRowError(
              rowNumber: 1,
              field: 'excel',
              message: 'Excel workbook contains no sheets.',
            ),
          ],
          totalRows: 0,
          duplicateCount: 0,
        );
      }

      final sheet = excel.tables.values.first;
      if (sheet.rows.length < 2) {
        return const ImportParseResult(
          validQuestions: [],
          errors: [
            ImportRowError(
              rowNumber: 1,
              field: 'excel',
              message: 'Excel sheet must contain headers and at least one row.',
            ),
          ],
          totalRows: 0,
          duplicateCount: 0,
        );
      }

      final headers = sheet.rows.first
          .map((cell) => (cell?.value?.toString() ?? '').trim().toLowerCase())
          .toList();

      final records = <Map<String, dynamic>>[];
      for (var r = 1; r < sheet.rows.length; r++) {
        final rowCells = sheet.rows[r];
        final values = rowCells
            .map((cell) => (cell?.value?.toString() ?? '').trim())
            .toList();
        if (values.every((v) => v.isEmpty)) continue;

        final map = <String, dynamic>{};
        for (var c = 0; c < headers.length; c++) {
          if (headers[c].isEmpty) continue;
          map[headers[c]] = c < values.length ? values[c] : '';
        }
        records.add(map);
      }

      return validateAndNormalize(records, preferredLang: preferredLang);
    } catch (e) {
      return ImportParseResult(
        validQuestions: const [],
        errors: [
          ImportRowError(
            rowNumber: 1,
            field: 'excel',
            message: 'Could not read Excel file: $e',
          ),
        ],
        totalRows: 0,
        duplicateCount: 0,
      );
    }
  }

  static String? normalizeCorrectOption(String raw) {
    final clean = raw.trim().toUpperCase().replaceAll(RegExp(r'[\s_]+'), ' ');
    switch (clean) {
      case 'A':
      case '1':
      case 'OPTION A':
      case 'OPT A':
        return 'A';
      case 'B':
      case '2':
      case 'OPTION B':
      case 'OPT B':
        return 'B';
      case 'C':
      case '3':
      case 'OPTION C':
      case 'OPT C':
        return 'C';
      case 'D':
      case '4':
      case 'OPTION D':
      case 'OPT D':
        return 'D';
      default:
        return null;
    }
  }

  static String _normalizeLang(String lang) {
    final lower = lang.trim().toLowerCase();
    if (lower.startsWith('te')) return 'te';
    if (lower.startsWith('hi')) return 'hi';
    if (lower.startsWith('ta')) return 'ta';
    return lower.isEmpty ? 'en' : lower;
  }

  static List<String> _langPriority(String preferredLang) {
    final primary = _normalizeLang(preferredLang);
    final langs = <String>[primary];
    for (final fallback in ['en', 'english', 'te', 'telugu', 'hi', 'hindi', 'ta', 'tamil']) {
      if (!langs.contains(fallback)) langs.add(fallback);
    }
    return langs;
  }

  static String _unwrapLocalizedValue(dynamic raw, List<String> langs) {
    if (raw == null) return '';
    if (raw is String) return raw.trim();
    if (raw is num || raw is bool) return raw.toString().trim();
    if (raw is Map) {
      final lower = <String, dynamic>{};
      raw.forEach((k, v) => lower[k.toString().trim().toLowerCase()] = v);
      for (final l in langs) {
        if (lower.containsKey(l)) {
          final v = _unwrapLocalizedValue(lower[l], langs);
          if (v.isNotEmpty) return v;
        }
      }
      for (final key in ['text', 'label', 'value', 'title', 'name', 'content']) {
        if (lower.containsKey(key)) {
          final v = _unwrapLocalizedValue(lower[key], langs);
          if (v.isNotEmpty) return v;
        }
      }
      for (final entry in lower.values) {
        final v = _unwrapLocalizedValue(entry, langs);
        if (v.isNotEmpty) return v;
      }
    }
    return '';
  }

  static Map<String, dynamic> _mergeLocalizedContainer(
    Map<String, dynamic> lowerRow,
    List<String> langs,
  ) {
    final merged = Map<String, dynamic>.from(lowerRow);
    void mergeFrom(dynamic container) {
      if (container is! Map) return;
      final sub = <String, dynamic>{};
      container.forEach((k, v) => sub[k.toString().trim().toLowerCase()] = v);
      for (final l in langs) {
        if (sub[l] is Map) {
          (sub[l] as Map).forEach((k, v) {
            merged.putIfAbsent(k.toString().trim().toLowerCase(), () => v);
          });
          break;
        }
      }
    }

    mergeFrom(lowerRow);
    mergeFrom(lowerRow['translations']);
    mergeFrom(lowerRow['languages']);
    mergeFrom(lowerRow['content']);
    mergeFrom(lowerRow['localized']);
    return merged;
  }

  static String _pickLocalizedField(
    Map<String, dynamic> row,
    List<String> aliases,
    List<String> langs,
  ) {
    for (final alias in aliases) {
      if (row.containsKey(alias)) {
        final v = _unwrapLocalizedValue(row[alias], langs);
        if (v.isNotEmpty) return v;
      }
    }
    for (final l in langs) {
      for (final alias in aliases) {
        for (final key in ['${alias}_$l', '${l}_$alias', '$alias.$l', '$alias-$l']) {
          if (row.containsKey(key)) {
            final v = _unwrapLocalizedValue(row[key], langs);
            if (v.isNotEmpty) return v;
          }
        }
      }
    }
    return '';
  }

  static List<String> _extractOptionsFromCollection(dynamic raw, List<String> langs) {
    if (raw == null) return const ['', '', '', ''];
    if (raw is List) {
      final out = List<String>.filled(4, '');
      for (var i = 0; i < raw.length && i < 4; i++) {
        out[i] = _unwrapLocalizedValue(raw[i], langs);
      }
      return out;
    }
    if (raw is Map) {
      final lower = <String, dynamic>{};
      raw.forEach((k, v) => lower[k.toString().trim().toLowerCase()] = v);
      final directA = _pickLocalizedField(lower, _optAAliases, langs);
      final directB = _pickLocalizedField(lower, _optBAliases, langs);
      final directC = _pickLocalizedField(lower, _optCAliases, langs);
      final directD = _pickLocalizedField(lower, _optDAliases, langs);
      if (directA.isNotEmpty || directB.isNotEmpty || directC.isNotEmpty || directD.isNotEmpty) {
        return [directA, directB, directC, directD];
      }
      final num1 = _unwrapLocalizedValue(lower['1'] ?? lower['0'], langs);
      final num2 = _unwrapLocalizedValue(lower['2'] ?? lower['1'], langs);
      final num3 = _unwrapLocalizedValue(lower['3'] ?? lower['2'], langs);
      final num4 = _unwrapLocalizedValue(lower['4'] ?? lower['3'], langs);
      if (lower.containsKey('1') || lower.containsKey('2') || lower.containsKey('3') || lower.containsKey('4')) {
        return [num1, num2, num3, num4];
      }
      for (final l in langs) {
        if (lower.containsKey(l)) {
          final nested = _extractOptionsFromCollection(lower[l], langs);
          if (nested.any((s) => s.isNotEmpty)) return nested;
        }
      }
    }
    return const ['', '', '', ''];
  }

  static ImportParseResult validateAndNormalize(
    List<Map<String, dynamic>> rawRows, {
    String preferredLang = 'en',
  }) {
    if (rawRows.isEmpty) {
      return const ImportParseResult(
        validQuestions: [],
        errors: [
          ImportRowError(
            rowNumber: 1,
            field: 'dataset',
            message: 'No question rows found.',
          ),
        ],
        totalRows: 0,
        duplicateCount: 0,
      );
    }

    final langs = _langPriority(preferredLang);
    final valid = <ParsedMcqRow>[];
    final errors = <ImportRowError>[];
    final normalizedRawRows = <Map<String, dynamic>>[];
    final seenQuestions = <String, int>{};
    var duplicateCount = 0;

    for (var i = 0; i < rawRows.length; i++) {
      final rowNum = i + 1;
      final lowerOriginal = <String, dynamic>{};
      rawRows[i].forEach((k, v) {
        lowerOriginal[k.trim().toLowerCase()] = v;
      });
      final lowerRow = _mergeLocalizedContainer(lowerOriginal, langs);

      final qText = _pickLocalizedField(lowerRow, _questionAliases, langs);
      var optA = _pickLocalizedField(lowerRow, _optAAliases, langs);
      var optB = _pickLocalizedField(lowerRow, _optBAliases, langs);
      var optC = _pickLocalizedField(lowerRow, _optCAliases, langs);
      var optD = _pickLocalizedField(lowerRow, _optDAliases, langs);

      if (optA.isEmpty || optB.isEmpty || optC.isEmpty || optD.isEmpty) {
        final optionContainerAliases = <String>[
          for (final l in langs) ...['options_$l', 'choices_$l', 'opts_$l'],
          'options',
          'choices',
          'answers',
          'opts',
        ];
        for (final key in optionContainerAliases) {
          if (!lowerRow.containsKey(key)) continue;
          final extracted = _extractOptionsFromCollection(lowerRow[key], langs);
          if (extracted.any((s) => s.isNotEmpty)) {
            if (optA.isEmpty) optA = extracted[0];
            if (optB.isEmpty) optB = extracted[1];
            if (optC.isEmpty) optC = extracted[2];
            if (optD.isEmpty) optD = extracted[3];
            if (optA.isNotEmpty && optB.isNotEmpty && optC.isNotEmpty && optD.isNotEmpty) {
              break;
            }
          }
        }
      }

      final rawCorrect = _pickLocalizedField(lowerRow, _correctAliases, langs);
      final explanation = _pickLocalizedField(lowerRow, _explanationAliases, langs);
      final rawKey = _pickLocalizedField(lowerRow, _keyAliases, langs);
      final qKey = rawKey.isNotEmpty ? rawKey : 'Q$rowNum';

      String? normalizedAnswer = normalizeCorrectOption(rawCorrect);
      if (normalizedAnswer == null && rawCorrect.isNotEmpty) {
        final normAns = rawCorrect.trim().toLowerCase();
        if (normAns == optA.trim().toLowerCase() && optA.isNotEmpty) {
          normalizedAnswer = 'A';
        } else if (normAns == optB.trim().toLowerCase() && optB.isNotEmpty) {
          normalizedAnswer = 'B';
        } else if (normAns == optC.trim().toLowerCase() && optC.isNotEmpty) {
          normalizedAnswer = 'C';
        } else if (normAns == optD.trim().toLowerCase() && optD.isNotEmpty) {
          normalizedAnswer = 'D';
        }
      }

      normalizedRawRows.add({
        'question_key': qKey,
        'question_text': qText,
        'option_a': optA,
        'option_b': optB,
        'option_c': optC,
        'option_d': optD,
        'correct_option': normalizedAnswer ?? rawCorrect,
        'explanation': explanation,
      });

      var rowHasError = false;
      if (qText.isEmpty) {
        errors.add(ImportRowError(
          rowNumber: rowNum,
          field: 'question_text',
          message: 'Question text is missing.',
        ));
        rowHasError = true;
      }
      if (optA.isEmpty || optB.isEmpty || optC.isEmpty || optD.isEmpty) {
        errors.add(ImportRowError(
          rowNumber: rowNum,
          field: 'options',
          message: 'All 4 options (A, B, C, D) are required.',
        ));
        rowHasError = true;
      }

      if (normalizedAnswer == null) {
        errors.add(ImportRowError(
          rowNumber: rowNum,
          field: 'correct_option',
          message: 'Invalid correct_option "$rawCorrect". Expected A, B, C, D or 1-4.',
        ));
        rowHasError = true;
      }

      if (qText.isNotEmpty) {
        final dedupeKey = qText.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
        if (seenQuestions.containsKey(dedupeKey)) {
          duplicateCount++;
          errors.add(ImportRowError(
            rowNumber: rowNum,
            field: 'question_text',
            message: 'Duplicate question found (first appeared at row ${seenQuestions[dedupeKey]}).',
          ));
          rowHasError = true;
        } else {
          seenQuestions[dedupeKey] = rowNum;
        }
      }

      if (!rowHasError && normalizedAnswer != null) {
        valid.add(ParsedMcqRow(
          questionKey: qKey,
          questionText: qText,
          optionA: optA,
          optionB: optB,
          optionC: optC,
          optionD: optD,
          correctOption: normalizedAnswer,
          explanation: explanation,
          displayOrder: valid.length + 1,
        ));
      }
    }

    return ImportParseResult(
      validQuestions: valid,
      errors: errors,
      totalRows: rawRows.length,
      duplicateCount: duplicateCount,
      rawRows: normalizedRawRows,
    );
  }
}
