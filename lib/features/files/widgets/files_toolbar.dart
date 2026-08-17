import 'package:flutter/material.dart';

import '../../../shared/models/scan_types.dart';
import '../files_constants.dart';

enum FilesViewMode { list, grid }

class FilesToolbar extends StatelessWidget {
  const FilesToolbar({
    super.key,
    required this.sortLabel,
    required this.viewMode,
    required this.onSortTap,
    required this.onViewModeChanged,
  });

  final String sortLabel;
  final FilesViewMode viewMode;
  final VoidCallback onSortTap;
  final ValueChanged<FilesViewMode> onViewModeChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(FilesConstants.screenPadding, 12, FilesConstants.screenPadding, 0),
      child: Row(
        children: [
          const Text(
            'Sort by:',
            style: TextStyle(fontSize: 13, color: FilesConstants.greySubtitle, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onSortTap,
              borderRadius: BorderRadius.circular(10),
              child: Ink(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: FilesConstants.chipBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      sortLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: FilesConstants.navyText,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: FilesConstants.greySubtitle),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          _ViewToggleButton(
            icon: Icons.grid_view_rounded,
            isActive: viewMode == FilesViewMode.grid,
            onTap: () => onViewModeChanged(FilesViewMode.grid),
          ),
          const SizedBox(width: 8),
          _ViewToggleButton(
            icon: Icons.view_list_rounded,
            isActive: viewMode == FilesViewMode.list,
            onTap: () => onViewModeChanged(FilesViewMode.list),
          ),
        ],
      ),
    );
  }

  static String sortLabelFor(DocumentSortBy sort, bool newestFirst) {
    return switch (sort) {
      DocumentSortBy.date => newestFirst ? 'Newest First' : 'Oldest First',
      DocumentSortBy.name => 'Name A-Z',
      DocumentSortBy.type => 'File Type',
    };
  }
}

class _ViewToggleButton extends StatelessWidget {
  const _ViewToggleButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? FilesConstants.accentBlue : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? FilesConstants.accentBlue : FilesConstants.chipBorder,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isActive ? Colors.white : FilesConstants.greySubtitle,
          ),
        ),
      ),
    );
  }
}
