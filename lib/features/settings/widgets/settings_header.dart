import 'package:flutter/material.dart';

import '../../../shared/widgets/app_animations.dart';
import '../../home/home_constants.dart';

class SettingsHeader extends StatelessWidget {
  const SettingsHeader({super.key, this.showBack = false});

  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        showBack ? 8 : HomeConstants.screenPadding,
        8,
        HomeConstants.screenPadding,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBack)
            IconButton(
              onPressed: () => Navigator.maybePop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              color: HomeConstants.navyText,
            ),
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: HomeConstants.navyText,
              height: 1.1,
            ),
          ).fadeSlideIn(delayMs: 0),
          const SizedBox(height: 4),
          const Text(
            'App info & support',
            style: TextStyle(fontSize: 14, color: HomeConstants.greySubtitle),
          ).fadeSlideIn(delayMs: 70),
        ],
      ),
    );
  }
}
