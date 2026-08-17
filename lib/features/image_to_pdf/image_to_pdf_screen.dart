import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../app/constants/app_colors.dart';
import '../../app/routes/route_names.dart';
import '../../shared/models/scan_session.dart';
import '../../shared/models/scan_types.dart';
import '../../shared/providers/document_provider.dart';
import '../../shared/services/pdf_service.dart';
import '../../shared/services/permission_service.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_loader.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../pdf_viewer/pdf_viewer_screen.dart';

class InitialImage {
  const InitialImage(this.bytes, this.name);

  final Uint8List bytes;
  final String name;
}

class ImageToPdfScreen extends StatefulWidget {
  const ImageToPdfScreen({super.key, this.initialImages});

  final List<InitialImage>? initialImages;

  @override
  State<ImageToPdfScreen> createState() => _ImageToPdfScreenState();
}

class _ImageToPdfScreenState extends State<ImageToPdfScreen> {
  final _picker = ImagePicker();
  final _uuid = const Uuid();
  final _pdfService = PdfService();
  final _nameController = TextEditingController(text: 'Gallery Document');
  final List<_PickedImage> _images = [];
  bool _isPicking = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialImages;
    if (initial != null && initial.isNotEmpty) {
      _images.addAll(
        initial.map((e) => _PickedImage(id: _uuid.v4(), bytes: e.bytes, name: e.name)),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String get _docName {
    final n = _nameController.text.trim();
    return n.isEmpty ? 'Gallery Document' : n;
  }

  List<Uint8List> get _pageBytes => _images.map((e) => e.bytes).toList();

  Future<void> _pickImages() async {
    if (_isPicking || _busy) return;
    _isPicking = true;
    try {
      final granted = await PermissionService.instance.requestPhotosPermission();
      if (!granted) return;

      final picked = await _picker.pickMultiImage(imageQuality: 90);
      if (picked.isEmpty) return;

      if (!mounted) return;
      AppLoader.show(context, message: 'Loading images…');
      for (final file in picked) {
        final bytes = await file.readAsBytes();
        _images.add(_PickedImage(id: _uuid.v4(), bytes: bytes, name: file.name));
      }
      if (mounted) {
        AppLoader.hide(context);
        setState(() {});
      }
    } on Exception {
      if (mounted) AppLoader.hide(context);
      // Ignore duplicate/cancelled picker activations.
    } finally {
      _isPicking = false;
    }
  }

  void _removeImage(String id) {
    setState(() => _images.removeWhere((i) => i.id == id));
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _images.removeAt(oldIndex);
      _images.insert(newIndex, item);
    });
  }

  Future<void> _save() async {
    if (_images.isEmpty || _busy) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    AppLoader.show(context, message: 'Saving PDF…');
    try {
      final session = ScanSession(
        id: _uuid.v4(),
        title: _docName,
        pages: _images
            .map((img) => ScanPage(
                  id: _uuid.v4(),
                  imageData: ScanImageData(id: img.id, bytes: img.bytes),
                ))
            .toList(),
      );
      final provider = context.read<DocumentProvider>();
      final doc = await provider.savePdf(session: session, pageBytes: _pageBytes);
      if (!mounted) return;
      AppLoader.hide(context);
      if (doc == null) {
        _snack('Could not save the PDF.');
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

  Future<void> _share() async {
    if (_images.isEmpty || _busy) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    AppLoader.show(context, message: 'Preparing share…');
    try {
      final bytes = await _pdfService.createPdf(
        pages: _pageBytes,
        quality: PdfQuality.high,
        title: _docName,
      );
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/$_docName.pdf';
      await File(path).writeAsBytes(bytes);
      if (!mounted) return;
      AppLoader.hide(context);
      await Share.shareXFiles([XFile(path)], text: _docName);
    } catch (_) {
      if (mounted) AppLoader.hide(context);
      _snack('Could not share the PDF.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _print() async {
    if (_images.isEmpty || _busy) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    AppLoader.show(context, message: 'Preparing print…');
    try {
      final bytes = await _pdfService.createPdf(
        pages: _pageBytes,
        quality: PdfQuality.high,
        title: _docName,
      );
      if (!mounted) return;
      AppLoader.hide(context);
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (_) {
      if (mounted) AppLoader.hide(context);
      _snack('Could not print. Please try again.');
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
    final hasImages = _images.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image to PDF'),
        actions: [
          if (hasImages)
            IconButton(
              tooltip: 'Share',
              icon: const Icon(Icons.share_outlined),
              onPressed: _busy ? null : _share,
            ),
        ],
      ),
      body: !hasImages
          ? EmptyStateWidget(
              icon: Icons.photo_library_rounded,
              title: 'Import images',
              subtitle: 'Select multiple images from your gallery and convert them into a PDF.',
              actionLabel: 'Select Images',
              onAction: _pickImages,
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    controller: _nameController,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'PDF name',
                      prefixIcon: const Icon(Icons.picture_as_pdf_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_images.length} image${_images.length > 1 ? 's' : ''} • drag to reorder',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.add_photo_alternate_rounded, size: 20),
                        label: const Text('Add More'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: _images.length,
                    onReorder: _reorder,
                    itemBuilder: (context, index) {
                      final img = _images[index];
                      return Container(
                        key: ValueKey(img.id),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFEEF2F7)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.memory(
                                  img.bytes,
                                  width: 60,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Page ${index + 1}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      img.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.errorRed),
                                onPressed: () => _removeImage(img.id),
                              ),
                              const Icon(Icons.drag_handle, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'Print',
                            icon: Icons.print_rounded,
                            isOutlined: true,
                            isLoading: _busy,
                            onPressed: _busy ? null : _print,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppButton(
                            label: _busy ? 'Saving...' : 'Save PDF',
                            icon: Icons.save_alt_rounded,
                            isLoading: _busy,
                            onPressed: _busy ? null : _save,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _PickedImage {
  _PickedImage({required this.id, required this.bytes, required this.name});

  final String id;
  final Uint8List bytes;
  final String name;
}
