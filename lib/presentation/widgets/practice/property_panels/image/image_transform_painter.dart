import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 变换预览绘制器
class ImageTransformPreviewPainter extends CustomPainter {
  final BuildContext context;
  final Size imageSize;
  final Size renderSize;
  final double cropTop;
  final double cropBottom;
  final double cropLeft;
  final double cropRight;
  final bool flipHorizontal;
  final bool flipVertical;
  final double contentRotation;
  final bool isTransformApplied;

  const ImageTransformPreviewPainter({
    required this.context,
    required this.imageSize,
    required this.renderSize,
    required this.cropTop,
    required this.cropBottom,
    required this.cropLeft,
    required this.cropRight,
    required this.flipHorizontal,
    required this.flipVertical,
    required this.contentRotation,
    required this.isTransformApplied,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Draw canvas border
    final canvasBorderPaint = Paint()
      ..color = colorScheme.primary.withAlpha(100)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final canvasRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(canvasRect, canvasBorderPaint);

    // 计算原始图像在预览区域中的显示
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;
    final scale = math.min(scaleX, scaleY);

    final scaledImageWidth = imageSize.width * scale;
    final scaledImageHeight = imageSize.height * scale;

    final offsetX = (size.width - scaledImageWidth) / 2;
    final offsetY = (size.height - scaledImageHeight) / 2;

    final imageRect = Rect.fromLTWH(offsetX, offsetY, scaledImageWidth, scaledImageHeight);

    // 保存画布状态用于图像变换
    canvas.save();

    // 如果有旋转，围绕图像中心旋转整个图像显示
    if (contentRotation != 0) {
      final imageCenterX = imageRect.center.dx;
      final imageCenterY = imageRect.center.dy;
      
      canvas.translate(imageCenterX, imageCenterY);
      canvas.rotate(contentRotation * (math.pi / 180.0));
      canvas.translate(-imageCenterX, -imageCenterY);
    }

    // 应用翻转变换
    if (flipHorizontal || flipVertical) {
      final imageCenterX = imageRect.center.dx;
      final imageCenterY = imageRect.center.dy;
      
      canvas.translate(imageCenterX, imageCenterY);
      canvas.scale(
        flipHorizontal ? -1.0 : 1.0, 
        flipVertical ? -1.0 : 1.0
      );
      canvas.translate(-imageCenterX, -imageCenterY);
    }

    // Draw image area border (representing the transformed image)
    final imageBorderPaint = Paint()
      ..color = colorScheme.tertiary.withAlpha(150)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawRect(imageRect, imageBorderPaint);

    // 恢复画布状态，这样裁剪区域不会跟着图像变换
    canvas.restore();

    // ===== 在正常坐标系下绘制裁剪区域 =====
    
    // 计算裁剪区域在原始图像坐标系中的位置
    final cropX = cropLeft;
    final cropY = cropTop;
    final cropWidth = renderSize.width - cropLeft - cropRight;
    final cropHeight = renderSize.height - cropTop - cropBottom;

    // 将裁剪区域映射到显示坐标系（基于原始图像，不受变换影响）
    final displayScaleX = scaledImageWidth / imageSize.width;
    final displayScaleY = scaledImageHeight / imageSize.height;

    final displayCropRect = Rect.fromLTWH(
      imageRect.left + (cropX * displayScaleX),
      imageRect.top + (cropY * displayScaleY),
      cropWidth * displayScaleX,
      cropHeight * displayScaleY,
    );

    // Only draw crop area if it's valid
    if (displayCropRect.width > 0 && displayCropRect.height > 0) {
      // Draw mask (everything outside crop area)
      final maskPaint = Paint()
        ..color = Colors.black.withAlpha(100)
        ..style = PaintingStyle.fill;

      final maskPath = Path()..addRect(imageRect);
      final cropPath = Path()..addRect(displayCropRect);
      maskPath.addPath(cropPath, Offset.zero);
      maskPath.fillType = PathFillType.evenOdd;

      canvas.drawPath(maskPath, maskPaint);

      // Draw crop border
      final borderPaint = Paint()
        ..color = colorScheme.error
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      canvas.drawRect(displayCropRect, borderPaint);

      // Draw corner markers
      const cornerSize = 8.0;
      final cornerPaint = Paint()
        ..color = colorScheme.error
        ..style = PaintingStyle.fill;

      // Top-left corner
      canvas.drawRect(
          Rect.fromLTWH(displayCropRect.left - cornerSize / 2,
              displayCropRect.top - cornerSize / 2, cornerSize, cornerSize),
          cornerPaint);

      // Top-right corner
      canvas.drawRect(
          Rect.fromLTWH(displayCropRect.right - cornerSize / 2,
              displayCropRect.top - cornerSize / 2, cornerSize, cornerSize),
          cornerPaint);

      // Bottom-left corner
      canvas.drawRect(
          Rect.fromLTWH(displayCropRect.left - cornerSize / 2,
              displayCropRect.bottom - cornerSize / 2, cornerSize, cornerSize),
          cornerPaint);

      // Bottom-right corner
      canvas.drawRect(
          Rect.fromLTWH(displayCropRect.right - cornerSize / 2,
              displayCropRect.bottom - cornerSize / 2, cornerSize, cornerSize),
          cornerPaint);
    }
    
    // 在右下角显示变换信息（在画布变换之外绘制，保持正常方向）
    if (flipHorizontal || flipVertical || contentRotation != 0) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'H:${flipHorizontal ? "Y" : "N"} V:${flipVertical ? "Y" : "N"} R:${contentRotation.toStringAsFixed(0)}°',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(size.width - textPainter.width - 4, size.height - textPainter.height - 4),
      );
    }
  }

  @override
  bool shouldRepaint(ImageTransformPreviewPainter oldDelegate) {
    return imageSize != oldDelegate.imageSize ||
        renderSize != oldDelegate.renderSize ||
        cropTop != oldDelegate.cropTop ||
        cropBottom != oldDelegate.cropBottom ||
        cropLeft != oldDelegate.cropLeft ||
        cropRight != oldDelegate.cropRight ||
        flipHorizontal != oldDelegate.flipHorizontal ||
        flipVertical != oldDelegate.flipVertical ||
        contentRotation != oldDelegate.contentRotation ||
        isTransformApplied != oldDelegate.isTransformApplied ||
        context != oldDelegate.context;
  }
} 