import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_sizes.dart';

/// Material 3 practice list item
class M3PracticeListItem extends StatelessWidget {
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

  const M3PracticeListItem({
    super.key,
    required this.practice,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    this.onLongPress,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
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
          height: 120, // 固定高度
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 缩略图区域 - 固定宽度，维持4:3比例
              Stack(
                children: [
                  SizedBox(
                    width: 160,
                    child: Container(
                      alignment: Alignment.center,
                      child: _buildThumbnail(context),
                    ),
                  ),
                  // Selection indicator
                  if (isSelectionMode)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              colorScheme.surface.withAlpha(204), // 0.8 opacity
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outline,
                          size: 20,
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
                      Text(
                        practice['title'] ?? '',
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDateTime(practice['updateTime']),
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${practice['pageCount'] ?? 0}${l10n.practiceListPages}',
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const Spacer(),
                      if (!isSelectionMode)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (onToggleFavorite != null)
                              IconButton(
                                onPressed: () {
                                  debugPrint(
                                      'List item收藏按钮点击: isFavorite=${practice['isFavorite']}');
                                  onToggleFavorite?.call();
                                },
                                icon: Icon(
                                  practice['isFavorite'] == true
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: practice['isFavorite'] == true
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                iconSize: 20,
                                splashRadius: 20,
                                tooltip: l10n.filterFavoritesOnly,
                              ),
                            Icon(
                              Icons.chevron_right,
                              color: colorScheme.onSurfaceVariant,
                              size: 20,
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
              l10n.practiceListThumbnailError,
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

  /// Build loading indicator
  Widget _buildLoadingIndicator(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: CircularProgressIndicator(
          color: colorScheme.primary,
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

  /// Build thumbnail widget
  Widget _buildThumbnail(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final thumbnail = practice['thumbnail'] as Uint8List?;

    if (thumbnail == null || thumbnail.isEmpty) {
      return _buildPlaceholder(context);
    }

    return AspectRatio(
      aspectRatio: 4 / 3, // 保持4:3比例，与作品浏览页一致
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Image.memory(
          thumbnail,
          fit: BoxFit.cover, // 使用cover而不是contain，与作品浏览页一致
          alignment: Alignment.center,
          gaplessPlayback: true,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (frame == null) {
              return _buildLoadingIndicator(context);
            }
            return child;
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorPlaceholder(context, l10n);
          },
        ),
      ),
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
}
