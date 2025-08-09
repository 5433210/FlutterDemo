import 'dart:async';

/// 用于控制频繁操作的节流助手类
class ThrottleHelper {
  Timer? _throttleTimer;
  DateTime _lastExecutionTime =
      DateTime.now().subtract(const Duration(minutes: 1));
  bool _isExecuting = false;
  final Duration _minInterval;
  
  // 🚀 优化：跟踪当前的Completer，防止内存泄漏
  Completer<dynamic>? _currentCompleter;

  ThrottleHelper({Duration minInterval = const Duration(milliseconds: 300)})
      : _minInterval = minInterval;

  /// 取消当前预定的节流操作
  void cancel() {
    _throttleTimer?.cancel();
    _throttleTimer = null;
    
    // 🚀 优化：取消时完成Completer，防止内存泄漏
    if (_currentCompleter != null && !_currentCompleter!.isCompleted) {
      _currentCompleter!.completeError(Exception('操作已取消'));
    }
    _currentCompleter = null;
  }

  /// 重置节流器状态
  void reset() {
    _throttleTimer?.cancel();
    _throttleTimer = null;
    _lastExecutionTime = DateTime.now().subtract(const Duration(minutes: 1));
    _isExecuting = false;
    
    // 🚀 优化：重置时完成Completer，防止内存泄漏
    if (_currentCompleter != null && !_currentCompleter!.isCompleted) {
      _currentCompleter!.completeError(Exception('节流器已重置'));
    }
    _currentCompleter = null;
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
    // 🚀 优化：先清理之前的定时器和Completer，防止泄漏
    _throttleTimer?.cancel();
    _throttleTimer = null;
    
    // 如果有未完成的Completer，先完成它
    if (_currentCompleter != null && !_currentCompleter!.isCompleted) {
      _currentCompleter!.completeError(Exception('被新操作替代'));
    }
    _currentCompleter = null;

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
      _currentCompleter = completer; // 跟踪当前Completer
      final remainingTime = _minInterval - timeSinceLastExecution;

      _throttleTimer = Timer(remainingTime, () async {
        // 🚀 优化：检查Completer是否仍然有效
        if (completer.isCompleted || _currentCompleter != completer) {
          return; // 已经被取消或替代
        }
        
        try {
          _isExecuting = true;
          _lastExecutionTime = DateTime.now();
          final result = await operation();
          
          // 双重检查，确保仍然是当前的Completer
          if (!completer.isCompleted && _currentCompleter == completer) {
            completer.complete(result);
          }
        } catch (e) {
          // 双重检查，确保仍然是当前的Completer
          if (!completer.isCompleted && _currentCompleter == completer) {
            completer.completeError(e);
          }
        } finally {
          _isExecuting = false;
          // 清理引用
          if (_currentCompleter == completer) {
            _currentCompleter = null;
          }
        }
      });

      return completer.future;
    }
  }
  
  /// 🚀 优化：添加dispose方法，确保资源被正确清理
  void dispose() {
    _throttleTimer?.cancel();
    _throttleTimer = null;
    
    if (_currentCompleter != null && !_currentCompleter!.isCompleted) {
      _currentCompleter!.completeError(Exception('ThrottleHelper已释放'));
    }
    _currentCompleter = null;
    _isExecuting = false;
  }
}
