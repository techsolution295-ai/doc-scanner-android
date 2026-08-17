import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/constants/app_colors.dart';
import '../../app/routes/app_routes.dart';
import '../../shared/models/scan_types.dart';
import '../../app/routes/route_names.dart';
import '../../shared/animations/success_animation.dart';
import '../../shared/models/scan_session.dart';
import '../../shared/providers/document_provider.dart';
import '../../shared/services/image_processing_service.dart';
import '../../shared/services/pdf_service.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_loader.dart';

class PdfPreviewScreen extends StatefulWidget {
  const PdfPreviewScreen({super.key, required this.session});

  final ScanSession session;

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  late ScanSession _session;
  final _processor = ImageProcessingService.instance;
  final _pdfService = PdfService();
  bool _isCreating = false;
  List<Uint8List>? _processedPages;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _processPages();
  }

  Future<void> _processPages() async {
    final pages = <Uint8List>[];
    for (final page in _session.pages) {
      final data = page.imageData;
      pages.add(await _processor.processImage(
        sourceBytes: data.bytes,
        filter: data.filter,
        brightness: data.brightness,
        contrast: data.contrast,
        rotation: data.rotation,
      ));
    }
    if (mounted) setState(() => _processedPages = pages);
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final page = _session.pages.removeAt(oldIndex);
      _session.pages.insert(newIndex, page);
      final bytes = _processedPages!.removeAt(oldIndex);
      _processedPages!.insert(newIndex, bytes);
    });
  }

  void _deletePage(int index) {
    if (_session.pages.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF must have at least one page.')),
      );
      return;
    }
    setState(() {
      _session.pages.removeAt(index);
      _processedPages?.removeAt(index);
    });
  }

  Future<void> _addMorePages() async {
    Navigator.of(context).pushNamed(
      RouteNames.scanner,
      arguments: ScannerArgs(isBatchMode: true, existingSession: _session),
    );
  }

  Future<void> _renameDocument() async {
    final controller = TextEditingController(text: _session.title);
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename Document'),
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
      setState(() => _session.title = name);
    }
  }

  Future<void> _createPdf({bool shareAfter = false}) async {
    if (_processedPages == null || _processedPages!.isEmpty || _isCreating) return;

    setState(() => _isCreating = true);
    AppLoader.show(
      context,
      message: shareAfter ? 'Preparing share…' : 'Saving PDF…',
    );

    final provider = context.read<DocumentProvider>();
    final doc = await provider.savePdf(
      session: _session,
      pageBytes: _processedPages!,
    );

    if (!mounted) return;
    AppLoader.hide(context);
    setState(() => _isCreating = false);

    if (doc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create PDF. Please try again.')),
      );
      return;
    }

    if (shareAfter) {
      await Share.shareXFiles([XFile(doc.filePath)], text: doc.name);
    } else {
      await showDialog<void>(
        context: context,
        builder: (_) => SuccessAnimation(
          message: 'PDF saved successfully!\n${doc.name}',
          onDone: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
      );
    }
  }

  Future<void> _printPdf() async {
    if (_processedPages == null || _processedPages!.isEmpty || _isCreating) return;

    setState(() => _isCreating = true);
    AppLoader.show(context, message: 'Preparing print…');
    try {
      final bytes = await _pdfService.createPdf(
        pages: _processedPages!,
        quality: _session.pdfQuality,
        compress: _session.compressPdf,
        title: _session.title,
      );
      if (!mounted) return;
      AppLoader.hide(context);
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (_) {
      if (!mounted) return;
      AppLoader.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not print. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_session.title),
        actions: [
          IconButton(icon: const Icon(Icons.edit_rounded), onPressed: _renameDocument),
        ],
      ),
      body: _processedPages == null
          ? const AppLoadingView(message: 'Preparing preview…')
          : Column(
              children: [
                _QualityOptions(
                  quality: _session.pdfQuality,
                  compress: _session.compressPdf,
                  onQualityChanged: (q) => setState(() => _session.pdfQuality = q),
                  onCompressChanged: (v) => setState(() => _session.compressPdf = v),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _session.pages.length,
                    onReorder: _reorder,
                    itemBuilder: (context, index) {
                      return Card(
                        key: ValueKey(_session.pages[index].id),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              _processedPages![index],
                              width: 48,
                              height: 64,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text('Page ${index + 1}'),
                          subtitle: const Text('Drag to reorder'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.drag_handle),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.errorRed),
                                onPressed: () => _deletePage(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_isCreating) const LinearProgressIndicator(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      AppButton(
                        label: 'Add More Pages',
                        icon: Icons.add_rounded,
                        isOutlined: true,
                        onPressed: _addMorePages,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: 'Print',
                              icon: Icons.print_rounded,
                              isOutlined: true,
                              isLoading: _isCreating,
                              onPressed: _printPdf,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppButton(
                              label: 'Share',
                              icon: Icons.share_rounded,
                              color: AppColors.successGreen,
                              isLoading: _isCreating,
                              onPressed: () => _createPdf(shareAfter: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        label: 'Save PDF',
                        icon: Icons.save_rounded,
                        isLoading: _isCreating,
                        onPressed: () => _createPdf(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _QualityOptions extends StatelessWidget {
  const _QualityOptions({
    required this.quality,
    required this.compress,
    required this.onQualityChanged,
    required this.onCompressChanged,
  });

  final PdfQuality quality;
  final bool compress;
  final ValueChanged<PdfQuality> onQualityChanged;
  final ValueChanged<bool> onCompressChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.lightBlue.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PDF Quality', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<PdfQuality>(
            segments: const [
              ButtonSegment(value: PdfQuality.low, label: Text('Low')),
              ButtonSegment(value: PdfQuality.medium, label: Text('Medium')),
              ButtonSegment(value: PdfQuality.high, label: Text('High')),
            ],
            selected: {quality},
            onSelectionChanged: (s) => onQualityChanged(s.first),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Compress PDF'),
            subtitle: const Text('Reduces file size by optimizing image quality'),
            value: compress,
            onChanged: onCompressChanged,
          ),
        ],
      ),
    );
  }
}
