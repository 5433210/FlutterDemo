import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 动态图像边界计算器
/// 根据图像的旋转状态计算包含整个旋转图像的最小矩形区域
class DynamicImageBounds {
  final Size originalImageSize;
  final double rotation; // 旋转角度（弧度）
  final bool flipHorizontal;
  final bool flipVertical;

  const DynamicImageBounds({
    required this.originalImageSize,
    required this.rotation,
    this.flipHorizontal = false,
    this.flipVertical = false,
  });

  /// 计算旋转后图像的包围盒尺寸
  Size get rotatedBounds {
    if (rotation == 0) {
      return originalImageSize;
    }

    final cos = math.cos(rotation).abs();
    final sin = math.sin(rotation).abs();
    
    final newWidth = originalImageSize.width * cos + originalImageSize.height * sin;
    final newHeight = originalImageSize.width * sin + originalImageSize.height * cos;
    
    return Size(newWidth, newHeight);
  }

  /// 计算原始图像坐标到动态边界坐标的偏移量
  Offset get coordinateOffset {
    if (rotation == 0) {
      return Offset.zero;
    }

    final rotatedSize = rotatedBounds;
    final offsetX = (rotatedSize.width - originalImageSize.width) / 2;
    final offsetY = (rotatedSize.height - originalImageSize.height) / 2;
    
    return Offset(offsetX, offsetY);
  }

  /// 将原始图像坐标转换为动态边界坐标（考虑翻转和旋转）
  Offset originalToDynamicCoords(Offset originalCoords) {
    final bounds = rotatedBounds;
    final imageCenterX = originalImageSize.width / 2;
    final imageCenterY = originalImageSize.height / 2;
    final boundsCenterX = bounds.width / 2;
    final boundsCenterY = bounds.height / 2;

    // 将原始图像坐标转换为相对于图像中心的坐标
    double x = originalCoords.dx - imageCenterX;
    double y = originalCoords.dy - imageCenterY;

    // 应用旋转
    if (rotation != 0) {
      final cos = math.cos(rotation);
      final sin = math.sin(rotation);
      final rotatedX = cos * x - sin * y;
      final rotatedY = sin * x + cos * y;
      x = rotatedX;
      y = rotatedY;
    }

    // 应用翻转
    if (flipHorizontal) x = -x;
    if (flipVertical) y = -y;

    // 转换为动态边界坐标
    return Offset(
      x + boundsCenterX,
      y + boundsCenterY,
    );
  }

  /// 将动态边界坐标转换为原始图像坐标（考虑翻转和旋转）
  Offset dynamicToOriginalCoords(Offset dynamicCoords) {
    return mapDynamicToImagePixel(dynamicCoords);
  }

  /// 将原始图像的裁剪区域转换为动态边界中的裁剪区域（考虑翻转和旋转）
  Rect originalToDynamicCropRect(Rect originalCropRect) {
    // 转换四个角点
    final topLeft = originalToDynamicCoords(originalCropRect.topLeft);
    final topRight = originalToDynamicCoords(originalCropRect.topRight);
    final bottomLeft = originalToDynamicCoords(originalCropRect.bottomLeft);
    final bottomRight = originalToDynamicCoords(originalCropRect.bottomRight);

    // 找到包围盒
    final minX = math.min(math.min(topLeft.dx, topRight.dx), math.min(bottomLeft.dx, bottomRight.dx));
    final maxX = math.max(math.max(topLeft.dx, topRight.dx), math.max(bottomLeft.dx, bottomRight.dx));
    final minY = math.min(math.min(topLeft.dy, topRight.dy), math.min(bottomLeft.dy, bottomRight.dy));
    final maxY = math.max(math.max(topLeft.dy, topRight.dy), math.max(bottomLeft.dy, bottomRight.dy));

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// 将动态边界中的裁剪区域转换为原始图像的裁剪区域（考虑翻转和旋转）
  Rect dynamicToOriginalCropRect(Rect dynamicCropRect) {
    // 转换四个角点
    final topLeft = dynamicToOriginalCoords(dynamicCropRect.topLeft);
    final topRight = dynamicToOriginalCoords(dynamicCropRect.topRight);
    final bottomLeft = dynamicToOriginalCoords(dynamicCropRect.bottomLeft);
    final bottomRight = dynamicToOriginalCoords(dynamicCropRect.bottomRight);

    // 找到包围盒
    final minX = math.min(math.min(topLeft.dx, topRight.dx), math.min(bottomLeft.dx, bottomRight.dx));
    final maxX = math.max(math.max(topLeft.dx, topRight.dx), math.max(bottomLeft.dx, bottomRight.dx));
    final minY = math.min(math.min(topLeft.dy, topRight.dy), math.min(bottomLeft.dy, bottomRight.dy));
    final maxY = math.max(math.max(topLeft.dy, topRight.dy), math.max(bottomLeft.dy, bottomRight.dy));

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// 验证动态边界中的裁剪区域是否有效
  Rect clampDynamicCropRect(Rect dynamicCropRect) {
    final bounds = rotatedBounds;
    
    // 确保裁剪区域在动态边界内
    final clampedLeft = math.max(0, dynamicCropRect.left);
    final clampedTop = math.max(0, dynamicCropRect.top);
    final clampedRight = math.min(bounds.width, dynamicCropRect.right);
    final clampedBottom = math.min(bounds.height, dynamicCropRect.bottom);
    
    final clampedWidth = math.max(10.0, clampedRight - clampedLeft);
    final clampedHeight = math.max(10.0, clampedBottom - clampedTop);
    
    return Rect.fromLTWH(clampedLeft.toDouble(), clampedTop.toDouble(), clampedWidth, clampedHeight);
  }

  /// 获取在动态边界中的有效裁剪范围
  Rect get validCropBounds {
    return Rect.fromLTWH(0, 0, rotatedBounds.width, rotatedBounds.height);
  }

  /// 计算像素在旋转变换中的映射
  /// 用于从动态边界坐标映射到原始图像坐标
  Offset mapDynamicToImagePixel(Offset dynamicPixel) {
    final bounds = rotatedBounds;
    final imageCenterX = originalImageSize.width / 2;
    final imageCenterY = originalImageSize.height / 2;
    final boundsCenterX = bounds.width / 2;
    final boundsCenterY = bounds.height / 2;

    // 将动态边界坐标转换为相对于边界中心的坐标
    double x = dynamicPixel.dx - boundsCenterX;
    double y = dynamicPixel.dy - boundsCenterY;

    // 应用逆向翻转
    if (flipHorizontal) x = -x;
    if (flipVertical) y = -y;

    // 应用逆向旋转
    if (rotation != 0) {
      final cos = math.cos(-rotation);
      final sin = math.sin(-rotation);
      final rotatedX = cos * x - sin * y;
      final rotatedY = sin * x + cos * y;
      x = rotatedX;
      y = rotatedY;
    }

    // 转换为原始图像坐标
    return Offset(
      x + imageCenterX,
      y + imageCenterY,
    );
  }

  @override
  String toString() {
    return 'DynamicImageBounds(original: ${originalImageSize.width}x${originalImageSize.height}, '
           'rotated: ${rotatedBounds.width.toStringAsFixed(1)}x${rotatedBounds.height.toStringAsFixed(1)}, '
           'rotation: ${(rotation * 180 / math.pi).toStringAsFixed(1)}°, '
           'offset: ${coordinateOffset.dx.toStringAsFixed(1)},${coordinateOffset.dy.toStringAsFixed(1)})';
  }
}