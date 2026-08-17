import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/constants/app_colors.dart';
import '../models/scan_session.dart';

class DocumentTile extends StatelessWidget {
  const DocumentTile({
    super.key,
    required this.document,
    required this.onTap,
    this.onFavorite,
    this.onShare,
    this.onDelete,
    this.onRename,
  });

  final ScannedDocument document;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;
  final VoidCallback? onRename;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM d, yyyy • h:mm a').format(document.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _Thumbnail(document: document),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            document.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (document.isFavorite)
                          const Icon(Icons.star_rounded, size: 16, color: AppColors.warningOrange),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$dateStr • ${document.pageCount} page${document.pageCount > 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      document.fileType.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: document.fileType == 'pdf'
                            ? AppColors.primaryBlue
                            : AppColors.successGreen,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (value) {
                  switch (value) {
                    case 'share':
                      onShare?.call();
                    case 'rename':
                      onRename?.call();
                    case 'favorite':
                      onFavorite?.call();
                    case 'delete':
                      onDelete?.call();
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'share', child: Text('Share')),
                  const PopupMenuItem(value: 'rename', child: Text('Rename')),
                  PopupMenuItem(
                    value: 'favorite',
                    child: Text(document.isFavorite ? 'Unfavorite' : 'Favorite'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: AppColors.errorRed)),
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

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.document});

  final ScannedDocument document;

  @override
  Widget build(BuildContext context) {
    final hasThumb = document.thumbnailPath != null &&
        File(document.thumbnailPath!).existsSync();

    return Container(
      width: 56,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.lightBlue,
        borderRadius: BorderRadius.circular(10),
        image: hasThumb
            ? DecorationImage(
                image: FileImage(File(document.thumbnailPath!)),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: !hasThumb
          ? Icon(
              document.fileType == 'pdf' ? Icons.picture_as_pdf : Icons.image,
              color: AppColors.primaryBlue,
            )
          : null,
    );
  }
}
