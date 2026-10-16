import 'package:flutter/material.dart';

import '../../../app/constants/app_assets.dart';
import '../../../app/constants/app_colors.dart';
import '../../../shared/widgets/app_animations.dart';
import '../home_constants.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.greeting,
    this.onPro,
    this.isPremium = false,
  });

  final String greeting;
  final VoidCallback? onPro;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HomeConstants.screenPadding,
        12,
        HomeConstants.screenPadding,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: HomeConstants.navyText,
                    height: 1.15,
                  ),
                ).fadeSlideIn(delayMs: 0),
                const SizedBox(height: 4),
                const Text(
                  'Welcome back!',
                  style: TextStyle(
                    fontSize: 14,
                    color: HomeConstants.greySubtitle,
                    height: 1.15,
                  ),
                ).fadeSlideIn(delayMs: 80),
              ],
            ),
          ),
          if (!isPremium) ...[
            const SizedBox(width: 12),
            _ProButton(onTap: onPro),
          ],
        ],
      ),
    );
  }
}

class _ProButton extends StatelessWidget {
  const _ProButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Go Pro',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.primaryBlue, width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  AppAssets.proCrown,
                  width: 18,
                  height: 18,
                  fit: BoxFit.contain,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: 6),
                const Text(
                  'PRO',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
