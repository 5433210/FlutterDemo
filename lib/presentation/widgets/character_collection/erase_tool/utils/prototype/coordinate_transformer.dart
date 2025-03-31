import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:vector_math/vector_math_64.dart';

/// 坐标转换器 - 原型验证版本
/// 处理各个坐标系统之间的转换，并提供调试和性能监控功能
class PrototypeCoordinateTransformer {
  static const int _maxTimeRecords = 100;

  /// 容器尺寸
  final Size viewportSize;

  /// 图像尺寸
  final Size imageSize;

  /// 设备像素比
  final double devicePixelRatio;

  /// 是否启用调试模式
  final bool debugMode;

  /// 变换矩阵
  Matrix4 _transform;

  /// 缓存的变换参数
  double _scale = 1.0;

  Offset _translation = Offset.zero;

  /// 性能监控数据
  final List<double> _conversionTimes = [];

  PrototypeCoordinateTransformer({
    required this.viewportSize,
    required this.imageSize,
    required this.devicePixelRatio,
    Matrix4? transform,
    this.debugMode = false,
  }) : _transform = transform ?? Matrix4.identity();

  /// 获取平均转换时间（毫秒）
  double get averageConversionTime {
    if (_conversionTimes.isEmpty) return 0.0;
    return _conversionTimes.reduce((a, b) => a + b) / _conversionTimes.length;
  }

  /// 获取实际缩放比例
  double get effectiveScale => _scale * devicePixelRatio;

  /// 清理性能数据
  void clearPerformanceData() {
    _conversionTimes.clear();
  }

  /// 获取性能数据
  Map<String, dynamic> getPerformanceData() {
    return {
      'averageConversionTime': averageConversionTime,
      'maxConversionTime':
          _conversionTimes.isEmpty ? 0.0 : _conversionTimes.reduce(math.max),
      'minConversionTime':
          _conversionTimes.isEmpty ? 0.0 : _conversionTimes.reduce(math.min),
      'transformScale': _scale,
      'sampleCount': _conversionTimes.length,
    };
  }

  /// 图像坐标转换为视口坐标
  Offset imageToViewport(Offset imagePoint) {
    final stopwatch = Stopwatch()..start();

    try {
      // 1. 应用缩放和平移
      final scaled = (imagePoint * effectiveScale) + _translation;

      // 2. 应用变换矩阵的逆矩阵
      final inverse = Matrix4.inverted(_transform);
      final vector = Vector3(scaled.dx, scaled.dy, 0.0);
      final transformed = _transformPoint(vector, matrix: inverse);

      // 3. 应用设备像素比的逆
      final result = Offset(transformed.x, transformed.y) / devicePixelRatio;

      // 记录性能数据
      _recordConversionTime(stopwatch.elapsedMicroseconds / 1000.0);

      if (debugMode) {
        print(
            '🔍 逆向转换: $imagePoint -> $result (${stopwatch.elapsedMicroseconds}μs)');
      }

      return result;
    } catch (e) {
      print('❌ 逆向转换错误: $e');
      return imagePoint;
    }
  }

  /// 更新变换矩阵
  void updateTransform(Matrix4 newTransform) {
    _transform = newTransform;
    _updateTransformParameters();
  }

  /// 验证转换精度
  double validateAccuracy(Offset original) {
    final transformed = viewportToImage(original);
    final backTransformed = imageToViewport(transformed);

    return (backTransformed - original).distance;
  }

  /// 视口坐标转换为图像坐标
  Offset viewportToImage(Offset viewportPoint) {
    final stopwatch = Stopwatch()..start();

    try {
      // 1. 应用设备像素比
      final physicalPoint = viewportPoint * devicePixelRatio;

      // 2. 应用变换矩阵
      final vector = Vector3(physicalPoint.dx, physicalPoint.dy, 0.0);
      final transformed = _transformPoint(vector);

      // 3. 应用缩放和平移
      final result = (Offset(transformed.x, transformed.y) - _translation) /
          effectiveScale;

      // 记录性能数据
      _recordConversionTime(stopwatch.elapsedMicroseconds / 1000.0);

      if (debugMode) {
        print(
            '� 坐标转换: $viewportPoint -> $result (${stopwatch.elapsedMicroseconds}μs)');
      }

      return result;
    } catch (e) {
      print('❌ 坐标转换错误: $e');
      return viewportPoint;
    }
  }

  /// 私有方法：记录转换时间
  void _recordConversionTime(double milliseconds) {
    _conversionTimes.add(milliseconds);
    if (_conversionTimes.length > _maxTimeRecords) {
      _conversionTimes.removeAt(0);
    }
  }

  /// 私有方法：点变换
  Vector3 _transformPoint(Vector3 point, {Matrix4? matrix}) {
    final m = matrix ?? _transform;
    final w = 1.0 / (m[3] * point.x + m[7] * point.y + m[11] * point.z + m[15]);

    return Vector3(
      (m[0] * point.x + m[4] * point.y + m[8] * point.z + m[12]) * w,
      (m[1] * point.x + m[5] * point.y + m[9] * point.z + m[13]) * w,
      (m[2] * point.x + m[6] * point.y + m[10] * point.z + m[14]) * w,
    );
  }

  /// 私有方法：更新变换参数
  void _updateTransformParameters() {
    try {
      // 提取缩放分量
      final row0 = _transform.getRow(0);
      final row1 = _transform.getRow(1);
      _scale = math.sqrt(row0[0] * row0[0] + row0[1] * row0[1]);

      // 提取平移分量
      _translation =
          Offset(_transform.getTranslation().x, _transform.getTranslation().y);

      if (debugMode) {
        print('📊 变换参数更新: scale=$_scale, translation=$_translation');
      }
    } catch (e) {
      print('❌ 更新变换参数错误: $e');
    }
  }
}
