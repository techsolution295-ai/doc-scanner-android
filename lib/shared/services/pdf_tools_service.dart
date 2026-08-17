import 'dart:typed_data';
import 'dart:ui';

import 'package:image/image.dart' as img;
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../models/scan_types.dart';
import 'pdf_service.dart';

/// Real PDF manipulation powered by the pure-Dart Syncfusion PDF
/// library (merge, split, rotate, delete, encrypt, watermark) and
/// the `printing` rasterizer (PDF → image).
class PdfToolsService {
  PdfToolsService._();
  static final PdfToolsService instance = PdfToolsService._();

  /// Number of pages in a PDF (returns 0 on failure / wrong password).
  int pageCount(Uint8List bytes, {String? password}) {
    try {
      final doc = PdfDocument(inputBytes: bytes, password: password);
      final count = doc.pages.count;
      doc.dispose();
      return count;
    } catch (_) {
      return 0;
    }
  }

  /// Returns true when the PDF is password protected.
  bool isEncrypted(Uint8List bytes) {
    try {
      PdfDocument(inputBytes: bytes).dispose();
      return false;
    } catch (_) {
      return true;
    }
  }

  Future<Uint8List> mergePdfs(List<Uint8List> inputs) async {
    final output = PdfDocument();
    output.pageSettings.margins.all = 0;

    for (final bytes in inputs) {
      final source = PdfDocument(inputBytes: bytes);
      for (var i = 0; i < source.pages.count; i++) {
        final srcPage = source.pages[i];
        final size = srcPage.size;
        final template = srcPage.createTemplate();
        output.pageSettings.size = size;
        output.pages.add().graphics.drawPdfTemplate(template, Offset.zero, size);
      }
      source.dispose();
    }

    final result = Uint8List.fromList(await output.save());
    output.dispose();
    return result;
  }

  /// Splits into one PDF per page.
  Future<List<Uint8List>> splitPages(Uint8List bytes) async {
    final source = PdfDocument(inputBytes: bytes);
    final results = <Uint8List>[];

    for (var i = 0; i < source.pages.count; i++) {
      final srcPage = source.pages[i];
      final size = srcPage.size;
      final out = PdfDocument();
      out.pageSettings.margins.all = 0;
      out.pageSettings.size = size;
      out.pages.add().graphics.drawPdfTemplate(srcPage.createTemplate(), Offset.zero, size);
      results.add(Uint8List.fromList(await out.save()));
      out.dispose();
    }

    source.dispose();
    return results;
  }

  /// Builds a new PDF containing only [order] (original zero-based page
  /// indexes) in the given sequence. Used for delete + reorder.
  Future<Uint8List> buildFromPages(Uint8List bytes, List<int> order) async {
    final pages = await splitPages(bytes);
    final selected = <Uint8List>[
      for (final i in order)
        if (i >= 0 && i < pages.length) pages[i],
    ];
    if (selected.isEmpty) {
      throw StateError('No pages selected.');
    }
    return mergePdfs(selected);
  }

  /// Rotates individual pages by the given quarter turns (per original index).
  Future<Uint8List> rotateIndividual(
    Uint8List bytes,
    Map<int, int> quarterTurnsByIndex,
  ) async {
    final doc = PdfDocument(inputBytes: bytes);
    for (var i = 0; i < doc.pages.count; i++) {
      final turns = (quarterTurnsByIndex[i] ?? 0) % 4;
      if (turns != 0) {
        doc.pages[i].rotation = _rotateBy(doc.pages[i].rotation, turns);
      }
    }
    final result = Uint8List.fromList(await doc.save());
    doc.dispose();
    return result;
  }

  /// Removes the given zero-based page indexes.
  Future<Uint8List> deletePages(Uint8List bytes, Set<int> pageIndexes) async {
    final doc = PdfDocument(inputBytes: bytes);
    final sorted = pageIndexes.toList()..sort((a, b) => b.compareTo(a));
    for (final idx in sorted) {
      if (idx >= 0 && idx < doc.pages.count) {
        doc.pages.removeAt(idx);
      }
    }
    final result = Uint8List.fromList(await doc.save());
    doc.dispose();
    return result;
  }

  /// Rotates every page 90° clockwise per quarter turn.
  Future<Uint8List> rotatePages(Uint8List bytes, {int quarterTurns = 1}) async {
    final doc = PdfDocument(inputBytes: bytes);
    for (var i = 0; i < doc.pages.count; i++) {
      final page = doc.pages[i];
      page.rotation = _rotateBy(page.rotation, quarterTurns);
    }
    final result = Uint8List.fromList(await doc.save());
    doc.dispose();
    return result;
  }

