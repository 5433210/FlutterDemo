import 'dart:ui';

import '../../../domain/models/character/path_info.dart';

/// 路径渲染数据类型
class PathRenderData {
  /// 已完成的路径列表
  final List<PathInfo> completedPaths;

  /// 当前正在绘制的路径
  final PathInfo? currentPath;

  /// 需要重绘的区域
  final Rect? dirtyBounds;

  /// 创建路径渲染数据实例
  const PathRenderData({
    required this.completedPaths,
    this.currentPath,
    this.dirtyBounds,
  });

  /// 创建空的渲染数据
  factory PathRenderData.empty() {
    return const PathRenderData(completedPaths: []);
  }

  /// 复制并修改部分属性
  PathRenderData copyWith({
    List<PathInfo>? completedPaths,
    PathInfo? currentPath,
    Rect? dirtyBounds,
  }) {
    return PathRenderData(
      completedPaths: completedPaths ?? this.completedPaths,
      currentPath: currentPath ?? this.currentPath,
      dirtyBounds: dirtyBounds ?? this.dirtyBounds,
    );
  }
}
