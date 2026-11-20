import 'package:flutter/material.dart';
import '../../../core/repositories/printable_omr_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../presentation/screens/qr_omr_scanner_screen.dart';
import 'printable_omr_pdf_service.dart';

/// One-line helper to launch Printable OMR PDF generation or the QR Scanner
/// from any exam card, past exam vault, or question bank header.
class PrintableOmrLauncher {
  static Future<void> openQrScanner(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const QrOmrScannerScreen()),
    );
  }

  static Future<void> generateAndPrintPdf(
    BuildContext context, {
    required String examId,
    String? candidateName,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final colors = context.colors;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Row(
            children: [
              CircularProgressIndicator(color: colors.primary, strokeWidth: 2.5),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Building Printable OMR + Questions PDF with QR Code...',
                  style: TextStyle(fontSize: 13, color: colors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final pack = await PrintableOmrRepository().generatePack(examId: examId);
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      await PrintableOmrPdfService.previewAndPrint(
        pack,
        candidateName: candidateName,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Printable Pack Ready (${pack.shortCode}). Scan its QR anytime to check answers!',
          ),
          backgroundColor: colors.accentEmerald,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: colors.dangerRed,
        ),
      );
    }
  }
}
