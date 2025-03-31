import 'layer_event.dart';

/// 事件分发器类
class EventDispatcher {
  final Map<LayerType, LayerEventHandler> _handlers = {};

  /// 分发事件到注册的处理器
  /// 返回是否有处理器处理了该事件
  bool dispatchEvent(LayerEvent event) {
    if (event.isHandled) return true;

    // 按优先级顺序尝试处理事件
    final handlerTypes = [
      LayerType.ui, // UI层优先处理
      LayerType.preview, // 然后是预览层
      LayerType.background, // 最后是背景层
    ];

    for (final type in handlerTypes) {
      final handler = _handlers[type];
      if (handler != null && handler.handleEvent(event)) {
        event.markHandled();
        return true;
      }
    }

    return false;
  }

  /// 注册图层事件处理器
  void registerHandler(LayerType type, LayerEventHandler handler) {
    _handlers[type] = handler;
  }

  /// 移除图层事件处理器
  void removeHandler(LayerType type) {
    _handlers.remove(type);
  }
}

/// 图层事件处理器接口
abstract class LayerEventHandler {
  bool handleEvent(LayerEvent event);
}

/// 定义图层类型枚举
enum LayerType {
  background,
  preview,
  ui,
}
