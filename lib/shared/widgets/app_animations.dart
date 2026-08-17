import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Subtle staggered entrance animations used across main tabs.
///
/// Animations keep content mostly visible from the first frame so splash → home
/// never flashes an empty white screen.
extension AppAnimateX on Widget {
  Widget fadeSlideIn({
    int delayMs = 0,
    int index = 0,
    double slideY = 0.06,
    Duration duration = const Duration(milliseconds: 420),
  }) {
    final delay = delayMs + index * 65;
    return animate()
        .fade(
          begin: 0.92,
          end: 1,
          delay: delay.ms,
          duration: duration,
          curve: Curves.easeOut,
        )
        .slideY(
          begin: slideY,
          end: 0,
          delay: delay.ms,
          duration: duration,
          curve: Curves.easeOutCubic,
        );
  }

  Widget fadeScaleIn({
    int delayMs = 0,
    int index = 0,
    Duration duration = const Duration(milliseconds: 400),
  }) {
    final delay = delayMs + index * 65;
    return animate()
        .fade(
          begin: 0.92,
          end: 1,
          delay: delay.ms,
          duration: duration,
          curve: Curves.easeOut,
        )
        .scale(
          begin: const Offset(0.97, 0.97),
          end: const Offset(1, 1),
          delay: delay.ms,
          duration: duration,
          curve: Curves.easeOutCubic,
        );
  }
}

class AnimatedTabBody extends StatelessWidget {
  const AnimatedTabBody({
    super.key,
    required this.active,
    required this.child,
  });

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: active ? 1 : 0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: active ? Offset.zero : const Offset(0, 0.015),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        child: child,
      ),
    );
  }
}
