import 'package:flutter/material.dart';

/// 自定义拖拽数据类，用于从图库项目拖拽到分类
class LibraryItemDragData {
  final String itemId;
  final Widget preview;

  const LibraryItemDragData({
    required this.itemId,
    required this.preview,
  });
}
