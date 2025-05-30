import 'dart:math' as math;
import 'dart:ui';

import 'package:charasgem/infrastructure/logging/logger.dart';
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

  /// 使用平滑连接创建路径
  static Path createSmoothPath(List<Offset> points, double width) {
    if (points.isEmpty) return Path();
    if (points.length == 1) {
      return createSolidCircle(points[0], width / 2);
    }

    final path = Path();

    // 添加第一个点的圆形
    path.addOval(Rect.fromCircle(center: points.first, radius: width / 2));

    // 添加连接的线段，确保平滑连接
    for (int i = 1; i < points.length; i++) {
      final gap = createSolidGap(points[i - 1], points[i], width);
      path.addPath(gap, Offset.zero);
    }

    return path;
  }

  /// 创建实心圆形路径
  static Path createSolidCircle(Offset center, double radius) {
    // 确保使用准确的圆形半径，不进行四舍五入
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  /// 创建两点之间的实心连接路径，改进版
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

    // 计算四个角点，确保精确表示
    final halfWidth = width / 2;
    final p1 = Offset(start.dx + nx * halfWidth, start.dy + ny * halfWidth);
    final p2 = Offset(start.dx - nx * halfWidth, start.dy - ny * halfWidth);
    final p3 = Offset(end.dx - nx * halfWidth, end.dy - ny * halfWidth);
    final p4 = Offset(end.dx + nx * halfWidth, end.dy + ny * halfWidth);

    // 创建路径，使用更精确的控制
    final path = Path();

    // 使用更精确的方式绘制四边形，确保边角处理正确
    path.moveTo(p1.dx, p1.dy);
    path.lineTo(p2.dx, p2.dy);
    path.lineTo(p3.dx, p3.dy);
    path.lineTo(p4.dx, p4.dy);

    // 确保路径闭合，防止边角泄漏
    path.close();

    // 为保证圆形的端点，添加两个半圆
    final startCircle = createSolidCircle(start, halfWidth);
    final endCircle = createSolidCircle(end, halfWidth);

    // 合并所有部分，确保完整覆盖
    path.addPath(startCircle, Offset.zero);
    path.addPath(endCircle, Offset.zero);

    return path;
  }

  /// 获取路径的边界矩形，安全处理
  static Rect? getPathBounds(Path path) {
    try {
      return path.getBounds();
    } catch (e) {
      AppLogger.error('获取路径边界出错', error: e);
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
