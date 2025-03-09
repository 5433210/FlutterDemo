import 'dart:async';

/// 事件总线，用于组件间通信
class EventBus {
  final _controller = StreamController.broadcast();

  /// 关闭事件总线
  void dispose() {
    _controller.close();
  }

  /// 发送事件
  void fire(dynamic event) {
    _controller.add(event);
  }

  /// 监听事件
  StreamSubscription<T> on<T>() {
    return _controller.stream
        .where((event) => event is T)
        .cast<T>()
        .listen(null);
  }
}
