import 'dart:async';

/// 用于控制频繁操作的节流助手类
class ThrottleHelper {
  Timer? _throttleTimer;
  DateTime _lastExecutionTime =
      DateTime.now().subtract(const Duration(minutes: 1));
  bool _isExecuting = false;
  final Duration _minInterval;

  ThrottleHelper({Duration minInterval = const Duration(milliseconds: 300)})
      : _minInterval = minInterval;

  /// 取消当前预定的节流操作
  void cancel() {
    _throttleTimer?.cancel();
  }

  /// 重置节流器状态
  void reset() {
    _throttleTimer?.cancel();
    _lastExecutionTime = DateTime.now().subtract(const Duration(minutes: 1));
    _isExecuting = false;
  }

  /// 执行节流操作，防止短时间内重复执行
  ///
  /// [operation] 要执行的操作
  /// [priority] 优先级，较高的优先级可以打断低优先级
  /// [forceExecute] 是否强制执行，忽略节流限制
  Future<T> throttle<T>(
    Future<T> Function() operation, {
    int priority = 0,
    bool forceExecute = false,
    String? operationName,
  }) async {
    // 取消任何现有的定时器
    _throttleTimer?.cancel();

    // 检查是否可以立即执行
    final now = DateTime.now();
    final timeSinceLastExecution = now.difference(_lastExecutionTime);
    final canExecuteNow = forceExecute ||
        (!_isExecuting && timeSinceLastExecution > _minInterval);

    if (canExecuteNow) {
      try {
        _isExecuting = true;
        _lastExecutionTime = now;
        return await operation();
      } finally {
        _isExecuting = false;
      }
    } else {
      // 如果不能立即执行，设置定时器
      final completer = Completer<T>();
      final remainingTime = _minInterval - timeSinceLastExecution;

      _throttleTimer = Timer(remainingTime, () async {
        try {
          if (!completer.isCompleted) {
            _isExecuting = true;
            _lastExecutionTime = DateTime.now();
            final result = await operation();
            completer.complete(result);
          }
        } catch (e) {
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        } finally {
          _isExecuting = false;
        }
      });

      return completer.future;
    }
  }
}
