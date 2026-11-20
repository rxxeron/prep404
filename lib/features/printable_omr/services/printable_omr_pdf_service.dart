import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/repositories/printable_omr_repository.dart';

/// Generates an A4 Printable OMR Sheet (Page 1 with embedded QR code)
/// followed by the formatted Question Paper (Pages 2+).
class PrintableOmrPdfService {
  static final PdfColor _brandOrange = PdfColor.fromHex('#F97316');
  static final PdfColor _inkDark = PdfColor.fromHex('#0F172A');
  static final PdfColor _inkMuted = PdfColor.fromHex('#475569');
  static final PdfColor _borderLight = PdfColor.fromHex('#CBD5E1');
  static final PdfColor _bgSoft = PdfColor.fromHex('#F8FAFC');

  /// Builds the PDF bytes for [pack].
  static Future<Uint8List> buildPdf(
    PrintableOmrPack pack, {
    String? candidateName,
  }) async {
    final doc = pw.Document(
      title: '${pack.title} (${pack.shortCode})',
      author: 'Prep404',
    );

    final negLabel = pack.negativeMark > 0
        ? '-${pack.negativeMark.toStringAsFixed(2)} per wrong'
        : 'None (No Negative Marking)';

    // =========================================================================
    // PAGE 1: OFFICIAL PRINTABLE OMR BUBBLE SHEET + EMBEDDED QR CODE
    // =========================================================================
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Top Brand Banner + QR Code
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: _bgSoft,
                  borderRadius: pw.BorderRadius.circular(10),
                  border: pw.Border.all(color: _borderLight, width: 1),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            children: [
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: pw.BoxDecoration(
                                  color: _brandOrange,
                                  borderRadius: pw.BorderRadius.circular(4),
                                ),
                                child: pw.Text(
                                  'PREP404 • OMR ANSWER SHEET',
                                  style: pw.TextStyle(
                                    color: PdfColors.white,
                                    fontSize: 8.5,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ),
                              pw.SizedBox(width: 8),
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3),
                                decoration: pw.BoxDecoration(
                                  border: pw.Border.all(color: _inkDark, width: 0.8),
                                  borderRadius: pw.BorderRadius.circular(4),
                                ),
                                child: pw.Text(
                                  pack.setLabel,
                                  style: pw.TextStyle(
                                    color: _inkDark,
                                    fontSize: 8.5,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            _sanitizeText(pack.title),
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: _inkDark,
                            ),
                            maxLines: 2,
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            'Questions: ${pack.totalQuestions}   •   Duration: ${pack.durationMinutes} min   •   Penalty: $negLabel',
                            style: pw.TextStyle(fontSize: 9, color: _inkMuted),
                          ),
                          pw.SizedBox(height: 10),
                          pw.Row(
                            children: [
                              pw.Text(
                                'Candidate: ',
                                style: pw.TextStyle(
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold,
                                    color: _inkDark),
                              ),
                              pw.Expanded(
                                child: pw.Container(
                                  padding: const pw.EdgeInsets.only(bottom: 2),
                                  decoration: const pw.BoxDecoration(
                                    border: pw.Border(
                                      bottom: pw.BorderSide(
                                          color: PdfColors.grey600, width: 0.6),
                                    ),
                                  ),
                                  child: pw.Text(
                                    _sanitizeText(candidateName ?? ''),
                                    style: pw.TextStyle(fontSize: 9, color: _inkDark),
                                  ),
                                ),
                              ),
                              pw.SizedBox(width: 14),
                              pw.Text(
                                'Date: __________',
                                style: pw.TextStyle(fontSize: 9, color: _inkMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 14),
                    // Embedded Vector QR Code
                    pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(8),
                        border: pw.Border.all(color: _brandOrange, width: 1.2),
                      ),
                      child: pw.Column(
                        children: [
                          pw.BarcodeWidget(
                            barcode: pw.Barcode.qrCode(),
                            data: pack.qrPayload,
                            width: 68,
                            height: 68,
                            color: _inkDark,
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            pack.shortCode,
                            style: pw.TextStyle(
                              fontSize: 8.5,
                              fontWeight: pw.FontWeight.bold,
                              color: _inkDark,
                            ),
                          ),
                          pw.Text(
                            'Scan in Prep404',
                            style: pw.TextStyle(fontSize: 6.5, color: _inkMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'INSTRUCTIONS: Fill circles completely with a black/blue pen or 2B pencil. When finished, open Prep404 → Scan OMR QR and point your camera at the QR code above to instantly check answers and save your score.',
                style: pw.TextStyle(fontSize: 8, color: _inkMuted),
              ),
              pw.SizedBox(height: 12),

              // Multi-Column OMR Bubble Grid (up to 100 questions on page 1)
              pw.Expanded(
                child: _buildOmrBubbleColumns(pack.totalQuestions),
              ),

              // Footer
              pw.Divider(color: _borderLight, thickness: 0.6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Prep404 Printable Practice Pack • Set Code: ${pack.shortCode}',
                    style: pw.TextStyle(fontSize: 8, color: _inkMuted),
                  ),
                  pw.Text(
                    'OMR Sheet (Page 1)',
                    style: pw.TextStyle(fontSize: 8, color: _inkMuted),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // =========================================================================
    // PAGES 2+: PRINTABLE QUESTION PAPER
    // =========================================================================
    if (pack.questions.isNotEmpty) {
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 28),
          header: (context) => pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 10),
            padding: const pw.EdgeInsets.only(bottom: 6),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: _borderLight, width: 0.7),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Text(
                    '${_sanitizeText(pack.title)} (${pack.setLabel})',
                    style: pw.TextStyle(
                      fontSize: 9.5,
                      fontWeight: pw.FontWeight.bold,
                      color: _inkDark,
                    ),
                    maxLines: 1,
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Text(
                  'Code: ${pack.shortCode}',
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: _brandOrange,
                  ),
                ),
              ],
            ),
          ),
          footer: (context) => pw.Container(
            margin: const pw.EdgeInsets.only(top: 8),
            padding: const pw.EdgeInsets.only(top: 5),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: _borderLight, width: 0.6),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Scan QR on Page 1 in Prep404 for instant Answer Key & Solutions',
                  style: pw.TextStyle(fontSize: 7.5, color: _inkMuted),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 7.5, color: _inkMuted),
                ),
              ],
            ),
          ),
          build: (context) {
            return pack.questions.map((q) {
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _borderLight, width: 0.6),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (q.passage != null && q.passage!.trim().isNotEmpty)
                      pw.Container(
                        margin: const pw.EdgeInsets.only(bottom: 6),
                        padding: const pw.EdgeInsets.all(7),
                        decoration: pw.BoxDecoration(
                          color: _bgSoft,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          _sanitizeText(q.passage!),
                          style: pw.TextStyle(fontSize: 8.5, color: _inkMuted),
                        ),
                      ),
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          '${q.order}. ',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: _inkDark,
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            _sanitizeText(q.questionText),
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: _inkDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Wrap(
                      spacing: 14,
                      runSpacing: 4,
                      children: q.options.map((opt) {
                        return pw.Container(
                          width: 235,
                          child: pw.Text(
                            '(${opt['id']}) ${_sanitizeText(opt['text'] ?? '')}',
                            style: pw.TextStyle(fontSize: 9.5, color: _inkDark),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            }).toList();
          },
        ),
      );
    }

    return doc.save();
  }

  /// Opens the native print / Save as PDF dialog.
  static Future<void> previewAndPrint(
    PrintableOmrPack pack, {
    String? candidateName,
  }) async {
    final bytes = await buildPdf(pack, candidateName: candidateName);
    await Printing.layoutPdf(
      name: 'Prep404_${pack.shortCode}.pdf',
      onLayout: (_) async => bytes,
    );
  }

  /// Shares the generated PDF directly via Android/iOS share sheet.
  static Future<void> sharePdf(
    PrintableOmrPack pack, {
    String? candidateName,
  }) async {
    final bytes = await buildPdf(pack, candidateName: candidateName);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Prep404_${pack.shortCode}.pdf',
    );
  }

  static pw.Widget _buildOmrBubbleColumns(int totalQuestions) {
    final count = totalQuestions.clamp(1, 100);
    final columns = count <= 25 ? 2 : (count <= 60 ? 3 : 4);
    final perCol = (count / columns).ceil();

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: List.generate(columns, (colIdx) {
        final start = colIdx * perCol + 1;
        final end = ((colIdx + 1) * perCol).clamp(0, count);
        if (start > count) return pw.Expanded(child: pw.SizedBox());

        return pw.Expanded(
          child: pw.Container(
            margin: pw.EdgeInsets.only(right: colIdx < columns - 1 ? 10 : 0),
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _borderLight, width: 0.7),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              children: [
                for (int q = start; q <= end; q++)
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 3),
                    child: pw.Row(
                      children: [
                        pw.SizedBox(
                          width: 22,
                          child: pw.Text(
                            q.toString().padLeft(2, '0'),
                            style: pw.TextStyle(
                              fontSize: 8.5,
                              fontWeight: pw.FontWeight.bold,
                              color: _inkDark,
                            ),
                          ),
                        ),
                        ...['A', 'B', 'C', 'D'].map(
                          (letter) => pw.Container(
                            width: 15,
                            height: 15,
                            margin: const pw.EdgeInsets.symmetric(horizontal: 3),
                            alignment: pw.Alignment.center,
                            decoration: pw.BoxDecoration(
                              shape: pw.BoxShape.circle,
                              border: pw.Border.all(color: _inkDark, width: 0.8),
                            ),
                            child: pw.Text(
                              letter,
                              style: pw.TextStyle(
                                fontSize: 7.5,
                                fontWeight: pw.FontWeight.bold,
                                color: _inkMuted,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// Cleans LaTeX delimiters and unsupported non-ASCII symbols for Helvetica PDF rendering.
  static String _sanitizeText(String input) {
    return input
        .replaceAll(r'\(', '')
        .replaceAll(r'\)', '')
        .replaceAll(r'\[', '')
        .replaceAll(r'\]', '')
        .replaceAll(r'$$', '')
        .replaceAll(r'$', '')
        .replaceAll('—', '-')
        .replaceAll('–', '-')
        .replaceAll('’', "'")
        .replaceAll('‘', "'")
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('×', 'x')
        .replaceAll('÷', '/')
        .replaceAll('≤', '<=')
        .replaceAll('≥', '>=')
        .replaceAll('≠', '!=')
        .replaceAll('°', ' deg')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
