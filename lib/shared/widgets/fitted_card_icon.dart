import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/constants/app_assets.dart';

/// Scales a card icon so the drawn artwork matches across assets.
///
/// Some PNGs fill more of their canvas than others, so [BoxFit.contain]
/// alone makes those icons look larger. [factorFor] shrinks only those.
class FittedCardIcon extends StatelessWidget {
  const FittedCardIcon({super.key, required this.asset});

  final String asset;

  /// Artwork size of the home icons that already look right.
  static const double targetFill = 0.68;

  static const Map<String, double> _fill = {
    AppAssets.iconCamera: 0.72,
    AppAssets.iconDocument: 0.67,
    AppAssets.iconIdCard: 0.64,
    AppAssets.iconImagePdf: 0.76,
    AppAssets.iconPdfTools: 0.68,
    AppAssets.iconMyFiles: 0.70,
    AppAssets.iconPremium: 0.73,
    AppAssets.iconRecent: 0.63,
    AppAssets.iconSettings: 0.63,
    AppAssets.toolMergePdf: 0.84,
    AppAssets.toolSplitPdf: 0.83,
    AppAssets.toolReorderPages: 0.80,
    AppAssets.toolCompressPdf: 0.84,
    AppAssets.toolConvertPdf: 0.78,
    AppAssets.toolPdfToImage: 0.80,
    AppAssets.toolRotatePdf: 0.85,
    AppAssets.toolDeletePages: 0.79,
    AppAssets.toolWatermark: 0.79,
    AppAssets.toolLockPdf: 0.89,
    AppAssets.toolUnlockPdf: 0.85,
    AppAssets.toolRedactPdf: 0.81,
  };

  static double factorFor(String asset) {
    final fill = _fill[asset] ?? targetFill;
    return (targetFill / fill).clamp(0.72, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxWidth, constraints.maxHeight);
        final box = side * factorFor(asset);
        return Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: box,
            height: box,
            child: Image.asset(asset, fit: BoxFit.contain),
          ),
        );
      },
    );
  }
}
