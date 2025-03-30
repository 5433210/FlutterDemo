import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

/// 坐标转换器
/// 负责将容器坐标转换为图像坐标
class CoordinateTransformer {
  /// 变换矩阵
  Matrix4 _transformMatrix = Matrix4.identity();

  /// 容器大小
  Size _containerSize = Size.zero;

  /// 图像大小
  Size _imageSize = Size.zero;

  /// 容器偏移
  Offset _containerOffset = Offset.zero;

  /// 视口区域
  Rect _viewport = Rect.zero;

  /// 调试模式标记
  bool _isDebugging = true; // 默认启用调试，帮助排查问题

  /// 最后一次转换的点
  final List<Offset> _lastTransformedPoints = [];

  /// 额外缩放系数，修正缩放问题
  double _scaleCorrection = 1.0;

  /// 校准偏移量，微调位置匹配
  Offset _calibrationOffset = Offset.zero;

  /// 获取最后一次转换的点，用于调试
  List<Offset> get lastTransformedPoints =>
      List.unmodifiable(_lastTransformedPoints);

  /// 禁用调试模式
  void disableDebug() {
    _isDebugging = false;
  }

  /// 启用调试模式
  void enableDebug() {
    _isDebugging = true;
  }

  /// 初始化变换
  void initializeTransform({
    required Matrix4 transformMatrix,
    required Size containerSize,
    required Size imageSize,
    required Offset containerOffset,
    Rect? viewport,
    double scaleCorrection = 1.0,
    Offset calibrationOffset = Offset.zero,
  }) {
    if (kDebugMode) {
      print('🔧 初始化坐标转换器');
      print('  - 容器大小: $containerSize');
      print('  - 图像大小: $imageSize');
      print('  - 容器偏移: $containerOffset');
      print('  - 变换矩阵: ${_matrixToString(transformMatrix)}');
    }

    _transformMatrix = transformMatrix;
    _containerSize = containerSize;
    _imageSize = imageSize;
    _containerOffset = containerOffset;
    _scaleCorrection = scaleCorrection;
    _calibrationOffset = calibrationOffset;

    if (viewport != null) {
      _viewport = viewport;
    } else {
      // 默认视口为完整容器
      _viewport =
          Rect.fromLTWH(0, 0, containerSize.width, containerSize.height);
    }

    // 计算有效比例，用于调试输出
    final effectiveScale = _getEffectiveScale();

    _logDebugInfo('初始化变换', {
      'transformMatrix': _matrixToString(transformMatrix),
      'containerSize': containerSize,
      'imageSize': imageSize,
      'containerOffset': containerOffset,
      'viewport': _viewport,
      'effectiveScale': effectiveScale,
      'scaleCorrection': _scaleCorrection,
      'calibrationOffset': _calibrationOffset,
    });
  }

  /// 设置校准偏移，用于微调坐标匹配
  void setCalibrationOffset(Offset offset) {
    _calibrationOffset = offset;
    _logDebugInfo('更新校准偏移', {'calibrationOffset': offset});
  }

  /// 转换点坐标 (容器坐标 -> 图像坐标)
  Offset transformPoint(Offset point) {
    try {
      // 应用设备像素比
      final physicalPoint = point * ui.window.devicePixelRatio;

      // 检查容器和图像尺寸，避免除以零错误
      if (_containerSize.isEmpty || _imageSize.isEmpty) {
        _logDebugInfo('转换错误', {'reason': '容器或图像尺寸为零'});
        return point;
      }

      // 获取矩阵变换的影响
      final matrixScale = _getMatrixScale();

      // 计算容器中图像的实际显示尺寸和缩放比例
      final effectiveScale = _getEffectiveScale() * _scaleCorrection;
      final imageDisplaySize = Size(_imageSize.width * effectiveScale,
          _imageSize.height * effectiveScale);

      // 计算图像在容器中的居中偏移
      final offsetX = (_containerSize.width - imageDisplaySize.width) / 2;
      final offsetY = (_containerSize.height - imageDisplaySize.height) / 2;

      // 将点从容器坐标系转换到图像坐标系
      // 考虑变换矩阵的缩放影响
      final imageX =
          (physicalPoint.dx - offsetX) / (effectiveScale * matrixScale.dx) +
              _calibrationOffset.dx;
      final imageY =
          (physicalPoint.dy - offsetY) / (effectiveScale * matrixScale.dy) +
              _calibrationOffset.dy;

      // 获取变换矩阵的平移分量，但不直接使用
      // 因为 InteractiveViewer 会自动处理平移
      final matrixTranslation = _getMatrixTranslation();

      // 最终转换后的点
      final transformedPoint = Offset(imageX, imageY);

      // 记录转换结果，用于调试
      if (_isDebugging) {
        _lastTransformedPoints.add(transformedPoint);
        if (_lastTransformedPoints.length > 20) {
          _lastTransformedPoints.removeAt(0);
        }

        _logDebugInfo('坐标转换', {
          'input': point,
          'physical': physicalPoint,
          'effectiveScale': effectiveScale,
          'imageDisplay': imageDisplaySize,
          'offset': Offset(offsetX, offsetY),
          'imageCoords': Offset(imageX, imageY),
          'matrixTranslation': matrixTranslation,
          'matrixScale': matrixScale,
          'transformed': transformedPoint,
        });
      }

      return transformedPoint;
    } catch (e) {
      if (kDebugMode) {
        print('❌ 坐标转换错误: $e');
      }
      return point;
    }
  }

