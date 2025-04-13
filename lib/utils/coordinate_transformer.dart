import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import '../infrastructure/logging/logger.dart';

/// 坐标转换工具类 - 使用左上角作为原点的实现
class CoordinateTransformer {
  final TransformationController transformationController;
  final Size imageSize;
  final Size viewportSize;
  final bool enableLogging;

  // 缓存变量
  late double _baseScale;
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

  /// 更新实际偏移量 - 考虑实际缩放比的影响
  Offset get actualOffset {
    final offset = currentOffset;
    final acScale = actualScale;
    return Offset(offset.dx / acScale, offset.dy / acScale);
  }

  /// 更新实际缩放比
  double get actualScale => currentScale * baseScale;

  /// 获取基础缩放比例 - 使图像刚好适应视口
  double get baseScale => _baseScale;

  /// 获取当前偏移量 - 直接从变换矩阵提取
  Offset get currentOffset {
    final matrix = transformationController.value;
    return Offset(matrix.entry(0, 3), matrix.entry(1, 3));
  }

  /// 获取当前缩放比例 - 从变换矩阵中提取
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
  /// 返回一个偏移量列表，每两个点构成一条线
  /// gridSize: 网格大小(像素)
  List<Offset> calculateGridLines(double gridSize) {
    final List<Offset> lines = [];
    final scale = currentScale;
    final scaledGridSize = gridSize * scale;
    final rect = displayRect;

    // 计算网格范围
    final startX = (rect.left / scaledGridSize).floor() * scaledGridSize;
    final endX = (rect.right / scaledGridSize).ceil() * scaledGridSize;
    final startY = (rect.top / scaledGridSize).floor() * scaledGridSize;
    final endY = (rect.bottom / scaledGridSize).ceil() * scaledGridSize;

    // 垂直线
    for (double x = startX; x <= endX; x += scaledGridSize) {
      lines.add(Offset(x, startY));
      lines.add(Offset(x, endY));
    }

    // 水平线
    for (double y = startY; y <= endY; y += scaledGridSize) {
      lines.add(Offset(startX, y));
      lines.add(Offset(endX, y));
    }

    if (enableLogging) {
      AppLogger.debug('生成网格线', data: {
        'gridSize': gridSize,
        'scaledGridSize': scaledGridSize.toStringAsFixed(2),
        'lineCount': (lines.length ~/ 2).toInt(),
      });
    }

    return lines;
  }

  /// 从PreviewCanvas中迁移的计算图像在视口中显示区域的方法
  Rect calculateImageRectInViewport() {
    // 计算图像在视口中的显示区域
    final matrix = transformationController.value;
    final topLeft = imageToViewportCoordinate(Offset.zero);
    final bottomRight = imageToViewportCoordinate(
      Offset(imageSize.width, imageSize.height),
    );

    return Rect.fromPoints(topLeft, bottomRight);
  }

  /// 图像矩形转换为视口矩形
  Rect imageRectToViewportRect(Rect imageRect) {
    // if (enableLogging) {
    //   AppLogger.debug('【坐标转换】将图像矩形转换为视口矩形', data: {
    //     'imageRect':
    //         '${imageRect.left},${imageRect.top},${imageRect.width}x${imageRect.height}',
    //     'imageSize': '${imageSize.width}x${imageSize.height}',
    //     'viewportSize': '${viewportSize.width}x${viewportSize.height}',
    //   });
    // }

    // try {
    //   // 1. 检查输入矩形是否有效
    //   if (imageRect.isEmpty || imageRect.width < 0 || imageRect.height < 0) {
    //     throw ArgumentError('无效的输入矩形: $imageRect');
    //   }

    //   // 2. 确保输入矩形在图像范围内
    //   final clampedImageRect = Rect.fromLTRB(
    //     imageRect.left.clamp(0.0, imageSize.width),
    //     imageRect.top.clamp(0.0, imageSize.height),
    //     imageRect.right.clamp(0.0, imageSize.width),
    //     imageRect.bottom.clamp(0.0, imageSize.height),
    //   );

    //   // 3. 转换矩形的角点
    //   final topLeft = imageToViewportCoordinate(clampedImageRect.topLeft);
    //   final bottomRight =
    //       imageToViewportCoordinate(clampedImageRect.bottomRight);

    //   // 4. 创建视口矩形并确保在视口范围内
    //   final viewportRect = Rect.fromPoints(topLeft, bottomRight)
    //       .intersect(Offset.zero & viewportSize);

    //   if (enableLogging) {
    //     AppLogger.debug('【坐标转换】转换结果', data: {
    //       'viewportRect':
    //           '${viewportRect.left},${viewportRect.top},${viewportRect.width}x${viewportRect.height}',
    //       'actualScale': actualScale.toStringAsFixed(3),
    //     });
    //   }

    //   return viewportRect;
    // } catch (e) {
    //   AppLogger.error('【坐标转换】图像矩形转换失败', error: e);
    //   // 发生错误时返回一个安全的默认值 - 视口中心的1x1矩形
    //   return Rect.fromCenter(
    //     center: Offset(viewportSize.width / 2, viewportSize.height / 2),
    //     width: 1,
    //     height: 1,
    //   );
    // }
    return imageRect; // 直接返回图像矩形 - 可能需要根据实际需求进行调整
  }

