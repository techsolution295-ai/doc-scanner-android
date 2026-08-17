import 'dart:convert';
import 'dart:typed_data';

import 'scan_types.dart';

/// Represents a single page in a scan session.
class ScanPage {
  ScanPage({
    required this.id,
    required this.imageData,
    this.thumbnailBytes,
  });

  final String id;
  ScanImageData imageData;
  Uint8List? thumbnailBytes;
}

/// Active scanning workflow state passed between screens.
class ScanSession {
  ScanSession({
    required this.id,
    this.title = 'Untitled Document',
    this.pages = const [],
    this.isCardScan = false,
    this.cardSide,
    this.pdfQuality = PdfQuality.high,
    this.compressPdf = false,
  });

  final String id;
  String title;
  List<ScanPage> pages;
  final bool isCardScan;
  String? cardSide; // 'front' | 'back'
  PdfQuality pdfQuality;
  bool compressPdf;

  ScanSession copyWith({
    String? title,
    List<ScanPage>? pages,
    PdfQuality? pdfQuality,
    bool? compressPdf,
  }) {
    return ScanSession(
      id: id,
      title: title ?? this.title,
      pages: pages ?? this.pages,
      isCardScan: isCardScan,
      cardSide: cardSide,
      pdfQuality: pdfQuality ?? this.pdfQuality,
      compressPdf: compressPdf ?? this.compressPdf,
    );
  }
}

/// Persisted document metadata for file manager.
class ScannedDocument {
  ScannedDocument({
    required this.id,
    required this.name,
    required this.filePath,
    required this.createdAt,
    required this.fileType,
    this.pageCount = 1,
    this.isFavorite = false,
    this.thumbnailPath,
    this.fileSizeBytes = 0,
  });

  final String id;
  String name;
  final String filePath;
  final DateTime createdAt;
  final String fileType; // 'pdf' | 'image'
  int pageCount;
  bool isFavorite;
  String? thumbnailPath;
  int fileSizeBytes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'filePath': filePath,
        'createdAt': createdAt.toIso8601String(),
        'fileType': fileType,
        'pageCount': pageCount,
        'isFavorite': isFavorite,
        'thumbnailPath': thumbnailPath,
        'fileSizeBytes': fileSizeBytes,
      };

  factory ScannedDocument.fromJson(Map<String, dynamic> json) {
    return ScannedDocument(
      id: json['id'] as String,
      name: json['name'] as String,
      filePath: json['filePath'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      fileType: json['fileType'] as String,
      pageCount: json['pageCount'] as int? ?? 1,
      isFavorite: json['isFavorite'] as bool? ?? false,
      thumbnailPath: json['thumbnailPath'] as String?,
      fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
    );
  }

  ScannedDocument copyWith({
    String? name,
    bool? isFavorite,
    int? pageCount,
  }) {
    return ScannedDocument(
      id: id,
      name: name ?? this.name,
      filePath: filePath,
      createdAt: createdAt,
      fileType: fileType,
      pageCount: pageCount ?? this.pageCount,
      isFavorite: isFavorite ?? this.isFavorite,
      thumbnailPath: thumbnailPath,
      fileSizeBytes: fileSizeBytes,
    );
  }
}

/// Premium subscription plan model.
class PremiumPlan {
  const PremiumPlan({
    required this.id,
    required this.title,
    required this.price,
    required this.period,
    required this.isPopular,
    this.savings,
  });

  final String id;
  final String title;
  final String price;
  final String period;
  final bool isPopular;
  final String? savings;
}

/// Onboarding slide content.
class OnboardingSlide {
  const OnboardingSlide({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final int icon; // Icons codePoint
  final int color; // Color value
}

List<OnboardingSlide> get defaultOnboardingSlides => const [
      OnboardingSlide(
        title: 'Scan Documents Instantly',
        subtitle:
            'Capture receipts, forms, certificates, and notes with auto edge detection and HD enhancement.',
        icon: 0xe3ae, // document_scanner
        color: 0xFF1A73E8,
      ),
      OnboardingSlide(
        title: 'Smart Card Scanner',
        subtitle:
            'Scan ID cards, passports, and business cards. Combine front and back into one professional PDF.',
        icon: 0xe870, // credit_card
        color: 0xFF4285F4,
      ),
      OnboardingSlide(
        title: 'Create & Share PDFs',
        subtitle:
            'Convert images to PDF, reorder pages, apply filters, and share instantly on WhatsApp or Gmail.',
        icon: 0xe873, // picture_as_pdf
        color: 0xFF0D47A1,
      ),
    ];

String encodeDocuments(List<ScannedDocument> docs) =>
    jsonEncode(docs.map((d) => d.toJson()).toList());

List<ScannedDocument> decodeDocuments(String raw) {
  final list = jsonDecode(raw) as List<dynamic>;
  return list
      .map((e) => ScannedDocument.fromJson(e as Map<String, dynamic>))
      .toList();
}
