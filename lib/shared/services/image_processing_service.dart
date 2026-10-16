import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../../shared/models/scan_types.dart';

/// Longest side kept for editing. Full camera frames are large enough to
/// run the UI out of memory while filters are applied.
const int kEditorMaxEdge = 2000;

/// UI brightness is an offset around 0. The image package treats brightness
/// as a multiplier where 1.0 leaves the pixel unchanged.
double _packageBrightness(double uiBrightness) => 1.0 + uiBrightness;

bool _hasColorEdits({
  required ScanFilterType filter,
  required double brightness,
  required double contrast,
  required int rotation,
}) {
  return filter != ScanFilterType.original ||
      brightness.abs() > 0.001 ||
      (contrast - 1).abs() > 0.001 ||
      rotation != 0;
}

/// Runs off the UI isolate. [brightness] is the editor offset (−0.5…0.5).
Uint8List processImageSync({
  required Uint8List sourceBytes,
  String filterName = 'original',
  double brightness = 0,
  double contrast = 1,
  int rotation = 0,
  int maxEdge = kEditorMaxEdge,
}) {
  try {
    final filter =
        ScanFilterType.values.asNameMap()[filterName] ??
        ScanFilterType.original;
    var image = img.decodeImage(sourceBytes);
    if (image == null) return sourceBytes;

    image = _limitEdge(image, maxEdge);

    if (rotation != 0) {
      image = img.copyRotate(image, angle: rotation.toDouble());
    }

    image = _applyFilter(image, filter);
    image = _adjustBrightnessContrast(image, brightness, contrast);

    return Uint8List.fromList(img.encodeJpg(image, quality: 88));
  } catch (_) {
    return sourceBytes;
  }
}

Uint8List cropImageSync(
  Uint8List sourceBytes, {
  double left = 0,
  double top = 0,
  double right = 1,
  double bottom = 1,
  int maxEdge = kEditorMaxEdge,
}) {
  try {
    final image = img.decodeImage(sourceBytes);
    if (image == null) return sourceBytes;

    final limited = _limitEdge(image, maxEdge);
    final l = left.clamp(0.0, 1.0);
    final t = top.clamp(0.0, 1.0);
    final r = right.clamp(0.0, 1.0);
    final b = bottom.clamp(0.0, 1.0);
    if (r - l < 0.02 || b - t < 0.02) return sourceBytes;

    final x = (limited.width * l).round().clamp(0, limited.width - 1);
    final y = (limited.height * t).round().clamp(0, limited.height - 1);
    final w = (limited.width * (r - l)).round().clamp(1, limited.width - x);
    final h = (limited.height * (b - t)).round().clamp(1, limited.height - y);

    final cropped = img.copyCrop(
      limited,
      x: x,
      y: y,
      width: w,
      height: h,
      antialias: false,
    );
    return Uint8List.fromList(img.encodeJpg(cropped, quality: 90));
  } catch (_) {
    return sourceBytes;
  }
}

Uint8List _encodeJpgIsolate(Map<String, Object> args) {
  try {
    final width = args['width'] as int;
    final height = args['height'] as int;
    final rgba = args['rgba'] as Uint8List;
    final quality = args['quality'] as int;
    final image = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: rgba.buffer,
      bytesOffset: rgba.offsetInBytes,
      numChannels: 4,
      order: img.ChannelOrder.rgba,
    );
    return Uint8List.fromList(img.encodeJpg(image, quality: quality));
  } catch (_) {
    return Uint8List(0);
  }
}

Uint8List _processImageIsolate(Map<String, Object> args) {
  return processImageSync(
    sourceBytes: args['bytes'] as Uint8List,
    filterName: args['filter'] as String,
    brightness: (args['brightness'] as num).toDouble(),
    contrast: (args['contrast'] as num).toDouble(),
    rotation: args['rotation'] as int,
    maxEdge: args['maxEdge'] as int,
  );
}

Uint8List _cropImageIsolate(Map<String, Object> args) {
  return cropImageSync(
    args['bytes'] as Uint8List,
    left: (args['left'] as num).toDouble(),
    top: (args['top'] as num).toDouble(),
    right: (args['right'] as num).toDouble(),
    bottom: (args['bottom'] as num).toDouble(),
    maxEdge: args['maxEdge'] as int,
  );
}

img.Image _limitEdge(img.Image image, int maxEdge) {
  final longest = math.max(image.width, image.height);
  if (longest <= maxEdge || maxEdge <= 0) return image;
  if (image.width >= image.height) {
    return img.copyResize(image, width: maxEdge);
  }
  return img.copyResize(image, height: maxEdge);
}

img.Image _applyFilter(img.Image image, ScanFilterType filter) {
  switch (filter) {
    case ScanFilterType.original:
      return image;
    case ScanFilterType.color:
      return img.adjustColor(image, saturation: 1.25, contrast: 1.08);
    case ScanFilterType.blackAndWhite:
      return img.grayscale(img.adjustColor(image, contrast: 1.45));
    case ScanFilterType.magicScan:
      final gray = img.grayscale(image);
      return img.adjustColor(
        gray,
        contrast: 1.55,
        brightness: 1.12,
        gamma: 0.92,
      );
    case ScanFilterType.sharp:
      return img.convolution(
        image,
        filter: const [0, -1, 0, -1, 5, -1, 0, -1, 0],
      );
    case ScanFilterType.grayscale:
      return img.grayscale(image);
    case ScanFilterType.clean:
      final cleaned = img.grayscale(image);
      return img.adjustColor(cleaned, contrast: 1.4, brightness: 1.1);
  }
}

