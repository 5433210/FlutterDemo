import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// 帧率监控工具
class FrameLogger {
  static bool _isRunning = false;
  static int _frameCount = 0;
  static Duration _lastReportTime = Duration.zero;
  static const _reportInterval = Duration(seconds: 1);

  // 启动帧率监控
  static void start() {
    if (_isRunning) return;

    _isRunning = true;
    _frameCount = 0;
    _lastReportTime = Duration(
        milliseconds:
            SchedulerBinding.instance.currentFrameTimeStamp.inMilliseconds);

    SchedulerBinding.instance.addTimingsCallback(_onTimingsCallback);

    if (kDebugMode) {
      print('🖼️ 启动帧率监控');
    }
  }

  // 停止帧率监控
  static void stop() {
    if (!_isRunning) return;

    _isRunning = false;
    SchedulerBinding.instance.removeTimingsCallback(_onTimingsCallback);

    if (kDebugMode) {
      print('🖼️ 停止帧率监控');
    }
  }

  // 分析帧定时信息
  static void _analyzeFrameTiming(FrameTiming timing) {
    if (!kDebugMode) return;

    final buildTime = _microsToMs(timing.buildDuration.inMicroseconds);
    final rasterTime = _microsToMs(timing.rasterDuration.inMicroseconds);
    final totalTime = buildTime + rasterTime;

    if (totalTime > 16.0) {
      print('⚠️ 帧处理时间过长: ${totalTime.toStringAsFixed(1)}ms '
          '(构建: ${buildTime.toStringAsFixed(1)}ms, '
          '渲染: ${rasterTime.toStringAsFixed(1)}ms)');

      // 分析哪个阶段有问题
      if (buildTime > 10.0) {
        print('   - 构建阶段耗时过长，请检查setState调用和复杂布局');
      }
      if (rasterTime > 10.0) {
        print('   - 渲染阶段耗时过长，请检查绘制操作和图像处理');
      }
    }
  }

  // 微秒转毫秒
  static double _microsToMs(int micros) {
    return micros / 1000.0;
  }

  // 处理每一帧回调
  static void _onTimingsCallback(List<FrameTiming> timings) {
    if (!_isRunning) return;

    _frameCount += timings.length;

    final now = Duration(
        milliseconds:
            SchedulerBinding.instance.currentFrameTimeStamp.inMilliseconds);
    final elapsed = now - _lastReportTime;

    if (elapsed >= _reportInterval) {
      final fps = _frameCount * 1000 / elapsed.inMilliseconds;
      if (kDebugMode) {
        print('🖼️ FPS: ${fps.toStringAsFixed(1)}');

        // 检查是否低于目标帧率
        if (fps < 55) {
          print('⚠️ 帧率过低: ${fps.toStringAsFixed(1)} FPS');
        }
      }

      _frameCount = 0;
      _lastReportTime = now;

      // 分析帧信息
      if (timings.isNotEmpty) {
        _analyzeFrameTiming(timings.last);
      }
    }
  }
}
