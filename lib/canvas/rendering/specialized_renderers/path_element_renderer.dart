import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/interfaces/element_data.dart';
import '../canvas_rendering_engine.dart';

/// 路径命令类
class PathCommand {
  final String type;
  final List<double> args;

  PathCommand(this.type, this.args);
}

/// 路径元素专用渲染器
class PathElementRenderer extends ElementRenderer {
  @override
  void render(Canvas canvas, ElementData element) {
    final pathData = element.properties['pathData'] as String?;
    if (pathData == null || pathData.isEmpty) return;

    final path = _parsePath(pathData);
    if (path == null) return;

    final paint = _createPaint(element);
    final strokePaint = _createStrokePaint(element);

    // 缩放路径以适应元素边界
    final scaledPath = _scalePath(path, element.bounds);

    // 绘制填充
    if (paint.color != Colors.transparent) {
      canvas.drawPath(scaledPath, paint);
    }

    // 绘制描边
    if (strokePaint != null) {
      canvas.drawPath(scaledPath, strokePaint);
    }
  }

  /// 添加弧线到路径
  void _addArcToPath(
      Path path,
      double startX,
      double startY,
      double endX,
      double endY,
      double rx,
      double ry,
      double rotation,
      bool largeArc,
      bool sweep) {
    // 简化实现：使用椭圆弧近似
    final centerX = (startX + endX) / 2;
    final centerY = (startY + endY) / 2;

    final rect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: rx * 2,
      height: ry * 2,
    );

    final startAngle = math.atan2(startY - centerY, startX - centerX);
    final endAngle = math.atan2(endY - centerY, endX - centerX);

    double sweepAngle = endAngle - startAngle;
    if (sweep && sweepAngle < 0) sweepAngle += 2 * math.pi;
    if (!sweep && sweepAngle > 0) sweepAngle -= 2 * math.pi;

    path.arcTo(rect, startAngle, sweepAngle, false);
  }

  /// 创建填充画笔
  Paint _createPaint(ElementData element) {
    final props = element.properties;
    final paint = Paint()..style = PaintingStyle.fill;

    final fillColor = props['fillColor'] as String?;
    if (fillColor != null) {
      paint.color = _parseColor(fillColor);
    } else {
      paint.color = Colors.transparent;
    }

    return paint;
  }

  /// 创建描边画笔
  Paint? _createStrokePaint(ElementData element) {
    final props = element.properties;
    final strokeColor = props['strokeColor'] as String?;
    final strokeWidth = (props['strokeWidth'] as num?)?.toDouble() ?? 0.0;

    if (strokeColor == null || strokeWidth <= 0) return null;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = _parseColor(strokeColor)
      ..strokeWidth = strokeWidth;

    // 设置线条端点样式
    final lineCap = props['strokeLineCap'] as String?;
    switch (lineCap) {
      case 'round':
        paint.strokeCap = StrokeCap.round;
        break;
      case 'square':
        paint.strokeCap = StrokeCap.square;
        break;
      default:
        paint.strokeCap = StrokeCap.butt;
        break;
    }

    // 设置线条连接样式
    final lineJoin = props['strokeLineJoin'] as String?;
    switch (lineJoin) {
      case 'round':
        paint.strokeJoin = StrokeJoin.round;
        break;
      case 'bevel':
        paint.strokeJoin = StrokeJoin.bevel;
        break;
      default:
        paint.strokeJoin = StrokeJoin.miter;
        break;
    }

    return paint;
  }

  /// 解析颜色
  Color _parseColor(String colorStr) {
    try {
      if (colorStr.startsWith('#')) {
        final hex = colorStr.substring(1);
        if (hex.length == 6) {
          return Color(int.parse('FF$hex', radix: 16));
        } else if (hex.length == 8) {
          return Color(int.parse(hex, radix: 16));
        }
      }
    } catch (e) {
      // 解析失败，返回默认颜色
    }
    return Colors.black;
  }

  /// 解析SVG路径数据
  Path? _parsePath(String pathData) {
    try {
      final path = Path();
      final commands = _parsePathCommands(pathData);

      double currentX = 0, currentY = 0;
      double lastControlX = 0, lastControlY = 0;

      for (final command in commands) {
        switch (command.type) {
          case 'M': // moveTo
            currentX = command.args[0];
            currentY = command.args[1];
            path.moveTo(currentX, currentY);
            break;

          case 'L': // lineTo
            currentX = command.args[0];
            currentY = command.args[1];
            path.lineTo(currentX, currentY);
            break;

          case 'C': // cubicTo
            lastControlX = command.args[2];
            lastControlY = command.args[3];
            currentX = command.args[4];
            currentY = command.args[5];
            path.cubicTo(
              command.args[0],
              command.args[1],
              lastControlX,
              lastControlY,
              currentX,
              currentY,
            );
            break;

          case 'Q': // quadraticBezierTo
            lastControlX = command.args[0];
            lastControlY = command.args[1];
            currentX = command.args[2];
            currentY = command.args[3];
            path.quadraticBezierTo(
              lastControlX,
              lastControlY,
              currentX,
              currentY,
            );
            break;

          case 'A': // arcTo (简化实现)
            final rx = command.args[0];
            final ry = command.args[1];
            final rotation = command.args[2];
            final largeArc = command.args[3] != 0;
            final sweep = command.args[4] != 0;
            final endX = command.args[5];
            final endY = command.args[6];

            _addArcToPath(path, currentX, currentY, endX, endY, rx, ry,
                rotation, largeArc, sweep);
            currentX = endX;
            currentY = endY;
            break;

          case 'Z': // closePath
            path.close();
            break;
        }
      }

      return path;
    } catch (e) {
      print('Error parsing path data: $e');
      return null;
    }
  }

  /// 解析路径命令
  List<PathCommand> _parsePathCommands(String pathData) {
    final commands = <PathCommand>[];
    final cleanData = pathData.replaceAll(RegExp(r'[,\s]+'), ' ').trim();

    final regex = RegExp(r'([MmLlHhVvCcSsQqTtAaZz])([^MmLlHhVvCcSsQqTtAaZz]*)');
    final matches = regex.allMatches(cleanData);

    for (final match in matches) {
      final type = match.group(1)!.toUpperCase();
      final argsStr = match.group(2)?.trim() ?? '';
      final args = argsStr.isEmpty
          ? <double>[]
          : argsStr
              .split(RegExp(r'\s+'))
              .map((s) => double.tryParse(s) ?? 0.0)
              .toList();

      commands.add(PathCommand(type, args));
    }

    return commands;
  }

  /// 缩放路径以适应边界
  Path _scalePath(Path originalPath, Rect bounds) {
    final pathBounds = originalPath.getBounds();
    if (pathBounds.isEmpty) return originalPath;

    final scaleX = bounds.width / pathBounds.width;
    final scaleY = bounds.height / pathBounds.height;

    final transform = Matrix4.identity()
      ..translate(-pathBounds.left, -pathBounds.top)
      ..scale(scaleX, scaleY);

    return originalPath.transform(transform.storage);
  }
}