img.Image _adjustBrightnessContrast(
  img.Image image,
  double brightness,
  double contrast,
) {
  final scaled = _packageBrightness(brightness);
  if ((scaled - 1).abs() < 0.001 && (contrast - 1).abs() < 0.001) {
    return image;
  }
  return img.adjustColor(
    image,
    brightness: scaled.clamp(0.2, 2.2),
    contrast: contrast.clamp(0.5, 2.0),
  );
}

class ImageProcessingService {
  ImageProcessingService._();
  static final ImageProcessingService instance = ImageProcessingService._();

  ({int width, int height})? readSize(Uint8List bytes) {
    try {
      final decoder = img.findDecoderForData(bytes);
      final info = decoder?.startDecode(bytes);
      if (info == null || info.width <= 0 || info.height <= 0) return null;
      return (width: info.width, height: info.height);
    } catch (_) {
      return null;
    }
  }

  /// Decodes through the platform so EXIF rotation is applied and huge
  /// camera frames are shrunk before any filter work.
  Future<Uint8List> normalize(
    Uint8List bytes, {
    int maxEdge = kEditorMaxEdge,
    bool force = false,
  }) async {
    if (bytes.isEmpty) return bytes;
    if (!force) {
      final size = readSize(bytes);
      if (size != null && size.width <= maxEdge && size.height <= maxEdge) {
        return bytes;
      }
    }
    try {
      return await _transcode(bytes, maxEdge);
    } catch (_) {
      return bytes;
    }
  }

  Future<Uint8List> processImage({
    required Uint8List sourceBytes,
    ScanFilterType filter = ScanFilterType.original,
    double brightness = 0.0,
    double contrast = 1.0,
    int rotation = 0,
    int maxEdge = kEditorMaxEdge,
  }) async {
    if (sourceBytes.isEmpty) return sourceBytes;
    try {
      final safe = await normalize(sourceBytes, maxEdge: maxEdge);
      if (!_hasColorEdits(
        filter: filter,
        brightness: brightness,
        contrast: contrast,
        rotation: rotation,
      )) {
        return safe;
      }
      final result = await compute(_processImageIsolate, <String, Object>{
        'bytes': safe,
        'filter': filter.name,
        'brightness': brightness,
        'contrast': contrast,
        'rotation': rotation,
        'maxEdge': maxEdge,
      });
      return result.isEmpty ? safe : result;
    } catch (_) {
      return sourceBytes;
    }
  }

  Future<Uint8List> cropImage(
    Uint8List sourceBytes, {
    double left = 0.08,
    double top = 0.08,
    double right = 0.92,
    double bottom = 0.92,
    int maxEdge = kEditorMaxEdge,
  }) async {
    if (sourceBytes.isEmpty) return sourceBytes;
    try {
      final safe = await normalize(sourceBytes, maxEdge: maxEdge);
      final result = await compute(_cropImageIsolate, <String, Object>{
        'bytes': safe,
        'left': left,
        'top': top,
        'right': right,
        'bottom': bottom,
        'maxEdge': maxEdge,
      });
      return result.isEmpty ? safe : result;
    } catch (_) {
      return sourceBytes;
    }
  }

  Future<Uint8List> cropToCardRatio(Uint8List sourceBytes) async {
    try {
      final safe = await normalize(sourceBytes);
      final image = img.decodeImage(safe);
      if (image == null) return safe;

      const cardRatio = 1.586;
      final imageRatio = image.width / image.height;

      final int cropW;
      final int cropH;
      final int offsetX;
      final int offsetY;
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
        x: offsetX.clamp(0, image.width - 1),
        y: offsetY.clamp(0, image.height - 1),
        width: cropW.clamp(1, image.width),
        height: cropH.clamp(1, image.height),
        antialias: false,
      );
      return Uint8List.fromList(img.encodeJpg(cropped, quality: 90));
    } catch (_) {
      return sourceBytes;
    }
  }

  Future<Uint8List> combineCardSides(
    Uint8List frontBytes,
    Uint8List backBytes,
  ) async {
    try {
      final frontSafe = await normalize(frontBytes, maxEdge: 1400);
      final backSafe = await normalize(backBytes, maxEdge: 1400);
      final front = img.decodeImage(frontSafe);
      final back = img.decodeImage(backSafe);
      if (front == null || back == null) return frontSafe;

      final targetW = math.max(front.width, back.width);
      final frontResized = img.copyResize(front, width: targetW);
      final backResized = img.copyResize(back, width: targetW);

      const gap = 24;
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

      return Uint8List.fromList(img.encodeJpg(canvas, quality: 90));
    } catch (_) {
      return frontBytes;
    }
  }

  Future<Uint8List> _transcode(Uint8List bytes, int maxEdge) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    ui.Codec? codec;
    ui.Image? uiImage;
    try {
      final width = descriptor.width;
      final height = descriptor.height;
      if (width <= 0 || height <= 0) return bytes;

      int? targetWidth;
      int? targetHeight;
      if (width >= height && width > maxEdge) {
        targetWidth = maxEdge;
      } else if (height > width && height > maxEdge) {
        targetHeight = maxEdge;
      }

      codec = await descriptor.instantiateCodec(
        targetWidth: targetWidth,
        targetHeight: targetHeight,
      );
      final frame = await codec.getNextFrame();
      uiImage = frame.image;
      final byteData = await uiImage.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (byteData == null) return bytes;

      final rgba = Uint8List.fromList(
        byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        ),
      );
      final encoded = await compute(_encodeJpgIsolate, <String, Object>{
        'width': uiImage.width,
        'height': uiImage.height,
        'rgba': rgba,
        'quality': 90,
      });
      if (encoded.isEmpty) return bytes;
      return encoded;
    } finally {
      uiImage?.dispose();
      codec?.dispose();
      descriptor.dispose();
      buffer.dispose();
    }
  }
}
