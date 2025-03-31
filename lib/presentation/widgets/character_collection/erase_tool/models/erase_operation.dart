import 'dart:ui';

import 'erase_mode.dart';

/// 擦除操作
class EraseOperation {
  /// 唯一标识符
  final String id;

  /// 路径点列表
  final List<Offset> points;

  /// 笔刷大小
  final double brushSize;

  /// 擦除模式
  final EraseMode mode;

  /// 创建时间
  final DateTime timestamp;

  /// 脏区域
  Rect? _boundingBox;

  /// 路径缓存
  Path? _cachedPath;

  EraseOperation({
    String? id,
    List<Offset>? points,
    double? brushSize,
    EraseMode? mode,
    DateTime? timestamp,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        points = points ?? <Offset>[],
        brushSize = brushSize ?? 20.0,
        mode = mode ?? EraseMode.normal,
        timestamp = timestamp ?? DateTime.now();

  /// 获取操作的边界矩形
  Rect get bounds {
    if (_boundingBox != null) return _boundingBox!;

    if (points.isEmpty) {
      return Rect.zero;
    }

    double minX = points[0].dx;
    double minY = points[0].dy;
    double maxX = points[0].dx;
    double maxY = points[0].dy;

    for (var point in points) {
      if (point.dx < minX) minX = point.dx;
      if (point.dy < minY) minY = point.dy;
      if (point.dx > maxX) maxX = point.dx;
      if (point.dy > maxY) maxY = point.dy;
    }

    // 考虑笔刷大小
    final halfBrush = brushSize / 2;
    _boundingBox = Rect.fromLTRB(
      minX - halfBrush,
      minY - halfBrush,
      maxX + halfBrush,
      maxY + halfBrush,
    );

    return _boundingBox!;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EraseOperation && other.id == id;
  }

  /// 添加点
  void addPoint(Offset point) {
    points.add(point);
    // 清除缓存
    _boundingBox = null;
    _cachedPath = null;
  }

  /// 应用擦除效果到画布
  void apply(Canvas canvas) {
    if (points.isEmpty) return;

    final path = createPath();
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF) // 白色
      ..strokeWidth = brushSize
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..blendMode = BlendMode.clear; // 清除模式

    // 绘制路径
    canvas.drawPath(path, paint);

    // 在每个点绘制圆形，确保断点处也被擦除
    paint.style = PaintingStyle.fill;
    for (final point in points) {
      canvas.drawCircle(point, brushSize / 2, paint);
    }
  }

  /// 检查是否可以与另一个操作合并
  bool canMergeWith(EraseOperation other) {
    if (mode != other.mode || brushSize != other.brushSize) {
      return false;
    }

    // 检查时间间隔
    const maxTimeGap = Duration(milliseconds: 500);
    if (other.timestamp.difference(timestamp).abs() > maxTimeGap) {
      return false;
    }

    // 检查空间距离
    if (points.isNotEmpty && other.points.isNotEmpty) {
      final lastPoint = points.last;
      final firstPoint = other.points.first;
      const maxDistance = 20.0;
      if ((lastPoint - firstPoint).distance > maxDistance) {
        return false;
      }
    }

    return true;
  }

  /// 创建笔刷路径
  Path createPath() {
    if (_cachedPath != null) return _cachedPath!;

    final path = Path();
    if (points.isEmpty) return path;

    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    _cachedPath = path;
    return path;
  }

  /// 获取边界矩形（用于兼容性）
  Rect getBounds() => bounds;

  /// 与另一个操作合并
  EraseOperation mergeWith(EraseOperation other) {
    if (!canMergeWith(other)) {
      throw StateError('Cannot merge incompatible operations');
    }

    return EraseOperation(
      id: id, // 保持原id
      points: [...points, ...other.points],
      brushSize: brushSize,
      mode: mode,
      timestamp: timestamp,
    );
  }

  /// 优化路径点
  EraseOperation optimize() {
    if (points.length < 3) return this;

    final optimizedPoints = <Offset>[points.first];
    const minDistance = 5.0; // 最小点距离

    for (int i = 1; i < points.length - 1; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final next = points[i + 1];

      // 计算当前点到前后点的距离
      final d1 = (curr - prev).distance;
      final d2 = (next - curr).distance;

      // 如果距离太小，跳过当前点
      if (d1 < minDistance && d2 < minDistance) continue;

      // 计算角度变化
      final angle1 = (curr - prev).direction;
      final angle2 = (next - curr).direction;
      final angleDiff = (angle2 - angle1).abs();

      // 如果角度变化大，保留该点
      if (angleDiff > 0.3) {
        // 约17度
        optimizedPoints.add(curr);
      }
    }

    optimizedPoints.add(points.last);

    return EraseOperation(
      id: id,
      points: optimizedPoints,
      brushSize: brushSize,
      mode: mode,
      timestamp: timestamp,
    );
  }
}
