import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';

/// Soft blue gradient with gentle shimmer + breathing zoom.
class AnimatedGradientBox extends StatefulWidget {
  const AnimatedGradientBox({
    super.key,
    required this.child,
    required this.borderRadius,
    this.height,
    this.padding,
    this.boxShadow,
    this.colors = _defaultColors,
    this.enableZoom = true,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final List<BoxShadow>? boxShadow;
  final List<Color> colors;
  final bool enableZoom;

  static const _defaultColors = AppColors.animatedGradientColors;

  @override
  State<AnimatedGradientBox> createState() => _AnimatedGradientBoxState();
}

class _AnimatedGradientBoxState extends State<AnimatedGradientBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Color> _blendGradients(double t) {
    final palette = widget.colors;
    if (palette.length < 2) return palette;

    final raw = (math.sin(t * 2 * math.pi) + 1) / 2;
    final wave = Curves.easeInOut.transform(raw);
    final half = palette.length ~/ 2;
    final setA = palette.sublist(0, half);
    final setB = palette.sublist(half);

    final count = math.max(setA.length, setB.length);
    return List.generate(count, (i) {
      final c1 = setA[i % setA.length];
      final c2 = setB[i % setB.length];
      return Color.lerp(c1, c2, wave)!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final wave = math.sin(t * 2 * math.pi);
        final colors = _blendGradients(t);
        final zoom = widget.enableZoom ? 1.0 + (wave + 1) * 0.006 : 1.0;

        return Transform.scale(
          scale: zoom,
          child: Container(
            height: widget.height,
            padding: widget.padding,
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              gradient: LinearGradient(
                begin: Alignment(-0.9 + wave * 0.15, -0.7),
                end: Alignment(0.9 - wave * 0.15, 0.85),
                colors: colors,
                stops: List.generate(
                  colors.length,
                  (i) => i / (colors.length - 1),
                ),
              ),
              boxShadow: widget.boxShadow,
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