  /// 更新容器偏移
  void updateContainerOffset(Offset offset) {
    final oldOffset = _containerOffset;
    if ((oldOffset - offset).distance > 0.1) {
      _containerOffset = offset;
      _logDebugInfo('更新容器偏移', {
        'old': oldOffset,
        'new': offset,
      });
    }
  }

  /// 更新容器大小
  void updateContainerSize(Size size) {
    if (_containerSize != size) {
      _containerSize = size;
      _logDebugInfo('更新容器大小', {'size': size});
    }
  }

  /// 更新图像大小
  void updateImageSize(Size size) {
    if (_imageSize != size) {
      _imageSize = size;
      _logDebugInfo('更新图像大小', {'size': size});
    }
  }

  /// 更新变换矩阵
  void updateTransform(Matrix4 transformMatrix) {
    // 检查是否有明显变化
    bool hasChange = false;
    for (int i = 0; i < 16; i++) {
      if ((_transformMatrix.storage[i] - transformMatrix.storage[i]).abs() >
          0.001) {
        hasChange = true;
        break;
      }
    }

    if (hasChange) {
      _transformMatrix = transformMatrix;
      if (_isDebugging) {
        _logDebugInfo('更新变换矩阵', {
          'matrix': _matrixToString(transformMatrix),
          'scale': _getMatrixScale(),
          'translation': _getMatrixTranslation(),
        });
      }
    }
  }

  /// 更新视口区域
  void updateViewport(Rect viewport) {
    if (_viewport != viewport) {
      _viewport = viewport;
      _logDebugInfo('更新视口', {'viewport': viewport});
    }
  }

  /// 获取有效缩放比例
  double _getEffectiveScale() {
    // 计算容器和图像的宽高比
    final containerRatio = _containerSize.width / _containerSize.height;
    final imageRatio = _imageSize.width / _imageSize.height;

    // 根据宽高比决定使用哪个维度的缩放
    final scale = math.min(_containerSize.width / _imageSize.width,
        _containerSize.height / _imageSize.height);

    return scale;
  }

  /// 获取变换矩阵的缩放分量
  Vector2 _getMatrixScale() {
    // 从变换矩阵中提取缩放分量
    final scaleX = vm.Vector3(_transformMatrix.getColumn(0).x,
            _transformMatrix.getColumn(0).y, _transformMatrix.getColumn(0).z)
        .length;
    final scaleY = vm.Vector3(_transformMatrix.getColumn(1).x,
            _transformMatrix.getColumn(1).y, _transformMatrix.getColumn(1).z)
        .length;

    return Vector2(scaleX, scaleY);
  }

  /// 获取变换矩阵的平移分量
  Offset _getMatrixTranslation() {
    // 从变换矩阵中提取平移分量
    final translation = _transformMatrix.getTranslation();
    return Offset(translation.x, translation.y);
  }

  /// 记录调试信息
  void _logDebugInfo(String action, Map<String, dynamic> data) {
    if (!_isDebugging) return;

    if (kDebugMode) {
      print('🔍 CoordinateTransformer - $action:');
      data.forEach((key, value) {
        print('  $key: $value');
      });
    }
  }

  /// 将矩阵转换为可读字符串
  String _matrixToString(Matrix4 matrix) {
    return 'Matrix4(${matrix.storage.take(4).join(', ')}...)';
  }
}

/// 2D向量
class Vector2 {
  final double dx;
  final double dy;

  const Vector2(this.dx, this.dy);

  @override
  String toString() => 'Vector2($dx, $dy)';
}
