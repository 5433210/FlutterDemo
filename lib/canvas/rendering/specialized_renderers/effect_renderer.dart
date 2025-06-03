import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/effects/canvas_effects_system.dart';

/// Collection element data
class CollectionElementData {
  final List<CollectionItem> items;
  final Color? backgroundColor;
  final Map<String, dynamic>? textureData;

  const CollectionElementData({
    required this.items,
    this.backgroundColor,
    this.textureData,
  });
}

/// Collection item data
class CollectionItem {
  final String id;
  final Rect bounds;
  final dynamic data;

  const CollectionItem({
    required this.id,
    required this.bounds,
    required this.data,
  });
}

/// Enhanced effect renderer that integrates with existing specialized renderers
///
/// This renderer provides a unified interface for applying effects to any Canvas element
/// while leveraging the existing specialized rendering infrastructure.
class EffectRenderer {
  static final EffectRenderer _instance = EffectRenderer._internal();
  final CanvasEffectsSystem _effectsSystem = CanvasEffectsSystem();
  // Performance tracking
  int _renderCount = 0;

  int _cacheHits = 0;

  int _cacheMisses = 0;
  factory EffectRenderer() => _instance;
  EffectRenderer._internal();

  /// Clear all caches and reset statistics
  void clearCaches() {
    _effectsSystem.clearCache();
    _renderCount = 0;
    _cacheHits = 0;
    _cacheMisses = 0;
  }

  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    final effectStats = _effectsSystem.getCacheStats();
    return {
      'renderCount': _renderCount,
      'cacheHits': _cacheHits,
      'cacheMisses': _cacheMisses,
      'cacheHitRate': _renderCount > 0 ? _cacheHits / _renderCount : 0.0,
      'effectsSystem': effectStats,
    };
  }

  /// Render any element with effects applied
  void renderElementWithEffects(
    Canvas canvas,
    ElementRenderInfo elementInfo, {
    List<CanvasEffect> effects = const [],
    bool useCache = true,
  }) {
    _renderCount++;

    // Generate cache key if caching enabled
    String? cacheKey;
    if (useCache && effects.isNotEmpty) {
      cacheKey = _generateCacheKey(elementInfo, effects);
    }

    // Apply effects using the effects system
    _effectsSystem.applyEffects(
      canvas,
      elementInfo.bounds,
      () => _renderElementCore(canvas, elementInfo),
      effects: effects.where((e) => e.enabled).toList(),
      cacheKey: cacheKey,
    );

    // Update cache statistics
    if (cacheKey != null) {
      // This would be implemented with proper cache hit detection
      _cacheHits++;
    } else {
      _cacheMisses++;
    }
  }

  Rect _calculateImageDestRect(Rect bounds, Size imageSize, BoxFit boxFit) {
    switch (boxFit) {
      case BoxFit.contain:
        final scale = math.min(
          bounds.width / imageSize.width,
          bounds.height / imageSize.height,
        );
        final scaledSize = Size(
          imageSize.width * scale,
          imageSize.height * scale,
        );
        return Rect.fromCenter(
          center: bounds.center,
          width: scaledSize.width,
          height: scaledSize.height,
        );

      case BoxFit.cover:
        final scale = math.max(
          bounds.width / imageSize.width,
          bounds.height / imageSize.height,
        );
        final scaledSize = Size(
          imageSize.width * scale,
          imageSize.height * scale,
        );
        return Rect.fromCenter(
          center: bounds.center,
          width: scaledSize.width,
          height: scaledSize.height,
        );

      default:
        return bounds;
    }
  }

  /// Helper methods for specific rendering tasks

  Offset _calculateTextOffset(Rect bounds, Size textSize, TextAlign align) {
    double x = bounds.left;
    switch (align) {
      case TextAlign.center:
        x = bounds.left + (bounds.width - textSize.width) / 2;
        break;
      case TextAlign.right:
        x = bounds.right - textSize.width;
        break;
      default:
        break;
    }

    final y = bounds.top + (bounds.height - textSize.height) / 2;
    return Offset(x, y);
  }

  /// Generate cache key for effect combination
  String _generateCacheKey(
      ElementRenderInfo elementInfo, List<CanvasEffect> effects) {
    final elementHash = elementInfo.hashCode;
    final effectsHash = effects.map((e) => e.hashCode).join(',');
    return '${elementHash}_$effectsHash';
  }

  /// Render collection element (e.g., character collections)
  void _renderCollectionElement(Canvas canvas, ElementRenderInfo elementInfo) {
    final collectionData = elementInfo.data as CollectionElementData;

    // Render background if specified
    if (collectionData.backgroundColor != null) {
      final backgroundPaint = Paint()
        ..color = collectionData.backgroundColor!
        ..style = PaintingStyle.fill;
      canvas.drawRect(elementInfo.bounds, backgroundPaint);
    }

    // Render collection items
    for (final item in collectionData.items) {
      _renderCollectionItem(canvas, item, collectionData);
    }

    // Render collection texture if specified
    if (collectionData.textureData != null) {
      _renderCollectionTexture(
          canvas, elementInfo.bounds, collectionData.textureData!);
    }
  }

  void _renderCollectionItem(Canvas canvas, CollectionItem item,
      CollectionElementData collectionData) {
    // This would integrate with existing collection rendering logic
    // Implementation depends on the specific collection item structure
  }

  void _renderCollectionTexture(
      Canvas canvas, Rect bounds, Map<String, dynamic> textureData) {
    // This would integrate with existing texture rendering logic
    // Implementation depends on the specific texture data structure
  }

  /// Render element using appropriate specialized renderer
  void _renderElementCore(Canvas canvas, ElementRenderInfo elementInfo) {
    switch (elementInfo.type) {
      case ElementType.text:
        _renderTextElement(canvas, elementInfo);
        break;
      case ElementType.image:
        _renderImageElement(canvas, elementInfo);
        break;
      case ElementType.shape:
        _renderShapeElement(canvas, elementInfo);
        break;
      case ElementType.collection:
        _renderCollectionElement(canvas, elementInfo);
        break;
      case ElementType.path:
        _renderPathElement(canvas, elementInfo);
        break;
      default:
        _renderGenericElement(canvas, elementInfo);
    }
  }

  /// Render generic/fallback element
  void _renderGenericElement(Canvas canvas, ElementRenderInfo elementInfo) {
    // Fallback rendering for unknown element types
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(elementInfo.bounds, paint);

    // Draw diagonal lines to indicate unknown element
    canvas.drawLine(
      elementInfo.bounds.topLeft,
      elementInfo.bounds.bottomRight,
      paint,
    );
    canvas.drawLine(
      elementInfo.bounds.topRight,
      elementInfo.bounds.bottomLeft,
      paint,
    );
  }

  /// Render image element with enhanced capabilities
  void _renderImageElement(Canvas canvas, ElementRenderInfo elementInfo) {
    final imageData = elementInfo.data as ImageElementData;

    if (imageData.image == null) {
      _renderImagePlaceholder(canvas, elementInfo.bounds);
      return;
    }

    final paint = Paint()
      ..filterQuality = imageData.filterQuality
      ..isAntiAlias = true;

    // Apply opacity if specified
    if (imageData.opacity < 1.0) {
      paint.color = Colors.white.withOpacity(imageData.opacity);
    }

    // Calculate source and destination rectangles
    final srcRect = Rect.fromLTWH(
      0,
      0,
      imageData.image!.width.toDouble(),
      imageData.image!.height.toDouble(),
    );

    final destRect = _calculateImageDestRect(
      elementInfo.bounds,
      srcRect.size,
      imageData.boxFit,
    );

    canvas.drawImageRect(imageData.image!, srcRect, destRect, paint);
  }

  void _renderImagePlaceholder(Canvas canvas, Rect bounds) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawRect(bounds, paint);

    // Draw image icon placeholder
    final iconSize = math.min(bounds.width, bounds.height) * 0.3;
    final iconRect = Rect.fromCenter(
      center: bounds.center,
      width: iconSize,
      height: iconSize,
    );

    final iconPaint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(iconRect, iconPaint);

    // Draw mountain peaks icon
    final path = Path();
    path.moveTo(iconRect.left + iconRect.width * 0.2, iconRect.bottom);
    path.lineTo(iconRect.left + iconRect.width * 0.4,
        iconRect.top + iconRect.height * 0.3);
    path.lineTo(iconRect.left + iconRect.width * 0.6,
        iconRect.top + iconRect.height * 0.5);
    path.lineTo(iconRect.left + iconRect.width * 0.8,
        iconRect.top + iconRect.height * 0.2);
    path.lineTo(iconRect.right, iconRect.bottom);

    canvas.drawPath(path, iconPaint);
  }

  /// Render path element with enhanced capabilities
  void _renderPathElement(Canvas canvas, ElementRenderInfo elementInfo) {
    final pathData = elementInfo.data as PathElementData;

    final paint = Paint()
      ..color = pathData.color
      ..style = pathData.filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = pathData.strokeWidth
      ..strokeCap = pathData.strokeCap
      ..strokeJoin = pathData.strokeJoin
      ..isAntiAlias = true;

    canvas.drawPath(pathData.path, paint);
  }

  /// Render shape element with enhanced capabilities
  void _renderShapeElement(Canvas canvas, ElementRenderInfo elementInfo) {
    final shapeData = elementInfo.data as ShapeElementData;

    final paint = Paint()
      ..color = shapeData.fillColor
      ..style = shapeData.filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = shapeData.strokeWidth
      ..isAntiAlias = true;

    switch (shapeData.shapeType) {
      case ShapeType.rectangle:
        canvas.drawRect(elementInfo.bounds, paint);
        break;
      case ShapeType.circle:
        final center = elementInfo.bounds.center;
        final radius = math.min(
              elementInfo.bounds.width,
              elementInfo.bounds.height,
            ) /
            2;
        canvas.drawCircle(center, radius, paint);
        break;
      case ShapeType.ellipse:
        canvas.drawOval(elementInfo.bounds, paint);
        break;
      case ShapeType.roundedRectangle:
        final rrect = RRect.fromRectAndRadius(
          elementInfo.bounds,
          Radius.circular(shapeData.cornerRadius),
        );
        canvas.drawRRect(rrect, paint);
        break;
      case ShapeType.polygon:
        if (shapeData.polygonPoints.isNotEmpty) {
          final path = Path();
          path.addPolygon(shapeData.polygonPoints, true);
          canvas.drawPath(path, paint);
        }
        break;
    }

    // Draw stroke if needed
    if (shapeData.filled && shapeData.strokeWidth > 0) {
      final strokePaint = Paint()
        ..color = shapeData.strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = shapeData.strokeWidth
        ..isAntiAlias = true;

      // Redraw shape with stroke
      switch (shapeData.shapeType) {
        case ShapeType.rectangle:
          canvas.drawRect(elementInfo.bounds, strokePaint);
          break;
        case ShapeType.circle:
          final center = elementInfo.bounds.center;
          final radius = math.min(
                elementInfo.bounds.width,
                elementInfo.bounds.height,
              ) /
              2;
          canvas.drawCircle(center, radius, strokePaint);
          break;
        case ShapeType.ellipse:
          canvas.drawOval(elementInfo.bounds, strokePaint);
          break;
        case ShapeType.roundedRectangle:
          final rrect = RRect.fromRectAndRadius(
            elementInfo.bounds,
            Radius.circular(shapeData.cornerRadius),
          );
          canvas.drawRRect(rrect, strokePaint);
          break;
        case ShapeType.polygon:
          if (shapeData.polygonPoints.isNotEmpty) {
            final path = Path();
            path.addPolygon(shapeData.polygonPoints, true);
            canvas.drawPath(path, strokePaint);
          }
          break;
      }
    }
  }

  /// Render text element with enhanced capabilities
  void _renderTextElement(Canvas canvas, ElementRenderInfo elementInfo) {
    final textData = elementInfo.data as TextElementData;

    // Create text painter
    final textPainter = TextPainter(
      text: TextSpan(
        text: textData.text,
        style: textData.textStyle,
      ),
      textDirection: textData.textDirection,
      textAlign: textData.textAlign,
    );

    textPainter.layout(maxWidth: elementInfo.bounds.width);

    // Calculate position for alignment
    final textOffset = _calculateTextOffset(
      elementInfo.bounds,
      textPainter.size,
      textData.textAlign,
    );

    textPainter.paint(canvas, textOffset);
  }
}

