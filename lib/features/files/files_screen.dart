import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/constants/app_colors.dart';
import '../../app/routes/route_names.dart';
import '../../shared/models/scan_session.dart';
import '../../shared/models/scan_types.dart';
import '../../shared/providers/document_provider.dart';
import '../../shared/widgets/app_animations.dart';
import '../../shared/widgets/app_loader.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../pdf_viewer/pdf_viewer_screen.dart';
import 'files_constants.dart';
import 'widgets/files_category_chips.dart';
import 'widgets/files_header.dart';
import 'widgets/files_list_item.dart';
import 'widgets/files_search_bar.dart';
import 'widgets/files_toolbar.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  final _searchController = TextEditingController();
  FilesViewMode _viewMode = FilesViewMode.list;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentProvider>().refresh();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FilesConstants.background,
      body: SafeArea(
        bottom: false,
        child: Consumer<DocumentProvider>(
          builder: (context, provider, _) {
            final counts = {
              for (final c in FileCategoryFilter.values) c: provider.categoryCount(c),
            };

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilesHeader(showBack: !widget.embedded).fadeSlideIn(delayMs: 0),
                FilesSearchBar(
                  controller: _searchController,
                  onChanged: provider.setSearchQuery,
                ).fadeSlideIn(delayMs: 60),
                FilesCategoryChips(
                  selected: provider.categoryFilter,
                  counts: counts,
                  onSelected: provider.setCategoryFilter,
                ).fadeSlideIn(delayMs: 120),
                FilesToolbar(
                  sortLabel: FilesToolbar.sortLabelFor(provider.sortBy, provider.sortNewestFirst),
                  viewMode: _viewMode,
                  onSortTap: () => _showSortSheet(provider),
                  onViewModeChanged: (mode) => setState(() => _viewMode = mode),
                ).fadeSlideIn(delayMs: 180),
                Expanded(
                  child: provider.isLoading
                      ? const AppLoadingView(message: 'Loading files…')
                      : provider.documents.isEmpty
                          ? EmptyStateWidget(
                              icon: Icons.folder_open_rounded,
                              title: provider.searchQuery.isNotEmpty
                                  ? 'No results found'
                                  : 'No documents yet',
                              subtitle: provider.searchQuery.isNotEmpty
                                  ? 'Try a different search term.'
                                  : 'Scanned documents and PDFs will appear here.',
                            )
                          : RefreshIndicator(
                              onRefresh: provider.refresh,
                              child: _viewMode == FilesViewMode.list
                                  ? _FilesList(
                                      documents: provider.documents,
                                      bottomPadding: widget.embedded ? 120 : 24,
                                      onOpen: _openDocument,
                                      onFavorite: (id) => provider.toggleFavorite(id),
                                      onMore: (doc, p) => _showDocMenu(p, doc),
                                    )
                                  : _FilesGrid(
                                      documents: provider.documents,
                                      bottomPadding: widget.embedded ? 120 : 24,
                                      onOpen: _openDocument,
                                      onFavorite: (id) => provider.toggleFavorite(id),
                                    ),
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _showSortSheet(DocumentProvider provider) async {
    final result = await showModalBottomSheet<_SortChoice>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SortSheet(
        current: provider.sortBy,
        newestFirst: provider.sortNewestFirst,
      ),
    );
    if (result != null) {
      provider.setSort(result.sort, newestFirst: result.newestFirst);
    }
  }

  void _showDocMenu(DocumentProvider provider, ScannedDocument doc) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                Share.shareXFiles([XFile(doc.filePath)], text: doc.name);
              },
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline_rounded),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(context);
                _renameDoc(provider, doc);
              },
            ),
            ListTile(
              leading: Icon(doc.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded),
              title: Text(doc.isFavorite ? 'Remove from favorites' : 'Add to favorites'),
              onTap: () {
                Navigator.pop(context);
                provider.toggleFavorite(doc.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.errorRed),
              title: const Text('Delete', style: TextStyle(color: AppColors.errorRed)),
              onTap: () {
                Navigator.pop(context);
                _deleteDoc(provider, doc.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDocument(ScannedDocument doc) async {
    if (await File(doc.filePath).exists()) {
      if (!mounted) return;
      Navigator.of(context).pushNamed(
        RouteNames.pdfViewer,
        arguments: PdfViewerArgs(filePath: doc.filePath, title: doc.name),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File no longer exists.')),
      );
    }
  }

  Future<void> _deleteDoc(DocumentProvider provider, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete document?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
    if (ok == true) await provider.deleteDocument(id);
  }

  Future<void> _renameDoc(DocumentProvider provider, ScannedDocument doc) async {
    final controller = TextEditingController(text: doc.name);
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await provider.renameDocument(doc.id, name);
    }
  }
}

class _FilesList extends StatelessWidget {
  const _FilesList({
    required this.documents,
    required this.bottomPadding,
    required this.onOpen,
    required this.onFavorite,
    required this.onMore,
  });

  final List<ScannedDocument> documents;
  final double bottomPadding;
  final ValueChanged<ScannedDocument> onOpen;
  final ValueChanged<String> onFavorite;
  final void Function(ScannedDocument, DocumentProvider) onMore;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<DocumentProvider>();

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: EdgeInsets.fromLTRB(FilesConstants.screenPadding, 14, FilesConstants.screenPadding, bottomPadding),
      itemCount: documents.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final doc = documents[i];
        return FilesListItem(
          document: doc,
          onTap: () => onOpen(doc),
          onFavorite: () => onFavorite(doc.id),
          onMore: () => onMore(doc, provider),
        ).fadeSlideIn(delayMs: 200, index: i, slideY: 0.05);
      },
    );
  }
}

