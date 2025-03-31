import 'package:flutter/material.dart';

/// 拖动结束事件
class DragEndEvent extends LayerEvent {
  DragEndEvent({required super.position});
}

/// 拖动开始事件
class DragStartEvent extends LayerEvent {
  DragStartEvent({required super.position});
}

/// 拖动更新事件
class DragUpdateEvent extends LayerEvent {
  final Offset delta;

  DragUpdateEvent({
    required super.position,
    required this.delta,
  });
}

/// 图层事件基类
abstract class LayerEvent {
  /// 事件发生的位置
  final Offset position;

  /// 是否已被处理
  bool _handled = false;

  LayerEvent({required this.position});

  /// 检查事件是否已被处理
  bool get isHandled => _handled;

  /// 标记事件已被处理
  void markHandled() {
    _handled = true;
  }
}

/// 点击事件
class TapEvent extends LayerEvent {
  TapEvent({required super.position});
}
