import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/routes/route_names.dart';
import '../../shared/providers/document_provider.dart';
import '../../shared/services/pdf_tools_service.dart';
import '../../shared/widgets/app_loader.dart';
import '../home/home_constants.dart';
import '../pdf_viewer/pdf_viewer_screen.dart';

enum PdfEditMode { organize, reorder, rotate, watermark, toImage }

class PdfEditScreen extends StatefulWidget {
  const PdfEditScreen({
    super.key,
    required this.bytes,
    required this.name,
    required this.mode,
  });

  final Uint8List bytes;
  final String name;
  final PdfEditMode mode;

  @override
  State<PdfEditScreen> createState() => _PdfEditScreenState();
}

class _PdfEditScreenState extends State<PdfEditScreen> {
  final _service = PdfToolsService.instance;

  bool _loading = true;
  bool _busy = false;
  List<Uint8List> _thumbs = [];

  /// Remaining/ordered original page indexes (organize + reorder).
  List<int> _order = [];

  /// Per original page index quarter turns (rotate).
  final Map<int, int> _turns = {};

  final _watermarkController = TextEditingController(text: 'CONFIDENTIAL');

  @override
  void initState() {
    super.initState();
    _renderThumbnails();
  }

  @override
  void dispose() {
    _watermarkController.dispose();
    super.dispose();
  }

