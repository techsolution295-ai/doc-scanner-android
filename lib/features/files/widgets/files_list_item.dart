import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../shared/models/scan_session.dart';
import '../files_constants.dart';

class FilesListItem extends StatelessWidget {
  const FilesListItem({
    super.key,
    required this.document,
    required this.onTap,
    this.onFavorite,
    this.onMore,
  });

  final ScannedDocument document;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final style = fileVisual(document);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(FilesConstants.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FilesConstants.cardRadius),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(FilesConstants.cardRadius),
            border: Border.all(color: FilesConstants.cardBorder),
            boxShadow: [FilesConstants.cardShadow],
          ),
          child: Row(
            children: [
              FileThumbnail(document: document, style: style),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: FilesConstants.navyText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      metaLine(document),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: FilesConstants.greySubtitle),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatFileDate(document.createdAt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: FilesConstants.greySubtitle),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onFavorite,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: Icon(
                  document.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: document.isFavorite ? const Color(0xFFEAB308) : FilesConstants.greySubtitle,
                  size: 22,
                ),
              ),
              IconButton(
                onPressed: onMore,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: const Icon(Icons.more_vert, color: FilesConstants.greySubtitle, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FilesGridItem extends StatelessWidget {
  const FilesGridItem({
    super.key,
    required this.document,
    required this.onTap,
    this.onFavorite,
  });

  final ScannedDocument document;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;

  @override
  Widget build(BuildContext context) {
    final style = fileVisual(document);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(FilesConstants.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FilesConstants.cardRadius),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(FilesConstants.cardRadius),
            border: Border.all(color: FilesConstants.cardBorder),
            boxShadow: [FilesConstants.cardShadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FileThumbnail(document: document, style: style, compact: true),
                  IconButton(
                    onPressed: onFavorite,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    icon: Icon(
                      document.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: document.isFavorite ? const Color(0xFFEAB308) : FilesConstants.greySubtitle,
                      size: 18,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                document.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: FilesConstants.navyText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                metaLine(document),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: FilesConstants.greySubtitle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FileThumbnail extends StatelessWidget {
  const FileThumbnail({
    super.key,
    required this.document,
    required this.style,
    this.compact = false,
  });

  final ScannedDocument document;
  final FileVisual style;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hasThumb = document.thumbnailPath != null && File(document.thumbnailPath!).existsSync();
    final width = compact ? 44.0 : 48.0;
    final height = compact ? 52.0 : 56.0;

    if (hasThumb) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          File(document.thumbnailPath!),
          width: width,
          height: height,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: style.fg.withValues(alpha: 0.15)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(style.icon, color: style.fg, size: compact ? 22 : 24),
          if (!compact) ...[
            const SizedBox(height: 2),
            Text(
              style.label,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: style.fg),
            ),
          ],
        ],
      ),
    );
  }
}

class FileVisual {
  const FileVisual(this.bg, this.fg, this.icon, this.label);

  final Color bg;
  final Color fg;
  final IconData icon;
  final String label;
}

String metaLine(ScannedDocument doc) {
  final parts = <String>[];
  if (doc.fileType == 'pdf') {
    parts.add('${doc.pageCount} Page${doc.pageCount == 1 ? '' : 's'}');
  }
  if (doc.fileSizeBytes > 0) {
    parts.add(formatFileSize(doc.fileSizeBytes));
  }
  return parts.join(' • ');
}

String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String formatFileDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final time = DateFormat('hh:mm a').format(date);

  if (day == today) return 'Today, $time';
  if (day == today.subtract(const Duration(days: 1))) return 'Yesterday, $time';
  return DateFormat('MMM d, yyyy • hh:mm a').format(date);
}

FileVisual fileVisual(ScannedDocument doc) {
  final name = doc.name.toLowerCase();
  if (doc.fileType == 'image') {
    return const FileVisual(Color(0xFFF3E8FF), Color(0xFF8B5CF6), Icons.image_rounded, 'IMG');
  }
  if (name.endsWith('.xls') || name.endsWith('.xlsx')) {
    return const FileVisual(Color(0xFFDCFCE7), Color(0xFF22C55E), Icons.table_chart_rounded, 'XLS');
  }
  if (name.endsWith('.ppt') || name.endsWith('.pptx')) {
    return const FileVisual(Color(0xFFFFEDD5), Color(0xFFF97316), Icons.slideshow_rounded, 'PPT');
  }
  if (name.endsWith('.doc') || name.endsWith('.docx') || name.endsWith('.txt')) {
    return const FileVisual(Color(0xFFDBEAFE), Color(0xFF3B82F6), Icons.description_rounded, 'DOC');
  }
  return const FileVisual(Color(0xFFFEE2E2), Color(0xFFEF4444), Icons.picture_as_pdf_rounded, 'PDF');
}
