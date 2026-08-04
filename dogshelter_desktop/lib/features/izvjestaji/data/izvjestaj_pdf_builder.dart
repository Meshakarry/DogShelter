import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:dogshelter_shared/core/date_format.dart';

/// One table (heading + headers + rows) inside a report PDF. A report can have more than
/// one section - e.g. Udomljavanje has both a "po rasi" and a "po mjesecima" breakdown.
class PdfReportSection {
  const PdfReportSection({required this.heading, required this.columnHeaders, required this.rows});

  final String heading;
  final List<String> columnHeaders;
  final List<List<String>> rows;
}

/// Builds admin-report PDFs with a bundled Noto Sans font, so Bosnian diacritics
/// (č/ć/š/ž/đ) render correctly instead of being ASCII-folded away by the default
/// Helvetica font (the workaround the CSBWebshop reference repo uses, deliberately not
/// copied here - see project notes on the Phase 9 QuestPDF font bug this fix mirrors).
abstract final class IzvjestajPdfBuilder {
  static pw.Font? _regular;
  static pw.Font? _bold;

  static Future<void> _ensureFontsLoaded() async {
    if (_regular != null && _bold != null) return;
    final regularData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
    _regular = pw.Font.ttf(regularData);
    _bold = pw.Font.ttf(boldData);
  }

  static Future<Uint8List> buildReportPdf({
    required String title,
    DateTime? datumOd,
    DateTime? datumDo,
    required List<PdfReportSection> sections,
    String? summaryLine,
  }) async {
    await _ensureFontsLoaded();

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: _regular!, bold: _bold!),
    );

    final String rangeLine = datumOd == null && datumDo == null
        ? 'Period: sve vrijeme'
        : 'Period: ${datumOd != null ? formatDate(datumOd) : '...'} - ${datumDo != null ? formatDate(datumDo) : '...'}';
    final String generated = formatDateTime(DateTime.now());

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) => <pw.Widget>[
          pw.Header(
            level: 0,
            child: pw.Text(title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 4),
          pw.Text('Azil Bugojno - administracija', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 2),
          pw.Text(rangeLine, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 16),
          for (final section in sections) ...[
            pw.Text(section.heading, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: section.columnHeaders,
              data: section.rows,
              headerStyle: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellHeight: 22,
              cellAlignments: {for (int i = 0; i < section.columnHeaders.length; i++) i: pw.Alignment.centerLeft},
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
            ),
            pw.SizedBox(height: 20),
          ],
          if (summaryLine != null) ...[
            pw.Divider(),
            pw.SizedBox(height: 4),
            pw.Text(summaryLine, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          ],
          pw.SizedBox(height: 24),
          pw.Text('Generisano: $generated', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        ],
      ),
    );

    return doc.save();
  }
}
