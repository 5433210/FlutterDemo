import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../rendering/specialized_renderers/collection_element_renderer.dart';
import '../../rendering/specialized_renderers/effect_renderer.dart';
import '../../rendering/specialized_renderers/image_element_renderer.dart';
import '../../rendering/specialized_renderers/path_element_renderer.dart';
import '../../rendering/specialized_renderers/shape_element_renderer.dart';
import '../../rendering/specialized_renderers/text_element_renderer.dart';
import '../effects/canvas_effects_system.dart';
import '../interfaces/element_data.dart';
import '../performance/canvas_performance_optimizer.dart';

/// Optimized rendering delegation system that intelligently routes rendering
/// operations to specialized renderers with performance optimization
class OptimizedRenderDelegateImpl {
  static final OptimizedRenderDelegateImpl _instance =
      OptimizedRenderDelegateImpl._internal();

  // Performance optimizer integration
  final CanvasPerformanceOptimizer _performanceOptimizer =
      CanvasPerformanceOptimizer();
  final CanvasEffectsSystem _effectsSystem = CanvasEffectsSystem();

  // Specialized renderers
  late final TextElementRenderer _textRenderer;
  late final ImageElementRenderer _imageRenderer;
  late final ShapeElementRenderer _shapeRenderer;
  late final CollectionElementRenderer _collectionRenderer;
  late final PathElementRenderer _pathRenderer;
  late final EffectRenderer _effectRenderer;

  // Render cache and optimization
  final Map<String, RenderPlan> _renderPlans = {};
  final Map<String, ui.Picture> _staticElementCache = {};
  final Set<String> _dirtyElements = {};

  // Viewport culling
  Rect? _viewport;
  double _lodThreshold = 1.0; // Level of detail threshold

  // Render statistics
  int _elementsRendered = 0;
  int _elementsCulled = 0;
  int _elementsFromCache = 0;
  bool _isInitialized = false;

  factory OptimizedRenderDelegateImpl() => _instance;

  OptimizedRenderDelegateImpl._internal();

  /// Clear all caches
  void clearCache() {
    _staticElementCache.clear();
    _dirtyElements.clear();
    _renderPlans.clear();
    _performanceOptimizer.clearAllCaches();
  }

  /// Get render statistics
  Map<String, dynamic> getRenderStats() {
    return {
      'elementsRendered': _elementsRendered,
      'elementsCulled': _elementsCulled,
      'elementsFromCache': _elementsFromCache,
      'cacheSize': _staticElementCache.length,
      'dirtyElements': _dirtyElements.length,
      'viewport': _viewport?.toString(),
      'lodThreshold': _lodThreshold,
    };
  }

  /// Initialize the render delegate with specialized renderers
  void initialize() {
    if (_isInitialized) return;

    _textRenderer = TextElementRenderer();
    _imageRenderer = ImageElementRenderer();
    _shapeRenderer = ShapeElementRenderer();
    _collectionRenderer = CollectionElementRenderer();
    _pathRenderer = PathElementRenderer();
    _effectRenderer = EffectRenderer();

    _isInitialized = true;
  }

  /// Mark element as dirty for re-rendering
  void markElementDirty(String elementId) {
    _dirtyElements.add(elementId);
    _performanceOptimizer.clearDirtyRegion(elementId);
  }

  /// Mark multiple elements as dirty
  void markElementsDirty(List<String> elementIds) {
    _dirtyElements.addAll(elementIds);
    for (final id in elementIds) {
      _performanceOptimizer.clearDirtyRegion(id);
    }
  }

  /// Render single element with optimization
  Future<void> renderElement(
    Canvas canvas,
    Map<String, dynamic> element, {
    bool enableCaching = true,
    bool force = false,
  }) async {
    if (!_isInitialized) initialize();

    final elementId = element['id'] as String;
    final elementType = element['type'] as String;

    final tracker =
        _performanceOptimizer.startTracking('renderElement_$elementType');

    try {
      // Check cache first
      if (enableCaching && !force && !_dirtyElements.contains(elementId)) {
        final cachedPicture = _performanceOptimizer.getCachedPicture(elementId);
        if (cachedPicture != null) {
          canvas.drawPicture(cachedPicture);
          _elementsFromCache++;
          return;
        }
      }

      // Render element
      await _renderElementInternal(canvas, element, enableCaching);

      // Remove from dirty set
      _dirtyElements.remove(elementId);
    } finally {
      tracker.finish();
    }
  }

