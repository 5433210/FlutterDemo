import 'dart:async';
import 'dart:ui' as ui;

// No longer needed: import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/canvas_state_manager.dart';
import '../../core/interfaces/element_data.dart';
import '../rendering_engine.dart';

/// 图像元素专用渲染器
///
/// 为图像元素提供高性能渲染，支持缓存和异步加载机制
/// 支持多种图像格式与滤镜效果
class ImageElementRenderer {
  static const String rendererType = 'image';

  final CanvasStateManager stateManager;

  // 图像缓存，避免重复加载
  final Map<String, ui.Image> _imageCache = {};

  // 记录加载中的图像请求
  final Set<String> _loadingImages = {};

  // 图像加载回调
  final Map<String, List<VoidCallback>> _loadCallbacks = {};

  ImageElementRenderer(this.stateManager);

  /// 添加图像加载完成回调
  void addLoadCallback(String imagePath, VoidCallback callback) {
    final cacheKey = imagePath;

    if (_imageCache.containsKey(cacheKey)) {
      // 图像已加载，直接调用回调
      callback();
    } else {
      // 图像未加载，添加到回调列表
      _loadCallbacks.putIfAbsent(cacheKey, () => []).add(callback);
    }
  }

  /// 清理资源
  void dispose() {
    _imageCache.forEach((_, image) => image.dispose());
    _imageCache.clear();
    _loadingImages.clear();
    _loadCallbacks.clear();
  }

  /// 预加载图像资源
  Future<void> preloadResources(ElementData element) async {
    final imagePath = element.properties['src'] as String?;

    if (imagePath != null && imagePath.isNotEmpty) {
      final cacheKey = imagePath;

      if (!_imageCache.containsKey(cacheKey) &&
          !_loadingImages.contains(cacheKey)) {
        await _loadImage(cacheKey, imagePath);
      }
    }
  }

  /// 渲染图像元素到画布
  void renderElement(
      Canvas canvas, ElementData element, RenderingContext context) {
    if (!element.visible) return;

    final rect = element.bounds;
    final imagePath = element.properties['src'] as String?;
    final opacity = element.properties['opacity'] as double? ?? 1.0;
    final blendMode =
        _parseBlendMode(element.properties['blendMode'] as String?);
    final filterQuality =
        _parseFilterQuality(element.properties['filterQuality'] as String?);
    final fit = _parseBoxFit(element.properties['fit'] as String?);

    // 应用元素变换
    canvas.save();

    // 处理元素的变换矩阵
    if (element.transform != null) {
      canvas.transform(element.transform!);
    }

    if (imagePath != null && imagePath.isNotEmpty) {
      final cacheKey = imagePath;
      final image = _imageCache[cacheKey];

      if (image != null) {
        // 图像已加载，直接绘制
        _drawImage(canvas, rect, image, opacity, blendMode, filterQuality, fit);
      } else {
        // 图像未加载，绘制占位符并开始加载
        _drawPlaceholder(canvas, rect);

        if (!_loadingImages.contains(cacheKey)) {
          _loadImage(cacheKey, imagePath).then((_) {
            // 图像加载完成后，通知重绘
            // stateManager.markElementDirty(element.id);
          });
        }
      }
    } else {
      // 无有效图像路径，绘制占位符
      _drawPlaceholder(canvas, rect);
    }

    // 如果元素被选中，绘制选择指示器
    if (context.isSelected(element.id)) {
      _drawSelectionIndicator(canvas, rect, context);
    }

    canvas.restore();
  }

  /// 判断元素是否需要重绘
  bool shouldRepaint(ElementData oldElement, ElementData newElement) {
    // 检查关键属性是否变化
    if (oldElement.visible != newElement.visible) return true;
    if (oldElement.transform != newElement.transform) return true;

    final oldSrc = oldElement.properties['src'] as String?;
    final newSrc = newElement.properties['src'] as String?;
    if (oldSrc != newSrc) return true;

    final oldOpacity = oldElement.properties['opacity'] as double? ?? 1.0;
    final newOpacity = newElement.properties['opacity'] as double? ?? 1.0;
    if (oldOpacity != newOpacity) return true;

    final oldBlendMode = oldElement.properties['blendMode'] as String?;
    final newBlendMode = newElement.properties['blendMode'] as String?;
    if (oldBlendMode != newBlendMode) return true;

    // 其他属性的变化检查...

    return false;
  }

  /// 绘制控制点
  void _drawControlHandles(Canvas canvas, Rect rect, RenderingContext context) {
    const handleSize = 8.0;
    final handlePaint = Paint()
      ..color = context.selectionColor
      ..style = PaintingStyle.fill;

    // 角控制点
    final handles = [
      Rect.fromCenter(
          center: rect.topLeft, width: handleSize, height: handleSize),
      Rect.fromCenter(
          center: rect.topRight, width: handleSize, height: handleSize),
      Rect.fromCenter(
          center: rect.bottomLeft, width: handleSize, height: handleSize),
      Rect.fromCenter(
          center: rect.bottomRight, width: handleSize, height: handleSize),
    ];

    // 边控制点
    handles.addAll([
      Rect.fromCenter(
          center: Offset(rect.left + rect.width / 2, rect.top),
          width: handleSize,
          height: handleSize),
      Rect.fromCenter(
          center: Offset(rect.right, rect.top + rect.height / 2),
          width: handleSize,
          height: handleSize),
      Rect.fromCenter(
          center: Offset(rect.left + rect.width / 2, rect.bottom),
          width: handleSize,
          height: handleSize),
      Rect.fromCenter(
          center: Offset(rect.left, rect.top + rect.height / 2),
          width: handleSize,
          height: handleSize),
    ]);

    for (var handle in handles) {
      canvas.drawRect(handle, handlePaint);
    }
  }

