import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/constants/app_assets.dart';
import '../../app/routes/route_names.dart';
import '../../shared/providers/document_provider.dart';
import '../../shared/services/pdf_tools_service.dart';
import '../../shared/widgets/app_loader.dart';
import '../image_to_pdf/image_to_pdf_flow.dart';
import '../pdf_viewer/pdf_viewer_screen.dart';
import 'pdf_compress_screen.dart';
import 'pdf_edit_screen.dart';
import 'pdf_redact_screen.dart';
import 'widgets/pdf_tool_section.dart';
import 'widgets/pdf_tools_header.dart';

class PdfToolsScreen extends StatefulWidget {
  const PdfToolsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<PdfToolsScreen> createState() => _PdfToolsScreenState();
}

class _PdfToolsScreenState extends State<PdfToolsScreen> {
  final _service = PdfToolsService.instance;

  static final _sections = [
    (
      'Organize Pages',
      [
        PdfToolItem('Merge PDF', 'Combine multiple PDF files', AppAssets.toolMergePdf, PdfToolAction.merge),
        PdfToolItem('Split PDF', 'Split PDF into parts', AppAssets.toolSplitPdf, PdfToolAction.split),
        PdfToolItem('Reorder Pages', 'Rearrange page order', AppAssets.toolReorderPages, PdfToolAction.reorder),
      ],
    ),
    (
      'Optimize PDF',
      [
        PdfToolItem('Compress PDF', 'Reduce file size', AppAssets.toolCompressPdf, PdfToolAction.compress),
        PdfToolItem('Convert to PDF', 'Convert images to PDF', AppAssets.toolConvertPdf, PdfToolAction.convert),
        PdfToolItem('PDF to Image', 'Export pages as images', AppAssets.toolPdfToImage, PdfToolAction.pdfToImage),
      ],
    ),
    (
      'Edit PDF',
      [
        PdfToolItem('Rotate PDF', 'Rotate pages easily', AppAssets.toolRotatePdf, PdfToolAction.rotate),
        PdfToolItem('Delete Pages', 'Remove unwanted pages', AppAssets.toolDeletePages, PdfToolAction.delete),
        PdfToolItem('Add Watermark', 'Add a text watermark', AppAssets.toolWatermark, PdfToolAction.watermark),
      ],
    ),
    (
      'Security',
      [
        PdfToolItem('Lock PDF', 'Password protect PDF', AppAssets.toolLockPdf, PdfToolAction.lock),
        PdfToolItem('Unlock PDF', 'Remove PDF password', AppAssets.toolUnlockPdf, PdfToolAction.unlock),
        PdfToolItem('Redact PDF', 'Hide sensitive content', AppAssets.toolRedactPdf, PdfToolAction.redact),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PdfToolsHeader(showBack: !widget.embedded),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(bottom: widget.embedded ? 110 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const PdfToolsHeroBanner(),
                    for (var i = 0; i < _sections.length; i++)
                      PdfToolSection(
                        title: _sections[i].$1,
                        tools: _sections[i].$2,
                        sectionIndex: i,
                        onToolTap: _handleAction,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Action dispatch
  // ---------------------------------------------------------------------------

  Future<void> _handleAction(PdfToolAction action) async {
    switch (action) {
      case PdfToolAction.merge:
        await _merge();
      case PdfToolAction.split:
        await _split();
      case PdfToolAction.reorder:
        await _reorder();
      case PdfToolAction.compress:
        await _compress();
      case PdfToolAction.convert:
        await ImageToPdfFlow.start(context);
      case PdfToolAction.pdfToImage:
        await _pdfToImage();
      case PdfToolAction.rotate:
        await _rotate();
      case PdfToolAction.delete:
        await _delete();
      case PdfToolAction.watermark:
        await _watermark();
      case PdfToolAction.lock:
        await _lock();
      case PdfToolAction.unlock:
        await _unlock();
      case PdfToolAction.redact:
        await _redact();
    }
  }

  // ---------------------------------------------------------------------------
  // Tool implementations
  // ---------------------------------------------------------------------------

  Future<void> _merge() async {
    final files = await _pickPdfs(multiple: true);
    if (files == null || files.length < 2) {
      if (files != null) _snack('Select at least 2 PDF files to merge.');
      return;
    }
    final result = await _run(() => _service.mergePdfs(files.map((f) => f.bytes).toList()));
    if (result == null) return;
    await _deliverPdf(result, 'Merged Document');
  }

  Future<void> _split() async {
    final file = await _pickSinglePdf();
    if (file == null) return;
    _openEditor(file, PdfEditMode.organize);
  }

  Future<void> _reorder() async {
    final file = await _pickSinglePdf();
    if (file == null) return;
    _openEditor(file, PdfEditMode.reorder);
  }

  Future<void> _compress() async {
    final file = await _pickSinglePdf();
    if (file == null || !mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PdfCompressScreen(bytes: file.bytes, name: file.name),
      ),
    );
  }

  Future<void> _redact() async {
    final file = await _pickSinglePdf();
    if (file == null || !mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PdfRedactScreen(bytes: file.bytes, name: file.name),
      ),
    );
  }

  Future<void> _pdfToImage() async {
    final file = await _pickSinglePdf();
    if (file == null) return;
    _openEditor(file, PdfEditMode.toImage);
  }

  Future<void> _rotate() async {
    final file = await _pickSinglePdf();
    if (file == null) return;
    _openEditor(file, PdfEditMode.rotate);
  }

  Future<void> _delete() async {
    final file = await _pickSinglePdf();
    if (file == null) return;
    _openEditor(file, PdfEditMode.organize);
  }

  Future<void> _watermark() async {
    final file = await _pickSinglePdf();
    if (file == null) return;
    _openEditor(file, PdfEditMode.watermark);
  }

  void _openEditor(_PickedPdf file, PdfEditMode mode) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PdfEditScreen(bytes: file.bytes, name: file.name, mode: mode),
      ),
    );
  }