  /// Render multiple elements with optimization
  Future<void> renderElements(
    Canvas canvas,
    List<Map<String, dynamic>> elements, {
    Rect? clipRect,
    double scale = 1.0,
    bool enableCaching = true,
    bool enableCulling = true,
  }) async {
    if (!_isInitialized) initialize();

    final tracker = _performanceOptimizer.startTracking('renderElements');

    try {
      _resetRenderStats();

      // Create render plan
      final renderPlan = _createRenderPlan(elements, scale, enableCulling);

      // Apply viewport clipping if specified
      if (clipRect != null) {
        canvas.save();
        canvas.clipRect(clipRect);
      }

      // Render in optimized order
      await _executeRenderPlan(canvas, renderPlan, enableCaching);

      if (clipRect != null) {
        canvas.restore();
      }

      _logRenderStats();
    } finally {
      tracker.finish();
    }
  }

  /// Set viewport for culling optimization
  void setViewport(Rect viewport, double scale) {
    _viewport = viewport;
    _lodThreshold = _calculateLODThreshold(scale);
  }

  // Internal implementation methods

  /// Calculate LOD threshold based on scale
  double _calculateLODThreshold(double scale) {
    // At very low zoom levels, start culling small elements
    if (scale < 0.1) return 0.5;
    if (scale < 0.25) return 0.75;
    return 1.0;
  }

  /// Calculate render priority (lower = render first)
  int _calculateRenderPriority(Map<String, dynamic> element, double scale) {
    final zIndex = (element['zIndex'] as num?)?.toInt() ?? 0;
    final complexity = _estimateRenderComplexity(element);

    // Background elements first, then by complexity, then by z-index
    return (zIndex * 1000) + complexity;
  }

  /// Create a render plan for optimization
  RenderPlan _createRenderPlan(
    List<Map<String, dynamic>> elements,
    double scale,
    bool enableCulling,
  ) {
    final items = <RenderItem>[];

    for (final element in elements) {
      final elementId = element['id'] as String;

      // Skip if should be culled
      if (enableCulling) {
        if (_shouldCullElement(element, scale)) {
          _elementsCulled++;
          continue;
        }
      }

      // Add to render plan
      final priority = _calculateRenderPriority(element, scale);
      items.add(RenderItem(
        element: element,
        priority: priority,
      ));
    }

    // Sort by priority
    items.sort((a, b) => a.priority.compareTo(b.priority));

    return RenderPlan(
      items: items,
      enableCulling: enableCulling,
      scale: scale,
    );
  }

  /// Estimate rendering complexity of an element (higher = more complex)
  int _estimateRenderComplexity(Map<String, dynamic> element) {
    final type = element['type'] as String;
    int complexity = 1;

    switch (type) {
      case 'text':
        // Text complexity based on length
        final text = element['text'] as String?;
        complexity = text != null ? math.min(10, text.length ~/ 50 + 1) : 1;
        break;
      case 'image':
        // Images are generally expensive
        complexity = 3;
        break;
      case 'shape':
        // Shape complexity based on points
        final shapeType = element['shapeType'] as String?;
        if (shapeType == 'polygon' || shapeType == 'polyline') {
          final points = element['points'] as List<dynamic>?;
          complexity =
              points != null ? math.min(5, points.length ~/ 10 + 1) : 1;
        }
        break;
      case 'path':
        // Paths can be very complex
        complexity = 4;
        break;
      case 'collection':
        // Collections contain multiple elements
        final children = element['children'] as List<dynamic>?;
        complexity = children != null ? math.min(8, children.length + 1) : 1;
        break;
    }

    // Check if has effects which add complexity
    final hasEffects = element['effects'] != null &&
        (element['effects'] as Map<String, dynamic>?)?.isNotEmpty == true;

    if (hasEffects) {
      complexity += 2;
    }

    return complexity;
  }

  /// Execute a render plan
  Future<void> _executeRenderPlan(
    Canvas canvas,
    RenderPlan plan,
    bool enableCaching,
  ) async {
    for (final item in plan.items) {
      await renderElement(
        canvas,
        item.element,
        enableCaching: enableCaching,
      );
      _elementsRendered++;
    }
  }

  /// Get element bounds from element data
  Rect _getElementBounds(Map<String, dynamic> element) {
    final x = (element['x'] as num?)?.toDouble() ?? 0.0;
    final y = (element['y'] as num?)?.toDouble() ?? 0.0;
    final width = (element['width'] as num?)?.toDouble() ?? 100.0;
    final height = (element['height'] as num?)?.toDouble() ?? 100.0;

    return Rect.fromLTWH(x, y, width, height);
  }

  /// Log render statistics
  void _logRenderStats() {
    if (kDebugMode) {
      print('Render stats: rendered=$_elementsRendered, '
          'culled=$_elementsCulled, '
          'fromCache=$_elementsFromCache');
    }
  }

