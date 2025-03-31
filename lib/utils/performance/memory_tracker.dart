import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// 内存使用监控工具
class MemoryTracker {
  static Timer? _timer;
  static bool _isRunning = false;
  static const _checkInterval = Duration(seconds: 5);

  // 样本集
  static final List<double> _memorySamples = [];
  static const _maxSamples = 20;

  // 立即检查内存使用
  static void checkNow() {
    if (!_isRunning) {
      print('💾 内存监控未启动，执行单次检查');
    }
    _checkMemoryUsage();
  }

  // 启动内存监控
  static void start() {
    if (_isRunning) return;

    _isRunning = true;
    _memorySamples.clear();

    // 定时检查内存使用情况
    _timer = Timer.periodic(_checkInterval, (_) {
      _checkMemoryUsage();
    });

    if (kDebugMode) {
      print('💾 启动内存监控');
    }
  }

  // 停止内存监控
  static void stop() {
    if (!_isRunning) return;

    _isRunning = false;
    _timer?.cancel();
    _timer = null;

    if (kDebugMode) {
      print('💾 停止内存监控');
      if (_memorySamples.isNotEmpty) {
        _printMemorySummary();
      }
    }
  }

  // 检查内存使用趋势
  static void _checkMemoryTrend() {
    if (_memorySamples.length < 5) return; // 至少需要5个样本

    final recentSamples = _memorySamples.sublist(_memorySamples.length - 5);
    final firstSample = recentSamples.first;
    final lastSample = recentSamples.last;
    final growthRate = (lastSample - firstSample) / firstSample * 100;

    if (growthRate > 20) {
      print('⚠️ 内存使用快速增长: ${growthRate.toStringAsFixed(1)}%，可能存在内存泄漏');
    }
  }

  // 检查当前内存使用
  static void _checkMemoryUsage() {
    // 实际应用中，这里可以通过平台特定的API获取真实内存使用数据
    // 这里使用模拟数据作为示例
    final usage = _getCurrentMemoryUsage();
    final usageMB = usage / 1024 / 1024; // 转换为MB

    // 记录样本
    _memorySamples.add(usageMB);
    if (_memorySamples.length > _maxSamples) {
      _memorySamples.removeAt(0);
    }

    if (kDebugMode) {
      print('💾 当前内存使用: ${usageMB.toStringAsFixed(1)} MB');

      // 检查是否超过阈值
      if (usageMB > 200) {
        print('⚠️ 内存使用超过警戒线: ${usageMB.toStringAsFixed(1)} MB');
      }

      // 检查内存增长趋势
      _checkMemoryTrend();
    }
  }

  // 获取当前内存使用情况
  // 在实际应用中，应使用平台特定API获取真实数据
  static double _getCurrentMemoryUsage() {
    // 模拟数据 - 实际应用中替换为真实实现
    // 基础内存 + 随机波动 + 样本数量影响(模拟内存泄漏)
    return 100 * 1024 * 1024 + // 基础100MB
        math.Random().nextDouble() * 50 * 1024 * 1024 + // 随机波动50MB
        _memorySamples.length * 2 * 1024 * 1024; // 每个样本增加2MB(模拟泄漏)
  }

  // 打印内存使用摘要
  static void _printMemorySummary() {
    if (_memorySamples.isEmpty) return;

    final avg = _memorySamples.reduce((a, b) => a + b) / _memorySamples.length;
    final min = _memorySamples.reduce(math.min);
    final max = _memorySamples.reduce(math.max);

    print('💾 内存使用摘要:');
    print('   - 平均: ${avg.toStringAsFixed(1)} MB');
    print('   - 最小: ${min.toStringAsFixed(1)} MB');
    print('   - 最大: ${max.toStringAsFixed(1)} MB');
    print('   - 波动: ${(max - min).toStringAsFixed(1)} MB');

    // 建议
    if (max > 200) {
      print('   - 建议: 内存峰值超过200MB，考虑优化内存使用');
    }
    if (max - min > 50) {
      print('   - 建议: 内存波动较大，检查资源释放');
    }
  }
}
