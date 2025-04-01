import 'dart:ui';

/// 路径平滑处理工具类
class PathSmoothing {
  /// 对路径点进行插值，创建更平滑的路径
  static Path createSmoothPath(List<Offset> points, {double tension = 0.5}) {
    if (points.length < 2) {
      final path = Path();
      if (points.isNotEmpty) {
        path.moveTo(points[0].dx, points[0].dy);
      }
      return path;
    }

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    if (points.length == 2) {
      // 只有两个点时，直接连线
      path.lineTo(points[1].dx, points[1].dy);
      return path;
    }

    // 使用三次贝塞尔曲线创建平滑曲线
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i < points.length - 2 ? points[i + 2] : p2;

      // 计算控制点
      final c1 = Offset(
        p1.dx + (p2.dx - p0.dx) * tension,
        p1.dy + (p2.dy - p0.dy) * tension,
      );
      final c2 = Offset(
        p2.dx - (p3.dx - p1.dx) * tension,
        p2.dy - (p3.dy - p1.dy) * tension,
      );

      // 添加三次贝塞尔曲线
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }

    return path;
  }

  /// 在两点之间插入额外的点，使路径更连续
  static List<Offset> interpolatePoints(List<Offset> points,
      {double maxDistance = 5.0}) {
    if (points.length < 2) return List.from(points);

    final result = <Offset>[];
    result.add(points.first);

    for (int i = 1; i < points.length; i++) {
      final start = points[i - 1];
      final end = points[i];
      final distance = (end - start).distance;

      if (distance > maxDistance) {
        // 在两点间插入额外的点
        final count = (distance / maxDistance).ceil();
        for (int j = 1; j < count; j++) {
          final t = j / count;
          result.add(Offset(
            start.dx + (end.dx - start.dx) * t,
            start.dy + (end.dy - start.dy) * t,
          ));
        }
      }

      result.add(end);
    }

    return result;
  }

  /// 对路径进行点采样，减少不必要的点
  static List<Offset> samplePoints(List<Offset> points,
      {double minDistance = 2.0}) {
    if (points.length < 3) return List.from(points);

    final result = <Offset>[];
    result.add(points.first);

    Offset lastPoint = points.first;
    for (int i = 1; i < points.length - 1; i++) {
      final current = points[i];
      if ((current - lastPoint).distance >= minDistance) {
        result.add(current);
        lastPoint = current;
      }
    }

    result.add(points.last);
    return result;
  }
}
