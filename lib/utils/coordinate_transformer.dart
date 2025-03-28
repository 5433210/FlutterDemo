import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import '../infrastructure/logging/logger.dart';

/// 坐标转换工具类 - 使用容器中心点作为原点的实现
class CoordinateTransformer {
  final TransformationController transformationController;
  final Size imageSize;
  final Size viewportSize;
  final bool enableLogging;

  // 缓存变量
  late final double _baseScale;
  late final Offset _viewportCenter;

  CoordinateTransformer({
    required this.transformationController,
    required this.imageSize,
    required this.viewportSize,
    this.enableLogging = false,
  }) {
    _viewportCenter = Offset(viewportSize.width / 2, viewportSize.height / 2);
    _calculateBaseScale();
    if (enableLogging) {
      _logInitialization();
    }
  }

  /// 获取实际偏移量
  Offset get actualOffset {
    final current = currentOffset;
    return Offset(
      current.dx * actualScale,
      current.dy * actualScale,
    );
  }

  /// 获取实际缩放比
  double get actualScale => currentScale / baseScale;

  /// 获取基础缩放比例
  double get baseScale => _baseScale;

  /// 获取当前偏移量
  Offset get currentOffset {
    final matrix = transformationController.value;
    return Offset(matrix.entry(0, 3), matrix.entry(1, 3));
  }

  /// 获取当前旋转角度（如果需要支持旋转）
  double get currentRotation {
    final matrix = transformationController.value;
    // 使用两个缩放轴的平均值可能更准确
    final a = matrix.entry(0, 0);
    final b = matrix.entry(0, 1);
    final c = matrix.entry(1, 0);
    final d = matrix.entry(1, 1);
    return math.sqrt(a * a + b * b + c * c + d * d) / math.sqrt(2);
  }

  /// 获取当前缩放比例
  double get currentScale {
    final matrix = transformationController.value;
    return matrix.getMaxScaleOnAxis();
  }

  /// 获取图像在视口中的显示区域
  Rect get displayRect {
    final matrix = transformationController.value;

    // 使用矩阵变换计算四个角的位置
    final topLeft = _transformPoint(Offset.zero, matrix);
    final topRight = _transformPoint(Offset(imageSize.width, 0), matrix);
    final bottomLeft = _transformPoint(Offset(0, imageSize.height), matrix);
    final bottomRight =
        _transformPoint(Offset(imageSize.width, imageSize.height), matrix);

    // 找出边界
    final left = math.min(math.min(topLeft.dx, topRight.dx),
        math.min(bottomLeft.dx, bottomRight.dx));
    final top = math.min(math.min(topLeft.dy, topRight.dy),
        math.min(bottomLeft.dy, bottomRight.dy));
    final right = math.max(math.max(topLeft.dx, topRight.dx),
        math.max(bottomLeft.dx, bottomRight.dx));
    final bottom = math.max(math.max(topLeft.dy, topRight.dy),
        math.max(bottomLeft.dy, bottomRight.dy));

    return Rect.fromLTRB(left, top, right, bottom);
  }

  /// 计算网格线
  List<Offset> calculateGridLines(double gridSize) {
    final List<Offset> lines = [];
    final displayRect = this.displayRect;
    final adjustedSpacing = gridSize * currentScale;

    // 计算网格线范围
    final startX =
        (displayRect.left / adjustedSpacing).floor() * adjustedSpacing;
    final endX = displayRect.right;
    final startY =
        (displayRect.top / adjustedSpacing).floor() * adjustedSpacing;
    final endY = displayRect.bottom;

    // 绘制垂直线
    for (double x = startX; x <= endX; x += adjustedSpacing) {
      lines.add(Offset(x, displayRect.top));
      lines.add(Offset(x, displayRect.bottom));
    }

    // 绘制水平线
    for (double y = startY; y <= endY; y += adjustedSpacing) {
      lines.add(Offset(displayRect.left, y));
      lines.add(Offset(displayRect.right, y));
    }

    return lines;
  }