class _FilesGrid extends StatelessWidget {
  const _FilesGrid({
    required this.documents,
    required this.bottomPadding,
    required this.onOpen,
    required this.onFavorite,
  });

  final List<ScannedDocument> documents;
  final double bottomPadding;
  final ValueChanged<ScannedDocument> onOpen;
  final ValueChanged<String> onFavorite;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: EdgeInsets.fromLTRB(FilesConstants.screenPadding, 14, FilesConstants.screenPadding, bottomPadding),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.92,
      ),
      itemCount: documents.length,
      itemBuilder: (_, i) {
        final doc = documents[i];
        return FilesGridItem(
          document: doc,
          onTap: () => onOpen(doc),
          onFavorite: () => onFavorite(doc.id),
        ).fadeScaleIn(delayMs: 200, index: i);
      },
    );
  }
}

class _SortChoice {
  const _SortChoice(this.sort, {this.newestFirst = true});

  final DocumentSortBy sort;
  final bool newestFirst;
}

class _SortSheet extends StatelessWidget {
  const _SortSheet({required this.current, required this.newestFirst});

  final DocumentSortBy current;
  final bool newestFirst;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sort by',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: FilesConstants.navyText),
          ),
          const SizedBox(height: 8),
          _sortTile(context, 'Newest First', current == DocumentSortBy.date && newestFirst,
              const _SortChoice(DocumentSortBy.date)),
          _sortTile(context, 'Oldest First', current == DocumentSortBy.date && !newestFirst,
              const _SortChoice(DocumentSortBy.date, newestFirst: false)),
          _sortTile(context, 'Name A-Z', current == DocumentSortBy.name, const _SortChoice(DocumentSortBy.name)),
          _sortTile(context, 'File Type', current == DocumentSortBy.type, const _SortChoice(DocumentSortBy.type)),
        ],
      ),
    );
  }

  Widget _sortTile(BuildContext context, String label, bool selected, _SortChoice choice) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: selected ? const Icon(Icons.check_rounded, color: FilesConstants.accentBlue) : null,
      onTap: () => Navigator.pop(context, choice),
    );
  }
}
