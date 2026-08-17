import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../app/constants/app_constants.dart';
import '../../shared/models/scan_types.dart';

class PdfService {
  Future<Uint8List> createPdf({
    required List<Uint8List> pages,
    required PdfQuality quality,
    bool compress = false,
    String title = 'Document',
  }) async {
    final pdf = pw.Document(
      title: title,
      creator: AppConstants.appName,
    );

    for (final pageBytes in pages) {
      final encoded = _encodeForQuality(pageBytes, quality, compress);
      final image = pw.MemoryImage(encoded);
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (context) => pw.Center(
            child: pw.Image(image, fit: pw.BoxFit.contain),
          ),
        ),
      );
    }

    return pdf.save();
  }

  /// Re-encodes a page image to JPEG at the selected quality tier.
  /// Higher compression downscales large images to reduce file size.
  Uint8List _encodeForQuality(
    Uint8List source,
    PdfQuality quality,
    bool compress,
  ) {
    try {
      final decoded = img.decodeImage(source);
      if (decoded == null) return source;

      final (maxDimension, jpgQuality) = switch (quality) {
        PdfQuality.low => (1240, 55),
        PdfQuality.medium => (1654, 72),
        PdfQuality.high => (2480, 90),
      };

      // Extra shrink when compression is explicitly requested.
      final effectiveMax = compress ? (maxDimension * 0.8).round() : maxDimension;
      final effectiveQuality = compress ? (jpgQuality - 12).clamp(35, 90) : jpgQuality;

      var processed = decoded;
      final longestSide =
          decoded.width > decoded.height ? decoded.width : decoded.height;
      if (longestSide > effectiveMax) {
        if (decoded.width >= decoded.height) {
          processed = img.copyResize(decoded, width: effectiveMax);
        } else {
          processed = img.copyResize(decoded, height: effectiveMax);
        }
      }

      return Uint8List.fromList(img.encodeJpg(processed, quality: effectiveQuality));
    } catch (_) {
      return source;
    }
  }

  int estimatePdfSizeKb(int pageCount, PdfQuality quality) {
    final perPage = switch (quality) {
      PdfQuality.low => 120,
      PdfQuality.medium => 280,
      PdfQuality.high => 520,
    };
    return pageCount * perPage;
  }
}
