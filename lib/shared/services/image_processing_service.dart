import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../shared/models/scan_types.dart';

class ImageProcessingService {
  ImageProcessingService._();
  static final ImageProcessingService instance = ImageProcessingService._();

  Future<Uint8List> processImage({
    required Uint8List sourceBytes,
    ScanFilterType filter = ScanFilterType.original,
    double brightness = 0.0,
    double contrast = 1.0,
    int rotation = 0,
  }) async {
    var image = img.decodeImage(sourceBytes);
    if (image == null) return sourceBytes;

    if (rotation != 0) {
      image = img.copyRotate(image, angle: rotation.toDouble());
    }

    image = _applyFilter(image, filter);
    image = _adjustBrightnessContrast(image, brightness, contrast);

    return Uint8List.fromList(img.encodeJpg(image, quality: 90));
  }

  img.Image _applyFilter(img.Image image, ScanFilterType filter) {
    switch (filter) {
      case ScanFilterType.original:
        return image;
      case ScanFilterType.color:
        return img.adjustColor(image, saturation: 1.3, contrast: 1.1);
      case ScanFilterType.blackAndWhite:
        return img.grayscale(img.adjustColor(image, contrast: 1.4));
      case ScanFilterType.magicScan:
        final gray = img.grayscale(image);
        return img.adjustColor(gray, contrast: 1.5, brightness: 0.05, gamma: 1.1);
      case ScanFilterType.sharp:
        return img.convolution(image, filter: [
          0, -1, 0,
          -1, 5, -1,
          0, -1, 0,
        ]);
      case ScanFilterType.grayscale:
        return img.grayscale(image);
      case ScanFilterType.clean:
        final cleaned = img.grayscale(image);
        return img.adjustColor(cleaned, contrast: 1.35, brightness: 0.08);
    }
  }

  img.Image _adjustBrightnessContrast(
    img.Image image,
    double brightness,
    double contrast,
  ) {
    if (brightness == 0 && contrast == 1.0) return image;
    return img.adjustColor(
      image,
      brightness: brightness,
      contrast: contrast,
    );
  }

  /// Simulated perspective crop — crops to normalized rect within image bounds.
  Future<Uint8List> cropImage(
    Uint8List sourceBytes, {
    double left = 0.08,
    double top = 0.08,
    double right = 0.92,
    double bottom = 0.92,
  }) async {
    final image = img.decodeImage(sourceBytes);
    if (image == null) return sourceBytes;

    final x = (image.width * left).round().clamp(0, image.width - 1);
    final y = (image.height * top).round().clamp(0, image.height - 1);
    final w = (image.width * (right - left)).round().clamp(1, image.width - x);
    final h = (image.height * (bottom - top)).round().clamp(1, image.height - y);

    final cropped = img.copyCrop(image, x: x, y: y, width: w, height: h);
    return Uint8List.fromList(img.encodeJpg(cropped, quality: 92));
  }

  /// Card aspect ratio crop (ID card ~ 1.586:1).
  Future<Uint8List> cropToCardRatio(Uint8List sourceBytes) async {
    final image = img.decodeImage(sourceBytes);
    if (image == null) return sourceBytes;

    const cardRatio = 1.586;
    final imageRatio = image.width / image.height;

    int cropW, cropH, offsetX, offsetY;
    if (imageRatio > cardRatio) {
      cropH = image.height;
      cropW = (cropH * cardRatio).round();
      offsetX = ((image.width - cropW) / 2).round();
      offsetY = 0;
    } else {
      cropW = image.width;
      cropH = (cropW / cardRatio).round();
      offsetX = 0;
      offsetY = ((image.height - cropH) / 2).round();
    }

    final cropped = img.copyCrop(
      image,
      x: offsetX,
      y: offsetY,
      width: cropW.clamp(1, image.width),
      height: cropH.clamp(1, image.height),
    );
    return Uint8List.fromList(img.encodeJpg(cropped, quality: 92));
  }

  Future<Uint8List> combineCardSides(
    Uint8List frontBytes,
    Uint8List backBytes,
  ) async {
    final front = img.decodeImage(frontBytes);
    final back = img.decodeImage(backBytes);
    if (front == null || back == null) return frontBytes;

    final targetW = math.max(front.width, back.width);
    final frontResized = img.copyResize(front, width: targetW);
    final backResized = img.copyResize(back, width: targetW);

    final gap = 24;
    final canvas = img.Image(
      width: targetW,
      height: frontResized.height + backResized.height + gap,
    );
    img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
    img.compositeImage(canvas, frontResized, dstX: 0, dstY: 0);
    img.compositeImage(
      canvas,
      backResized,
      dstX: 0,
      dstY: frontResized.height + gap,
    );

    return Uint8List.fromList(img.encodeJpg(canvas, quality: 92));
  }
}
