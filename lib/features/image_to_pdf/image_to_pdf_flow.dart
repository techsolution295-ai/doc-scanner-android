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
    var loaderShown = false;
    try {
      final picked = await ImagePicker().pickMultiImage(imageQuality: 90);
      if (picked.isEmpty || !context.mounted) return;

      AppLoader.show(context, message: 'Loading images…');
      loaderShown = true;

      final images = <InitialImage>[];
      for (final file in picked) {
        images.add(InitialImage(await file.readAsBytes(), file.name));
      }

      if (context.mounted) {
        await AppLoader.hide(context);
        loaderShown = false;
      }
      if (!context.mounted) return;

      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => ImageToPdfScreen(initialImages: images),
        ),
      );
    } catch (_) {
      if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not open gallery. Please try again.')),
        );
      }
    } finally {
      if (loaderShown) await AppLoader.hide(context);
      // Delay reset so a duplicate activity-result callback can't relaunch it.
      Future<void>.delayed(const Duration(milliseconds: 900), () => _picking = false);
    }
  }
}
