import 'dart:typed_data';

import 'package:doc_scanner/shared/services/image_processing_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

Uint8List _jpeg({required int width, required int height, required int shade}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(shade, shade, shade));
  return Uint8List.fromList(img.encodeJpg(image, quality: 95));
}

void main() {
  test('magic scan keeps a light page light', () {
    final out = processImageSync(
      sourceBytes: _jpeg(width: 40, height: 40, shade: 210),
      filterName: 'magicScan',
    );
    final decoded = img.decodeImage(out)!;
    final pixel = decoded.getPixel(20, 20);
    expect(pixel.r, greaterThan(120));
  });

  test('clean scan does not turn the page black', () {
    final out = processImageSync(
      sourceBytes: _jpeg(width: 40, height: 40, shade: 200),
      filterName: 'clean',
    );
    final decoded = img.decodeImage(out)!;
    expect(decoded.getPixel(20, 20).r, greaterThan(100));
  });

  test('brightness offset brightens instead of blacking out', () {
    final source = _jpeg(width: 32, height: 32, shade: 140);
    final brighter = img.decodeImage(
      processImageSync(sourceBytes: source, brightness: 0.35),
    )!;
    final darker = img.decodeImage(
      processImageSync(sourceBytes: source, brightness: -0.35),
    )!;
    expect(brighter.getPixel(8, 8).r, greaterThan(darker.getPixel(8, 8).r));
    expect(darker.getPixel(8, 8).r, greaterThan(40));
  });

  test('crop uses the selected area of the page', () {
    final out = cropImageSync(
      _jpeg(width: 100, height: 200, shade: 180),
      left: 0.25,
      top: 0.25,
      right: 0.75,
      bottom: 0.75,
    );
    final decoded = img.decodeImage(out)!;
    expect(decoded.width, inInclusiveRange(48, 52));
    expect(decoded.height, inInclusiveRange(98, 102));
  });
}
