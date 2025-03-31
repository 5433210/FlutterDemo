import 'package:flutter/material.dart';

/// 擦除模式枚举
enum EraseMode {
  normal, // 普通擦除
  outline, // 描边模式
  invert, // 反转模式
}

/// 擦除工具状态
class EraseState {
  // 画笔大小
  double brushSize = 10.0;

  // 笔刷颜色反转（擦白变成擦黑）
  bool invertMode = false;

  // 图像反转
  bool imageInvertMode = false;

  // 是否描边模式
  bool outlineMode = false;

  // 当前活动模式
  EraseMode mode = EraseMode.normal;

  // 获取当前画笔颜色 - 基于模式
  Color get brushColor => invertMode ? Colors.black : Colors.white;

  // 复制状态
  EraseState copy() {
    final newState = EraseState()
      ..brushSize = brushSize
      ..invertMode = invertMode
      ..outlineMode = outlineMode
      ..imageInvertMode = imageInvertMode
      ..mode = mode;

    return newState;
  }
}