  /// Render collection element
  Future<void> _renderCollectionElement(
      Canvas canvas, Map<String, dynamic> element) async {
    // Create ElementData for the renderer
    final elementData = ElementData(
      id: element['id'] as String,
      type: 'collection',
      layerId: element['layerId'] as String? ?? 'default',
      bounds: _getElementBounds(element),
      opacity: (element['opacity'] as num?)?.toDouble() ?? 1.0,
      visible: (element['visible'] as bool?) ?? true,
      rotation: (element['rotation'] as num?)?.toDouble() ?? 0.0,
      properties: element,
      zIndex: (element['zIndex'] as num?)?.toInt() ?? 0,
      version: (element['version'] as num?)?.toInt() ?? 1,
    );

    // Use specialized renderer
    _collectionRenderer.render(canvas, elementData);
  }

  /// Internal element rendering with caching
  Future<void> _renderElementInternal(
    Canvas canvas,
    Map<String, dynamic> element,
    bool enableCaching,
  ) async {
    final elementId = element['id'] as String;

    // If caching is enabled, render to a picture
    if (enableCaching) {
      final pictureRecorder = ui.PictureRecorder();
      final pictureCanvas = Canvas(pictureRecorder);

      await _renderSingleElement(pictureCanvas, element);

      final picture = pictureRecorder.endRecording();
      canvas.drawPicture(picture);

      // Cache the picture for future use
      _performanceOptimizer.cachePicture(elementId, picture);
    } else {
      // Render directly to canvas
      await _renderSingleElement(canvas, element);
    }
  }

  /// Render image element
  Future<void> _renderImageElement(
      Canvas canvas, Map<String, dynamic> element) async {
    // Create ElementData for the renderer
    final elementData = ElementData(
      id: element['id'] as String,
      type: 'image',
      layerId: element['layerId'] as String? ?? 'default',
      bounds: _getElementBounds(element),
      opacity: (element['opacity'] as num?)?.toDouble() ?? 1.0,
      visible: (element['visible'] as bool?) ?? true,
      rotation: (element['rotation'] as num?)?.toDouble() ?? 0.0,
      properties: element,
      zIndex: (element['zIndex'] as num?)?.toInt() ?? 0,
      version: (element['version'] as num?)?.toInt() ?? 1,
    );

    // Use specialized renderer
    _imageRenderer.render(canvas, elementData);
  }

  /// Render path element
  Future<void> _renderPathElement(
      Canvas canvas, Map<String, dynamic> element) async {
    // Create ElementData for the renderer
    final elementData = ElementData(
      id: element['id'] as String,
      type: 'path',
      layerId: element['layerId'] as String? ?? 'default',
      bounds: _getElementBounds(element),
      opacity: (element['opacity'] as num?)?.toDouble() ?? 1.0,
      visible: (element['visible'] as bool?) ?? true,
      rotation: (element['rotation'] as num?)?.toDouble() ?? 0.0,
      properties: element,
      zIndex: (element['zIndex'] as num?)?.toInt() ?? 0,
      version: (element['version'] as num?)?.toInt() ?? 1,
    );

    // Use specialized renderer
    _pathRenderer.render(canvas, elementData);
  }

  /// Render placeholder for unknown elements
  void _renderPlaceholder(Canvas canvas, Rect bounds) {
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawRect(bounds, paint);

    final strokePaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRect(bounds, strokePaint);

    // Draw X
    canvas.drawLine(
      Offset(bounds.left, bounds.top),
      Offset(bounds.right, bounds.bottom),
      strokePaint,
    );
    canvas.drawLine(
      Offset(bounds.right, bounds.top),
      Offset(bounds.left, bounds.bottom),
      strokePaint,
    );
  }

  /// Render shape element
  Future<void> _renderShapeElement(
      Canvas canvas, Map<String, dynamic> element) async {
    // Create ElementData for the renderer
    final elementData = ElementData(
      id: element['id'] as String,
      type: 'shape',
      layerId: element['layerId'] as String? ?? 'default',
      bounds: _getElementBounds(element),
      opacity: (element['opacity'] as num?)?.toDouble() ?? 1.0,
      visible: (element['visible'] as bool?) ?? true,
      rotation: (element['rotation'] as num?)?.toDouble() ?? 0.0,
      properties: element,
      zIndex: (element['zIndex'] as num?)?.toInt() ?? 0,
      version: (element['version'] as num?)?.toInt() ?? 1,
    );

    // Use specialized renderer
    _shapeRenderer.render(canvas, elementData);
  }

