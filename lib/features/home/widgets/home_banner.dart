import 'package:flutter/material.dart';

import '../../../app/constants/app_assets.dart';
import '../../../shared/widgets/app_animations.dart';
import '../home_constants.dart';

class HomeBanner extends StatelessWidget {
  const HomeBanner({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(HomeConstants.bannerRadius),
          child: Image.asset(
            AppAssets.homeBanner,
            width: screenWidth - 16,
            fit: BoxFit.fitWidth,
          ),
        ),
      ).fadeScaleIn(delayMs: 120),
    );
  }
}
