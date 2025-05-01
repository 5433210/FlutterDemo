import 'package:flutter/material.dart';

/// 自定义光标类，提供 Flutter 中没有的光标类型
class CustomCursors {
  /// 调整大小光标 - 下中
  static MouseCursor get resizeBottom => SystemMouseCursors.resizeUpDown;

  /// 调整大小光标 - 左下角
  static MouseCursor get resizeBottomLeft => SystemMouseCursors.resizeDownLeft;

  /// 调整大小光标 - 右下角
  static MouseCursor get resizeBottomRight =>
      SystemMouseCursors.resizeDownRight;

  /// 调整大小光标 - 左中
  static MouseCursor get resizeLeft => SystemMouseCursors.resizeLeftRight;

  /// 调整大小光标 - 右中
  static MouseCursor get resizeRight => SystemMouseCursors.resizeLeftRight;

  /// 调整大小光标 - 上中
  static MouseCursor get resizeTop => SystemMouseCursors.resizeUpDown;

  /// 调整大小光标 - 左上角
  static MouseCursor get resizeTopLeft => SystemMouseCursors.resizeUpLeft;

  /// 调整大小光标 - 右上角
  static MouseCursor get resizeTopRight => SystemMouseCursors.resizeUpRight;

  /// 旋转光标
  static MouseCursor get rotate {
    // 使用 grab 光标作为旋转光标，因为它更符合旋转操作的直觉
    return SystemMouseCursors.grab;
  }

  /// 获取控制点光标
  static MouseCursor getControlPointCursor(int index) {
    switch (index) {
      case 0: // 左上角
        return resizeTopLeft;
      case 1: // 上中
        return resizeTop;
      case 2: // 右上角
        return resizeTopRight;
      case 3: // 右中
        return resizeRight;
      case 4: // 右下角
        return resizeBottomRight;
      case 5: // 下中
        return resizeBottom;
      case 6: // 左下角
        return resizeBottomLeft;
      case 7: // 左中
        return resizeLeft;
      case 8: // 旋转
        return rotate;
      default:
        return SystemMouseCursors.basic;
    }
  }
}
