import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';

/// Home grid tool card — matches mockup: icon top, title, subtitle.
class QuickActionCard extends StatelessWidget {
  const QuickActionCard({
    super.key,
    this.icon,
    this.assetIcon,
    required this.label,
    required this.color,
    required this.onTap,
    this.subtitle,
    this.iconSize = 44,
  }) : assert(icon != null || assetIcon != null, 'Provide icon or assetIcon');

  final IconData? icon;
  final String? assetIcon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String? subtitle;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: assetIcon != null ? AppColors.cardWhite : color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: assetIcon != null ? Border.all(color: AppColors.borderLight.withValues(alpha: 0.5)) : null,
                  ),
                  child: assetIcon != null
                      ? Image.asset(
                          assetIcon!,
                          width: iconSize,
                          height: iconSize,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        )
                      : Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
