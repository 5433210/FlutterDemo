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

    // Calculate scale for image in canvas
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;
    final scale = math.min(scaleX, scaleY);

    final scaledImageWidth = imageSize.width * scale;
    final scaledImageHeight = imageSize.height * scale;

    final offsetX = (size.width - scaledImageWidth) / 2;
    final offsetY = (size.height - scaledImageHeight) / 2;

    final actualImageRect =
        Rect.fromLTWH(offsetX, offsetY, scaledImageWidth, scaledImageHeight);

    // Draw image area border
    final imageBorderPaint = Paint()
      ..color = colorScheme.tertiary.withAlpha(150)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawRect(actualImageRect, imageBorderPaint);

    // Calculate crop area
    final displayWidth = actualImageRect.width;
    final displayHeight = actualImageRect.height;

    final uiToDisplayScaleX = displayWidth / renderSize.width;
    final uiToDisplayScaleY = displayHeight / renderSize.height;

    final cropRectLeft = actualImageRect.left + (cropLeft * uiToDisplayScaleX);
    final cropRectTop = actualImageRect.top + (cropTop * uiToDisplayScaleY);
    final cropRectRight =
        actualImageRect.right - (cropRight * uiToDisplayScaleX);
    final cropRectBottom =
        actualImageRect.bottom - (cropBottom * uiToDisplayScaleY);

    final cropRect =
        Rect.fromLTRB(cropRectLeft, cropRectTop, cropRectRight, cropRectBottom);

    // Only draw crop area if it's valid
    if (cropRect.width > 0 && cropRect.height > 0) {
      // Get center of crop area (for rotation)
      final centerX = cropRect.center.dx;
      final centerY = cropRect.center.dy;

      // Create path for rotated crop area
      Path rotatedCropPath = Path();

      if (contentRotation != 0) {
        final rotationRadians = contentRotation * (math.pi / 180.0);

        final matrix4 = Matrix4.identity()
          ..translate(centerX, centerY)
          ..rotateZ(rotationRadians)
          ..translate(-centerX, -centerY);

        rotatedCropPath.addRect(cropRect);
        rotatedCropPath = rotatedCropPath.transform(matrix4.storage);
      } else {
        rotatedCropPath.addRect(cropRect);
      }

      // Draw mask
      final maskPaint = Paint()
        ..color = Colors.black.withAlpha(100)
        ..style = PaintingStyle.fill;

      final maskPath = Path()..addRect(actualImageRect);
      maskPath.addPath(rotatedCropPath, Offset.zero);
      maskPath.fillType = PathFillType.evenOdd;

      canvas.drawPath(maskPath, maskPaint);

      // Draw crop area border and markers
      canvas.save();

      if (contentRotation != 0) {
        canvas.translate(centerX, centerY);
        canvas.rotate(contentRotation * (math.pi / 180.0));
        canvas.translate(-centerX, -centerY);
      }

      // Draw crop border
      final borderPaint = Paint()
        ..color = colorScheme.error
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      canvas.drawRect(cropRect, borderPaint);

      // Draw corner markers
      const cornerSize = 8.0;
      final cornerPaint = Paint()
        ..color = colorScheme.error
        ..style = PaintingStyle.fill;

      // Top-left corner
      canvas.drawRect(
          Rect.fromLTWH(cropRect.left - cornerSize / 2,
              cropRect.top - cornerSize / 2, cornerSize, cornerSize),
          cornerPaint);

      // Top-right corner
      canvas.drawRect(
          Rect.fromLTWH(cropRect.right - cornerSize / 2,
              cropRect.top - cornerSize / 2, cornerSize, cornerSize),
          cornerPaint);

      // Bottom-left corner
      canvas.drawRect(
          Rect.fromLTWH(cropRect.left - cornerSize / 2,
              cropRect.bottom - cornerSize / 2, cornerSize, cornerSize),
          cornerPaint);

      // Bottom-right corner
      canvas.drawRect(
          Rect.fromLTWH(cropRect.right - cornerSize / 2,
              cropRect.bottom - cornerSize / 2, cornerSize, cornerSize),
          cornerPaint);

      canvas.restore();
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