import 'package:flutter/material.dart';

import '../../../app/constants/app_assets.dart';
import '../../../app/constants/app_colors.dart';
import '../../../shared/widgets/animated_gradient_box.dart';
import '../../../shared/widgets/app_animations.dart';
import '../../home/home_constants.dart';

class SettingsHeroCard extends StatelessWidget {
  const SettingsHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HomeConstants.screenPadding,
        18,
        HomeConstants.screenPadding,
        0,
      ),
      child: AnimatedGradientBox(
        borderRadius: BorderRadius.circular(HomeConstants.cardRadius),
        padding: const EdgeInsets.all(20),
        colors: AppColors.animatedGradientColors,
        boxShadow: [
          BoxShadow(
            color: HomeConstants.linkBlue.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Image.asset(AppAssets.iconDocument, fit: BoxFit.contain),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enjoy Free App Features',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Scan documents, create PDFs, and use powerful tools — all included at no cost.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).fadeScaleIn(delayMs: 120);
  }
}
