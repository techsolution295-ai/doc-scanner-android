import 'package:flutter/material.dart';

import '../files_constants.dart';

class FilesHeader extends StatelessWidget {
  const FilesHeader({super.key, this.showBack = false});

  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(showBack ? 8 : FilesConstants.screenPadding, 8, FilesConstants.screenPadding, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBack)
            IconButton(
              onPressed: () => Navigator.maybePop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              color: FilesConstants.navyText,
            ),
          const Text(
            'My Files',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: FilesConstants.navyText,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'All your scanned documents',
            style: TextStyle(
              fontSize: 14,
              color: FilesConstants.greySubtitle,
            ),
          ),
        ],
      ),
    );
  }
}