  /// Render a single element based on its type
  Future<void> _renderSingleElement(
      Canvas canvas, Map<String, dynamic> element) async {
    final elementType = element['type'] as String;
    final bounds = _getElementBounds(element);

    // Register region for optimization
    final elementId = element['id'] as String;
    _performanceOptimizer.registerDirtyRegion(elementId, bounds);

    // Apply common transformations
    canvas.save();

    // Apply element opacity
    final opacity = (element['opacity'] as num?)?.toDouble() ?? 1.0;
    if (opacity < 1.0) {
      canvas.saveLayer(
          bounds, Paint()..color = Colors.white.withOpacity(opacity));
    }

    // Apply element transform if any
    final rotation = (element['rotation'] as num?)?.toDouble() ?? 0.0;
    if (rotation != 0) {
      final centerX = bounds.left + bounds.width / 2;
      final centerY = bounds.top + bounds.height / 2;
      canvas.translate(centerX, centerY);
      canvas.rotate(rotation);
      canvas.translate(-centerX, -centerY);
    }

    // Render based on element type
    switch (elementType) {
      case 'text':
        await _renderTextElement(canvas, element);
        break;
      case 'image':
        await _renderImageElement(canvas, element);
        break;
      case 'shape':
        await _renderShapeElement(canvas, element);
        break;
      case 'path':
        await _renderPathElement(canvas, element);
        break;
      case 'collection':
        await _renderCollectionElement(canvas, element);
        break;
      default:
        // Unknown element type, render as placeholder
        _renderPlaceholder(canvas, bounds);
        break;
    }

    // Restore canvas state
    if (opacity < 1.0) {
      canvas.restore();
    }
    canvas.restore();
  }

  /// Render text element
  Future<void> _renderTextElement(
      Canvas canvas, Map<String, dynamic> element) async {
    // Create ElementData for the renderer
    final elementData = ElementData(
      id: element['id'] as String,
      type: 'text',
      layerId: element['layerId'] as String? ?? 'default',
      bounds: _getElementBounds(element),
      opacity: (element['opacity'] as num?)?.toDouble() ?? 1.0,
      visible: (element['visible'] as bool?) ?? true,
      rotation: (element['rotation'] as num?)?.toDouble() ?? 0.0,
      properties: element,
      zIndex: (element['zIndex'] as num?)?.toInt() ?? 0,
      version: (element['version'] as num?)?.toInt() ?? 1,
    );

    // Use specialized renderer
    _textRenderer.render(canvas, elementData);
  }

  /// Reset render statistics
  void _resetRenderStats() {
    _elementsRendered = 0;
    _elementsCulled = 0;
    _elementsFromCache = 0;
  }

  /// Check if element should be culled based on viewport
  bool _shouldCullElement(Map<String, dynamic> element, double scale) {
    // If no viewport defined, don't cull
    if (_viewport == null) return false;

    // Skip culling for very important elements
    final isImportant = element['important'] as bool? ?? false;
    if (isImportant) return false;

    // Get element bounds
    final bounds = _getElementBounds(element);

    // Check if completely outside viewport
    if (!bounds.overlaps(_viewport!)) {
      return true;
    }

    // Check level of detail culling for small elements
    return _shouldCullForLOD(element, scale);
  }

  /// Check if element should be culled for level of detail
  bool _shouldCullForLOD(Map<String, dynamic> element, double scale) {
    // Skip LOD culling at high zoom levels
    if (scale >= _lodThreshold) return false;

    final elementType = element['type'] as String;
    final bounds = _getElementBounds(element);

    // Calculate screen area
    final screenArea = bounds.width * bounds.height * scale * scale;

    switch (elementType) {
      case 'text':
        // Cull very small text
        return screenArea < 100; // 10x10 pixels
      case 'image':
        // Keep images visible longer
        return screenArea < 25; // 5x5 pixels
      case 'shape':
        // Basic shapes
        return screenArea < 50; // 7x7 pixels
      case 'path':
        // Paths might be important
        return screenArea < 36; // 6x6 pixels
      case 'collection':
        // Collections might contain important items
        return screenArea < 25; // 5x5 pixels
      default:
        return screenArea < 64; // 8x8 pixels
    }
  }
}

/// Render item for optimization
class RenderItem {
  final Map<String, dynamic> element;
  final int priority;

  const RenderItem({
    required this.element,
    required this.priority,
  });
}

/// Render plan for batch optimization
class RenderPlan {
  final List<RenderItem> items;
  final bool enableCulling;
  final double scale;

  const RenderPlan({
    required this.items,
    this.enableCulling = true,
    this.scale = 1.0,
  });
}
