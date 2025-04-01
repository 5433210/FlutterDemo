import 'dart:ui';

import 'package:flutter/material.dart';

/// 路径调试跟踪器 - 帮助检测路径创建和使用中的问题
class PathTracer {
  static bool enabled = true;
  static int _counter = 0;
  static final Map<int, _PathInfo> _trackedPaths = {};

  /// 添加路径操作
  static void addOperation(Path path, String operation, {dynamic data}) {
    if (!enabled) return;

    final id = path.hashCode;
    final info = _trackedPaths[id];
    if (info != null) {
      info.operations.add('$operation: $data');
      info.pointCount++;

      if (info.pointCount % 10 == 0) {
        print('🔍 路径更新 #$id - 点数: ${info.pointCount} - $operation');
      }
    }
  }

  /// 开始跟踪新路径
  static void beginPath(Path path, {String? source}) {
    if (!enabled) return;

    final id = path.hashCode;
    _trackedPaths[id] = _PathInfo(
      id: id,
      createdAt: DateTime.now(),
      source: source ?? 'unknown',
      pointCount: 0,
      operations: [],
    );

    _counter++;
    print('🔍 路径创建 #$id (总数: $_counter) - 来源: ${source ?? "未知"}');
  }

  /// 结束路径跟踪
  static void endPath(Path path, {String? reason}) {
    if (!enabled) return;

    final id = path.hashCode;
    final info = _trackedPaths[id];
    if (info != null) {
      final duration = DateTime.now().difference(info.createdAt);
      print('🔍 路径结束 #$id - 点数: ${info.pointCount} - '
          '持续时间: ${duration.inMilliseconds}ms - '
          '原因: ${reason ?? "完成"}');

      _trackedPaths.remove(id);
    }
  }

  /// 打印当前跟踪的所有路径
  static void printStatus() {
    if (!enabled) return;

    print('===== 路径跟踪状态 =====');
    print('跟踪中的路径数: ${_trackedPaths.length}');

    _trackedPaths.forEach((id, info) {
      final duration = DateTime.now().difference(info.createdAt);
      print('路径 #$id - 来源: ${info.source} - 点数: ${info.pointCount} - '
          '已存在: ${duration.inSeconds}s');
    });

    print('=======================');
  }
}

class _PathInfo {
  final int id;
  final DateTime createdAt;
  final String source;
  int pointCount;
  final List<String> operations;

  _PathInfo({
    required this.id,
    required this.createdAt,
    required this.source,
    this.pointCount = 0,
    required this.operations,
  });
}
