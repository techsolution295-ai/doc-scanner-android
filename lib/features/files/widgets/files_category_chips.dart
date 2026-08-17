import 'package:flutter/material.dart';

import '../../../shared/models/scan_types.dart';
import '../files_constants.dart';

class FilesCategoryChips extends StatelessWidget {
  const FilesCategoryChips({
    super.key,
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  final FileCategoryFilter selected;
  final Map<FileCategoryFilter, int> counts;
  final ValueChanged<FileCategoryFilter> onSelected;

  static const _items = [
    (FileCategoryFilter.all, 'All Files', Icons.folder_rounded, Color(0xFF2B7FFF)),
    (FileCategoryFilter.pdf, 'PDF', Icons.picture_as_pdf_rounded, Color(0xFFEF4444)),
    (FileCategoryFilter.images, 'Images', Icons.image_rounded, Color(0xFF8B5CF6)),
    (FileCategoryFilter.docs, 'Docs', Icons.description_rounded, Color(0xFF3B82F6)),
    (FileCategoryFilter.others, 'Others', Icons.table_chart_rounded, Color(0xFF22C55E)),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(FilesConstants.screenPadding, 12, FilesConstants.screenPadding, 0),
      child: Row(
        children: [
          for (var i = 0; i < _items.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Builder(
              builder: (_) {
                final (category, label, icon, color) = _items[i];
                return _CategoryChip(
                  label: label,
                  count: counts[category] ?? 0,
                  icon: icon,
                  iconColor: color,
                  isSelected: selected == category,
                  onTap: () => onSelected(category),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.count,
    required this.icon,
    required this.iconColor,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color iconColor;
  final bool isSelected;
  final VoidCallback onTap;

  static const _selectedBg = Color(0xFFEAF2FF);
  static const _selectedBorder = Color(0xFFB8D4FF);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? _selectedBg : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? _selectedBorder : FilesConstants.chipBorder,
            ),
            boxShadow: isSelected
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isSelected
                      ? iconColor.withValues(alpha: 0.18)
                      : iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 17, color: iconColor),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? FilesConstants.accentBlue : FilesConstants.navyText,
                    ),
                  ),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? FilesConstants.accentBlue.withValues(alpha: 0.75)
                          : FilesConstants.greySubtitle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
