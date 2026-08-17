import 'package:flutter/material.dart';

import '../../../app/constants/app_assets.dart';
import '../../../shared/widgets/app_animations.dart';
import '../../home/home_constants.dart';

class PdfToolsHeader extends StatelessWidget {
  const PdfToolsHeader({super.key, this.showBack = true});

  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              color: const Color(0xFF0F172A),
            )
          else
            const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'PDF Tools',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          SizedBox(width: showBack ? 48 : 12),
        ],
      ),
    ).fadeSlideIn(delayMs: 0);
  }
}

class PdfToolsHeroBanner extends StatelessWidget {
  const PdfToolsHeroBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(HomeConstants.bannerRadius),
        child: Image.asset(
          AppAssets.pdfToolsBanner,
          width: screenWidth - 16,
          fit: BoxFit.fitWidth,
        ),
      ),
    ).fadeScaleIn(delayMs: 80);
  }
}