  /// 图像坐标转换为视口坐标
  Offset imageToViewportCoordinate(Offset imageCoord) {
    // if (enableLogging) {
    //   AppLogger.debug('【坐标转换】将图像坐标转换为视口坐标: ${imageCoord.dx},${imageCoord.dy}');
    // }

    // // 1. 应用缩放
    // final acScale = actualScale;
    // final scaledOffset = Offset(
    //   imageCoord.dx * acScale,
    //   imageCoord.dy * acScale,
    // );

    // // 2. 应用平移，得到最终视口坐标
    // final viewportRect = Offset(
    //     scaledOffset.dx + currentOffset.dx, scaledOffset.dy + currentOffset.dy);

    // if (enableLogging) {
    //   AppLogger.debug('【坐标转换】视图→视口: '
    //       '(${imageCoord.dx.toStringAsFixed(1)},${imageCoord.dy.toStringAsFixed(1)}) → '
    //       '(${viewportRect.dx.toStringAsFixed(1)},${viewportRect.dy.toStringAsFixed(1)})'
    //       ' [scale=$acScale, offset=${currentOffset.dx.toStringAsFixed(1)},${currentOffset.dy.toStringAsFixed(1)}]');
    // }

    // return viewportRect;
    return imageCoord; // 直接返回图像坐标 - 可能需要根据实际需求进行调整
  }

  /// 记录坐标转换过程 - 用于调试
  void logCoordinateConversion(Offset viewportPoint) {
    if (!enableLogging) return;

    final imagePoint = viewportToViewCoordinate(viewportPoint);
    final scale = actualScale;

    AppLogger.debug('坐标转换详情', data: {
      'viewport': '${viewportPoint.dx.toInt()},${viewportPoint.dy.toInt()}',
      'image': '${imagePoint.dx.toInt()},${imagePoint.dy.toInt()}',
      'currentScale': currentScale.toStringAsFixed(2),
      'baseScale': baseScale.toStringAsFixed(2),
      'actualScale': scale.toStringAsFixed(2),
      'offset':
          '${currentOffset.dx.toStringAsFixed(1)},${currentOffset.dy.toStringAsFixed(1)}',
    });
  }

  /// 鼠标点击坐标（相对组件左上角）直接转换为图像坐标
  Offset mouseToViewCoordinate(Offset mousePoint) {
    try {
      if (enableLogging) {
        AppLogger.debug(
            '【坐标转换】将鼠标坐标转换为图像坐标: ${mousePoint.dx},${mousePoint.dy}');
      }

      // 直接使用鼠标坐标作为视口坐标
      final adjustedPoint = mousePoint;

      AppLogger.debug('【坐标转换】鼠标坐标转换为视口坐标(相对中心点): '
          '(${mousePoint.dx},${mousePoint.dy}) → '
          '(${adjustedPoint.dx},${adjustedPoint.dy})');

      return viewportToViewCoordinate(adjustedPoint);
    } catch (e) {
      AppLogger.error('【坐标转换】鼠标坐标转换为图像坐标失败', error: e);
      return Offset.zero;
    }
  }

  /// 重新计算基础缩放比例 - 用于视口尺寸变化时
  void recalculateBaseScale() {
    _calculateBaseScale();
    if (enableLogging) {
      AppLogger.debug('重新计算基础缩放比例', data: {
        'newBaseScale': _baseScale.toStringAsFixed(3),
      });
    }
  }

  Rect viewportRectToImageRect(Rect viewportRect) {
    if (enableLogging) {
      AppLogger.debug(
          '【矩形转换】将视口矩形转换为图像矩形: ${viewportRect.left},${viewportRect.top},${viewportRect.width}x${viewportRect.height}');
    }
    final topLeft = viewportToViewCoordinate(viewportRect.topLeft);
    final bottomRight = viewportToViewCoordinate(viewportRect.bottomRight);

    final viewRect = Rect.fromPoints(topLeft, bottomRight);
    final imageRect = viewRectToImageRect(viewRect);
    if (enableLogging) {
      AppLogger.debug(
          '【矩形转换】转换结果: ${imageRect.left},${imageRect.top},${imageRect.width}x${imageRect.height}');
    }

    return imageRect;
  }

