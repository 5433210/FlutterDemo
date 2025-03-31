import 'package:flutter/foundation.dart';

/// 性能监控工具类
class PerformanceMonitor {
  // 记录事件延迟
  static void logEventLatency(String tag, Duration latency) {
    if (kDebugMode) {
      print('⌛ $tag: ${latency.inMilliseconds}ms');

      // 检查是否超过阈值
      if (latency.inMilliseconds > 16) {
        print('⚠️ $tag: Event latency exceeded frame budget (16ms)');
      }
    }
  }

  // 记录操作耗时
  static void logFrameTime(String tag, Duration duration) {
    if (kDebugMode) {
      print('⏱️ $tag: ${duration.inMilliseconds}ms');
    }
  }

  // 记录内存使用情况
  static void logMemoryUsage(String tag) {
    if (kDebugMode) {
      print('💾 $tag: Memory monitoring');
      // 在实际应用中，可以调用平台特定API获取内存使用情况
    }
  }

  // 异步操作跟踪
  static Future<T> trackAsyncOperation<T>(
      String tag, Future<T> Function() operation) async {
    final stopwatch = Stopwatch()..start();
    final result = await operation();
    stopwatch.stop();

    logFrameTime(tag, stopwatch.elapsed);
    return result;
  }

  // 跟踪操作执行时间
  static T trackOperation<T>(String tag, T Function() operation) {
    final stopwatch = Stopwatch()..start();
    final result = operation();
    stopwatch.stop();

    logFrameTime(tag, stopwatch.elapsed);
    return result;
  }
}
