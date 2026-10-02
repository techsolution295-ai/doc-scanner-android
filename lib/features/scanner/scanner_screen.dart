import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../app/constants/app_colors.dart';
import '../../app/routes/app_routes.dart';
import '../../app/routes/route_names.dart';
import '../../shared/animations/scanner_line_animation.dart';
import '../../shared/models/scan_session.dart';
import '../../shared/models/scan_types.dart';
import '../../shared/services/image_processing_service.dart';
import '../../shared/services/permission_service.dart';
import '../../shared/widgets/app_loader.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key, this.args});

  final ScannerArgs? args;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _flashOn = false;
  bool _isCapturing = false;
  bool _autoScanEnabled = true;
  int _autoScanCountdown = 0;
  bool _documentDetected = false;
  late AnimationController _captureBounce;
  final _imagePicker = ImagePicker();
  final _uuid = const Uuid();
  final _processor = ImageProcessingService.instance;

  bool get _isBatchMode => widget.args?.isBatchMode ?? false;
  ScanSession? _batchSession;

  @override
  void initState() {
    super.initState();
    _captureBounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.85,
      upperBound: 1.0,
    )..value = 1.0;
    _initCamera();
    _batchSession = widget.args?.existingSession;
  }

  Future<void> _initCamera() async {
    final granted = await PermissionService.instance.requestCameraPermission();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required to scan documents.')),
        );
      }
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      final backCamera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() => _isInitialized = true);
        _startAutoScan();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    }
  }

  /// Simulates edge detection then auto-captures after countdown.
  Future<void> _startAutoScan() async {
    if (!_autoScanEnabled || _isBatchMode) return;

    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted || _isCapturing) return;

    setState(() {
      _documentDetected = true;
      _autoScanCountdown = 3;
    });

    for (var i = 3; i > 0; i--) {
      if (!mounted || !_autoScanEnabled || _isCapturing) return;
      setState(() => _autoScanCountdown = i);
      await Future<void>.delayed(const Duration(seconds: 1));
    }

    if (!mounted || _isCapturing || !_autoScanEnabled) return;
    setState(() => _autoScanCountdown = 0);
    await _capture();
  }

  void _cancelAutoScan() {
    _autoScanEnabled = false;
    setState(() {
      _autoScanCountdown = 0;
      _documentDetected = false;
    });
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;
    _flashOn = !_flashOn;
    await _cameraController!.setFlashMode(
      _flashOn ? FlashMode.torch : FlashMode.off,
    );
    setState(() {});
  }

  Future<void> _capture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    _cancelAutoScan();

    setState(() => _isCapturing = true);
    await _captureBounce.reverse();
    await _captureBounce.forward();

    try {
      final file = await _cameraController!.takePicture();
      final bytes = await file.readAsBytes();
      await _processCapture(bytes);
    } catch (e) {
      if (mounted) {
        AppLoader.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isBatchMode) {
      final images = await _imagePicker.pickMultiImage(imageQuality: 90);
      if (images.isEmpty) return;

      if (!mounted) return;
      AppLoader.show(context, message: 'Loading images…');
      final session = ScanSession(id: _uuid.v4());
      for (final img in images) {
        final bytes = await img.readAsBytes();
        final cropped = await _processor.cropImage(bytes);
        session.pages.add(ScanPage(
          id: _uuid.v4(),
          imageData: ScanImageData(id: _uuid.v4(), bytes: cropped),
        ));
      }
      if (!mounted) return;
      AppLoader.hide(context);
      Navigator.of(context).pushReplacementNamed(
        RouteNames.pdfPreview,
        arguments: session,
      );
      return;
    }

    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (image == null) return;
    if (!mounted) return;
    AppLoader.show(context, message: 'Processing image…');
    final bytes = await image.readAsBytes();
    await _processCapture(bytes);
  }

  Future<void> _processCapture(Uint8List bytes) async {
    // Auto crop simulates edge detection crop
    if (mounted) AppLoader.show(context, message: 'Processing image…');
    final cropped = await _processor.cropImage(bytes);

    final page = ScanPage(
      id: _uuid.v4(),
      imageData: ScanImageData(id: _uuid.v4(), bytes: cropped),
    );

    if (_isBatchMode) {
      _batchSession ??= ScanSession(id: _uuid.v4());
      _batchSession!.pages.add(page);

      if (!mounted) return;
      AppLoader.hide(context);
      final addMore = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Page captured'),
          content: Text('${_batchSession!.pages.length} page(s) in batch. Add another?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Continue to PDF'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add More'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      if (addMore != true) {
        Navigator.of(context).pushReplacementNamed(
          RouteNames.pdfPreview,
          arguments: _batchSession,
        );
      }
      return;
    }

    final session = ScanSession(
      id: _uuid.v4(),
      pages: [page],
      isCardScan: widget.args?.isCardMode ?? false,
    );

    if (!mounted) return;
    AppLoader.hide(context);
    Navigator.of(context).pushReplacementNamed(
      RouteNames.editor,
      arguments: session,
    );
  }

  @override
  void dispose() {
    _captureBounce.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(_isBatchMode ? 'Batch Scan' : 'Document Scanner'),
        actions: [
          if (_isBatchMode && (_batchSession?.pages.isNotEmpty ?? false))
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Chip(
                  label: Text('${_batchSession!.pages.length} pages'),
                  backgroundColor: AppColors.primaryBlue,
                  labelStyle: const TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_isInitialized && _cameraController != null)
            CameraPreview(_cameraController!)
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          // Dark overlay with transparent scan window
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.5),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.6),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
          Center(
            child: const ScannerLineAnimation(height: 320),
          ),
          if (_documentDetected && _autoScanCountdown > 0)
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.edgeOverlay.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.document_scanner_outlined, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Document detected — scanning in $_autoScanCountdown...',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          if (_isCapturing)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 12),
                  Text('Capturing...', style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ControlButton(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      onTap: _pickFromGallery,
                    ),
                    ScaleTransition(
                      scale: _captureBounce,
                      child: GestureDetector(
                        onTap: _isCapturing ? null : _capture,
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: _isCapturing
                                  ? const Padding(
                                      padding: EdgeInsets.all(20),
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                    _ControlButton(
                      icon: _flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                      label: 'Flash',
                      onTap: _toggleFlash,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onTap,
          icon: Icon(icon, color: Colors.white, size: 28),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white24,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
