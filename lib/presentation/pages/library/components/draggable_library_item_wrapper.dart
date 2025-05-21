import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../domain/entities/library_item.dart';
import 'library_drag_data.dart';
import 'm3_library_item.dart';

/// 支持拖放的图库项目包装器
class DraggableLibraryItemWrapper extends StatelessWidget {
  final LibraryItem item;
  final bool isSelected;
  final Function() onTap;
  final Function() onLongPress;
  final List<LibraryItem> items;
  final bool isListView;
  final Function()? onToggleFavorite;
  const DraggableLibraryItemWrapper({
    Key? key,
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.items,
    this.isListView = false,
    this.onToggleFavorite,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    // 创建可拖动的库项目
    final itemKey = ValueKey('library_item_${item.id}');
    return Draggable<LibraryItemDragData>(
      key: itemKey,
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
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
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
        child: M3LibraryItem(
          item: item,
          isSelected: isSelected,
          onTap: onTap,
          onLongPress: onLongPress,
          items: items,
          isListView: isListView,
          onToggleFavorite: onToggleFavorite,
        ),
      ),
      child: M3LibraryItem(
        item: item,
        isSelected: isSelected,
        onTap: onTap,
        onLongPress: onLongPress,
        items: items,
        isListView: isListView,
        onToggleFavorite: onToggleFavorite,
      ),
    );
  }
}
