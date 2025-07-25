import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../application/providers/service_providers.dart';
import '../../../../../../domain/models/work/work_entity.dart';
import '../../../../../../infrastructure/providers/config_providers.dart';
import '../../../../../../infrastructure/providers/storage_providers.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../../../../theme/app_sizes.dart';
import '../../../../../../utils/date_formatter.dart';
import '../../../../../widgets/image/cached_image.dart';

class M3WorkListItem extends ConsumerWidget {
  final WorkEntity work;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;

  /// 切换收藏状态的回调
  final VoidCallback? onToggleFavorite;

  /// 编辑标签的回调
  final VoidCallback? onTagsEdited;

  const M3WorkListItem({
    super.key,
    required this.work,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    this.onToggleFavorite,
    this.onTagsEdited,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      key: ValueKey('work_item_${work.id}'),
      elevation: isSelected ? 2 : 1,
      margin: EdgeInsets.zero,
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
        child: SizedBox(
          height: AppSizes.workListItemHeight, // 固定高度
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 缩略图区域 - 固定宽度
              Stack(
                children: [
                  SizedBox(
                    width: AppSizes.workListThumbnailWidth,
                    child: Container(
                      alignment: Alignment.center,
                      child: _buildThumbnail(context, ref),
                    ),
                  ),

                  // 选择指示器
                  if (isSelectionMode)
                    Positioned(
                      top: AppSizes.s,
                      left: AppSizes.s,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primaryContainer
                              : colorScheme.surfaceContainerHighest
                                  .withAlpha(100),
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

              // 右侧内容区域
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 顶部：标题行
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              work.title,
                              style: theme.textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // 收藏按钮
                          if (!isSelectionMode && onToggleFavorite != null)
                            IconButton(
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
                          if (work.imageCount != null && work.imageCount! > 0)
                            _buildImageCount(context, work.imageCount!),
                        ],
                      ),
                      const SizedBox(height: AppSizes.xxs),

                      // 作者行
                      ...[
                        Text(
                          work.author,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSizes.xs),
                      ], // 风格和工具
                      Row(
                        children: [
                          Consumer(
                            builder: (context, ref, child) {
                              final locale = Localizations.localeOf(context);
                              final styleDisplayName = ref
                                  .watch(styleDisplayNamesWithLocaleProvider(
                                      locale.languageCode))
                                  .maybeWhen(
                                    data: (names) =>
                                        names[work.style] ?? work.style,
                                    orElse: () => work.style,
                                  );
                              return _buildInfoChip(
                                context,
                                Icons.brush_outlined,
                                styleDisplayName,
                              );
                            },
                          ),
                          const SizedBox(width: AppSizes.s),
                          Consumer(
                            builder: (context, ref, child) {
                              final locale = Localizations.localeOf(context);
                              final toolDisplayName = ref
                                  .watch(toolDisplayNamesWithLocaleProvider(
                                      locale.languageCode))
                                  .maybeWhen(
                                    data: (names) =>
                                        names[work.tool] ?? work.tool,
                                    orElse: () => work.tool,
                                  );
                              return _buildInfoChip(
                                context,
                                Icons.construction_outlined,
                                toolDisplayName,
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.xs),

                      // 底部日期和元数据信息
                      Row(
                        children: [
                          // 导入日期
                          Flexible(
                            child: _buildInfoItem(
                              context,
                              Icons.add_circle_outline,
                              DateFormatter.formatCompact(work.createTime),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.xs),
                      // 元数据预览
                      Flexible(
                        child: _buildMetadataPreview(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建图片数量指示器
  Widget _buildImageCount(BuildContext context, int count) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.photo_library_outlined,
              size: 16, color: colorScheme.onPrimaryContainer),
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  // 构建带图标的信息小标签
  Widget _buildInfoChip(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSecondaryContainer),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  // 构建带图标的信息项
  Widget _buildInfoItem(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // 构建元数据预览
  Widget _buildMetadataPreview(BuildContext context) {
    final tags = work.tags;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    if (tags.isEmpty && onTagsEdited == null) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: AppSizes.tagChipSpacing,
              runSpacing: AppSizes.tagChipSpacing,
              children: tags.map((tag) => _buildTagChip(context, tag)).toList(),
            ),
          ),
        ),
        if (onTagsEdited != null)
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            padding: const EdgeInsets.all(AppSizes.xs),
            onPressed: () {
              print('DEBUG: 列表项编辑标签按钮被点击 - ${work.id}');
              onTagsEdited?.call();
            },
            tooltip: AppLocalizations.of(context).editTags,
          ),
      ],
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
          color: colorScheme.onSurfaceVariant.withAlpha(128),
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
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.tagChipBorderRadius),
      ),
      child: Text(
        '#$tag',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.primary,
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
      builder: (context, existsSnapshot) {
        if (!existsSnapshot.hasData || !existsSnapshot.data!) {
          return _buildPlaceholder(context);
        }

        return CachedImage(
          path: thumbnailPath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(context),
        );
      },
    );
  }
}
