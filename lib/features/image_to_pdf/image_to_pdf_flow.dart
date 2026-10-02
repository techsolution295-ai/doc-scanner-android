import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../shared/widgets/app_loader.dart';
import 'image_to_pdf_screen.dart';

/// Opens the gallery directly, then shows the Image → PDF preview
/// screen with the picked images (no intermediate empty screen).
class ImageToPdfFlow {
  ImageToPdfFlow._();

  static bool _picking = false;

  static Future<void> start(BuildContext context) async {
    // Guard against re-entrancy and OS re-delivery re-triggering the picker.
    if (_picking) return;
    _picking = true;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final picked = await ImagePicker().pickMultiImage(imageQuality: 90);
      if (picked.isEmpty) return;

      if (!context.mounted) return;
      AppLoader.show(context, message: 'Loading images…');

      final images = <InitialImage>[];
      for (final f in picked) {
        images.add(InitialImage(await f.readAsBytes(), f.name));
      }

      if (context.mounted) AppLoader.hide(context);

      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => ImageToPdfScreen(initialImages: images),
        ),
      );
    } on Exception {
      if (context.mounted) AppLoader.hide(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open gallery. Please try again.')),
      );
    } finally {
      // Delay reset so a duplicate activity-result callback can't relaunch it.
      Future<void>.delayed(const Duration(milliseconds: 900), () => _picking = false);
    }
  }
}
