import 'package:flutter/material.dart';

import '../../../shared/widgets/app_animations.dart';
import '../home_constants.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.greeting});

  final String greeting;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HomeConstants.screenPadding,
        12,
        HomeConstants.screenPadding,
        0,
      ),
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
    );
  }
}
