import 'package:flutter/material.dart';

/// 路径处理工具类
class PathUtils {
  /// 克隆路径并确保闭合
  static Path clonePath(Path source, {bool close = true}) {
    final result = Path()..addPath(source, Offset.zero);
    if (close) result.close();
    return result;
  }

  /// 将多个路径合并为一个实心区域
  static Path combineToSolidPath(List<Path> paths, double strokeWidth) {
    if (paths.isEmpty) return Path();

    final result = Path();
    for (final path in paths) {
      // 为每个路径点创建一个圆形区域
      for (final metric in path.computeMetrics()) {
        var distance = 0.0;
        while (distance < metric.length) {
          final tangent = metric.getTangentForOffset(distance);
          if (tangent != null) {
            result.addOval(
              Rect.fromCircle(
                center: tangent.position,
                radius: strokeWidth / 2,
              ),
            );
          }
          // 每次移动一小段距离，确保圆形之间有重叠
          distance += strokeWidth / 4;
        }
      }
    }
    return result..close();
  }

  /// 创建一个圆形的实心路径
  static Path createSolidCircle(Offset center, double radius) {
    return Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..close();
  }

  /// 连接两点之间的间隙，创建实心区域
  static Path createSolidGap(Offset start, Offset end, double width) {
    final path = Path();
    final distance = (end - start).distance;

    // 如果距离太小，只创建一个圆形
    if (distance < width / 2) {
      path.addOval(Rect.fromCircle(center: end, radius: width / 2));
      return path..close();
    }

    // 计算需要的圆形数量，确保有足够的重叠
    final steps = (distance / (width / 4)).ceil();
    print('创建间隙路径 - 距离: $distance, 步数: $steps');

    // 在两点之间插入均匀分布的圆形
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final point = Offset(
        start.dx + (end.dx - start.dx) * t,
        start.dy + (end.dy - start.dy) * t,
      );
      path.addOval(Rect.fromCircle(center: point, radius: width / 2));
    }

    return path..close();
  }

  /// 获取路径的边界矩形，安全处理
  static Rect? getPathBounds(Path path) {
    try {
      return path.getBounds();
    } catch (e) {
      print('获取路径边界出错: $e');
      return null;
    }
  }

  /// 判断路径是否为空
  static bool isPathEmpty(Path path) {
    final bounds = getPathBounds(path);
    if (bounds == null) return true;
    return bounds.isEmpty;
  }

  /// 智能合并多个路径为一个实心区域
  static Path mergePaths(List<Path> paths, {bool close = true}) {
    if (paths.isEmpty) return Path();
    if (paths.length == 1) {
      final result = Path()..addPath(paths.first, Offset.zero);
      if (close) result.close();
      return result;
    }

    var result = Path()..addPath(paths.first, Offset.zero);
    for (int i = 1; i < paths.length; i++) {
      try {
        result = Path.combine(PathOperation.union, result, paths[i]);
      } catch (e) {
        print('合并路径出错: $e');
      }
    }
    if (close) result.close();
    return result;
  }
}
