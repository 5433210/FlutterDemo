import 'package:flutter/material.dart';

import '../models/erase_mode.dart';
import 'erase_tool_controller.dart';

/// 擦除手势处理Mixin
/// 提供处理擦除相关手势的方法
mixin EraseGestureMixin<T extends StatefulWidget> on State<T> {
  /// 最小移动阈值，防止抖动
  static const double _minMoveThreshold = 0.5;

  /// 跟踪是否正在擦除
  bool _isErasing = false;

  /// 上一次位置
  Offset? _lastPosition;

  /// 获取擦除工具控制器
  EraseToolController get controller;

  /// 处理笔刷大小变更
  void handleBrushSizeChanged(double size) {
    controller.setBrushSize(size);
  }

  /// 处理清除所有
  void handleClearAll() {
    controller.clearAll();
  }

  /// 处理模式变更
  void handleModeChanged(EraseMode mode) {
    controller.setMode(mode);
  }

  /// 处理取消事件
  void handlePanCancel() {
    if (_isErasing) {
      print('EraseGestureMixin: 擦除取消 ❌');
      controller.cancelErase();
      _isErasing = false;
      _lastPosition = null;
    }
  }

  /// 处理抬起事件
  void handlePanEnd(DragEndDetails details) {
    if (_isErasing) {
      print(
          'EraseGestureMixin: 擦除完成 ✓ (velocity: ${details.velocity.pixelsPerSecond})');
      controller.endErase();
      _isErasing = false;
      _lastPosition = null;
    }
  }

  /// 处理按下事件
  void handlePanStart(DragStartDetails details) {
    print('EraseGestureMixin: 开始擦除 🖌️ at ${details.localPosition}');
    controller.startErase(details.localPosition);
    _isErasing = true;
    _lastPosition = details.localPosition;
  }

  /// 处理移动事件
  void handlePanUpdate(DragUpdateDetails details) {
    if (!_isErasing) {
      // 异常情况：没有开始就收到更新
      print('EraseGestureMixin: 收到更新但未开始擦除，自动开始');
      controller.startErase(details.localPosition);
      _isErasing = true;
    }

    // 检查移动距离是否超过阈值，避免微小抖动
    if (_lastPosition != null) {
      final distance = (details.localPosition - _lastPosition!).distance;
      if (distance < _minMoveThreshold) {
        return; // 忽略微小移动
      }
    }

    controller.continueErase(details.localPosition);
    _lastPosition = details.localPosition;

    // 日志记录，每10个点记录一次
    if (controller.currentPoints.length % 10 == 0) {
      print('EraseGestureMixin: 擦除更新 ➡️ 点数:${controller.currentPoints.length}');
    }
  }

  /// 处理重做
  void handleRedo() {
    controller.redo();
  }

  /// 处理撤销
  void handleUndo() {
    controller.undo();
  }
}