  PdfPageRotateAngle _rotateBy(PdfPageRotateAngle current, int quarterTurns) {
    const order = [
      PdfPageRotateAngle.rotateAngle0,
      PdfPageRotateAngle.rotateAngle90,
      PdfPageRotateAngle.rotateAngle180,
      PdfPageRotateAngle.rotateAngle270,
    ];
    final next = (order.indexOf(current) + quarterTurns) % 4;
    return order[next];
  }

  /// Password protects a PDF (AES 256-bit).
  Future<Uint8List> lockPdf(Uint8List bytes, String password) async {
    final doc = PdfDocument(inputBytes: bytes);
    doc.security.algorithm = PdfEncryptionAlgorithm.aesx256Bit;
    doc.security.userPassword = password;
    doc.security.ownerPassword = password;
    final result = Uint8List.fromList(await doc.save());
    doc.dispose();
    return result;
  }

  /// Removes password protection. Throws if the password is wrong.
  Future<Uint8List> unlockPdf(Uint8List bytes, String password) async {
    final doc = PdfDocument(inputBytes: bytes, password: password);
    doc.security.userPassword = '';
    doc.security.ownerPassword = '';
    final result = Uint8List.fromList(await doc.save());
    doc.dispose();
    return result;
  }

  /// Draws a diagonal text watermark on every page.
  Future<Uint8List> addWatermark(Uint8List bytes, String text) async {
    final doc = PdfDocument(inputBytes: bytes);
    final font = PdfStandardFont(PdfFontFamily.helvetica, 42,
        style: PdfFontStyle.bold);
    final brush = PdfSolidBrush(PdfColor(180, 180, 180));

    for (var i = 0; i < doc.pages.count; i++) {
      final page = doc.pages[i];
      final g = page.graphics;
      final size = page.size;
      g.save();
      g.setTransparency(0.35);
      g.translateTransform(size.width / 2, size.height / 2);
      g.rotateTransform(-40);
      g.drawString(
        text,
        font,
        brush: brush,
        bounds: Rect.fromLTWH(-size.width / 2, -30, size.width, 80),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
      g.restore();
    }

    final result = Uint8List.fromList(await doc.save());
    doc.dispose();
    return result;
  }

  /// Re-saves the PDF with best content compression.
  Future<Uint8List> compressPdf(Uint8List bytes) async {
    final doc = PdfDocument(inputBytes: bytes);
    doc.compressionLevel = PdfCompressionLevel.best;
    final result = Uint8List.fromList(await doc.save());
    doc.dispose();
    return result;
  }

  /// Compresses a PDF at a user-chosen quality tier by re-rasterizing
  /// pages and re-encoding at a matching resolution + JPEG quality.
  Future<Uint8List> compressToQuality(Uint8List bytes, PdfQuality quality) async {
    final dpi = switch (quality) {
      PdfQuality.low => 100.0,
      PdfQuality.medium => 150.0,
      PdfQuality.high => 200.0,
    };
    final images = await pdfToImages(bytes, dpi: dpi);
    return PdfService().createPdf(pages: images, quality: quality, compress: true);
  }

  /// Burns opaque black rectangles (normalized 0-1 coordinates) onto each
  /// page image and rebuilds a flattened, truly-redacted PDF.
  Future<Uint8List> buildRedactedPdf(
    List<Uint8List> pageImages,
    List<List<Rect>> normalizedRectsPerPage,
  ) async {
    final output = <Uint8List>[];
    for (var i = 0; i < pageImages.length; i++) {
      final decoded = img.decodeImage(pageImages[i]);
      final rects = i < normalizedRectsPerPage.length ? normalizedRectsPerPage[i] : const <Rect>[];
      if (decoded == null || rects.isEmpty) {
        output.add(pageImages[i]);
        continue;
      }
      final w = decoded.width;
      final h = decoded.height;
      for (final r in rects) {
        img.fillRect(
          decoded,
          x1: (r.left * w).round().clamp(0, w - 1),
          y1: (r.top * h).round().clamp(0, h - 1),
          x2: (r.right * w).round().clamp(0, w - 1),
          y2: (r.bottom * h).round().clamp(0, h - 1),
          color: img.ColorRgb8(0, 0, 0),
        );
      }
      output.add(Uint8List.fromList(img.encodeJpg(decoded, quality: 90)));
    }
    return PdfService().createPdf(pages: output, quality: PdfQuality.high);
  }

  /// Rasterizes each PDF page to a PNG image.
  Future<List<Uint8List>> pdfToImages(Uint8List bytes, {double dpi = 150}) async {
    final images = <Uint8List>[];
    await for (final page in Printing.raster(bytes, dpi: dpi)) {
      images.add(await page.toPng());
    }
    return images;
  }
}
