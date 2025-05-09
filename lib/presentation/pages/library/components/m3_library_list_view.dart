import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/library_item.dart';
import '../../../../theme/app_sizes.dart';
import '../../../../presentation/providers/library/library_management_provider.dart';
import 'm3_library_item.dart';

/// 图库列表视图
class M3LibraryListView extends ConsumerWidget {
  /// 图库项目列表
  final List<LibraryItem> items;

  /// 是否处于批量选择模式
  final bool isBatchMode;

  /// 选中的项目ID集合
  final Set<String> selectedItems;

  /// 项目选择回调
  final Function(String) onItemTap;

  /// 项目长按回调
  final Function(String) onItemLongPress;

  /// 构造函数
  const M3LibraryListView({
    super.key,
    required this.items,
    required this.isBatchMode,
    required this.selectedItems,
    required this.onItemTap,
    required this.onItemLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryManagementProvider);
    const spacing = 16.0;

    return ListView.builder(
      padding: const EdgeInsets.all(spacing),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: spacing),
          child: M3LibraryItem(
            item: item,
            items: items,
            isSelected: selectedItems.contains(item.id),
            onTap: () => onItemTap(item.id),
            onLongPress: () => onItemLongPress(item.id),
            isListView: true,
          ),
        );
      },
    );
  }
}
