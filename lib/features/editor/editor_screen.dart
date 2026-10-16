import 'dart:async';
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
import '../../shared/widgets/banner_ad_widget.dart';

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
  int _imageWidth = 0;
  int _imageHeight = 0;

  ScanFilterType _filter = ScanFilterType.original;
  double _brightness = 0.0;
  double _contrast = 1.0;
  int _rotation = 0;

  double _cropLeft = 0.08;
  double _cropTop = 0.08;
  double _cropRight = 0.92;
  double _cropBottom = 0.92;
  bool _showCrop = false;

  final _processor = ImageProcessingService.instance;
  final _uuid = const Uuid();
  final _normalizedPages = <String>{};

  Timer? _previewDebounce;
  bool _previewRunning = false;
  bool _previewAgain = false;
  int _previewTicket = 0;

  ScanPage? get _currentPage {
    if (_currentPageIndex < 0 || _currentPageIndex >= _session.pages.length) {
      return null;
    }
    return _session.pages[_currentPageIndex];
  }

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _syncControlsFromPage();
    _preparePage();
  }

  @override
  void dispose() {
    _previewDebounce?.cancel();
    super.dispose();
  }

  void _syncControlsFromPage() {
    final page = _currentPage;
    if (page == null) return;
    final data = page.imageData;
    _filter = data.filter;
    _brightness = data.brightness;
    _contrast = data.contrast;
    _rotation = data.rotation;
  }

  Future<void> _preparePage() async {
    final page = _currentPage;
    if (page == null) return;
    final ticket = ++_previewTicket;
    setState(() => _isProcessing = true);
    try {
      if (!_normalizedPages.contains(page.id)) {
        var bytes = await _processor.normalize(
          page.imageData.bytes,
          force: true,
        );
        if (!mounted || ticket != _previewTicket) return;
        if (page.imageData.rotation != 0) {
          bytes = await _processor.processImage(
            sourceBytes: bytes,
            rotation: page.imageData.rotation,
          );
          page.imageData.rotation = 0;
          _rotation = 0;
        }
        if (!mounted || ticket != _previewTicket) return;
        page.imageData.bytes = bytes;
        _normalizedPages.add(page.id);
      }
      _rememberSize(page.imageData.bytes);
      await _loadDisplayImage();
    } catch (_) {
      if (!mounted || ticket != _previewTicket) return;
      setState(() {
        _displayBytes = page.imageData.bytes;
        _isProcessing = false;
      });
      _showMessage('Could not prepare this page.');
    }
  }

  void _rememberSize(Uint8List bytes) {
    final size = _processor.readSize(bytes);
    if (size == null) return;
    _imageWidth = size.width;
    _imageHeight = size.height;
  }

  void _schedulePreview() {
    _previewDebounce?.cancel();
    _previewDebounce = Timer(const Duration(milliseconds: 280), () {
      if (mounted) _loadDisplayImage();
    });
  }

  Future<void> _loadDisplayImage() async {
    final page = _currentPage;
    if (page == null) return;
    if (_previewRunning) {
      _previewAgain = true;
      return;
    }
    _previewRunning = true;
    final ticket = _previewTicket;
    if (mounted) setState(() => _isProcessing = true);
    try {
      do {
        _previewAgain = false;
        final filter = _filter;
        final brightness = _brightness;
        final contrast = _contrast;
        final rotation = _rotation;
        final source = page.imageData.bytes;
        final bytes = await _processor.processImage(
          sourceBytes: source,
          filter: filter,
          brightness: brightness,
          contrast: contrast,
          rotation: rotation,
        );
        if (!mounted ||
            ticket != _previewTicket ||
            _currentPage?.id != page.id) {
          return;
        }
        final stale =
            _filter != filter ||
            _brightness != brightness ||
            _contrast != contrast ||
            _rotation != rotation;
        if (stale) {
          _previewAgain = true;
          continue;
        }
        _rememberSize(bytes);
        setState(() {
          _displayBytes = bytes;
          _isProcessing = false;
        });
      } while (_previewAgain && mounted);
    } catch (_) {
      if (!mounted || ticket != _previewTicket) return;
      setState(() {
        _displayBytes ??= page.imageData.bytes;
        _isProcessing = false;
      });
      _showMessage('Could not update the preview.');
    } finally {
      _previewRunning = false;
      if (_previewAgain && mounted && ticket == _previewTicket) {
        _loadDisplayImage();
      }
    }
  }

  Future<void> _applyCrop() async {
    final page = _currentPage;
    if (page == null || _isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final cropped = await _processor.cropImage(
        page.imageData.bytes,
        left: _cropLeft,
        top: _cropTop,
        right: _cropRight,
        bottom: _cropBottom,
      );
      if (!mounted) return;
      page.imageData.bytes = cropped;
      _rememberSize(cropped);
      _showCrop = false;
      _resetCropRect();
      await _loadDisplayImage();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showMessage('Could not crop this page.');
    }
  }

  Future<void> _rotate() async {
    final page = _currentPage;
    if (page == null || _isProcessing) return;
    _previewDebounce?.cancel();
    setState(() => _isProcessing = true);
    try {
      final rotated = await _processor.processImage(
        sourceBytes: page.imageData.bytes,
        rotation: 90,
      );
      if (!mounted) return;
      page.imageData.bytes = rotated;
      page.imageData.rotation = 0;
      _rotation = 0;
      _rememberSize(rotated);
      _resetCropRect();
      await _loadDisplayImage();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showMessage('Could not rotate this page.');
    }
  }

  Future<void> _commitEdits() async {
    final page = _currentPage;
    if (page == null) return;
    final data = page.imageData;
    final hasEdits =
        _filter != ScanFilterType.original ||
        _brightness.abs() > 0.001 ||
        (_contrast - 1).abs() > 0.001 ||
        _rotation != 0;
    if (!hasEdits) {
      data
        ..filter = ScanFilterType.original
        ..brightness = 0
        ..contrast = 1
        ..rotation = 0;
      return;
    }
    final baked = await _processor.processImage(
      sourceBytes: data.bytes,
      filter: _filter,
      brightness: _brightness,
      contrast: _contrast,
      rotation: _rotation,
    );
    data
      ..bytes = baked
      ..filter = ScanFilterType.original
      ..brightness = 0
      ..contrast = 1
      ..rotation = 0;
    _filter = ScanFilterType.original;
    _brightness = 0;
    _contrast = 1;
    _rotation = 0;
    _displayBytes = baked;
    _rememberSize(baked);
  }

  Future<void> _addPage() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await _commitEdits();
      final pages = await DocumentScannerService.instance.scanPages(
        maxPages: 10,
      );
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
      await _goToPage(_session.pages.length - 1, commitCurrent: false);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Scanner is not available on this device.');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _goToPage(int index, {bool commitCurrent = true}) async {
    if (index < 0 || index >= _session.pages.length) return;
    if (index == _currentPageIndex && _displayBytes != null) return;
    _previewDebounce?.cancel();
    _previewTicket++;
    if (commitCurrent) {
      setState(() => _isProcessing = true);
      try {
        await _commitEdits();
      } catch (_) {
        if (mounted) _showMessage('Could not save edits for this page.');
      }
    }
    if (!mounted) return;
    setState(() {
      _currentPageIndex = index;
      _displayBytes = null;
      _imageWidth = 0;
      _imageHeight = 0;
      _showCrop = false;
      _resetCropRect();
      _syncControlsFromPage();
    });
    await _preparePage();
  }

  void _resetCropRect() {
    _cropLeft = 0.08;
    _cropTop = 0.08;
    _cropRight = 0.92;
    _cropBottom = 0.92;
  }

  Future<void> _deletePage() async {
    if (_session.pages.length <= 1 || _isProcessing) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this page?'),
        content: const Text('This page will be removed from the document.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final removed = _session.pages.removeAt(_currentPageIndex);
    _normalizedPages.remove(removed.id);
    final next = _currentPageIndex.clamp(0, _session.pages.length - 1);
    _currentPageIndex = -1;
    await _goToPage(next, commitCurrent: false);
  }

  Future<void> _continueToPreview() async {
    if (_currentPage == null || _isProcessing) return;
    _previewDebounce?.cancel();
    setState(() => _isProcessing = true);
    try {
      await _commitEdits();
      if (!mounted) return;
      await Navigator.of(
        context,
      ).pushNamed(RouteNames.pdfPreview, arguments: _session);
      if (!mounted) return;
      if (_session.pages.isEmpty) {
        Navigator.of(context).pop();
        return;
      }
      if (_currentPageIndex >= _session.pages.length) {
        _currentPageIndex = _session.pages.length - 1;
      }
      _syncControlsFromPage();
      _rememberSize(_currentPage!.imageData.bytes);
      setState(() => _displayBytes = _currentPage!.imageData.bytes);
    } catch (_) {
      if (mounted) _showMessage('Could not open the preview.');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Rect _fittedRect(Size view) {
    if (_imageWidth <= 0 || _imageHeight <= 0 || view.isEmpty) {
      return Offset.zero & view;
    }
    final imageAspect = _imageWidth / _imageHeight;
    final viewAspect = view.width / view.height;
    if (imageAspect > viewAspect) {
      final height = view.width / imageAspect;
      final top = (view.height - height) / 2;
      return Rect.fromLTWH(0, top, view.width, height);
    }
    final width = view.height * imageAspect;
    final left = (view.width - width) / 2;
    return Rect.fromLTWH(left, 0, width, view.height);
  }

  @override
  Widget build(BuildContext context) {
    final page = _currentPage;
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          page == null
              ? 'Edit'
              : 'Edit • Page ${_currentPageIndex + 1}/${_session.pages.length}',
        ),
        actions: [
          if (_session.pages.length > 1) ...[
            IconButton(
              tooltip: 'Previous page',
              icon: const Icon(Icons.navigate_before_rounded),
              onPressed: _currentPageIndex > 0 && !_isProcessing
                  ? () => _goToPage(_currentPageIndex - 1)
                  : null,
            ),
            IconButton(
              tooltip: 'Next page',
              icon: const Icon(Icons.navigate_next_rounded),
              onPressed:
                  _currentPageIndex < _session.pages.length - 1 &&
                      !_isProcessing
                  ? () => _goToPage(_currentPageIndex + 1)
                  : null,
            ),
            IconButton(
              tooltip: 'Delete page',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _isProcessing ? null : _deletePage,
            ),
          ],
        ],
      ),
      body: TopBannerBody(
        child: page == null
          ? const Center(
              child: Text(
                'No pages to edit',
                style: TextStyle(color: Colors.white),
              ),
            )
          : Column(
              children: [
                Expanded(child: _buildPreview()),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.46,
                  ),
                  child: Material(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ToolBar(
                            onCrop: _isProcessing
                                ? null
                                : () => setState(() => _showCrop = !_showCrop),
                            onRotate: _isProcessing ? null : _rotate,
                            onFilters: _isProcessing ? null : _showFilterSheet,
                            onBrightness: _isProcessing
                                ? null
                                : _showAdjustSheet,
                            showCropActive: _showCrop,
                          ),
                          if (_showCrop) _buildCropControls(),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: AppButton(
                                    label: 'Add Page',
                                    icon: Icons.add_rounded,
                                    isOutlined: true,
                                    onPressed: _isProcessing ? null : _addPage,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AppButton(
                                    label: 'Save & Preview',
                                    icon: Icons.picture_as_pdf_rounded,
                                    onPressed: _isProcessing
                                        ? null
                                        : _continueToPreview,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildPreview() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final view = Size(constraints.maxWidth, constraints.maxHeight);
        final imageRect = _fittedRect(view);
        final bytes = _displayBytes;
        return SizedBox(
          width: view.width,
          height: view.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Color(0xFF0F172A)),
              if (bytes != null && !_showCrop)
                InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: SizedBox(
                    width: view.width,
                    height: view.height,
                    child: Image.memory(
                      bytes,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                )
              else if (bytes != null)
                Positioned.fromRect(
                  rect: imageRect,
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.fill,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.medium,
                  ),
                )
              else
                const Positioned.fill(
                  child: AppLoadingView(message: 'Loading page…'),
                ),
              if (_showCrop && bytes != null)
                Positioned.fromRect(
                  rect: imageRect,
                  child: _CropOverlay(
                    left: _cropLeft,
                    top: _cropTop,
                    right: _cropRight,
                    bottom: _cropBottom,
                    onChanged: (left, top, right, bottom) {
                      setState(() {
                        _cropLeft = left;
                        _cropTop = top;
                        _cropRight = right;
                        _cropBottom = bottom;
                      });
                    },
                  ),
                ),
              if (_isProcessing)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x66000000),
                    child: Center(
                      child: AppLoaderCard(
                        message: 'Processing…',
                        compact: true,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCropControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Drag the corners, or use the sliders',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Row(
            children: [
              const Icon(
                Icons.swap_horiz_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
              Expanded(
                child: RangeSlider(
                  values: RangeValues(_cropLeft, _cropRight),
                  onChanged: (v) {
                    if (v.end - v.start < 0.12) return;
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
              const Icon(
                Icons.swap_vert_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
              Expanded(
                child: RangeSlider(
                  values: RangeValues(_cropTop, _cropBottom),
                  onChanged: (v) {
                    if (v.end - v.start < 0.12) return;
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
                  onPressed: _isProcessing
                      ? null
                      : () => setState(_resetCropRect),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Apply Crop',
                  onPressed: _isProcessing ? null : _applyCrop,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: 132,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: ScanFilterType.values.map((filter) {
              final selected = _filter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ChoiceChip(
                  label: Text(filter.label),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _filter = filter);
                    Navigator.pop(sheetContext);
                    _loadDisplayImage();
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showAdjustSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Brightness',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Slider(
                  value: _brightness,
                  min: -0.45,
                  max: 0.45,
                  onChanged: (v) {
                    _brightness = v;
                    setSheetState(() {});
                    _schedulePreview();
                  },
                ),
                Text('Contrast', style: Theme.of(context).textTheme.titleSmall),
                Slider(
                  value: _contrast,
                  min: 0.6,
                  max: 1.8,
                  onChanged: (v) {
                    _contrast = v;
                    setSheetState(() {});
                    _schedulePreview();
                  },
                ),
              ],
            ),
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

  final VoidCallback? onCrop;
  final VoidCallback? onRotate;
  final VoidCallback? onFilters;
  final VoidCallback? onBrightness;
  final bool showCropActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _Tool(
            icon: Icons.crop_rounded,
            label: 'Crop',
            onTap: onCrop,
            active: showCropActive,
          ),
          _Tool(
            icon: Icons.rotate_right_rounded,
            label: 'Rotate',
            onTap: onRotate,
          ),
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
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = !enabled
        ? AppColors.textSecondary.withValues(alpha: 0.4)
        : active
        ? AppColors.primaryBlue
        : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CropOverlay extends StatefulWidget {
  const _CropOverlay({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.onChanged,
  });

  final double left;
  final double top;
  final double right;
  final double bottom;
  final void Function(double left, double top, double right, double bottom)
  onChanged;

  @override
  State<_CropOverlay> createState() => _CropOverlayState();
}

enum _CropDrag { none, move, topLeft, topRight, bottomLeft, bottomRight }

class _CropOverlayState extends State<_CropOverlay> {
  static const _minSpan = 0.12;
  static const _handle = 28.0;

  _CropDrag _drag = _CropDrag.none;
  Offset _origin = Offset.zero;
  double _startLeft = 0;
  double _startTop = 0;
  double _startRight = 0;
  double _startBottom = 0;

  void _begin(DragStartDetails details, Size size) {
    final point = details.localPosition;
    final rect = Rect.fromLTRB(
      size.width * widget.left,
      size.height * widget.top,
      size.width * widget.right,
      size.height * widget.bottom,
    );
    _origin = point;
    _startLeft = widget.left;
    _startTop = widget.top;
    _startRight = widget.right;
    _startBottom = widget.bottom;

    bool near(Offset corner) => (point - corner).distance <= _handle;
    if (near(rect.topLeft)) {
      _drag = _CropDrag.topLeft;
    } else if (near(rect.topRight)) {
      _drag = _CropDrag.topRight;
    } else if (near(rect.bottomLeft)) {
      _drag = _CropDrag.bottomLeft;
    } else if (near(rect.bottomRight)) {
      _drag = _CropDrag.bottomRight;
    } else if (rect.inflate(8).contains(point)) {
      _drag = _CropDrag.move;
    } else {
      _drag = _CropDrag.none;
    }
  }

  void _update(DragUpdateDetails details, Size size) {
    if (_drag == _CropDrag.none || size.width <= 0 || size.height <= 0) return;
    final dx = (details.localPosition.dx - _origin.dx) / size.width;
    final dy = (details.localPosition.dy - _origin.dy) / size.height;

    var left = _startLeft;
    var top = _startTop;
    var right = _startRight;
    var bottom = _startBottom;

    switch (_drag) {
      case _CropDrag.move:
        final width = _startRight - _startLeft;
        final height = _startBottom - _startTop;
        left = (_startLeft + dx).clamp(0.0, 1 - width);
        top = (_startTop + dy).clamp(0.0, 1 - height);
        right = left + width;
        bottom = top + height;
      case _CropDrag.topLeft:
        left = (_startLeft + dx).clamp(0.0, _startRight - _minSpan);
        top = (_startTop + dy).clamp(0.0, _startBottom - _minSpan);
      case _CropDrag.topRight:
        right = (_startRight + dx).clamp(_startLeft + _minSpan, 1.0);
        top = (_startTop + dy).clamp(0.0, _startBottom - _minSpan);
      case _CropDrag.bottomLeft:
        left = (_startLeft + dx).clamp(0.0, _startRight - _minSpan);
        bottom = (_startBottom + dy).clamp(_startTop + _minSpan, 1.0);
      case _CropDrag.bottomRight:
        right = (_startRight + dx).clamp(_startLeft + _minSpan, 1.0);
        bottom = (_startBottom + dy).clamp(_startTop + _minSpan, 1.0);
      case _CropDrag.none:
        return;
    }

    widget.onChanged(left, top, right, bottom);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) => _begin(details, size),
          onPanUpdate: (details) => _update(details, size),
          child: CustomPaint(
            size: size,
            painter: _CropOverlayPainter(
              left: widget.left,
              top: widget.top,
              right: widget.right,
              bottom: widget.bottom,
            ),
          ),
        );
      },
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

    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(cropRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(overlayPath, Paint()..color = const Color(0x99000000));

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    final thirdW = cropRect.width / 3;
    final thirdH = cropRect.height / 3;
    for (var i = 1; i <= 2; i++) {
      canvas.drawLine(
        Offset(cropRect.left + thirdW * i, cropRect.top),
        Offset(cropRect.left + thirdW * i, cropRect.bottom),
        gridPaint,
      );
      canvas.drawLine(
        Offset(cropRect.left, cropRect.top + thirdH * i),
        Offset(cropRect.right, cropRect.top + thirdH * i),
        gridPaint,
      );
    }

    canvas.drawRect(
      cropRect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    const cornerLen = 22.0;
    final cornerPaint = Paint()
      ..color = AppColors.edgeOverlay
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    void corner(Offset start, Offset horizontal, Offset vertical) {
      canvas.drawLine(start, horizontal, cornerPaint);
      canvas.drawLine(start, vertical, cornerPaint);
    }

    corner(
      cropRect.topLeft,
      cropRect.topLeft + const Offset(cornerLen, 0),
      cropRect.topLeft + const Offset(0, cornerLen),
    );
    corner(
      cropRect.topRight,
      cropRect.topRight + const Offset(-cornerLen, 0),
      cropRect.topRight + const Offset(0, cornerLen),
    );
    corner(
      cropRect.bottomLeft,
      cropRect.bottomLeft + const Offset(cornerLen, 0),
      cropRect.bottomLeft + const Offset(0, -cornerLen),
    );
    corner(
      cropRect.bottomRight,
      cropRect.bottomRight + const Offset(-cornerLen, 0),
      cropRect.bottomRight + const Offset(0, -cornerLen),
    );
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) {
    return left != oldDelegate.left ||
        top != oldDelegate.top ||
        right != oldDelegate.right ||
        bottom != oldDelegate.bottom;
  }
}
