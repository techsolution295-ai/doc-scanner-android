import 'package:flutter/material.dart';

import '../../../shared/models/scan_session.dart';
import '../../../shared/widgets/app_animations.dart';
import '../../files/widgets/files_list_item.dart';
import '../home_constants.dart';

class RecentScanItem extends StatelessWidget {
  const RecentScanItem({
    super.key,
    required this.document,
    required this.subtitle,
    this.showDivider = true,
    this.animationIndex = 0,
    this.onFavoriteTap,
    this.onMoreTap,
    this.onTap,
  });

  final ScannedDocument document;
  final String subtitle;
  final bool showDivider;
  final int animationIndex;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onMoreTap;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = fileVisual(document);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            SizedBox(
              height: 72,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    FileThumbnail(document: document, style: style),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            document.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: HomeConstants.navyText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: HomeConstants.greySubtitle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onFavoriteTap,
                      icon: Icon(
                        document.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: document.isFavorite
                            ? const Color(0xFFEAB308)
                            : HomeConstants.greySubtitle,
                        size: 22,
                      ),
                    ),
                    IconButton(
                      onPressed: onMoreTap,
                      icon: const Icon(Icons.more_vert, color: HomeConstants.greySubtitle, size: 22),
                    ),
                  ],
                ),
              ),
            ),
            if (showDivider)
              const Divider(height: 1, thickness: 1, indent: 74, color: Color(0xFFEEF2F7)),
          ],
        ),
      ),
    ).fadeSlideIn(delayMs: 520, index: animationIndex, slideY: 0.04);
  }
}
