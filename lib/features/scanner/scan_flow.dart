import 'package:flutter/material.dart';

import '../../app/routes/route_names.dart';
import '../../shared/services/document_scanner_service.dart';

/// Central entry point for launching the native document scanner
/// (real edge detection + auto crop + multi-page) and routing the
/// captured pages into the edit → PDF pipeline.
class ScanFlow {
  ScanFlow._();

  /// Launches the professional multi-page document scanner.
  static Future<void> startDocumentScan(BuildContext context) async {
    await _run(
      context,
      () => DocumentScannerService.instance.scanToSession(maxPages: 20),
    );
  }

  static Future<void> _run(
    BuildContext context,
    Future<dynamic> Function() scan,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final session = await scan();
      if (session == null) return; // user cancelled
      if (!context.mounted) return;
      navigator.pushNamed(RouteNames.editor, arguments: session);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('Permission')
                ? 'Camera permission is required to scan.'
                : 'Scanner is not available on this device.',
          ),
        ),
      );
    }
  }
}
