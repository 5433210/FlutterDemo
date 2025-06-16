import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/service_providers.dart';
import '../../../../infrastructure/providers/storage_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_sizes.dart';
import '../../../widgets/image/cached_image.dart';
import 'dialogs/m3_practice_tag_edit_dialog.dart';

/// Material 3 practice grid item
class M3PracticeGridItem extends ConsumerWidget {
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

  const M3PracticeGridItem({
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
      // child: _buildThumbnail(context, ref),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
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
                                  .withValues(alpha: 0.7),
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
                  // 收藏按钮
                  if (!isSelectionMode && onToggleFavorite != null)
                    Positioned(
                      right: AppSizes.s,
                      top: AppSizes.s,
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
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
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          padding: const EdgeInsets.all(AppSizes.xs),
                          onPressed: onToggleFavorite,
                          tooltip: l10n.favoritesOnly,
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    practice['title'] ?? '',
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDateTime(practice['updateTime']),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${practice['pageCount'] ?? 0}${l10n.pages}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  // 标签和编辑按钮
                  if ((practice['tags'] != null &&
                          practice['tags'].isNotEmpty) ||
                      onTagsEdited != null)
                    Container(
                      margin: const EdgeInsets.only(top: AppSizes.s),
                      child: Row(
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
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              padding: const EdgeInsets.all(AppSizes.xs),
                              tooltip: l10n.edit,
                            ),
                        ],
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

  /// Build placeholder widget
  Widget _buildPlaceholder(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.note_alt_outlined,
          size: 48,
          color: colorScheme.onSurfaceVariant.withAlpha(128), // 0.5 opacity
        ),
      ),
    );
  }

  /// Build tags list widget
  Widget _buildTagsList(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
      child: Row(
        children: [
          for (var i = 0; i < tags.length; i++)
            Padding(
              padding: EdgeInsets.only(right: i < tags.length - 1 ? 4 : 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '#${tags[i]}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build thumbnail widget
  Widget _buildThumbnail(BuildContext context, WidgetRef ref) {
    final practiceId = practice['id'] as String?;

    if (practiceId == null) {
      return _buildPlaceholder(context);
    }

    final storage = ref.watch(initializedStorageProvider);
    final practiceStorage = ref.watch(practiceStorageServiceProvider);
    final thumbnailPath =
        practiceStorage.getPracticeCoverThumbnailPath(practiceId);

    return FutureBuilder<bool>(
      future: storage.fileExists(thumbnailPath),
      builder: (context, snapshot) {
        // 显示从文件系统加载的缩略图
        return CachedImage(
          path: thumbnailPath,
          fit: BoxFit.cover,
          // errorBuilder: (context, error, stackTrace) {
          //   return _buildErrorPlaceholder(context, l10n);
          // },
        );
      },
    );
  }

  /// Format date time string
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

      // Format as YYYY-MM-DD
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
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
      builder: (context) => M3PracticeTagEditDialog(
        tags: currentTags,
        suggestedTags: const [], // We'll implement suggested tags later
        onSaved: (newTags) {
          onTagsEdited!(practiceId, newTags);
        },
      ),
    );
  }
}