  Future<void> _lock() async {
    final file = await _pickSinglePdf();
    if (file == null) return;
    final password = await _showTextDialog(
      title: 'Set Password',
      hint: 'Enter password',
      obscure: true,
    );
    if (password == null || password.isEmpty) return;
    final result = await _run(() => _service.lockPdf(file.bytes, password));
    if (result == null) return;
    await _deliverPdf(result, '${file.name} (Locked)', openAfter: false,
        message: 'PDF locked and saved to My Files.');
  }

  Future<void> _unlock() async {
    final file = await _pickSinglePdf();
    if (file == null) return;

    // Not locked → just preview it.
    if (!_service.isEncrypted(file.bytes)) {
      if (!mounted) return;
      _snack('This PDF does not have a lock.');
      final doc = await context.read<DocumentProvider>().addRawPdf(
            name: file.name,
            bytes: file.bytes,
          );
      if (!mounted || doc == null) return;
      Navigator.of(context).pushNamed(
        RouteNames.pdfViewer,
        arguments: PdfViewerArgs(filePath: doc.filePath, title: doc.name),
      );
      return;
    }

    final password = await _showTextDialog(
      title: 'Enter Password',
      hint: 'PDF password',
      obscure: true,
    );
    if (password == null || password.isEmpty) return;
    final result = await _run(
      () => _service.unlockPdf(file.bytes, password),
      errorMessage: 'Wrong password. Please try again.',
    );
    if (result == null) return;
    await _deliverPdf(result, '${file.name} (Unlocked)');
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<List<_PickedPdf>?> _pickPdfs({bool multiple = false}) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: multiple,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final picked = <_PickedPdf>[];
    for (final f in result.files) {
      Uint8List? bytes = f.bytes;
      if (bytes == null && f.path != null) {
        bytes = await File(f.path!).readAsBytes();
      }
      if (bytes != null) {
        picked.add(_PickedPdf(_stripExtension(f.name), bytes));
      }
    }
    return picked.isEmpty ? null : picked;
  }

  Future<_PickedPdf?> _pickSinglePdf() async {
    final files = await _pickPdfs();
    return files?.first;
  }

  String _stripExtension(String name) {
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  /// Runs [task] behind a blocking loading dialog with error handling.
  Future<T?> _run<T>(Future<T> Function() task, {String? errorMessage}) async {
    return AppLoader.run(
      context,
      message: 'Processing…',
      errorMessage: errorMessage ?? 'Something went wrong. Please try again.',
      task: task,
    );
  }

  Future<void> _deliverPdf(
    Uint8List bytes,
    String name, {
    bool openAfter = true,
    String? message,
  }) async {
    if (!mounted) return;
    final doc = await context.read<DocumentProvider>().addRawPdf(
          name: name,
          bytes: bytes,
        );
    if (!mounted) return;
    if (doc == null) {
      _snack('Could not save the result.');
      return;
    }
    if (openAfter) {
      Navigator.of(context).pushNamed(
        RouteNames.pdfViewer,
        arguments: PdfViewerArgs(filePath: doc.filePath, title: doc.name),
      );
    }
    _snack(message ?? 'Saved to My Files.');
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<String?> _showTextDialog({
    required String title,
    required String hint,
    bool obscure = false,
  }) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: obscure,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

}

class _PickedPdf {
  const _PickedPdf(this.name, this.bytes);

  final String name;
  final Uint8List bytes;
}
