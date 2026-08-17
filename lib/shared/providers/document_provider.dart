import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../shared/models/scan_types.dart';
import '../models/scan_session.dart';
import '../services/document_service.dart';

class DocumentProvider extends ChangeNotifier {
  DocumentProvider(this._documentService) {
    _loadDocuments();
  }

  final DocumentService _documentService;

  List<ScannedDocument> _documents = [];
  bool _isLoading = false;
  Completer<void>? _loadCompleter;
  bool _hasLoadedOnce = false;
  String _searchQuery = '';
  DocumentSortBy _sortBy = DocumentSortBy.date;
  DocumentFileType _fileTypeFilter = DocumentFileType.all;
  FileCategoryFilter _categoryFilter = FileCategoryFilter.all;
  bool _sortNewestFirst = true;

  List<ScannedDocument> get documents => _filteredAndSorted;
  FileCategoryFilter get categoryFilter => _categoryFilter;
  bool get sortNewestFirst => _sortNewestFirst;
  int get totalDocumentCount => _documents.length;
  List<ScannedDocument> get recentDocuments =>
      List<ScannedDocument>.from(_documents)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  DocumentSortBy get sortBy => _sortBy;
  DocumentFileType get fileTypeFilter => _fileTypeFilter;

  List<ScannedDocument> get favorites =>
      _documents.where((d) => d.isFavorite).toList();

  int categoryCount(FileCategoryFilter category) {
    if (category == FileCategoryFilter.all) return _documents.length;
    return _documents.where((d) => _matchesCategory(d, category)).length;
  }

  bool _matchesCategory(ScannedDocument doc, FileCategoryFilter category) {
    return switch (category) {
      FileCategoryFilter.all => true,
      FileCategoryFilter.pdf => doc.fileType == 'pdf',
      FileCategoryFilter.images => doc.fileType == 'image',
      FileCategoryFilter.docs => _isDocFile(doc.name),
      FileCategoryFilter.others =>
        doc.fileType != 'pdf' && doc.fileType != 'image' && !_isDocFile(doc.name),
    };
  }

  bool _isDocFile(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.doc') ||
        lower.endsWith('.docx') ||
        lower.endsWith('.txt') ||
        lower.endsWith('.rtf');
  }

  List<ScannedDocument> get _filteredAndSorted {
    var list = List<ScannedDocument>.from(_documents);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((d) => d.name.toLowerCase().contains(q)).toList();
    }

    if (_categoryFilter != FileCategoryFilter.all) {
      list = list.where((d) => _matchesCategory(d, _categoryFilter)).toList();
    } else if (_fileTypeFilter != DocumentFileType.all) {
      final type = _fileTypeFilter == DocumentFileType.pdf ? 'pdf' : 'image';
      list = list.where((d) => d.fileType == type).toList();
    }

    switch (_sortBy) {
      case DocumentSortBy.date:
        list.sort(
          (a, b) => _sortNewestFirst
              ? b.createdAt.compareTo(a.createdAt)
              : a.createdAt.compareTo(b.createdAt),
        );
      case DocumentSortBy.name:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case DocumentSortBy.type:
        list.sort((a, b) => a.fileType.compareTo(b.fileType));
    }

    return list;
  }

  Future<void> _loadDocuments() async {
    _isLoading = true;
    _loadCompleter ??= Completer<void>();
    notifyListeners();
    try {
      _documents = await _documentService.loadDocuments();
    } finally {
      _isLoading = false;
      _hasLoadedOnce = true;
      if (!(_loadCompleter?.isCompleted ?? true)) {
        _loadCompleter!.complete();
      }
      _loadCompleter = null;
      notifyListeners();
    }
  }

  /// Waits until documents have been loaded at least once.
  Future<void> ensureLoaded() async {
    if (_hasLoadedOnce && !_isLoading) return;
    _loadCompleter ??= Completer<void>();
    return _loadCompleter!.future;
  }

  Future<void> refresh() => _loadDocuments();

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSortBy(DocumentSortBy sort) {
    _sortBy = sort;
    notifyListeners();
  }

  void setFileTypeFilter(DocumentFileType type) {
    _fileTypeFilter = type;
    notifyListeners();
  }

  void setCategoryFilter(FileCategoryFilter category) {
    _categoryFilter = category;
    _fileTypeFilter = DocumentFileType.all;
    notifyListeners();
  }

  void setSort(DocumentSortBy sort, {bool? newestFirst}) {
    _sortBy = sort;
    if (newestFirst != null) _sortNewestFirst = newestFirst;
    notifyListeners();
  }

  Future<ScannedDocument?> savePdf({
    required ScanSession session,
    required List<Uint8List> pageBytes,
  }) async {
    final doc = await _documentService.savePdfDocument(
      session: session,
      pageBytes: pageBytes,
    );
    if (doc != null) {
      _documents.insert(0, doc);
      notifyListeners();
    }
    return doc;
  }

  Future<ScannedDocument?> addRawPdf({
    required String name,
    required Uint8List bytes,
    int pageCount = 1,
    Uint8List? thumbnailSource,
  }) async {
    final doc = await _documentService.saveRawPdf(
      name: name,
      bytes: bytes,
      pageCount: pageCount,
      thumbnailSource: thumbnailSource,
    );
    if (doc != null) {
      _documents.insert(0, doc);
      notifyListeners();
    }
    return doc;
  }

  Future<bool> renameDocument(String id, String newName) async {
    final success = await _documentService.renameDocument(id, newName);
    if (success) {
      final index = _documents.indexWhere((d) => d.id == id);
      if (index != -1) {
        _documents[index] = _documents[index].copyWith(name: newName);
        notifyListeners();
      }
    }
    return success;
  }

  Future<bool> deleteDocument(String id) async {
    final success = await _documentService.deleteDocument(id);
    if (success) {
      _documents.removeWhere((d) => d.id == id);
      notifyListeners();
    }
    return success;
  }

  Future<void> toggleFavorite(String id) async {
    final index = _documents.indexWhere((d) => d.id == id);
    if (index == -1) return;
    final updated = _documents[index].copyWith(
      isFavorite: !_documents[index].isFavorite,
    );
    await _documentService.updateDocument(updated);
    _documents[index] = updated;
    notifyListeners();
  }
}
