import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'erase_tool_controller.dart';

/// 擦除手势处理混入
/// 提供通用的擦除手势处理能力
mixin EraseGestureMixin<T extends StatefulWidget> on State<T> {
  /// 擦除工具控制器
  EraseToolController get controller;

  /// 处理笔刷大小变化
  void handleBrushSizeChanged(double size) {
    // 确保控制器可用
    controller.setBrushSize(size);
  }

  /// 处理清除所有
  void handleClearAll() {
    // 确保控制器可用
    controller.clearAll();
  }

  /// 处理平移取消
  void handlePanCancel() {
    // 确保控制器可用
    if (kDebugMode) {
      print('✏️ 擦除取消');
    }

    // 处理擦除取消
    controller.cancelErase();
  }

  /// 处理平移结束
  void handlePanEnd(DragEndDetails details) {
    // 确保控制器可用
    if (kDebugMode) {
      print('✏️ 擦除结束');
    }

    // 处理擦除结束
    controller.endErase();
  }

  /// 处理平移开始
  void handlePanStart(DragStartDetails details) {
    // 确保控制器可用
    final localPosition = details.localPosition;

    if (kDebugMode) {
      print('✏️ 开始擦除: $localPosition');
    }

    // 处理擦除开始
    controller.startErase(localPosition);
  }

  /// 处理平移更新
  void handlePanUpdate(DragUpdateDetails details) {
    // 确保控制器可用
    final localPosition = details.localPosition;

    if (kDebugMode && details.delta.distance > 5) {
      print('✏️ 擦除更新: $localPosition (delta: ${details.delta})');
    }

    // 处理擦除更新
    controller.continueErase(localPosition);
  }

  /// 处理重做
  void handleRedo() {
    // 确保控制器可用
    controller.redo();
  }

  /// 处理撤销
  void handleUndo() {
    // 确保控制器可用
    controller.undo();
  }
}
