import 'package:flutter/material.dart';

import '../../../shared/widgets/app_animations.dart';
import '../../../shared/widgets/fitted_card_icon.dart';
import '../home_constants.dart';

class FeatureGridCard extends StatelessWidget {
  const FeatureGridCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.iconAsset,
    required this.onTap,
    this.animationIndex = 0,
  });

  final String title;
  // Kept so the subtitle label can be restored.
  // ignore: unused_field
  final String subtitle;
  final String iconAsset;
  final VoidCallback onTap;
  final int animationIndex;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(HomeConstants.cardRadius),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HomeConstants.cardRadius),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(HomeConstants.cardRadius),
            border: Border.all(color: const Color(0xFFEEF2F7)),
            boxShadow: [HomeConstants.softShadow(blur: 14, y: 5, opacity: 0.05)],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FittedCardIcon(asset: iconAsset),
                  ),
                ),
                const SizedBox(height: 8),
                _FitLabel(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: HomeConstants.navyText,
                    height: 1.1,
                  ),
                ),
                // _FitLabel(
                //   subtitle,
                //   style: const TextStyle(
                //     fontSize: 10,
                //     color: HomeConstants.greySubtitle,
                //     height: 1,
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    ).fadeScaleIn(delayMs: 280, index: animationIndex);
  }
}

class _FitLabel extends StatelessWidget {
  const _FitLabel(this.text, {required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          softWrap: false,
          textAlign: TextAlign.center,
          style: style,
        ),
      ),
    );
  }
}
