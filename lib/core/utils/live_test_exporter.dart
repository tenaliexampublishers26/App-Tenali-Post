import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/lms_models.dart';

class LiveTestExporter {
  static Uint8List buildExcelBytes(
    LmsLiveTest test,
    List<LmsLiveTestSubmission> ranked,
  ) {
    final excel = Excel.createExcel();
    final sheetName = excel.getDefaultSheet() ?? 'Results';
    final sheet = excel[sheetName];

    final headers = [
      'Rank',
      'Student Name',
      'Phone',
      'Email',
      'Location',
      'Correct',
      'Wrong',
      'Attempted',
      'Total Questions',
      'Marks Obtained',
      'Percentage',
      'Submitted At',
    ];
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    final df = DateFormat('yyyy-MM-dd HH:mm');
    for (var i = 0; i < ranked.length; i++) {
      final r = ranked[i];
      final rank = r.rank > 0 ? r.rank : (i + 1);
      sheet.appendRow([
        IntCellValue(rank),
        TextCellValue(r.studentName),
        TextCellValue(r.phoneNumber),
        TextCellValue(r.email),
        TextCellValue(r.location),
        IntCellValue(r.correctCount),
        IntCellValue(r.wrongCount),
        IntCellValue(r.attemptedCount),
        IntCellValue(r.totalQuestions),
        DoubleCellValue(r.marksObtained),
        DoubleCellValue(r.percentage),
        TextCellValue(df.format(r.submittedAt.toLocal())),
      ]);
    }

    final encoded = excel.encode();
    return Uint8List.fromList(encoded ?? const []);
  }

  static Future<Uint8List> buildPdfBytes(
    LmsLiveTest test,
    List<LmsLiveTestSubmission> ranked,
  ) async {
    final doc = pw.Document();
    final df = DateFormat('dd MMM yyyy, HH:mm');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) => [
          pw.Text(
            'Tenali Exams Publishers — Live Test Merit List',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${test.title}  |  Date: ${DateFormat('dd MMM yyyy').format(test.testDate)}  |  Questions: ${test.questionCount}  |  Submissions: ${ranked.length}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 14),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF0B2545)),
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            headers: const [
              'Rank',
              'Name',
              'Phone',
              'Location',
              'Correct',
              'Wrong',
              'Marks',
              '%',
              'Submitted',
            ],
            data: List.generate(ranked.length, (i) {
              final r = ranked[i];
              final rank = r.rank > 0 ? r.rank : (i + 1);
              return [
                '#$rank',
                r.studentName,
                r.phoneNumber,
                r.location,
                '${r.correctCount}',
                '${r.wrongCount}',
                r.marksObtained.toStringAsFixed(0),
                '${r.percentage.toStringAsFixed(1)}%',
                df.format(r.submittedAt.toLocal()),
              ];
            }),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static Future<void> shareExcel(
    LmsLiveTest test,
    List<LmsLiveTestSubmission> ranked,
  ) async {
    final bytes = buildExcelBytes(test, ranked);
    final safeTitle = test.title.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final fileName = '${safeTitle}_Results.xlsx';

    if (kIsWeb) {
      await Share.shareXFiles([
        XFile.fromData(
          bytes,
          mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          name: fileName,
        ),
      ], text: '${test.title} Ranked Results (.xlsx)');
      return;
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles([XFile(file.path)], text: '${test.title} Ranked Results (.xlsx)');
  }

  static Future<void> shareOrPrintPdf(
    LmsLiveTest test,
    List<LmsLiveTestSubmission> ranked,
  ) async {
    final bytes = await buildPdfBytes(test, ranked);
    final safeTitle = test.title.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    await Printing.sharePdf(bytes: bytes, filename: '${safeTitle}_Results.pdf');
  }
}
