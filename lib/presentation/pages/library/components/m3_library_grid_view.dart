import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/library_item.dart';
import '../../../../presentation/providers/library/library_management_provider.dart';
import '../../../../presentation/providers/settings/grid_size_provider.dart';
import 'draggable_library_item_wrapper.dart';

/// 图库网格视图
class M3LibraryGridView extends ConsumerWidget {
  /// 图库项目列表
  final List<LibraryItem> items;

  /// 是否处于批量选择模式
  final bool isBatchMode;

  /// 选中的项目ID集合
  final Set<String> selectedItems;

  /// 项目点击回调
  final Function(String) onItemTap;

  /// 项目长按回调
  final Function(String) onItemLongPress;

  /// 构造函数
  const M3LibraryGridView({
    super.key,
    required this.items,
    required this.isBatchMode,
    required this.selectedItems,
    required this.onItemTap,
    required this.onItemLongPress,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const spacing = 16.0;
    // Get the current grid size preference
    final gridSizeOption = ref.watch(gridSizeProvider);
    final minItemWidth = gridSizeOption.minItemWidth;

    return LayoutBuilder(builder: (context, constraints) {
      // Calculate how many columns can fit based on available width
      final width = constraints.maxWidth;
      // Calculate number of columns (minimum 2, maximum 8)
      int crossAxisCount =
          max(2, min(8, (width - spacing) ~/ (minItemWidth + spacing)));

      return GridView.builder(
        padding: const EdgeInsets.all(spacing),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 1,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return DraggableLibraryItemWrapper(
            item: item,
            items: items,
            isSelected: selectedItems.contains(item.id),
            onTap: () => onItemTap(item.id),
            onLongPress: () => onItemLongPress(item.id),
            onToggleFavorite: () => ref
                .read(libraryManagementProvider.notifier)
                .toggleFavorite(item.id),
          );
        },
      );
    });
  }
}