  /// 图像矩形转换为视口矩形
  Rect imageRectToViewportRect(Rect imageRect) {
    final topLeft = imageToViewportCoordinate(imageRect.topLeft);
    final bottomRight = imageToViewportCoordinate(imageRect.bottomRight);
    return Rect.fromPoints(topLeft, bottomRight);
  }

  /// 图像坐标转换为视口坐标
  Offset imageToViewportCoordinate(Offset imageCoord) {
    final matrix = transformationController.value;

    // 使用变换矩阵转换坐标
    final vector3 = matrix.transform3(Vector3(
      imageCoord.dx - imageSize.width / 2, // 相对于图片中心的坐标
      imageCoord.dy - imageSize.height / 2,
      0,
    ));

    // 转换为相对于视口中心的坐标
    return Offset(
      vector3.x + _viewportCenter.dx,
      vector3.y + _viewportCenter.dy,
    );
  }

  /// 记录坐标转换过程
  void logCoordinateConversion(Offset viewportPoint) {
    if (!enableLogging) return;

    final imagePoint = viewportToImageCoordinate(viewportPoint);

    AppLogger.debug('坐标转换', data: {
      'viewport': '${viewportPoint.dx.toInt()},${viewportPoint.dy.toInt()}',
      'image': '${imagePoint.dx.toInt()},${imagePoint.dy.toInt()}',
      'scale': currentScale.toStringAsFixed(2),
    });
  }

  /// 视口坐标转换为图像坐标
  Offset viewportToImageCoordinate(Offset viewportPoint) {
    try {
      // 计算逆变换矩阵
      final inverseMatrix = Matrix4.inverted(transformationController.value);

      // 使用逆变换转换坐标
      final relativePoint = Offset(
        viewportPoint.dx - _viewportCenter.dx,
        viewportPoint.dy - _viewportCenter.dy,
      );
      final vector3 = inverseMatrix
          .transform3(Vector3(relativePoint.dx, relativePoint.dy, 0));

      // 确保坐标在图像范围内
      final result = Offset(vector3.x.clamp(0, imageSize.width),
          vector3.y.clamp(0, imageSize.height));

      return result;
    } catch (e) {
      AppLogger.error('视口坐标转换为图像坐标失败', error: e);
      return Offset.zero;
    }
  }

  /// 视口坐标转换为视图坐标 (为兼容旧代码保留)
  Offset viewportToViewCoordinate(Offset viewportPoint) {
    return viewportToImageCoordinate(viewportPoint);
  }

  /// 视图坐标转换为图像坐标 (为兼容旧代码保留)
  Offset viewToImageCoordinate(Offset viewCoord) {
    return viewCoord;
  }

  /// 计算基础缩放比例
  void _calculateBaseScale() {
    final viewportRatio = viewportSize.width / viewportSize.height;
    final imageRatio = imageSize.width / imageSize.height;

    if (viewportRatio < imageRatio) {
      // 宽度适配
      _baseScale = viewportSize.width / imageSize.width;
    } else {
      // 高度适配
      _baseScale = viewportSize.height / imageSize.height;
    }
  }

  /// 记录初始化信息
  void _logInitialization() {
    AppLogger.debug('坐标转换器初始化', data: {
      'imageSize': '${imageSize.width}x${imageSize.height}',
      'viewportSize': '${viewportSize.width}x${viewportSize.height}',
      'baseScale': _baseScale.toStringAsFixed(3),
      'viewportCenter': '${_viewportCenter.dx},${_viewportCenter.dy}',
    });
  }

  /// 应用矩阵变换到点
  Offset _transformPoint(Offset point, Matrix4 transform) {
    final vector = transform.transform3(Vector3(
        point.dx - imageSize.width / 2, point.dy - imageSize.height / 2, 0.0));
    return Offset(vector.x, vector.y);
  }
}
