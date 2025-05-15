import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../application/providers/service_providers.dart';
import '../../../../../../domain/models/work/work_entity.dart';
import '../../../../../../infrastructure/providers/storage_providers.dart';
import '../../../../../../theme/app_sizes.dart';
import '../../../../../widgets/image/cached_image.dart';

class M3WorkGridItem extends ConsumerWidget {
  final WorkEntity work;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;

  /// 切换收藏状态的回调
  final VoidCallback? onToggleFavorite;

  const M3WorkGridItem({
    super.key,
    required this.work,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: isSelected ? 3 : 1,
      surfaceTintColor: isSelected ? colorScheme.primaryContainer : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        side: isSelected
            ? BorderSide(
                color: colorScheme.primary,
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
            // 缩略图区域
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    alignment: Alignment.center,
                    child: _buildThumbnail(context, ref),
                  ),
                  // 收藏按钮
                  if (!isSelectionMode && onToggleFavorite != null)
                    Positioned(
                      top: AppSizes.s,
                      right: AppSizes.s,
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            work.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: work.isFavorite
                                ? colorScheme.error
                                : colorScheme.onSurfaceVariant,
                          ),
                          iconSize: AppSizes.iconMedium,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          padding: const EdgeInsets.all(AppSizes.xs),
                          onPressed: onToggleFavorite,
                        ),
                      ),
                    ),
                  // 选择指示器
                  if (isSelectionMode)
                    Positioned(
                      top: AppSizes.s,
                      right: AppSizes.s,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primaryContainer
                              : colorScheme.surfaceContainerHighest
                                  .withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.xs),
                          child: Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                            size: AppSizes.iconMedium,
                          ),
                        ),
                      ),
                    ),
                ],
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
                  const SizedBox(height: AppSizes.xxs),
                  Text(
                    work.author,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.xs),
                  // 添加标签行
                  if (work.tags.isNotEmpty)
                    SizedBox(
                      height: AppSizes.workGridItemTagHeight,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: work.tags.length > 3 ? 3 : work.tags.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: AppSizes.tagChipSpacing),
                        itemBuilder: (context, index) {
                          final tag = work.tags[index];
                          return _buildTagChip(context, tag);
                        },
                      ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: colorScheme.onSurfaceVariant.withOpacity(0.5),
        ),
      ),
    );
  }

  // 构建标签
  Widget _buildTagChip(BuildContext context, String tag) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.tagChipHorizontalPadding,
          vertical: AppSizes.tagChipVerticalPadding),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withOpacity(0.7),
        borderRadius: BorderRadius.circular(AppSizes.tagChipBorderRadius),
      ),
      child: Text(
        '#$tag',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSecondaryContainer,
          fontSize: AppSizes.tagChipFontSize,
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
