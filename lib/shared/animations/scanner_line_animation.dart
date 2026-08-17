import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/constants/app_colors.dart';

/// Animated horizontal scanner line overlay for camera preview.
class ScannerLineAnimation extends StatelessWidget {
  const ScannerLineAnimation({super.key, this.height = 280});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Edge detection corner brackets
          CustomPaint(
            size: Size(double.infinity, height),
            painter: _EdgeDetectionPainter(),
          ),
          // Moving scan line
          Animate(
            onPlay: (c) => c.repeat(reverse: true),
            effects: [
              MoveEffect(
                begin: const Offset(0, -100),
                end: const Offset(0, 100),
                duration: 2.seconds,
                curve: Curves.easeInOut,
              ),
            ],
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.scannerLine.withValues(alpha: 0.9),
                    Colors.transparent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.scannerLine.withValues(alpha: 0.5),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EdgeDetectionPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.edgeOverlay
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const inset = 28.0;
    const cornerLen = 36.0;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, inset, size.width - inset * 2, size.height - inset * 2),
      const Radius.circular(8),
    );

    canvas.drawRRect(rect, paint..color = AppColors.edgeOverlay.withValues(alpha: 0.3));

    // Corner accents
    final cornerPaint = Paint()
      ..color = AppColors.edgeOverlay
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    void drawCorner(Offset start, Offset hEnd, Offset vEnd) {
      canvas.drawLine(start, hEnd, cornerPaint);
      canvas.drawLine(start, vEnd, cornerPaint);
    }

    drawCorner(Offset(inset, inset), Offset(inset + cornerLen, inset), Offset(inset, inset + cornerLen));
    drawCorner(
      Offset(size.width - inset, inset),
      Offset(size.width - inset - cornerLen, inset),
      Offset(size.width - inset, inset + cornerLen),
    );
    drawCorner(
      Offset(inset, size.height - inset),
      Offset(inset + cornerLen, size.height - inset),
      Offset(inset, size.height - inset - cornerLen),
    );
    drawCorner(
      Offset(size.width - inset, size.height - inset),
      Offset(size.width - inset - cornerLen, size.height - inset),
      Offset(size.width - inset, size.height - inset - cornerLen),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
