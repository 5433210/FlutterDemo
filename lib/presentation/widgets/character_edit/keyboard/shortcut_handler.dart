import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 编辑器快捷键定义
class EditorShortcuts {
  // 保存快捷键
  static const save = SingleActivator(
    LogicalKeyboardKey.keyS,
    control: true,
  );

  // 撤销快捷键
  static const undo = SingleActivator(
    LogicalKeyboardKey.keyZ,
    control: true,
  );

  // 重做快捷键 (更改为ctrl+y)
  static const redo = SingleActivator(
    LogicalKeyboardKey.keyY,
    control: true,
  );

  // 打开汉字输入框快捷键
  static const openInput = SingleActivator(
    LogicalKeyboardKey.keyE,
    control: true,
  );

  // 切换反转模式快捷键 (更改为ctrl+r)
  static const toggleInvert = SingleActivator(
    LogicalKeyboardKey.keyR,
    control: true,
  );

  // 切换图像反转快捷键 (更改为ctrl+i)
  static const toggleImageInvert = SingleActivator(
    LogicalKeyboardKey.keyI,
    control: true,
  );

  // 切换轮廓显示快捷键
  static const toggleContour = SingleActivator(
    LogicalKeyboardKey.keyO,
    control: true,
  );

  // 平移模式快捷键已移除 - 现在使用Alt键进行平移

  // 增加笔刷大小快捷键
  static const increaseBrushSize = SingleActivator(
    LogicalKeyboardKey.equal, // 加号键
    control: true,
  );

  // 减小笔刷大小快捷键
  static const decreaseBrushSize = SingleActivator(
    LogicalKeyboardKey.minus, // 减号键
    control: true,
  );

  // 笔刷大小调整步长
  static const double brushSizeStep = 5.0;

  // 笔刷大小最小值和最大值
  static const double minBrushSize = 1.0;
  static const double maxBrushSize = 50.0;

  // 获取快捷键文本描述
  static String getShortcutLabel(SingleActivator shortcut) {
    final List<String> parts = [];

    if (shortcut.control) parts.add('Ctrl');
    if (shortcut.shift) parts.add('Shift');
    if (shortcut.alt) parts.add('Alt');

    String key = shortcut.trigger.keyLabel;
    if (key.length == 1) key = key.toUpperCase();
    parts.add(key);

    return parts.join('+');
  }
}

/// 快捷键提示构建器
class ShortcutTooltipBuilder {
  static String build(String action, SingleActivator shortcut) {
    return '$action (${EditorShortcuts.getShortcutLabel(shortcut)})';
  }
}
