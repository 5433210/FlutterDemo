import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/work.dart';
import '../../../../infrastructure/logging/logger.dart';
import '../../../../utils/path_helper.dart';

// Provider to cache thumbnail paths and avoid expensive I/O operations
final workThumbnailProvider =
    FutureProvider.family<String?, String>((ref, workId) async {
  try {
    return await PathHelper.getWorkThumbnailPath(workId);
  } catch (e, stack) {
    AppLogger.error('Error loading thumbnail path',
        tag: 'workThumbnailProvider',
        error: e,
        stackTrace: stack,
        data: {'workId': workId});
    return null;
  }
});

class WorkCard extends ConsumerWidget {
  final Work work;
  final VoidCallback onTap;

  const WorkCard({
    super.key,
    required this.work,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final thumbnailAsync = ref.watch(workThumbnailProvider(work.id ?? ''));

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail
            Expanded(
              child: thumbnailAsync.when(
                data: (thumbnailPath) => _buildThumbnail(thumbnailPath),
                loading: () => const Center(
                  child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (err, stack) => _buildErrorThumbnail(),
              ),
            ),

            // Work info - with fixed height to avoid layout shifts
            Container(
              padding: const EdgeInsets.all(8.0),
              height: 72,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    work.name ?? '未命名作品',
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Author and style
                  Row(
                    children: [
                      if (work.author != null) ...[
                        Expanded(
                          child: Text(
                            work.author ?? '',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      if (work.style != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            work.style ?? '',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorThumbnail() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.broken_image,
          size: 48,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildPlaceholderThumbnail() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildThumbnail(String? thumbnailPath) {
    if (thumbnailPath == null) {
      return _buildPlaceholderThumbnail();
    }

    final file = File(thumbnailPath);

    return Hero(
      tag: 'work-thumbnail-${work.id}',
      child: Image.file(
        file,
        fit: BoxFit.cover,
        cacheWidth: 300, // Optimize memory usage
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorThumbnail();
        },
      ),
    );
  }
}
