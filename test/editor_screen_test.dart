import 'dart:typed_data';

import 'package:doc_scanner/features/editor/editor_screen.dart';
import 'package:doc_scanner/shared/models/scan_session.dart';
import 'package:doc_scanner/shared/models/scan_types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  testWidgets('crop controls apply without throwing', (tester) async {
    final image = img.Image(width: 80, height: 120);
    img.fill(image, color: img.ColorRgb8(230, 230, 230));
    final bytes = Uint8List.fromList(img.encodeJpg(image));
    final session = ScanSession(
      id: 'session',
      pages: [
        ScanPage(
          id: 'page',
          imageData: ScanImageData(id: 'image', bytes: bytes),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: EditorScreen(session: session),
      ),
    );

    Future<bool> busy() async {
      await tester.pump();
      return find.textContaining('Processing').evaluate().isNotEmpty ||
          find.textContaining('Loading page').evaluate().isNotEmpty;
    }

    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      if (!await busy()) break;
    }
    expect(await busy(), isFalse);

    await tester.tap(find.text('Crop'));
    await tester.pump();
    expect(find.text('Apply Crop'), findsOneWidget);

    await tester.tap(find.text('Apply Crop'));
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pump();
      if (find.text('Apply Crop').evaluate().isEmpty) break;
    }

    expect(find.text('Apply Crop'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
