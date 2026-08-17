import 'dart:io';
import 'dart:typed_data';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:uuid/uuid.dart';

import '../models/scan_session.dart';
import '../models/scan_types.dart';

/// Professional document scanning powered by the native ML Kit
/// document scanner (Android) / VisionKit (iOS): real-time edge
/// detection, automatic cropping, perspective correction and
/// multi-page capture.
class DocumentScannerService {
  DocumentScannerService._();
  static final DocumentScannerService instance = DocumentScannerService._();

  final _uuid = const Uuid();

  /// Launches the native scanner and returns the captured page bytes.
  /// Returns an empty list if the user cancels.
  Future<List<Uint8List>> scanPages({
    int maxPages = 20,
    bool allowGalleryImport = true,
  }) async {
    final paths = await CunningDocumentScanner.getPictures(
      noOfPages: maxPages,
      isGalleryImportAllowed: allowGalleryImport,
    );

    if (paths == null || paths.isEmpty) return [];

    final result = <Uint8List>[];
    for (final path in paths) {
      final file = File(path);
      if (await file.exists()) {
        result.add(await file.readAsBytes());
      }
    }
    return result;
  }

  /// Scans documents and builds a ready-to-edit [ScanSession].
  /// Returns null when nothing was captured.
  Future<ScanSession?> scanToSession({
    int maxPages = 20,
    bool allowGalleryImport = true,
    bool isCardScan = false,
  }) async {
    final pages = await scanPages(
      maxPages: maxPages,
      allowGalleryImport: allowGalleryImport,
    );
    if (pages.isEmpty) return null;

    return ScanSession(
      id: _uuid.v4(),
      isCardScan: isCardScan,
      pages: pages
          .map(
            (bytes) => ScanPage(
              id: _uuid.v4(),
              imageData: ScanImageData(id: _uuid.v4(), bytes: bytes),
            ),
          )
          .toList(),
    );
  }

  /// Scans a single page (used for ID card front/back capture).
  Future<Uint8List?> scanSinglePage({bool allowGalleryImport = true}) async {
    final pages = await scanPages(
      maxPages: 1,
      allowGalleryImport: allowGalleryImport,
    );
    return pages.isEmpty ? null : pages.first;
  }
}
