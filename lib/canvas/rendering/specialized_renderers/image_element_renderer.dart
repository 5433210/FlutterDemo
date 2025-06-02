import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/interfaces/element_data.dart';
import '../canvas_rendering_engine.dart';

/// 图像元素专用渲染器
class ImageElementRenderer extends ElementRenderer {
  // 图像缓存
  final Map<String, ui.Image> _imageCache = {};

  @override
  void dispose() {
    _imageCache.clear();
  }

  /// 加载图像（异步）
  Future<void> loadImage(String imagePath) async {
    if (_imageCache.containsKey(imagePath)) return;

    try {
      // TODO: 实现实际的图像加载逻辑
      // final bytes = await loadImageBytes(imagePath);
      // final image = await decodeImageFromList(bytes);
      // _imageCache[imagePath] = image;
    } catch (e) {
      // 加载失败，记录错误
      print('Failed to load image: $imagePath, error: $e');
    }
  }

  @override
  void render(Canvas canvas, ElementData element) {
    final imagePath = element.properties['src'] as String?;
    if (imagePath == null) return;

    final image = _imageCache[imagePath];
    if (image == null) {
      // 图像未加载，绘制占位符
      _renderPlaceholder(canvas, element);
      // TODO: 异步加载图像
      return;
    }

    // 计算图像绘制参数
    final srcRect = _calculateSourceRect(image, element);
    final dstRect =
        Rect.fromLTWH(0, 0, element.bounds.width, element.bounds.height);

    // 创建画笔
    final paint = Paint();

    // 应用滤镜效果
    _applyImageFilters(paint, element);

    // 绘制图像
    canvas.drawImageRect(image, srcRect, dstRect, paint);
  }

  /// 应用图像滤镜
  void _applyImageFilters(Paint paint, ElementData element) {
    final props = element.properties;

    // 透明度
    final opacity = (props['opacity'] as num?)?.toDouble() ?? 1.0;
    if (opacity < 1.0) {
      paint.color = paint.color.withOpacity(opacity);
    }

    // 色调
    final hue = (props['hue'] as num?)?.toDouble();
    if (hue != null && hue != 0) {
      // TODO: 实现色调调整
    }

    // 饱和度
    final saturation = (props['saturation'] as num?)?.toDouble();
    if (saturation != null && saturation != 1.0) {
      // TODO: 实现饱和度调整
    }

    // 亮度
    final brightness = (props['brightness'] as num?)?.toDouble();
    if (brightness != null && brightness != 1.0) {
      // TODO: 实现亮度调整
    }
  }

  /// 计算源矩形（支持裁剪模式）
  Rect _calculateSourceRect(ui.Image image, ElementData element) {
    final fitMode = element.properties['fit'] as String? ?? 'contain';

    switch (fitMode) {
      case 'fill':
        return Rect.fromLTWH(
            0, 0, image.width.toDouble(), image.height.toDouble());

      case 'cover':
        final imageAspect = image.width / image.height;
        final elementAspect = element.bounds.width / element.bounds.height;

        if (imageAspect > elementAspect) {
          // 图像更宽，裁剪左右
          final cropWidth = image.height * elementAspect;
          final cropX = (image.width - cropWidth) / 2;
          return Rect.fromLTWH(cropX, 0, cropWidth, image.height.toDouble());
        } else {
          // 图像更高，裁剪上下
          final cropHeight = image.width / elementAspect;
          final cropY = (image.height - cropHeight) / 2;
          return Rect.fromLTWH(0, cropY, image.width.toDouble(), cropHeight);
        }

      default: // contain
        return Rect.fromLTWH(
            0, 0, image.width.toDouble(), image.height.toDouble());
    }
  }

  /// 渲染占位符
  void _renderPlaceholder(Canvas canvas, ElementData element) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.fill;

    final rect =
        Rect.fromLTWH(0, 0, element.bounds.width, element.bounds.height);
    canvas.drawRect(rect, paint);

    // 绘制图标
    final iconPaint = Paint()
      ..color = Colors.grey.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final center = rect.center;
    const iconSize = 24.0;
    final iconRect = Rect.fromCenter(
      center: center,
      width: iconSize,
      height: iconSize,
    );

    canvas.drawRect(iconRect, iconPaint);

    // 绘制X
    canvas.drawLine(iconRect.topLeft, iconRect.bottomRight, iconPaint);
    canvas.drawLine(iconRect.topRight, iconRect.bottomLeft, iconPaint);
  }
}
