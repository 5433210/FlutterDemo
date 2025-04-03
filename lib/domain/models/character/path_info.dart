import 'dart:ui';

import 'package:flutter/material.dart';

/// 表示一个擦除路径的信息
class PathInfo {
  /// 路径的几何定义
  final Path path;

  /// 笔刷大小
  final double brushSize;

  /// 笔刷颜色
  final Color brushColor;

  /// 创建一个新的路径信息实例
  const PathInfo({
    required this.path,
    required this.brushSize,
    required this.brushColor,
  });

  /// 创建路径信息的副本，可以选择性地修改部分属性
  PathInfo copyWith({
    Path? path,
    double? brushSize,
    Color? brushColor,
  }) {
    return PathInfo(
      path: path ?? this.path,
      brushSize: brushSize ?? this.brushSize,
      brushColor: brushColor ?? this.brushColor,
    );
  }
}
