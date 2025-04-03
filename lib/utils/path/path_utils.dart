import 'dart:math' as math;
import 'dart:ui';

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

  /// 创建实心圆形路径
  static Path createSolidCircle(Offset center, double radius) {
    // 确保使用准确的圆形半径，不进行四舍五入
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  /// 创建两点之间的实心连接路径
  static Path createSolidGap(Offset start, Offset end, double width) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    if (distance < 0.001) {
      // 如果点几乎重合，返回一个小圆
      return createSolidCircle(start, width / 2);
    }

    // 计算垂直于连线的单位向量
    final nx = -dy / distance;
    final ny = dx / distance;

    // 计算四个角点 - 确保使用准确的笔刷宽度，不进行四舍五入
    final halfWidth = width / 2;
    final p1 = Offset(start.dx + nx * halfWidth, start.dy + ny * halfWidth);
    final p2 = Offset(start.dx - nx * halfWidth, start.dy - ny * halfWidth);
    final p3 = Offset(end.dx - nx * halfWidth, end.dy - ny * halfWidth);
    final p4 = Offset(end.dx + nx * halfWidth, end.dy + ny * halfWidth);

    // 创建路径
    final path = Path();
    path.moveTo(p1.dx, p1.dy);
    path.lineTo(p2.dx, p2.dy);
    path.lineTo(p3.dx, p3.dy);
    path.lineTo(p4.dx, p4.dy);
    path.close();

    return path;
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

  /// 检查路径是否为空
  static bool isPathEmpty(Path path) {
    try {
      final bounds = path.getBounds();
      return bounds.isEmpty || (bounds.width < 0.1 && bounds.height < 0.1);
    } catch (e) {
      return true;
    }
  }

  /// 合并多条路径
  static Path mergePaths(List<Path> paths) {
    if (paths.isEmpty) return Path();
    if (paths.length == 1) return paths.first;

    final result = Path();
    for (final path in paths) {
      result.addPath(path, Offset.zero);
    }
    return result;
  }
}
