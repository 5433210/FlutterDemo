import 'dart:ui';

/// 表示单个擦除操作的数据模型
class EraseOperation {
  /// 操作唯一标识符
  final String id;

  /// 擦除点列表
  final List<Offset> points;

  /// 笔刷大小
  final double brushSize;

  /// 操作时间戳
  final DateTime timestamp;

  /// 创建一个擦除操作
  EraseOperation({
    required this.id,
    List<Offset>? points,
    required this.brushSize,
    DateTime? timestamp,
  })  : points = points ?? <Offset>[],
        timestamp = timestamp ?? DateTime.now();

  /// 添加擦除点
  void addPoint(Offset point) {
    points.add(point);
  }

  /// 将操作应用到画布上
  void apply(Canvas canvas) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = const Color(0x00000000) // 透明色
      ..strokeWidth = brushSize
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..blendMode = BlendMode.clear; // 使用清除混合模式实现擦除效果

    // 创建路径并添加点
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  /// 判断两个操作是否可以合并
  /// 用于优化历史记录和性能
  bool canMergeWith(EraseOperation other) {
    // 如果两个操作时间间隔小于500毫秒，认为它们是连续的操作
    final timeDifference =
        timestamp.difference(other.timestamp).inMilliseconds.abs();
    if (timeDifference > 500) return false;

    // 如果笔刷大小不同，不合并
    if (brushSize != other.brushSize) return false;

    // 如果点之间的距离太远，不合并
    if (points.isNotEmpty && other.points.isNotEmpty) {
      final distance = (points.last - other.points.first).distance;
      return distance < brushSize * 2; // 如果距离小于两倍笔刷大小，认为可以合并
    }

    return false;
  }

  /// 创建此操作的副本
  EraseOperation copyWith({
    String? id,
    List<Offset>? points,
    double? brushSize,
    DateTime? timestamp,
  }) {
    return EraseOperation(
      id: id ?? this.id,
      points: points ?? List<Offset>.from(this.points),
      brushSize: brushSize ?? this.brushSize,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// 计算操作的边界矩形，用于局部更新
  Rect getBounds() {
    if (points.isEmpty) return Rect.zero;

    double minX = points.first.dx;
    double minY = points.first.dy;
    double maxX = points.first.dx;
    double maxY = points.first.dy;

    for (final point in points) {
      if (point.dx < minX) minX = point.dx;
      if (point.dy < minY) minY = point.dy;
      if (point.dx > maxX) maxX = point.dx;
      if (point.dy > maxY) maxY = point.dy;
    }

    // 添加笔刷大小的半径，确保包含所有可能被擦除的区域
    return Rect.fromLTRB(
      minX - brushSize / 2,
      minY - brushSize / 2,
      maxX + brushSize / 2,
      maxY + brushSize / 2,
    );
  }
}
