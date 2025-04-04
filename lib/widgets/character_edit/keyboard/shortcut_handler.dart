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

  // 重做快捷键
  static const redo = SingleActivator(
    LogicalKeyboardKey.keyZ,
    control: true,
    shift: true,
  );

  // 打开汉字输入框快捷键
  static const openInput = SingleActivator(
    LogicalKeyboardKey.keyE,
    control: true,
  );

  // 切换反转模式快捷键
  static const toggleInvert = SingleActivator(
    LogicalKeyboardKey.keyI,
    control: true,
  );

  // 切换图像反转快捷键
  static const toggleImageInvert = SingleActivator(
    LogicalKeyboardKey.keyI,
    control: true,
    shift: true,
  );

  // 切换轮廓显示快捷键
  static const toggleContour = SingleActivator(
    LogicalKeyboardKey.keyO,
    control: true,
  );

  // 切换平移模式快捷键
  static const togglePanMode = SingleActivator(
    LogicalKeyboardKey.keyP,
    control: true,
  );

  // 切换笔刷大小预设快捷键
  static const List<SingleActivator> brushSizePresets = [
    SingleActivator(LogicalKeyboardKey.digit1, control: true),
    SingleActivator(LogicalKeyboardKey.digit2, control: true),
    SingleActivator(LogicalKeyboardKey.digit3, control: true),
  ];

  // 笔刷大小预设值
  static const List<double> brushSizes = [5.0, 15.0, 30.0];

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