/// Element render information container
class ElementRenderInfo {
  final String id;
  final ElementType type;
  final Rect bounds;
  final dynamic data;
  final Matrix4? transform;

  const ElementRenderInfo({
    required this.id,
    required this.type,
    required this.bounds,
    required this.data,
    this.transform,
  });

  @override
  int get hashCode => Object.hash(id, type, bounds, data, transform);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ElementRenderInfo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          bounds == other.bounds &&
          data == other.data &&
          transform == other.transform;
}

/// Element type enumeration
enum ElementType {
  text,
  image,
  shape,
  collection,
  path,
  group,
}

/// Image element data
class ImageElementData {
  final ui.Image? image;
  final BoxFit boxFit;
  final FilterQuality filterQuality;
  final double opacity;

  const ImageElementData({
    this.image,
    this.boxFit = BoxFit.contain,
    this.filterQuality = FilterQuality.high,
    this.opacity = 1.0,
  });
}

/// Path element data
class PathElementData {
  final Path path;
  final Color color;
  final double strokeWidth;
  final StrokeCap strokeCap;
  final StrokeJoin strokeJoin;
  final bool filled;

  const PathElementData({
    required this.path,
    this.color = Colors.black,
    this.strokeWidth = 1.0,
    this.strokeCap = StrokeCap.round,
    this.strokeJoin = StrokeJoin.round,
    this.filled = false,
  });
}

/// Shape element data
class ShapeElementData {
  final ShapeType shapeType;
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;
  final bool filled;
  final double cornerRadius;
  final List<Offset> polygonPoints;

  const ShapeElementData({
    required this.shapeType,
    this.fillColor = Colors.blue,
    this.strokeColor = Colors.black,
    this.strokeWidth = 1.0,
    this.filled = true,
    this.cornerRadius = 0.0,
    this.polygonPoints = const [],
  });
}

/// Shape type enumeration
enum ShapeType {
  rectangle,
  circle,
  ellipse,
  roundedRectangle,
  polygon,
}

/// Text element data
class TextElementData {
  final String text;
  final TextStyle textStyle;
  final TextDirection textDirection;
  final TextAlign textAlign;

  const TextElementData({
    required this.text,
    required this.textStyle,
    this.textDirection = TextDirection.ltr,
    this.textAlign = TextAlign.left,
  });
}
