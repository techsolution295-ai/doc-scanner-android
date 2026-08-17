import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../app/constants/app_constants.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  Directory? _documentsDir;
  Directory? _thumbnailsDir;

  Future<Directory> get documentsDirectory async {
    if (_documentsDir != null) return _documentsDir!;
    final appDir = await getApplicationDocumentsDirectory();
    _documentsDir = Directory('${appDir.path}/${AppConstants.documentsFolder}');
    if (!await _documentsDir!.exists()) {
      await _documentsDir!.create(recursive: true);
    }
    return _documentsDir!;
  }

  Future<Directory> get thumbnailsDirectory async {
    if (_thumbnailsDir != null) return _thumbnailsDir!;
    final docs = await documentsDirectory;
    _thumbnailsDir = Directory('${docs.path}/thumbnails');
    if (!await _thumbnailsDir!.exists()) {
      await _thumbnailsDir!.create(recursive: true);
    }
    return _thumbnailsDir!;
  }

  Future<String> generateFilePath(String fileName) async {
    final dir = await documentsDirectory;
    return '${dir.path}/$fileName';
  }

  Future<int> getCacheSizeBytes() async {
    final dir = await documentsDirectory;
    if (!await dir.exists()) return 0;
    int total = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }

  Future<void> clearCache() async {
    final dir = await documentsDirectory;
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      _documentsDir = null;
      _thumbnailsDir = null;
      await documentsDirectory;
    }
  }
}
