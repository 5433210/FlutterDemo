import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../domain/entities/library_item.dart';
import '../../../../theme/app_sizes.dart';
import 'library_drag_data.dart';

/// 图库项目组件
class M3LibraryItem extends StatelessWidget {
  /// 图库项目
  final LibraryItem item;

  /// 是否选中
  final bool isSelected;

  /// 点击回调
  final Function() onTap;

  /// 长按回调
  final Function() onLongPress;

  /// 是否为列表视图
  final bool isListView;

  /// 图库项目列表（用于预览）
  final List<LibraryItem> items;

  /// 收藏按钮点击回调
  final Function()? onToggleFavorite;

  /// 构造函数
  const M3LibraryItem({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.items,
    this.isListView = false,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isListView) {
      return _buildListViewItem(context, theme);
    } else {
      return _buildGridViewItem(context, theme);
    }
  }

  Widget _buildGridViewItem(BuildContext context, ThemeData theme) {
    return Draggable<LibraryItemDragData>(
      data: LibraryItemDragData(
        itemId: item.id,
        preview: Image.memory(
          item.thumbnail ?? Uint8List(0),
          fit: BoxFit.contain,
          width: 60,
          height: 60,
        ),
      ),
      feedback: Material(
        elevation: 4.0,
        child: Container(
          width: 100,
          height: 100,
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(color: theme.colorScheme.primary, width: 2),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Image.memory(
            item.thumbnail ?? Uint8List(0),
            fit: BoxFit.contain,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: Card(
          clipBehavior: Clip.antiAlias,
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surface,
          child: Center(
            child: Image.memory(
              item.thumbnail ?? Uint8List(0),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.broken_image,
                  color: theme.colorScheme.error,
                  size: 48,
                );
              },
            ),
          ),
        ),
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        color: isSelected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surface,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Stack(
            children: [
              // 缩略图
              Center(
                child: Image.memory(
                  item.thumbnail ?? Uint8List(0),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.broken_image,
                      color: theme.colorScheme.error,
                      size: 48,
                    );
                  },
                ),
              ),

              // 选中指示器
              if (isSelected)
                Positioned(
                  top: AppSizes.spacing8,
                  left: AppSizes.spacing8,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    child: Icon(
                      Icons.check,
                      color: theme.colorScheme.onPrimary,
                      size: 16,
                    ),
                  ),
                ),

              // 收藏按钮
              Positioned(
                top: AppSizes.spacing8,
                right: AppSizes.spacing8,
                child: IconButton(
                  icon: Icon(
                    item.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: item.isFavorite
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: onToggleFavorite,
                ),
              ),

              // 底部信息栏
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.spacing8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.fileName,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${item.width}x${item.height}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
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

  Widget _buildListViewItem(BuildContext context, ThemeData theme) {
    return Card(
      margin: EdgeInsets.zero,
      color: isSelected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surface,
      child: ListTile(
        leading: SizedBox(
          width: 48,
          height: 48,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.memory(
              item.thumbnail ?? Uint8List(0),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.broken_image,
                  color: theme.colorScheme.error,
                );
              },
            ),
          ),
        ),
        title: Text(item.fileName),
        subtitle: Text(
          '${item.width}x${item.height}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 收藏按钮
            IconButton(
              icon: Icon(
                item.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: item.isFavorite
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant,
              ),
              onPressed: onToggleFavorite,
            ),
          ],
        ),
        selected: isSelected,
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}
