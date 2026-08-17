import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes/route_names.dart';
import '../../shared/models/scan_types.dart';
import '../../shared/providers/document_provider.dart';
import '../../shared/services/pdf_tools_service.dart';
import '../../shared/widgets/app_loader.dart';
import '../home/home_constants.dart';
import '../pdf_viewer/pdf_viewer_screen.dart';

class PdfCompressScreen extends StatefulWidget {
  const PdfCompressScreen({super.key, required this.bytes, required this.name});

  final Uint8List bytes;
  final String name;

  @override
  State<PdfCompressScreen> createState() => _PdfCompressScreenState();
}

class _PdfCompressScreenState extends State<PdfCompressScreen> {
  PdfQuality _level = PdfQuality.medium;
  bool _busy = false;

  String get _originalSize => _formatSize(widget.bytes.length);

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _compressAndSave() async {
    if (_busy) return;
    setState(() => _busy = true);
    AppLoader.show(context, message: 'Compressing PDF…');
    try {
      final result = await PdfToolsService.instance.compressToQuality(widget.bytes, _level);
      if (!mounted) return;
      final doc = await context.read<DocumentProvider>().addRawPdf(
            name: '${widget.name} (Compressed)',
            bytes: result,
          );
      if (!mounted) return;
      AppLoader.hide(context);
      if (doc == null) {
        _snack('Could not save the compressed PDF.');
        return;
      }
      final before = widget.bytes.length;
      final saved = before > result.length ? ((1 - result.length / before) * 100).round() : 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(saved > 0
              ? 'Compressed to ${_formatSize(result.length)} ($saved% smaller).'
              : 'Compressed to ${_formatSize(result.length)}.'),
        ),
      );
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
      backgroundColor: HomeConstants.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.5,
        foregroundColor: HomeConstants.navyText,
        title: const Text(
          'Compress PDF',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: HomeConstants.navyText),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEEF2F7)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: HomeConstants.linkBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.compress_rounded, color: HomeConstants.linkBlue),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text('Current size: $_originalSize',
                          style: const TextStyle(fontSize: 13, color: HomeConstants.greySubtitle)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Choose compression level',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: HomeConstants.navyText)),
          const SizedBox(height: 12),
          _LevelTile(
            title: 'Small size',
            subtitle: 'Maximum compression • lower quality',
            icon: Icons.filter_drama_rounded,
            selected: _level == PdfQuality.low,
            onTap: () => setState(() => _level = PdfQuality.low),
          ),
          _LevelTile(
            title: 'Balanced',
            subtitle: 'Good quality with reduced size (recommended)',
            icon: Icons.balance_rounded,
            selected: _level == PdfQuality.medium,
            onTap: () => setState(() => _level = PdfQuality.medium),
          ),
          _LevelTile(
            title: 'High quality',
            subtitle: 'Best quality • slightly smaller',
            icon: Icons.high_quality_rounded,
            selected: _level == PdfQuality.high,
            onTap: () => setState(() => _level = PdfQuality.high),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _busy ? null : _compressAndSave,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.compress_rounded),
              style: ElevatedButton.styleFrom(
                backgroundColor: HomeConstants.linkBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              label: Text(_busy ? 'Compressing...' : 'Compress & Save',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? HomeConstants.linkBlue : const Color(0xFFEEF2F7),
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: selected ? HomeConstants.linkBlue : HomeConstants.greySubtitle),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700, color: HomeConstants.navyText)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: const TextStyle(fontSize: 12.5, color: HomeConstants.greySubtitle)),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  color: selected ? HomeConstants.linkBlue : HomeConstants.greySubtitle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
