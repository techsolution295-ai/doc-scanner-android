import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes/route_names.dart';
import '../../shared/providers/document_provider.dart';
import '../../shared/services/pdf_tools_service.dart';
import '../../shared/widgets/app_loader.dart';
import '../home/home_constants.dart';
import '../pdf_viewer/pdf_viewer_screen.dart';

class PdfRedactScreen extends StatefulWidget {
  const PdfRedactScreen({super.key, required this.bytes, required this.name});

  final Uint8List bytes;
  final String name;

  @override
  State<PdfRedactScreen> createState() => _PdfRedactScreenState();
}

class _PdfRedactScreenState extends State<PdfRedactScreen> {
  final _service = PdfToolsService.instance;

  bool _loading = true;
  bool _busy = false;
  List<Uint8List> _pages = [];
  final List<Size> _sizes = [];
  late List<List<Rect>> _rects;

  int _index = 0;
  Rect? _dragRect;
  Offset? _dragStart;

  @override
  void initState() {
    super.initState();
    _render();
  }

  Future<void> _render() async {
    try {
      final imgs = await _service.pdfToImages(widget.bytes, dpi: 150);
      for (final bytes in imgs) {
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        _sizes.add(Size(frame.image.width.toDouble(), frame.image.height.toDouble()));
        frame.image.dispose();
      }
      if (!mounted) return;
      setState(() {
        _pages = imgs;
        _rects = List.generate(imgs.length, (_) => <Rect>[]);
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

  Size _displaySize(BoxConstraints c, int index) {
    final imgSize = _sizes[index];
    final aspect = imgSize.width / imgSize.height;
    var w = c.maxWidth;
    var h = w / aspect;
    if (h > c.maxHeight) {
      h = c.maxHeight;
      w = h * aspect;
    }
    return Size(w, h);
  }

  void _onPanStart(DragStartDetails d, Size box) {
    _dragStart = d.localPosition;
    setState(() => _dragRect = Rect.fromPoints(d.localPosition, d.localPosition));
  }

  void _onPanUpdate(DragUpdateDetails d, Size box) {
    if (_dragStart == null) return;
    final p = Offset(
      d.localPosition.dx.clamp(0, box.width),
      d.localPosition.dy.clamp(0, box.height),
    );
    setState(() => _dragRect = Rect.fromPoints(_dragStart!, p));
  }

  void _onPanEnd(Size box) {
    final r = _dragRect;
    _dragStart = null;
    if (r == null || r.width < 6 || r.height < 6) {
      setState(() => _dragRect = null);
      return;
    }
    final normalized = Rect.fromLTRB(
      r.left / box.width,
      r.top / box.height,
      r.right / box.width,
      r.bottom / box.height,
    );
    setState(() {
      _rects[_index].add(normalized);
      _dragRect = null;
    });
  }

  void _undo() {
    if (_rects[_index].isEmpty) return;
    setState(() => _rects[_index].removeLast());
  }

  void _clearPage() {
    if (_rects[_index].isEmpty) return;
    setState(() => _rects[_index].clear());
  }

  bool get _hasAnyRedaction => _rects.any((r) => r.isNotEmpty);

  Future<void> _save() async {
    if (_busy) return;
    if (!_hasAnyRedaction) {
      _snack('Draw at least one box to redact.');
      return;
    }
    setState(() => _busy = true);
    AppLoader.show(context, message: 'Applying redaction…');
    try {
      final result = await _service.buildRedactedPdf(_pages, _rects);
      if (!mounted) return;
      final doc = await context.read<DocumentProvider>().addRawPdf(
            name: '${widget.name} (Redacted)',
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

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.5,
        foregroundColor: HomeConstants.navyText,
        title: const Text('Redact PDF',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: HomeConstants.navyText)),
        actions: [
          IconButton(tooltip: 'Undo', onPressed: _loading ? null : _undo, icon: const Icon(Icons.undo_rounded)),
          IconButton(tooltip: 'Clear page', onPressed: _loading ? null : _clearPage, icon: const Icon(Icons.layers_clear_rounded)),
        ],
      ),
      body: _loading
          ? const AppLoadingView(message: 'Loading pages…')
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Text(
                    'Drag on the page to draw black boxes over sensitive content.',
                    style: TextStyle(fontSize: 12.5, color: HomeConstants.greySubtitle),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final box = _displaySize(constraints, _index);
                        return Center(
                          child: GestureDetector(
                            onPanStart: (d) => _onPanStart(d, box),
                            onPanUpdate: (d) => _onPanUpdate(d, box),
                            onPanEnd: (_) => _onPanEnd(box),
                            child: SizedBox(
                              width: box.width,
                              height: box.height,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Image.memory(_pages[_index], fit: BoxFit.fill),
                                  ),
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: _RedactPainter(
                                        rects: _rects[_index],
                                        dragRect: _dragRect,
                                        box: box,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                _buildPager(),
                _buildBottomBar(),
              ],
            ),
    );
  }

  Widget _buildPager() {
    if (_pages.length <= 1) return const SizedBox(height: 4);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _index > 0 ? () => setState(() => _index--) : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Text('Page ${_index + 1} / ${_pages.length}',
              style: const TextStyle(fontWeight: FontWeight.w600, color: HomeConstants.navyText)),
          IconButton(
            onPressed: _index < _pages.length - 1 ? () => setState(() => _index++) : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16, 6, 16, 12 + MediaQuery.paddingOf(context).bottom),
      child: SizedBox(
        height: 52,
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _busy ? null : _save,
          icon: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.save_alt_rounded),
          style: ElevatedButton.styleFrom(
            backgroundColor: HomeConstants.linkBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          label: Text(_busy ? 'Saving...' : 'Apply & Save',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ),
      ),
    );
  }
}

class _RedactPainter extends CustomPainter {
  _RedactPainter({required this.rects, required this.dragRect, required this.box});

  final List<Rect> rects;
  final Rect? dragRect;
  final Size box;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = Colors.black;
    for (final r in rects) {
      canvas.drawRect(
        Rect.fromLTRB(r.left * box.width, r.top * box.height, r.right * box.width, r.bottom * box.height),
        fill,
      );
    }
    if (dragRect != null) {
      canvas.drawRect(dragRect!, Paint()..color = Colors.black.withValues(alpha: 0.55));
      canvas.drawRect(
        dragRect!,
        Paint()
          ..color = HomeConstants.linkBlue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RedactPainter old) => true;
}
