import 'dart:math' as math;
import 'package:flutter/material.dart';
import './dynamic_image_bounds.dart';

/// 图像变换坐标协调器
/// 负责在原始图像坐标系和动态边界坐标系之间进行转换
class ImageTransformCoordinator {
  final Size originalImageSize;
  final double rotation; // 旋转角度（弧度）
  final bool flipHorizontal;
  final bool flipVertical;
  
  late final DynamicImageBounds _bounds;

  ImageTransformCoordinator({
    required this.originalImageSize,
    required this.rotation,
    this.flipHorizontal = false,
    this.flipVertical = false,
  }) {
    _bounds = DynamicImageBounds(
      originalImageSize: originalImageSize,
      rotation: rotation,
      flipHorizontal: flipHorizontal,
      flipVertical: flipVertical,
    );
  }

  /// 获取动态边界大小
  Size get dynamicBounds => _bounds.rotatedBounds;

  /// 获取动态边界计算器
  DynamicImageBounds get bounds => _bounds;

  /// 将原始图像坐标系的裁剪参数转换为动态边界坐标系
  Map<String, double> originalToDynamicCropParams({
    required double cropX,
    required double cropY,
    required double cropWidth,
    required double cropHeight,
  }) {
    // 如果没有变换，直接返回
    if (rotation == 0 && !flipHorizontal && !flipVertical) {
      return {
        'cropX': cropX,
        'cropY': cropY,
        'cropWidth': cropWidth,
        'cropHeight': cropHeight,
      };
    }

    // 创建原始坐标系的裁剪矩形
    final originalRect = Rect.fromLTWH(cropX, cropY, cropWidth, cropHeight);
    
    // 转换为动态边界坐标系
    final dynamicRect = _bounds.originalToDynamicCropRect(originalRect);
    
    return {
      'cropX': dynamicRect.left,
      'cropY': dynamicRect.top,
      'cropWidth': dynamicRect.width,
      'cropHeight': dynamicRect.height,
    };
  }

  /// 将动态边界坐标系的裁剪参数转换为原始图像坐标系
  Map<String, double> dynamicToOriginalCropParams({
    required double cropX,
    required double cropY,
    required double cropWidth,
    required double cropHeight,
  }) {
    // 如果没有变换，直接返回
    if (rotation == 0 && !flipHorizontal && !flipVertical) {
      return {
        'cropX': cropX,
        'cropY': cropY,
        'cropWidth': cropWidth,
        'cropHeight': cropHeight,
      };
    }

    // 创建动态边界坐标系的裁剪矩形
    final dynamicRect = Rect.fromLTWH(cropX, cropY, cropWidth, cropHeight);
    
    // 转换为原始图像坐标系
    final originalRect = _bounds.dynamicToOriginalCropRect(dynamicRect);
    
    return {
      'cropX': originalRect.left,
      'cropY': originalRect.top,
      'cropWidth': originalRect.width,
      'cropHeight': originalRect.height,
    };
  }

  /// 获取当前变换状态下的有效裁剪范围（动态边界坐标系）
  Rect getValidDynamicCropBounds() {
    return _bounds.validCropBounds;
  }

  /// 验证并调整动态边界坐标系中的裁剪区域
  Rect clampDynamicCropRect(Rect cropRect) {
    return _bounds.clampDynamicCropRect(cropRect);
  }

  /// 将显示坐标转换为动态边界坐标
  /// containerSize: 容器大小
  /// displayOffset: 在容器中的显示偏移
  /// scale: 缩放比例
  Rect displayToDynamicCropRect({
    required Rect displayRect,
    required Size containerSize,
    required double scale,
  }) {
    final dynamicSize = _bounds.rotatedBounds;
    
    // 计算动态边界在容器中的位置
    final scaledDynamicWidth = dynamicSize.width * scale;
    final scaledDynamicHeight = dynamicSize.height * scale;
    final offsetX = (containerSize.width - scaledDynamicWidth) / 2;
    final offsetY = (containerSize.height - scaledDynamicHeight) / 2;
    
    // 将显示坐标转换为动态边界坐标
    final dynamicCropRect = Rect.fromLTWH(
      (displayRect.left - offsetX) / scale,
      (displayRect.top - offsetY) / scale,
      displayRect.width / scale,
      displayRect.height / scale,
    );
    
    return clampDynamicCropRect(dynamicCropRect);
  }

  /// 将动态边界坐标转换为显示坐标
  Rect dynamicToDisplayCropRect({
    required Rect dynamicRect,
    required Size containerSize,
    required double scale,
  }) {
    final dynamicSize = _bounds.rotatedBounds;
    
    // 计算动态边界在容器中的位置
    final scaledDynamicWidth = dynamicSize.width * scale;
    final scaledDynamicHeight = dynamicSize.height * scale;
    final offsetX = (containerSize.width - scaledDynamicWidth) / 2;
    final offsetY = (containerSize.height - scaledDynamicHeight) / 2;
    
    // 将动态边界坐标转换为显示坐标
    return Rect.fromLTWH(
      dynamicRect.left * scale + offsetX,
      dynamicRect.top * scale + offsetY,
      dynamicRect.width * scale,
      dynamicRect.height * scale,
    );
  }

  /// 调试信息
  Map<String, dynamic> getDebugInfo() {
    return {
      'originalImageSize': '${originalImageSize.width}x${originalImageSize.height}',
      'dynamicBounds': '${dynamicBounds.width.toStringAsFixed(1)}x${dynamicBounds.height.toStringAsFixed(1)}',
      'rotation': '${(rotation * 180 / math.pi).toStringAsFixed(1)}°',
      'flipHorizontal': flipHorizontal,
      'flipVertical': flipVertical,
      'coordinateOffset': '${_bounds.coordinateOffset.dx.toStringAsFixed(1)},${_bounds.coordinateOffset.dy.toStringAsFixed(1)}',
    };
  }

  @override
  String toString() {
    return 'ImageTransformCoordinator(${getDebugInfo()})';
  }
}