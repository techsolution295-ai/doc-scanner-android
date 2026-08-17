import 'dart:io';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../shared/widgets/app_loader.dart';
import '../home/home_constants.dart';

class PdfViewerArgs {
  const PdfViewerArgs({required this.filePath, required this.title});

  final String filePath;
  final String title;
}

/// In-app PDF viewer with built-in print and share support.
class PdfViewerScreen extends StatelessWidget {
  const PdfViewerScreen({super.key, required this.args});

  final PdfViewerArgs args;

  Future<void> _print(BuildContext context, File file) async {
    AppLoader.show(context, message: 'Preparing print…');
    try {
      final bytes = await file.readAsBytes();
      if (!context.mounted) return;
      AppLoader.hide(context);
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (_) {
      if (!context.mounted) return;
      AppLoader.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not print. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final file = File(args.filePath);

    return Scaffold(
      backgroundColor: const Color(0xFFEEF1F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.5,
        foregroundColor: HomeConstants.navyText,
        title: Text(
          args.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: HomeConstants.navyText,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Print',
            icon: const Icon(Icons.print_outlined),
            onPressed: file.existsSync() ? () => _print(context, file) : null,
          ),
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.share_outlined),
            onPressed: () => Share.shareXFiles([XFile(args.filePath)], text: args.title),
          ),
        ],
      ),
      body: file.existsSync()
          ? PdfPreview(
              build: (format) => file.readAsBytes(),
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              allowPrinting: true,
              allowSharing: false,
              maxPageWidth: 800,
              pdfFileName: args.title,
              loadingWidget: const AppLoadingView(message: 'Loading PDF…'),
            )
          : const Center(
              child: Text('File not found.'),
            ),
    );
  }
}
