enum Tool {
  pan, // 拖拽工具（用于平移和缩放图片）
  selection, // 框选工具（用于框选新字符）
  multiSelect, // 多选工具（用于选择多个已有字符）
  erase; // 擦除工具（用于擦除预览图像的部分）

  String get displayName {
    switch (this) {
      case Tool.pan:
        return '拖拽工具';
      case Tool.selection:
        return '框选工具';
      case Tool.multiSelect:
        return '多选工具';
      case Tool.erase:
        return '擦除工具';
    }
  }

  String get iconName {
    switch (this) {
      case Tool.pan:
        return 'pan_tool';
      case Tool.selection:
        return 'crop_square';
      case Tool.multiSelect:
        return 'select_all';
      case Tool.erase:
        return 'auto_fix_high';
    }
  }
}
