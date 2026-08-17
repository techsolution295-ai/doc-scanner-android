import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../app/constants/app_colors.dart';
import '../../app/routes/route_names.dart';
import '../../shared/models/scan_session.dart';
import '../../shared/models/scan_types.dart';
import '../../shared/services/document_scanner_service.dart';
import '../../shared/services/image_processing_service.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_loader.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.session});

  final ScanSession session;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late ScanSession _session;
  int _currentPageIndex = 0;
  Uint8List? _displayBytes;
  bool _isProcessing = false;

  ScanFilterType _filter = ScanFilterType.original;
  double _brightness = 0.0;
  double _contrast = 1.0;
  int _rotation = 0;

  // Crop handles (normalized 0-1)
  double _cropLeft = 0.05;
  double _cropTop = 0.05;
  double _cropRight = 0.95;
  double _cropBottom = 0.95;
  bool _showCrop = false;

  final _processor = ImageProcessingService.instance;
  final _uuid = const Uuid();

  ScanPage get _currentPage => _session.pages[_currentPageIndex];

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _loadDisplayImage();
  }

  Future<void> _loadDisplayImage() async {
    setState(() => _isProcessing = true);
    final data = _currentPage.imageData;
    final bytes = await _processor.processImage(
      sourceBytes: data.bytes,
      filter: _filter,
      brightness: _brightness,
      contrast: _contrast,
      rotation: _rotation,
    );
    if (mounted) {
      setState(() {
        _displayBytes = bytes;
        _isProcessing = false;
      });
    }
  }

  Future<void> _applyCrop() async {
    setState(() => _isProcessing = true);
    final cropped = await _processor.cropImage(
      _currentPage.imageData.bytes,
      left: _cropLeft,
      top: _cropTop,
      right: _cropRight,
      bottom: _cropBottom,
    );
    _currentPage.imageData.bytes = cropped;
    _showCrop = false;
    _resetCropRect();
    await _loadDisplayImage();
  }

  void _rotate() {
    _rotation = (_rotation + 90) % 360;
    _loadDisplayImage();
  }

  Future<void> _savePageEdits() async {
    if (_displayBytes == null) return;
    _currentPage.imageData
      ..bytes = _displayBytes!
      ..filter = _filter
      ..brightness = _brightness
      ..contrast = _contrast
      ..rotation = _rotation;
  }

  Future<void> _addPage() async {
    await _savePageEdits();
    try {
      final pages = await DocumentScannerService.instance.scanPages(maxPages: 10);
      if (pages.isEmpty || !mounted) return;
      setState(() {
        for (final bytes in pages) {
          _session.pages.add(
            ScanPage(
              id: _uuid.v4(),
              imageData: ScanImageData(id: _uuid.v4(), bytes: bytes),
            ),
          );
        }
      });
      _goToPage(_session.pages.length - 1);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scanner is not available on this device.')),
      );
    }
  }

  void _goToPage(int index) {
    if (index < 0 || index >= _session.pages.length) return;
    setState(() {
      _currentPageIndex = index;
      _filter = _currentPage.imageData.filter;
      _brightness = _currentPage.imageData.brightness;
      _contrast = _currentPage.imageData.contrast;
      _rotation = _currentPage.imageData.rotation;
      _showCrop = false;
      _resetCropRect();
    });
    _loadDisplayImage();
  }

  void _resetCropRect() {
    _cropLeft = 0.05;
    _cropTop = 0.05;
    _cropRight = 0.95;
    _cropBottom = 0.95;
  }

  Future<void> _deletePage() async {
    if (_session.pages.length <= 1) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this page?'),
        content: const Text('This page will be removed from the document.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() {
      _session.pages.removeAt(_currentPageIndex);
      if (_currentPageIndex >= _session.pages.length) {
        _currentPageIndex = _session.pages.length - 1;
      }
    });
    _goToPage(_currentPageIndex);
  }

  Future<void> _continueToPreview() async {
    AppLoader.show(context, message: 'Preparing preview…');
    await _savePageEdits();
    if (!mounted) return;
    AppLoader.hide(context);
    Navigator.of(context).pushNamed(RouteNames.pdfPreview, arguments: _session);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit • Page ${_currentPageIndex + 1}/${_session.pages.length}'),
        actions: [
          if (_session.pages.length > 1) ...[
            IconButton(
              tooltip: 'Previous page',
              icon: const Icon(Icons.navigate_before_rounded),
              onPressed: _currentPageIndex > 0
                  ? () async {
                      await _savePageEdits();
                      _goToPage(_currentPageIndex - 1);
                    }
                  : null,
            ),
            IconButton(
              tooltip: 'Next page',
              icon: const Icon(Icons.navigate_next_rounded),
              onPressed: _currentPageIndex < _session.pages.length - 1
                  ? () async {
                      await _savePageEdits();
                      _goToPage(_currentPageIndex + 1);
                    }
                  : null,
            ),
            IconButton(
              tooltip: 'Delete page',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _deletePage,
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_displayBytes != null)
                  InteractiveViewer(
                    child: Image.memory(_displayBytes!, fit: BoxFit.contain),
                  )
                else
                  const AppLoadingView(message: 'Loading page…'),
                if (_isProcessing)
                  const ColoredBox(
                    color: Color(0x59000000),
                    child: Center(
                      child: AppLoaderCard(message: 'Processing…', compact: true),
                    ),
                  ),
                if (_showCrop)
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return CustomPaint(
                          size: Size(constraints.maxWidth, constraints.maxHeight),
                          painter: _CropOverlayPainter(
                            left: _cropLeft,
                            top: _cropTop,
                            right: _cropRight,
                            bottom: _cropBottom,
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          _ToolBar(
            onCrop: () => setState(() => _showCrop = !_showCrop),
            onRotate: _rotate,
            onFilters: () => _showFilterSheet(),
            onBrightness: () => _showAdjustSheet(),
            showCropActive: _showCrop,
          ),
          if (_showCrop)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Adjust crop area', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.swap_horiz_rounded, size: 20, color: AppColors.textSecondary),
                      Expanded(
                        child: RangeSlider(
                          values: RangeValues(_cropLeft, _cropRight),
                          onChanged: (v) {
                            if (v.end - v.start < 0.1) return;
                            setState(() {
                              _cropLeft = v.start;
                              _cropRight = v.end;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.swap_vert_rounded, size: 20, color: AppColors.textSecondary),
                      Expanded(
                        child: RangeSlider(
                          values: RangeValues(_cropTop, _cropBottom),
                          onChanged: (v) {
                            if (v.end - v.start < 0.1) return;
                            setState(() {
                              _cropTop = v.start;
                              _cropBottom = v.end;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Reset',
                          isOutlined: true,
                          onPressed: () => setState(_resetCropRect),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(label: 'Apply Crop', onPressed: _applyCrop),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Add Page',
                    icon: Icons.add_rounded,
                    isOutlined: true,
                    onPressed: _addPage,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Save & Preview PDF',
                    icon: Icons.picture_as_pdf_rounded,
                    onPressed: _continueToPreview,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SizedBox(
        height: 120,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(16),
          children: ScanFilterType.values.map((f) {
            final selected = _filter == f;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ChoiceChip(
                label: Text(f.label),
                selected: selected,
                onSelected: (_) {
                  _filter = f;
                  Navigator.pop(context);
                  _loadDisplayImage();
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showAdjustSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Brightness', style: Theme.of(context).textTheme.titleSmall),
              Slider(
                value: _brightness,
                min: -0.5,
                max: 0.5,
                onChanged: (v) {
                  setSheetState(() => _brightness = v);
                  setState(() => _brightness = v);
                  _loadDisplayImage();
                },
              ),
              Text('Contrast', style: Theme.of(context).textTheme.titleSmall),
              Slider(
                value: _contrast,
                min: 0.5,
                max: 2.0,
                onChanged: (v) {
                  setSheetState(() => _contrast = v);
                  setState(() => _contrast = v);
                  _loadDisplayImage();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolBar extends StatelessWidget {
  const _ToolBar({
    required this.onCrop,
    required this.onRotate,
    required this.onFilters,
    required this.onBrightness,
    required this.showCropActive,
  });

  final VoidCallback onCrop;
  final VoidCallback onRotate;
  final VoidCallback onFilters;
  final VoidCallback onBrightness;
  final bool showCropActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _Tool(icon: Icons.crop_rounded, label: 'Crop', onTap: onCrop, active: showCropActive),
          _Tool(icon: Icons.rotate_right_rounded, label: 'Rotate', onTap: onRotate),
          _Tool(icon: Icons.filter_rounded, label: 'Filters', onTap: onFilters),
          _Tool(icon: Icons.tune_rounded, label: 'Adjust', onTap: onBrightness),
        ],
      ),
    );
  }
}

class _Tool extends StatelessWidget {
  const _Tool({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? AppColors.primaryBlue : null),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: active ? AppColors.primaryBlue : AppColors.textSecondary,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CropOverlayPainter extends CustomPainter {
  _CropOverlayPainter({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final double left, top, right, bottom;

  @override
  void paint(Canvas canvas, Size size) {
    final cropRect = Rect.fromLTRB(
      size.width * left,
      size.height * top,
      size.width * right,
      size.height * bottom,
    );

    // Dim outside crop area using even-odd path (no black full-screen bug)
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(cropRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      overlayPath,
      Paint()..color = Colors.black.withValues(alpha: 0.5),
    );

    // Crop border with corner accents
    final borderPaint = Paint()
      ..color = AppColors.edgeOverlay
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawRect(cropRect, borderPaint);

    const cornerLen = 24.0;
    final cornerPaint = Paint()
      ..color = AppColors.edgeOverlay
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    void corner(Offset start, Offset hEnd, Offset vEnd) {
      canvas.drawLine(start, hEnd, cornerPaint);
      canvas.drawLine(start, vEnd, cornerPaint);
    }

    corner(cropRect.topLeft, cropRect.topLeft + const Offset(cornerLen, 0), cropRect.topLeft + const Offset(0, cornerLen));
    corner(cropRect.topRight, cropRect.topRight + const Offset(-cornerLen, 0), cropRect.topRight + const Offset(0, cornerLen));
    corner(cropRect.bottomLeft, cropRect.bottomLeft + const Offset(cornerLen, 0), cropRect.bottomLeft + const Offset(0, -cornerLen));
    corner(cropRect.bottomRight, cropRect.bottomRight + const Offset(-cornerLen, 0), cropRect.bottomRight + const Offset(0, -cornerLen));
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter old) => true;
}
