import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../app/constants/app_colors.dart';
import '../../app/routes/route_names.dart';
import '../../shared/models/scan_session.dart';
import '../../shared/models/scan_types.dart';
import '../../shared/services/document_scanner_service.dart';
import '../../shared/services/image_processing_service.dart';
import '../../shared/services/permission_service.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_loader.dart';

class CardScannerScreen extends StatefulWidget {
  const CardScannerScreen({super.key});

  @override
  State<CardScannerScreen> createState() => _CardScannerScreenState();
}

class _CardScannerScreenState extends State<CardScannerScreen> {
  final _uuid = const Uuid();
  final _picker = ImagePicker();
  final _processor = ImageProcessingService.instance;

  Uint8List? _frontBytes;
  Uint8List? _backBytes;
  String _step = 'front'; // front | back | preview
  bool _busy = false;

  Future<void> _captureSide(bool fromCamera) async {
    if (_busy) return;
    _busy = true;
    try {
      await _doCaptureSide(fromCamera);
    } on Exception {
      if (mounted) AppLoader.hide(context);
      // Ignore duplicate/cancelled picker or scanner activations.
    } finally {
      _busy = false;
    }
  }

  Future<void> _doCaptureSide(bool fromCamera) async {
    Uint8List? bytes;

    if (fromCamera) {
      try {
        bytes = await DocumentScannerService.instance.scanSinglePage(
          allowGalleryImport: false,
        );
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera scanner is not available on this device.')),
          );
        }
        return;
      }
    } else {
      final granted = await PermissionService.instance.requestPhotosPermission();
      if (!granted) return;
      final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 95);
      if (image == null) return;
      if (!mounted) return;
      AppLoader.show(context, message: 'Loading image…');
      bytes = await image.readAsBytes();
    }

    if (bytes == null) return;
    if (mounted) AppLoader.show(context, message: 'Processing card…');
    final cropped = await _processor.cropToCardRatio(bytes);

    if (!mounted) return;
    AppLoader.hide(context);
    setState(() {
      if (_step == 'front') {
        _frontBytes = cropped;
        _step = 'back';
      } else {
        _backBytes = cropped;
        _step = 'preview';
      }
    });
  }

  Future<void> _continueToEditor() async {
    if (_frontBytes == null) return;

    AppLoader.show(context, message: 'Preparing editor…');
    Uint8List finalBytes;
    if (_backBytes != null) {
      finalBytes = await _processor.combineCardSides(_frontBytes!, _backBytes!);
    } else {
      finalBytes = _frontBytes!;
    }

    final session = ScanSession(
      id: _uuid.v4(),
      title: 'Card Scan',
      isCardScan: true,
      pages: [
        ScanPage(
          id: _uuid.v4(),
          imageData: ScanImageData(id: _uuid.v4(), bytes: finalBytes),
        ),
      ],
    );

    if (!mounted) return;
    AppLoader.hide(context);
    Navigator.of(context).pushNamed(RouteNames.editor, arguments: session);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Card Scanner')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StepIndicator(currentStep: _step),
            const SizedBox(height: 24),
            Text(
              _step == 'front'
                  ? 'Scan front side'
                  : _step == 'back'
                      ? 'Scan back side (optional)'
                      : 'Card preview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Supports ID cards, CNIC, passport, driving license, and business cards.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            if (_step != 'preview') ...[
              _CardPlaceholder(
                label: _step == 'front' ? 'Front Side' : 'Back Side',
                bytes: _step == 'front' ? _frontBytes : _backBytes,
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Capture with Camera',
                icon: Icons.camera_alt_rounded,
                onPressed: () => _captureSide(true),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Import from Gallery',
                icon: Icons.photo_library_rounded,
                isOutlined: true,
                onPressed: () => _captureSide(false),
              ),
              if (_step == 'back') ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(() => _step = 'preview'),
                  child: const Text('Skip back side'),
                ),
              ],
            ] else ...[
              _CardPreviewLayout(front: _frontBytes!, back: _backBytes),
              const SizedBox(height: 24),
              AppButton(
                label: 'Edit & Create PDF',
                icon: Icons.arrow_forward_rounded,
                onPressed: _continueToEditor,
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Rescan',
                isOutlined: true,
                onPressed: () => setState(() {
                  _frontBytes = null;
                  _backBytes = null;
                  _step = 'front';
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});

  final String currentStep;

  @override
  Widget build(BuildContext context) {
    final steps = ['Front', 'Back', 'Preview'];
    final activeIndex = switch (currentStep) {
      'front' => 0,
      'back' => 1,
      _ => 2,
    };

    return Row(
      children: List.generate(steps.length, (i) {
        final isActive = i <= activeIndex;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primaryBlue : AppColors.lightBlue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (i < steps.length - 1) const SizedBox(width: 4),
            ],
          ),
        );
      }),
    );
  }
}

class _CardPlaceholder extends StatelessWidget {
  const _CardPlaceholder({required this.label, this.bytes});

  final String label;
  final Uint8List? bytes;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.586,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.lightBlue.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3), width: 2),
          image: bytes != null
              ? DecorationImage(image: MemoryImage(bytes!), fit: BoxFit.cover)
              : null,
        ),
        child: bytes == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.credit_card_rounded, size: 48, color: AppColors.primaryBlue.withValues(alpha: 0.5)),
                  const SizedBox(height: 8),
                  Text(label, style: TextStyle(color: AppColors.textSecondary)),
                ],
              )
            : null,
      ),
    );
  }
}

class _CardPreviewLayout extends StatelessWidget {
  const _CardPreviewLayout({required this.front, this.back});

  final Uint8List front;
  final Uint8List? back;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(front, fit: BoxFit.cover),
        ),
        if (back != null) ...[
          const SizedBox(height: 16),
          const Text('Back Side', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(back!, fit: BoxFit.cover),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.lightBlue.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primaryBlue),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Front and back will be combined into a single professional PDF page.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
