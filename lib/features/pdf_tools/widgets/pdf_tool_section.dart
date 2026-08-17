import 'package:flutter/material.dart';

import '../../../shared/widgets/app_animations.dart';

class PdfToolCard extends StatelessWidget {
  const PdfToolCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.iconAsset,
    this.onTap,
    this.animationIndex = 0,
  });

  final String title;
  final String subtitle;
  final String iconAsset;
  final VoidCallback? onTap;
  final int animationIndex;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEF2F7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  flex: 5,
                  child: Center(
                    child: Image.asset(iconAsset, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 2),
                Flexible(
                  flex: 2,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
                Flexible(
                  flex: 3,
                  child: Center(
                    child: Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: Color(0xFF64748B),
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).fadeScaleIn(delayMs: 180, index: animationIndex);
  }
}

enum PdfToolAction {
  merge,
  split,
  reorder,
  compress,
  convert,
  pdfToImage,
  rotate,
  delete,
  watermark,
  lock,
  unlock,
  redact,
}

class PdfToolItem {
  const PdfToolItem(this.title, this.subtitle, this.iconAsset, this.action);

  final String title;
  final String subtitle;
  final String iconAsset;
  final PdfToolAction action;
}

class PdfToolSection extends StatelessWidget {
  const PdfToolSection({
    super.key,
    required this.title,
    required this.tools,
    required this.onToolTap,
    this.sectionIndex = 0,
  });

  final String title;
  final List<PdfToolItem> tools;
  final ValueChanged<PdfToolAction> onToolTap;
  final int sectionIndex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B66FF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ).fadeSlideIn(delayMs: 100, index: sectionIndex),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.84,
            ),
            itemCount: tools.length,
            itemBuilder: (_, i) {
              final t = tools[i];
              return PdfToolCard(
                title: t.title,
                subtitle: t.subtitle,
                iconAsset: t.iconAsset,
                onTap: () => onToolTap(t.action),
                animationIndex: sectionIndex * 3 + i,
              );
            },
          ),
        ],
      ),
    );
  }
}