  /// 绘制已加载的图像
  void _drawImage(
    Canvas canvas,
    Rect rect,
    ui.Image image,
    double opacity,
    BlendMode blendMode,
    FilterQuality filterQuality,
    BoxFit fit,
  ) {
    final paint = Paint()
      ..filterQuality = filterQuality
      ..color = Colors.white.withOpacity(opacity)
      ..blendMode = blendMode;

    final Size imageSize =
        Size(image.width.toDouble(), image.height.toDouble());
    final FittedSizes sizes = applyBoxFit(fit, imageSize, rect.size);
    final Rect outputSubrect =
        Alignment.center.inscribe(sizes.destination, rect);
    final Rect inputSubrect =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());

    canvas.drawImageRect(image, inputSubrect, outputSubrect, paint);
  }

  /// 绘制占位符
  void _drawPlaceholder(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawRect(rect, paint);

    // 绘制占位符图标
    final iconPaint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final iconRect = Rect.fromCenter(
      center: rect.center,
      width: rect.width * 0.3,
      height: rect.height * 0.3,
    );

    canvas.drawRect(iconRect, iconPaint);

    // 绘制对角线
    canvas.drawLine(
      iconRect.topLeft,
      iconRect.bottomRight,
      iconPaint,
    );

    canvas.drawLine(
      iconRect.topRight,
      iconRect.bottomLeft,
      iconPaint,
    );
  }

  /// 绘制选择指示器
  void _drawSelectionIndicator(
      Canvas canvas, Rect rect, RenderingContext context) {
    final paint = Paint()
      ..color = context.selectionColor.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    canvas.drawRect(rect, paint);

    final borderPaint = Paint()
      ..color = context.selectionColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRect(rect, borderPaint);

    // 绘制控制点
    _drawControlHandles(canvas, rect, context);
  }

  /// 加载图像资源
  Future<void> _loadImage(String cacheKey, String imagePath) async {
    if (_loadingImages.contains(cacheKey)) return;

    _loadingImages.add(cacheKey);

    try {
      ui.Image image;

      if (imagePath.startsWith('assets/')) {
        // 加载资源图像
        final data = await rootBundle.load(imagePath);
        final buffer = data.buffer.asUint8List();
        final codec = await ui.instantiateImageCodec(buffer);
        final frame = await codec.getNextFrame();
        image = frame.image;
      } else if (imagePath.startsWith('http://') ||
          imagePath.startsWith('https://')) {
        // 加载网络图像
        final completer = Completer<ui.Image>();
        final imageProvider = NetworkImage(imagePath);

        final stream = imageProvider.resolve(const ImageConfiguration());
        final listener = ImageStreamListener((info, _) {
          completer.complete(info.image);
        }, onError: (exception, stackTrace) {
          completer.completeError(exception);
        });

        stream.addListener(listener);
        image = await completer.future;
        stream.removeListener(listener);
      } else {
        // 当作文件路径处理
        throw UnimplementedError('本地文件图像加载暂未实现');
      }

      // 缓存图像
      _imageCache[cacheKey] = image;

      // 触发回调
      _triggerCallbacks(cacheKey);
    } catch (e) {
      debugPrint('加载图像失败: $imagePath, 错误: $e');
    } finally {
      _loadingImages.remove(cacheKey);
    }
  }

  /// 解析混合模式
  BlendMode _parseBlendMode(String? mode) {
    if (mode == null) return BlendMode.srcOver;

    switch (mode.toLowerCase()) {
      case 'multiply':
        return BlendMode.multiply;
      case 'screen':
        return BlendMode.screen;
      case 'overlay':
        return BlendMode.overlay;
      case 'darken':
        return BlendMode.darken;
      case 'lighten':
        return BlendMode.lighten;
      case 'color-dodge':
        return BlendMode.colorDodge;
      case 'color-burn':
        return BlendMode.colorBurn;
      case 'hard-light':
        return BlendMode.hardLight;
      case 'soft-light':
        return BlendMode.softLight;
      case 'difference':
        return BlendMode.difference;
      case 'exclusion':
        return BlendMode.exclusion;
      case 'hue':
        return BlendMode.hue;
      case 'saturation':
        return BlendMode.saturation;
      case 'color':
        return BlendMode.color;
      case 'luminosity':
        return BlendMode.luminosity;
      default:
        return BlendMode.srcOver;
    }
  }

  /// 解析图像适应模式
  BoxFit _parseBoxFit(String? fit) {
    if (fit == null) return BoxFit.contain;

    switch (fit.toLowerCase()) {
      case 'fill':
        return BoxFit.fill;
      case 'contain':
        return BoxFit.contain;
      case 'cover':
        return BoxFit.cover;
      case 'fit-width':
        return BoxFit.fitWidth;
      case 'fit-height':
        return BoxFit.fitHeight;
      case 'none':
        return BoxFit.none;
      case 'scale-down':
        return BoxFit.scaleDown;
      default:
        return BoxFit.contain;
    }
  }

  /// 解析过滤器质量
  FilterQuality _parseFilterQuality(String? quality) {
    if (quality == null) return FilterQuality.low;

    switch (quality.toLowerCase()) {
      case 'none':
        return FilterQuality.none;
      case 'low':
        return FilterQuality.low;
      case 'medium':
        return FilterQuality.medium;
      case 'high':
        return FilterQuality.high;
      default:
        return FilterQuality.low;
    }
  }

  /// 触发图像加载完成回调
  void _triggerCallbacks(String cacheKey) {
    final callbacks = _loadCallbacks[cacheKey] ?? [];
    for (final callback in callbacks) {
      callback();
    }
    _loadCallbacks.remove(cacheKey);
  }
}
