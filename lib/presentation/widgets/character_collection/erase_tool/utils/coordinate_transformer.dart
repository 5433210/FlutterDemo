import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

/// 坐标转换工具类
/// 负责处理不同坐标系之间的转换，特别是处理InteractiveViewer下的坐标变换
class CoordinateTransformer {
  /// 变换矩阵
  Matrix4 _transformMatrix = Matrix4.identity();

  /// 容器尺寸
  Size _containerSize = Size.zero;

  /// 图像尺寸
  Size _imageSize = Size.zero;

  /// 容器偏移
  Offset _containerOffset = Offset.zero;

  /// 视口区域
  Rect _viewport = Rect.zero;

  /// 基础缩放比例
  double _baseScale = 1.0;

  /// 中心偏移
  Offset _centerOffset = Offset.zero;

  /// 构造函数
  CoordinateTransformer({
    Matrix4? transformMatrix,
    Size? containerSize,
    Size? imageSize,
    Offset? containerOffset,
  }) {
    if (transformMatrix != null) _transformMatrix = transformMatrix;
    if (containerSize != null) _containerSize = containerSize;
    if (imageSize != null) _imageSize = imageSize;
    if (containerOffset != null) _containerOffset = containerOffset;
    _calculateBaseScale();
    _calculateCenterOffset();
  }

  /// 初始化变换参数
  void initializeTransform({
    required Matrix4 transformMatrix,
    required Size containerSize,
    required Size imageSize,
    Offset? containerOffset,
    Rect? viewport,
  }) {
    _transformMatrix = transformMatrix;
    _containerSize = containerSize;
    _imageSize = imageSize;
    _containerOffset = containerOffset ?? Offset.zero;
    if (viewport != null) {
      _viewport = viewport;
      print(
          '📺 Viewport: ${viewport.left},${viewport.top},${viewport.width}x${viewport.height}');
    }
    _calculateBaseScale();
    _calculateCenterOffset();
    print('🔄 初始化参数:');
    print('📐 容器尺寸: $_containerSize');
    print('🖼️ 图像尺寸: $_imageSize');
    print('📏 基础缩放: $_baseScale');
    print('🎯 中心偏移: $_centerOffset');
  }

  /// 将界面坐标转换为图像坐标
  Offset transformPoint(Offset point) {
    print('💫 坐标转换 [transformPoint]');
    print('➡️ 输入界面坐标: $point');

    try {
      // 1. 考虑视口偏移
      final viewportAdjustedPoint =
          point - Offset(_viewport.left, _viewport.top);
      print('📺 视口调整后: $viewportAdjustedPoint');

      // 2. 考虑容器偏移和中心偏移
      final adjustedPoint = viewportAdjustedPoint - _containerOffset;
      print('↔️ 考虑容器偏移后: $adjustedPoint');

      // 3. 获取当前变换矩阵信息
      final scale = _transformMatrix.getMaxScaleOnAxis();
      print('📏 变换矩阵缩放: $scale');
      print('📏 基础缩放: $_baseScale');

      // 4. 应用变换矩阵的逆变换
      final inverted = Matrix4.inverted(_transformMatrix);
      final vector = Vector3(adjustedPoint.dx - _centerOffset.dx,
          adjustedPoint.dy - _centerOffset.dy, 0);
      vector.applyMatrix4(inverted);

      // 5. 计算最终图像坐标
      // 需要考虑基础缩放和中心偏移的复合效果
      final rawResult = Offset(
        (vector.x) / _baseScale + _imageSize.width / 2,
        (vector.y) / _baseScale + _imageSize.height / 2,
      );
      print('📏 原始计算结果: $rawResult');

      // 6. 验证结果是否在图像边界内
      final validatedResult = _validatePoint(rawResult);
      print('✅ 最终图像坐标: $validatedResult');

      return validatedResult;
    } catch (e) {
      print('❌ 坐标转换错误: $e');
      // 错误时返回默认处理
      return _fallbackTransform(point);
    }
  }

  /// 更新容器偏移
  void updateContainerOffset(Offset offset) {
    _containerOffset = offset;
  }

  /// 更新容器尺寸
  void updateContainerSize(Size size) {
    _containerSize = size;
    _calculateBaseScale();
    _calculateCenterOffset();
  }

  /// 更新图像尺寸
  void updateImageSize(Size size) {
    _imageSize = size;
    _calculateBaseScale();
    _calculateCenterOffset();
  }

  /// 更新变换矩阵
  void updateTransform(Matrix4 matrix) {
    _transformMatrix = matrix;
    print('📐 更新变换矩阵: scale=${matrix.getMaxScaleOnAxis()}');
  }

  /// 更新视口区域
  void updateViewport(Rect viewport) {
    _viewport = viewport;
    print(
        '📺 更新视口: ${viewport.left},${viewport.top},${viewport.width}x${viewport.height}');
  }

  /// 计算基础缩放比例
  void _calculateBaseScale() {
    if (_imageSize.width <= 0 ||
        _imageSize.height <= 0 ||
        _containerSize.width <= 0 ||
        _containerSize.height <= 0) {
      _baseScale = 1.0;
      return;
    }

    // 计算适合容器的缩放比例
    final scaleX = _containerSize.width / _imageSize.width;
    final scaleY = _containerSize.height / _imageSize.height;

    // 取小者确保图像完全适合容器
    _baseScale = scaleX < scaleY ? scaleX : scaleY;

    print('📏 缩放计算: ');
    print('  - 容器尺寸: $_containerSize');
    print('  - 图像尺寸: $_imageSize');
    print('  - X轴缩放: $scaleX');
    print('  - Y轴缩放: $scaleY');
    print('  - 最终基础缩放: $_baseScale');
  }

  /// 计算中心偏移
  void _calculateCenterOffset() {
    // 计算容器中心
    final containerCenterX = _containerSize.width / 2;
    final containerCenterY = _containerSize.height / 2;

    // 由于图像在容器中居中显示，需要考虑这个居中偏移
    _centerOffset = Offset(containerCenterX, containerCenterY);
    print('🎯 中心偏移计算: $_centerOffset');
  }

  /// 坐标转换失败时的回退处理
  Offset _fallbackTransform(Offset point) {
    // 简单比例转换
    final scaleX = _imageSize.width / _containerSize.width;
    final scaleY = _imageSize.height / _containerSize.height;

    final imageX = point.dx * scaleX;
    final imageY = point.dy * scaleY;

    return _validatePoint(Offset(imageX, imageY));
  }

  /// 验证点是否在图像范围内
  Offset _validatePoint(Offset point) {
    final dx = point.dx.clamp(0.0, _imageSize.width);
    final dy = point.dy.clamp(0.0, _imageSize.height);
    return Offset(dx, dy);
  }
}
