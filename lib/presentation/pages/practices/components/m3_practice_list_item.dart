import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/service_providers.dart';
import '../../../../infrastructure/providers/storage_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_sizes.dart';
import '../../../widgets/image/cached_image.dart';

/// Material 3 practice list item
class M3PracticeListItem extends ConsumerWidget {
  /// Practice data
  final Map<String, dynamic> practice;

  /// Whether the item is selected
  final bool isSelected;

  /// Whether in selection mode
  final bool isSelectionMode;

  /// Callback when the item is tapped
  final VoidCallback onTap;

  /// Callback when the item is long pressed
  final VoidCallback? onLongPress;

  /// Callback when favorite is toggled
  final VoidCallback? onToggleFavorite;

  /// Callback when tags are edited
  final Function(String, List<String>)? onTagsEdited;

  const M3PracticeListItem({
    super.key,
    required this.practice,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    this.onLongPress,
    this.onToggleFavorite,
    this.onTagsEdited,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return Card(
      elevation:
          isSelected ? AppSizes.cardElevationSelected : AppSizes.cardElevation,
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
        onLongPress: onLongPress,
        child: SizedBox(
          height: AppSizes.workListItemHeight, // 使用统一的高度
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 缩略图区域 - 固定宽度，维持4:3比例
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
                      right: AppSizes.s,
                      top: AppSizes.s,
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
              // 内容区域
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.spacingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              practice['title'] ?? '',
                              style: theme.textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!isSelectionMode && onToggleFavorite != null)
                            IconButton(
                              onPressed: onToggleFavorite,
                              icon: Icon(
                                practice['isFavorite'] == true
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: practice['isFavorite'] == true
                                    ? colorScheme.error
                                    : colorScheme.onSurfaceVariant,
                              ),
                              iconSize: AppSizes.iconMedium,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              padding: const EdgeInsets.all(AppSizes.xs),
                              tooltip: l10n.favoritesOnly,
                            ),
                        ],
                      ),

                      const SizedBox(height: AppSizes.xs),

                      // 信息行
                      Row(
                        children: [
                          _buildInfoChip(
                            context,
                            Icons.calendar_today_outlined,
                            _formatDateTime(practice['updateTime']),
                          ),
                          const SizedBox(width: AppSizes.s),
                          _buildInfoChip(
                            context,
                            Icons.article_outlined,
                            '${practice['pageCount'] ?? 0}${l10n.pages}',
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.xs),

                      // 标签和编辑按钮
                      Row(
                        children: [
                          Expanded(
                            child: _buildTagsList(context),
                          ),
                          if (!isSelectionMode && onTagsEdited != null)
                            IconButton(
                              onPressed: () => _showTagEditDialog(context),
                              icon: const Icon(Icons.edit_outlined),
                              iconSize: AppSizes.iconMedium,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              padding: const EdgeInsets.all(AppSizes.xs),
                              tooltip: l10n.edit,
                            ),
                        ],
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

  /// Build error placeholder
  Widget _buildErrorPlaceholder(BuildContext context, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_not_supported,
              size: 24,
              color: colorScheme.onSurfaceVariant.withAlpha(128), // 0.5 opacity
            ),
            const SizedBox(height: 4),
            Text(
              l10n.thumbnailLoadError,
              style: TextStyle(
                color:
                    colorScheme.onSurfaceVariant.withAlpha(178), // 0.7 opacity
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建带图标的信息标签
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

  /// 构建标签项
  Widget _buildTagChip(BuildContext context, dynamic tag) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.tagChipHorizontalPadding,
        vertical: AppSizes.tagChipVerticalPadding,
      ),
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

  /// 构建标签列表
  Widget _buildTagsList(BuildContext context) {
    final theme = Theme.of(context);
    final tags = (practice['tags'] as List<dynamic>?) ?? [];

    if (tags.isEmpty) {
      return Text(
        AppLocalizations.of(context).noTags,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.hintColor,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Wrap(
        spacing: AppSizes.tagChipSpacing,
        runSpacing: AppSizes.tagChipSpacing,
        children: tags.map((tag) => _buildTagChip(context, tag)).toList(),
      ),
    );
  }

  /// Build thumbnail widget
  Widget _buildThumbnail(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final practiceId = practice['id'] as String;
    final storage = ref.watch(initializedStorageProvider);
    final practiceStorage = ref.watch(practiceStorageServiceProvider);
    final thumbnailPath =
        practiceStorage.getPracticeCoverThumbnailPath(practiceId);

    return FutureBuilder<bool>(
      future: storage.fileExists(thumbnailPath),
      builder: (context, snapshot) {
        // 显示从文件系统加载的缩略图
        return AspectRatio(
          aspectRatio: 4 / 3, // 保持4:3比例
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            child: CachedImage(
              path: thumbnailPath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildErrorPlaceholder(context, l10n);
              },
            ),
          ),
        );
      },
    );
  }

  /// Format date time string with seconds
  String _formatDateTime(dynamic dateTimeValue) {
    if (dateTimeValue == null) return '';

    try {
      DateTime dateTime;

      if (dateTimeValue is String) {
        dateTime = DateTime.parse(dateTimeValue);
      } else if (dateTimeValue is DateTime) {
        dateTime = dateTimeValue;
      } else {
        return '';
      }

      // Format as YYYY-MM-DD HH:mm:ss
      final year = dateTime.year.toString();
      final month = dateTime.month.toString().padLeft(2, '0');
      final day = dateTime.day.toString().padLeft(2, '0');
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final second = dateTime.second.toString().padLeft(2, '0');

      return '$year-$month-$day $hour:$minute:$second';
    } catch (e) {
      debugPrint('Format date time failed: $e');
      return dateTimeValue is String ? dateTimeValue : '';
    }
  }

  /// Show tag edit dialog
  void _showTagEditDialog(BuildContext context) {
    if (onTagsEdited == null) return;

    final practiceId = practice['id'] as String;
    final currentTags =
        List<String>.from(practice['tags'] as List<dynamic>? ?? []);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.edit, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.cancel),
                    ),
                    TextButton(
                      onPressed: () {
                        onTagsEdited!(practiceId, currentTags);
                        Navigator.of(context).pop();
                      },
                      child: Text(l10n.save),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