  /// 从PreviewCanvas._transformToImageCoordinates迁移
  /// 将视口坐标转换为图像坐标，考虑了当前变换和设备像素比
  Offset viewportToImageCoordinate(Offset viewportOffset) {
    // 1. 基础转换 - 从PreviewCanvas迁移
    final matrix = transformationController.value.clone();
    final vector = Matrix4.inverted(matrix)
        .transform3(Vector3(viewportOffset.dx, viewportOffset.dy, 0));
    final basicTransform = Offset(vector.x, vector.y);

    // 2. 增强功能 - 设备像素比处理
    return basicTransform;
  }

  /// 视口坐标转换为图像坐标
  /// 按照公式: Xview = (Xviewport/ActualScaleX) - ActualOffsetX
  Offset viewportToViewCoordinate(Offset viewportPoint) {
    // try {
    //   if (enableLogging) {
    //     AppLogger.debug(
    //         '【坐标转换】将视口坐标转换为图像坐标: ${viewportPoint.dx},${viewportPoint.dy}');
    //   }

    //   // 计算实际缩放比例
    //   final actualScale = currentScale * baseScale;

    //   // 计算实际偏移量
    //   final actualOffset = Offset(
    //     currentOffset.dx / actualScale,
    //     currentOffset.dy / actualScale,
    //   );

    //   AppLogger.debug('【坐标转换】计算参数', data: {
    //     'currentScale': currentScale.toStringAsFixed(3),
    //     'baseScale': baseScale.toStringAsFixed(3),
    //     'actualScale': actualScale.toStringAsFixed(3),
    //     'currentOffset': '${currentOffset.dx},${currentOffset.dy}',
    //     'actualOffset': '${actualOffset.dx},${actualOffset.dy}',
    //   });

    //   // 应用转换公式: Xview = (Xviewport/ActualScaleX) - ActualOffsetX
    //   final viewCoordinate = Offset(
    //     viewportPoint.dx / actualScale - actualOffset.dx,
    //     viewportPoint.dy / actualScale - actualOffset.dy,
    //   );

    //   AppLogger.debug('【坐标转换】转换结果', data: {
    //     'viewportPoint': '${viewportPoint.dx},${viewportPoint.dy}',
    //     'viewCoordinate': '${viewCoordinate.dx},${viewCoordinate.dy}',
    //   });

    //   return viewCoordinate;
    // } catch (e) {
    //   AppLogger.error('【坐标转换】视口坐标转换为图像坐标失败', error: e);
    //   return Offset.zero;
    // }
    return viewportPoint; // 直接返回视口坐标 - 可能需要根据实际需求进行调整
  }

  Rect viewRectToImageRect(Rect viewRect) {
    if (enableLogging) {
      AppLogger.debug(
          '【坐标转换】将视图矩形转换为图像矩形: ${viewRect.left},${viewRect.top},${viewRect.width}x${viewRect.height}');
    }

    // 直接使用视图坐标作为图像坐标
    return Rect.fromLTWH(
        viewRect.left, viewRect.top, viewRect.width, viewRect.height);
  }

  /// 计算基础缩放比例
  /// 根据公式:
  /// if (ViewportHeight/ViewportWidth < ImageHeight/ImageWidth):
  ///     BaseScale = ViewportWidth/ImageWidth
  /// else:
  ///     BaseScale = ViewportHeight/ImageHeight
  void _calculateBaseScale() {
    final viewportRatio = viewportSize.width / viewportSize.height;
    final imageRatio = imageSize.width / imageSize.height;

    if (viewportRatio < imageRatio) {
      // 宽度适配 - 图像宽度充满视口宽度
      _baseScale = viewportSize.width / imageSize.width;
    } else {
      // 高度适配 - 图像高度充满视口高度
      _baseScale = viewportSize.height / imageSize.height;
    }

    if (enableLogging) {
      AppLogger.debug('基础缩放计算', data: {
        'viewportRatio': viewportRatio.toStringAsFixed(3),
        'imageRatio': imageRatio.toStringAsFixed(3),
        'mode': viewportRatio < imageRatio ? '宽度适配' : '高度适配',
        'baseScale': _baseScale.toStringAsFixed(3),
      });
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

  /// 应用矩阵变换到点 - 辅助方法
  Offset _transformPoint(Offset point, Matrix4 transform) {
    // 直接使用点坐标
    final vector = Vector3(point.dx, point.dy, 0.0);

    // 应用变换
    final transformed = transform.transform3(vector);

    // 返回变换后的坐标
    return Offset(transformed.x, transformed.y);
  }
}
