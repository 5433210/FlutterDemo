import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../application/providers/service_providers.dart';
import '../../../../../../domain/models/work/work_entity.dart';
import '../../../../../../infrastructure/providers/storage_providers.dart';
import '../../../../../../theme/app_colors.dart';
import '../../../../../../theme/app_sizes.dart';
import '../../../../../widgets/image/cached_image.dart';

class WorkGridItem extends ConsumerWidget {
  final WorkEntity work;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;

  const WorkGridItem({
    super.key,
    required this.work,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      elevation:
          isSelected ? AppSizes.cardElevationSelected : AppSizes.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        side: isSelected
            ? BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              )
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 缩略图区域 - 固定宽度，维持比例
            Expanded(
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: _buildThumbnail(context, ref),
              ),
            ),

            // 底部信息区域
            Padding(
              padding: const EdgeInsets.all(AppSizes.s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    work.title,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    work.author,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建缩略图占位符
  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: AppColors.textHint,
        ),
      ),
    );
  }

  // 构建缩略图
  Widget _buildThumbnail(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(initializedStorageProvider);
    final workStorage = ref.watch(workStorageProvider);
    final thumbnailPath = workStorage.getWorkCoverThumbnailPath(work.id);

    return FutureBuilder<bool>(
      future: storage.fileExists(thumbnailPath),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!) {
          return _buildPlaceholder(context);
        }

        return CachedImage(
          path: thumbnailPath,
          fit: BoxFit.cover,
        );
      },
    );
  }
}
