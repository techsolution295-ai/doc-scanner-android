import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../splash_constants.dart';

class SplashAnimatedBackground extends StatelessWidget {
  const SplashAnimatedBackground({super.key, required this.scanProgress});

  final double scanProgress;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: SplashConstants.backgroundGradient,
            ),
          ),
        ),
        ...List.generate(3, (i) => _GlowOrb(index: i)),
        CustomPaint(
          painter: _GridPainter(opacity: 0.06 + scanProgress * 0.04),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: MediaQuery.sizeOf(context).height * (0.15 + scanProgress * 0.55),
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  SplashConstants.glowCyan.withValues(alpha: 0.9),
                  Colors.white.withValues(alpha: 0.95),
                  SplashConstants.glowCyan.withValues(alpha: 0.9),
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: SplashConstants.glowCyan.withValues(alpha: 0.55),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 400.ms),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final colors = [SplashConstants.glowBlue, SplashConstants.glowCyan, Colors.white];
    final positions = [
      Offset(size.width * 0.12, size.height * 0.18),
      Offset(size.width * 0.82, size.height * 0.28),
      Offset(size.width * 0.55, size.height * 0.78),
    ];

    return Positioned(
      left: positions[index].dx - 70,
      top: positions[index].dy - 70,
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors[index].withValues(alpha: 0.14),
          boxShadow: [
            BoxShadow(
              color: colors[index].withValues(alpha: 0.25),
              blurRadius: 60,
              spreadRadius: 10,
            ),
          ],
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: -12, end: 12, duration: (2200 + index * 400).ms, curve: Curves.easeInOut)
          .scale(
            begin: const Offset(0.92, 0.92),
            end: const Offset(1.08, 1.08),
            duration: (2600 + index * 300).ms,
            curve: Curves.easeInOut,
          ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.opacity});

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = 1;

    const gap = 36.0;
    for (var x = 0.0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => oldDelegate.opacity != opacity;
}

class SplashProgressBar extends StatelessWidget {
  const SplashProgressBar({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Preparing your scanner...',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.75),
            letterSpacing: 0.3,
          ),
        ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.2, end: 0),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: SizedBox(
            height: 5,
            width: 220,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: Colors.white.withValues(alpha: 0.18)),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            SplashConstants.glowCyan,
                            Colors.white,
                            SplashConstants.glowBlue,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: SplashConstants.glowCyan.withValues(alpha: 0.6),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 1000.ms).scale(begin: const Offset(0.9, 1), curve: Curves.easeOut),
        const SizedBox(height: 8),
        Text(
          '${(progress * 100).clamp(0, 100).toInt()}%',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

class SplashFloatingParticles extends StatelessWidget {
  const SplashFloatingParticles({super.key});

  @override
  Widget build(BuildContext context) {
    final random = math.Random(7);
    return Stack(
      children: List.generate(18, (i) {
        final left = random.nextDouble() * MediaQuery.sizeOf(context).width;
        final top = random.nextDouble() * MediaQuery.sizeOf(context).height;
        final dot = random.nextDouble() * 3 + 2;

        return Positioned(
          left: left,
          top: top,
          child: Container(
            width: dot,
            height: dot,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: random.nextDouble() * 0.35 + 0.15),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fade(begin: 0.2, end: 0.9, duration: (1200 + i * 120).ms)
              .moveY(begin: -8, end: 8, duration: (1800 + i * 90).ms),
        );
      }),
    );
  }
}
