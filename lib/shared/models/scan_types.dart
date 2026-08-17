import 'dart:typed_data';

enum ScanFilterType {
  original('Original'),
  color('Color'),
  blackAndWhite('Black & White'),
  magicScan('Magic Scan'),
  sharp('Sharp'),
  grayscale('Grayscale'),
  clean('Clean Scan');

  const ScanFilterType(this.label);
  final String label;
}

enum PdfQuality { low, medium, high }

enum DocumentSortBy { date, name, type }

enum DocumentFileType { pdf, image, all }

enum FileCategoryFilter { all, pdf, images, docs, others }

/// Lightweight image holder used across editor and PDF flows.
class ScanImageData {
  ScanImageData({
    required this.id,
    required this.bytes,
    this.rotation = 0,
    this.filter = ScanFilterType.original,
    this.brightness = 0.0,
    this.contrast = 1.0,
    this.label,
  });

  final String id;
  Uint8List bytes;
  int rotation;
  ScanFilterType filter;
  double brightness;
  double contrast;
  String? label;

  ScanImageData copyWith({
    Uint8List? bytes,
    int? rotation,
    ScanFilterType? filter,
    double? brightness,
    double? contrast,
    String? label,
  }) {
    return ScanImageData(
      id: id,
      bytes: bytes ?? this.bytes,
      rotation: rotation ?? this.rotation,
      filter: filter ?? this.filter,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      label: label ?? this.label,
    );
  }
}
