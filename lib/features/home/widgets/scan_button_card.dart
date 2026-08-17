import 'package:flutter/material.dart';

import '../../../app/constants/app_assets.dart';
import '../../../app/constants/app_colors.dart';
import '../../../shared/widgets/animated_gradient_box.dart';
import '../../../shared/widgets/app_animations.dart';
import '../home_constants.dart';

class ScanButtonCard extends StatefulWidget {
  const ScanButtonCard({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  State<ScanButtonCard> createState() => _ScanButtonCardState();
}

class _ScanButtonCardState extends State<ScanButtonCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HomeConstants.screenPadding,
        HomeConstants.sectionGap,
        HomeConstants.screenPadding,
        0,
      ),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(HomeConstants.scanCardRadius),
            child: AnimatedGradientBox(
              height: 92,
              borderRadius: BorderRadius.circular(HomeConstants.scanCardRadius),
              colors: AppColors.animatedGradientColors,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        AppAssets.iconCamera,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scan Document',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tap to start scanning',
                            style: TextStyle(
                              color: Color(0xD9FFFFFF),
                              fontSize: 15,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ).fadeSlideIn(delayMs: 220);
  }
}