  Future<void> _renderThumbnails() async {
    try {
      final dpi = widget.mode == PdfEditMode.toImage ? 200.0 : 70.0;
      final imgs = await _service.pdfToImages(widget.bytes, dpi: dpi);
      if (!mounted) return;
      setState(() {
        _thumbs = imgs;
        _order = List<int>.generate(imgs.length, (i) => i);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read this PDF.')),
      );
      Navigator.of(context).pop();
    }
  }

  String get _title => switch (widget.mode) {
        PdfEditMode.organize => 'Manage Pages',
        PdfEditMode.reorder => 'Reorder Pages',
        PdfEditMode.rotate => 'Rotate Pages',
        PdfEditMode.watermark => 'Add Watermark',
        PdfEditMode.toImage => 'PDF to Image',
      };

  Future<Uint8List> _process() {
    switch (widget.mode) {
      case PdfEditMode.organize:
      case PdfEditMode.reorder:
        return _service.buildFromPages(widget.bytes, _order);
      case PdfEditMode.rotate:
        return _service.rotateIndividual(widget.bytes, _turns);
      case PdfEditMode.watermark:
        return _service.addWatermark(widget.bytes, _watermarkController.text.trim());
      case PdfEditMode.toImage:
        throw UnimplementedError();
    }
  }

  bool get _canSave {
    if (widget.mode == PdfEditMode.organize || widget.mode == PdfEditMode.toImage) {
      return _order.isNotEmpty;
    }
    if (widget.mode == PdfEditMode.watermark) {
      return _watermarkController.text.trim().isNotEmpty;
    }
    return true;
  }

  bool get _isImageMode => widget.mode == PdfEditMode.toImage;

  List<Uint8List> get _selectedImages =>
      [for (final i in _order) if (i >= 0 && i < _thumbs.length) _thumbs[i]];

  Future<void> _saveToGallery() async {
    if (!_canSave || _busy) return;
    setState(() => _busy = true);
    AppLoader.show(context, message: 'Saving to gallery…');
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          if (mounted) AppLoader.hide(context);
          _snack('Gallery permission is required to save images.');
          return;
        }
      }
      final images = _selectedImages;
      for (var i = 0; i < images.length; i++) {
        await Gal.putImageBytes(images[i], name: '${widget.name}_page_${i + 1}');
      }
      if (mounted) AppLoader.hide(context);
      _snack('${images.length} image(s) saved to gallery.');
    } catch (_) {
      if (mounted) AppLoader.hide(context);
      _snack('Could not save images to gallery.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareImages() async {
    if (!_canSave || _busy) return;
    setState(() => _busy = true);
    AppLoader.show(context, message: 'Preparing share…');
    try {
      final images = _selectedImages;
      final dir = await getTemporaryDirectory();
      final files = <XFile>[];
      for (var i = 0; i < images.length; i++) {
        final path = '${dir.path}/${widget.name}_page_${i + 1}.png';
        await File(path).writeAsBytes(images[i]);
        files.add(XFile(path));
      }
      if (!mounted) return;
      AppLoader.hide(context);
      await Share.shareXFiles(files, text: widget.name);
    } catch (_) {
      if (mounted) AppLoader.hide(context);
      _snack('Could not share images.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (!_canSave || _busy) return;
    setState(() => _busy = true);
    AppLoader.show(context, message: 'Saving PDF…');
    try {
      final result = await _process();
      if (!mounted) return;
      final provider = context.read<DocumentProvider>();
      final doc = await provider.addRawPdf(
        name: '${widget.name} (${_suffix()})',
        bytes: result,
      );
      if (!mounted) return;
      AppLoader.hide(context);
      if (doc == null) {
        _snack('Could not save the file.');
        return;
      }
      Navigator.of(context).pushReplacementNamed(
        RouteNames.pdfViewer,
        arguments: PdfViewerArgs(filePath: doc.filePath, title: doc.name),
      );
    } catch (_) {
      if (mounted) AppLoader.hide(context);
      _snack('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _print() async {
    if (!_canSave || _busy) return;
    setState(() => _busy = true);
    AppLoader.show(context, message: 'Preparing print…');
    try {
      final result = await _process();
      if (!mounted) return;
      AppLoader.hide(context);
      await Printing.layoutPdf(onLayout: (_) async => result);
    } catch (_) {
      if (mounted) AppLoader.hide(context);
      _snack('Could not print. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _suffix() => switch (widget.mode) {
        PdfEditMode.organize => 'Edited',
        PdfEditMode.reorder => 'Reordered',
        PdfEditMode.rotate => 'Rotated',
        PdfEditMode.watermark => 'Watermarked',
        PdfEditMode.toImage => 'Image',
      };

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeConstants.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.5,
        foregroundColor: HomeConstants.navyText,
        title: Text(
          _title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: HomeConstants.navyText,
          ),
        ),
      ),
      body: _loading
          ? const AppLoadingView(message: 'Loading pages…')
          : Column(
              children: [
                Expanded(child: _buildBody()),
                _buildBottomBar(),
              ],
            ),
    );
  }

  Widget _buildBody() {
    switch (widget.mode) {
      case PdfEditMode.reorder:
        return _buildReorderList();
      case PdfEditMode.watermark:
        return _buildWatermarkEditor();
      case PdfEditMode.organize:
      case PdfEditMode.rotate:
      case PdfEditMode.toImage:
        return _buildPageGrid();
    }
  }

  Widget _buildPageGrid() {
    final isRotate = widget.mode == PdfEditMode.rotate;
    final indexes = isRotate ? List<int>.generate(_thumbs.length, (i) => i) : _order;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.66,
      ),
      itemCount: indexes.length,
      itemBuilder: (_, i) {
        final orig = indexes[i];
        return _PageCard(
          image: _thumbs[orig],
          pageLabel: 'Page ${orig + 1}',
          rotationTurns: _turns[orig] ?? 0,
          trailing: isRotate
              ? _RoundIconButton(
                  icon: Icons.rotate_right_rounded,
                  color: HomeConstants.linkBlue,
                  onTap: () => setState(() {
                    _turns[orig] = ((_turns[orig] ?? 0) + 1) % 4;
                  }),
                )
              : _RoundIconButton(
                  icon: Icons.close_rounded,
                  color: const Color(0xFFEF4444),
                  onTap: _order.length <= 1
                      ? null
                      : () => setState(() => _order.remove(orig)),
                ),
        );
      },
    );
  }

  Widget _buildReorderList() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _order.length,
      onReorder: (oldIndex, newIndex) => setState(() {
        if (newIndex > oldIndex) newIndex--;
        final item = _order.removeAt(oldIndex);
        _order.insert(newIndex, item);
      }),
      itemBuilder: (_, i) {
        final orig = _order[i];
        return Container(
          key: ValueKey(orig),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEEF2F7)),
            boxShadow: [HomeConstants.softShadow(blur: 10, y: 3, opacity: 0.04)],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 72,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  image: DecorationImage(
                    image: MemoryImage(_thumbs[orig]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Page ${orig + 1}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: HomeConstants.navyText,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Text(
                  '#${i + 1}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: HomeConstants.greySubtitle,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.drag_handle_rounded, color: HomeConstants.greySubtitle),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWatermarkEditor() {
    final firstThumb = _thumbs.isNotEmpty ? _thumbs.first : null;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (firstThumb != null)
            AspectRatio(
              aspectRatio: 0.72,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  image: DecorationImage(image: MemoryImage(firstThumb), fit: BoxFit.contain),
                ),
                child: Center(
                  child: Transform.rotate(
                    angle: -0.7,
                    child: Text(
                      _watermarkController.text.trim(),
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 20),
          TextField(
            controller: _watermarkController,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Watermark text',
              hintText: 'e.g. CONFIDENTIAL',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'The watermark is applied diagonally across every page.',
              style: TextStyle(fontSize: 12.5, color: HomeConstants.greySubtitle),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final secondaryLabel = _isImageMode ? 'Share' : 'Print';
    final secondaryIcon = _isImageMode ? Icons.share_outlined : Icons.print_rounded;
    final primaryLabel = _isImageMode ? 'Save to Gallery' : 'Save';
    final onSecondary = _isImageMode ? _shareImages : _print;
    final onPrimary = _isImageMode ? _saveToGallery : _save;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _busy || !_canSave ? null : onSecondary,
              icon: Icon(secondaryIcon, size: 20),
              style: OutlinedButton.styleFrom(
                foregroundColor: HomeConstants.linkBlue,
                side: const BorderSide(color: HomeConstants.linkBlue),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              label: Text(secondaryLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _busy || !_canSave ? null : onPrimary,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(_isImageMode ? Icons.download_rounded : Icons.save_alt_rounded, size: 20),
              style: ElevatedButton.styleFrom(
                backgroundColor: HomeConstants.linkBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              label: Text(primaryLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageCard extends StatelessWidget {
  const _PageCard({
    required this.image,
    required this.pageLabel,
    required this.trailing,
    this.rotationTurns = 0,
  });

  final Uint8List image;
  final String pageLabel;
  final Widget trailing;
  final int rotationTurns;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Transform.rotate(
                    angle: rotationTurns * 1.5707963,
                    child: Image.memory(image, fit: BoxFit.contain),
                  ),
                ),
              ),
              Positioned(top: 4, right: 4, child: trailing),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          pageLabel,
          style: const TextStyle(fontSize: 11, color: HomeConstants.greySubtitle),
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.color, this.onTap});

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap == null ? Colors.grey.shade300 : color,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
      ),
    );
  }
}
