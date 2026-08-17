import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../app/constants/app_constants.dart';
import '../models/scan_session.dart';
import 'pdf_service.dart';
import 'storage_service.dart';

class DocumentService {
  DocumentService(this._prefs);

  final SharedPreferences _prefs;
  final _uuid = const Uuid();
  final _pdfService = PdfService();
  final _storage = StorageService.instance;

  Future<List<ScannedDocument>> loadDocuments() async {
    final raw = _prefs.getString(AppConstants.prefsDocuments);
    if (raw == null || raw.isEmpty) return [];

    final docs = decodeDocuments(raw);
    final valid = <ScannedDocument>[];
    for (final doc in docs) {
      if (await File(doc.filePath).exists()) {
        valid.add(doc);
      }
    }
    if (valid.length != docs.length) {
      await _saveMetadata(valid);
    }
    return valid;
  }

  Future<ScannedDocument?> savePdfDocument({
    required ScanSession session,
    required List<Uint8List> pageBytes,
  }) async {
    try {
      final id = _uuid.v4();
      final safeName = _sanitizeFileName(session.title);
      final fileName = '${safeName}_${DateTime.now().millisecondsSinceEpoch}${AppConstants.pdfExtension}';
      final filePath = await _storage.generateFilePath(fileName);

      final pdfBytes = await _pdfService.createPdf(
        pages: pageBytes,
        quality: session.pdfQuality,
        compress: session.compressPdf,
        title: session.title,
      );

      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      String? thumbPath;
      if (pageBytes.isNotEmpty) {
        thumbPath = await _saveThumbnail(pageBytes.first, id);
      }

      final doc = ScannedDocument(
        id: id,
        name: session.title,
        filePath: filePath,
        createdAt: DateTime.now(),
        fileType: 'pdf',
        pageCount: pageBytes.length,
        thumbnailPath: thumbPath,
        fileSizeBytes: pdfBytes.length,
      );

      final docs = await loadDocuments();
      docs.insert(0, doc);
      await _saveMetadata(docs);
      return doc;
    } catch (e) {
      return null;
    }
  }

  /// Persists an already-built PDF (e.g. from PDF Tools) into the library.
  Future<ScannedDocument?> saveRawPdf({
    required String name,
    required Uint8List bytes,
    int pageCount = 1,
    Uint8List? thumbnailSource,
  }) async {
    try {
      final id = _uuid.v4();
      final safeName = _sanitizeFileName(name);
      final fileName =
          '${safeName}_${DateTime.now().millisecondsSinceEpoch}${AppConstants.pdfExtension}';
      final filePath = await _storage.generateFilePath(fileName);

      await File(filePath).writeAsBytes(bytes);

      String? thumbPath;
      if (thumbnailSource != null) {
        thumbPath = await _saveThumbnail(thumbnailSource, id);
      }

      final doc = ScannedDocument(
        id: id,
        name: name,
        filePath: filePath,
        createdAt: DateTime.now(),
        fileType: 'pdf',
        pageCount: pageCount,
        thumbnailPath: thumbPath,
        fileSizeBytes: bytes.length,
      );

      final docs = await loadDocuments();
      docs.insert(0, doc);
      await _saveMetadata(docs);
      return doc;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _saveThumbnail(Uint8List bytes, String id) async {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      final thumb = img.copyResize(decoded, width: 200);
      final thumbDir = await _storage.thumbnailsDirectory;
      final path = '${thumbDir.path}/$id.jpg';
      await File(path).writeAsBytes(img.encodeJpg(thumb, quality: 70));
      return path;
    } catch (_) {
      return null;
    }
  }

  Future<bool> renameDocument(String id, String newName) async {
    final docs = await loadDocuments();
    final index = docs.indexWhere((d) => d.id == id);
    if (index == -1) return false;
    docs[index] = docs[index].copyWith(name: newName);
    await _saveMetadata(docs);
    return true;
  }

  Future<bool> deleteDocument(String id) async {
    final docs = await loadDocuments();
    final index = docs.indexWhere((d) => d.id == id);
    if (index == -1) return false;

    final doc = docs[index];
    try {
      final file = File(doc.filePath);
      if (await file.exists()) await file.delete();
      if (doc.thumbnailPath != null) {
        final thumb = File(doc.thumbnailPath!);
        if (await thumb.exists()) await thumb.delete();
      }
    } catch (_) {}

    docs.removeAt(index);
    await _saveMetadata(docs);
    return true;
  }

  Future<void> updateDocument(ScannedDocument doc) async {
    final docs = await loadDocuments();
    final index = docs.indexWhere((d) => d.id == doc.id);
    if (index != -1) {
      docs[index] = doc;
      await _saveMetadata(docs);
    }
  }

  Future<void> _saveMetadata(List<ScannedDocument> docs) async {
    await _prefs.setString(AppConstants.prefsDocuments, encodeDocuments(docs));
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
  }
}
