import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../app/constants/app_assets.dart';
import '../splash_constants.dart';

class SplashBrandLogo extends StatelessWidget {
  const SplashBrandLogo({super.key, required this.pulse});

  final double pulse;

  @override
  Widget build(BuildContext context) {
    final ringScale = 1.0 + pulse * 0.12;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 150,
          height: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: ringScale,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18 + pulse * 0.2),
                      width: 2,
                    ),
                  ),
                ),
              ),
              Transform.scale(
                scale: 1.0 + pulse * 0.06,
                child: Container(
                  width: 118,
                  height: 118,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                    boxShadow: [
                      BoxShadow(
                        color: SplashConstants.glowCyan.withValues(alpha: 0.25 + pulse * 0.2),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 96,
                height: 96,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: SplashConstants.glowBlue.withValues(alpha: 0.35),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Image.asset(AppAssets.iconDocument, fit: BoxFit.contain),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.3, 0.3),
                    end: const Offset(1, 1),
                    duration: 900.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: 500.ms),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Doc Scanner',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.2,
            height: 1.15,
          ),
        )
            .animate()
            .fadeIn(delay: 450.ms, duration: 600.ms)
            .slideY(begin: 0.35, end: 0, curve: Curves.easeOutCubic),
        const SizedBox(height: 10),
        Text(
          'Scan  •  Enhance  •  Share PDF',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.82),
            letterSpacing: 0.6,
          ),
        )
            .animate()
            .fadeIn(delay: 700.ms, duration: 500.ms)
            .slideY(begin: 0.25, end: 0),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _FeatureChip(label: 'HD Scan', delay: 850),
            _FeatureChip(label: 'PDF Tools', delay: 950),
            _FeatureChip(label: 'ID Card', delay: 1050),
          ],
        ),
      ],
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label, required this.delay});

  final String label;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: delay.ms)
        .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack);
  }
}
