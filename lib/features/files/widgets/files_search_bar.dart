import 'package:flutter/material.dart';

import '../files_constants.dart';

class FilesSearchBar extends StatelessWidget {
  const FilesSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FilesConstants.screenPadding,
        16,
        FilesConstants.screenPadding,
        0,
      ),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: FilesConstants.chipBorder),
          boxShadow: [FilesConstants.cardShadow],
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14, color: FilesConstants.navyText),
          decoration: const InputDecoration(
            hintText: 'Search documents...',
            hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 22),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}
