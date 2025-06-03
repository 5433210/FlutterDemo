import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../performance/canvas_performance_optimizer.dart';

/// Blur effect implementation
class BlurEffect extends CanvasEffect {
  final double sigmaX;
  final double sigmaY;
  final TileMode tileMode;

  const BlurEffect({
    this.sigmaX = 2.0,
    this.sigmaY = 2.0,
    this.tileMode = TileMode.clamp,
    super.enabled = true,
    super.opacity = 1.0,
  }) : super(type: EffectType.blur);

  @override
  int get hashCode => Object.hash(super.hashCode, sigmaX, sigmaY, tileMode);

  BlurEffect copyWith({
    double? sigmaX,
    double? sigmaY,
    TileMode? tileMode,
    bool? enabled,
    double? opacity,
  }) {
    return BlurEffect(
      sigmaX: sigmaX ?? this.sigmaX,
      sigmaY: sigmaY ?? this.sigmaY,
      tileMode: tileMode ?? this.tileMode,
      enabled: enabled ?? this.enabled,
      opacity: opacity ?? this.opacity,
    );
  }
}

/// Base class for all canvas effects
abstract class CanvasEffect {
  final EffectType type;
  final bool enabled;
  final double opacity;

  const CanvasEffect({
    required this.type,
    this.enabled = true,
    this.opacity = 1.0,
  });

  @override
  int get hashCode => Object.hash(type, enabled, opacity);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CanvasEffect &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          enabled == other.enabled &&
          opacity == other.opacity;
}

/// Comprehensive Canvas Effects System for applying visual effects to elements
///
/// This system provides a unified interface for applying shadows, blur, gradients,
/// and other visual effects to Canvas elements. It integrates with the existing
/// Canvas rendering pipeline and supports performance optimization through caching.
class CanvasEffectsSystem {
  static final CanvasEffectsSystem _instance = CanvasEffectsSystem._internal();
  // Cache management (deprecated - use performance optimizer)
  @deprecated
  static const int maxCacheSize = 100;
  // Performance optimizer integration
  final CanvasPerformanceOptimizer _performanceOptimizer =
      CanvasPerformanceOptimizer();

  // Effect cache for performance optimization (deprecated - use performance optimizer)
  @deprecated
  final Map<String, ui.Picture> _effectCache = {};

  @deprecated
  final Map<String, ui.ImageFilter> _filterCache = {};
  @deprecated
  final Map<String, ui.Shader> _shaderCache = {};
  @deprecated
  int _cacheAccessCounter = 0;

  // Element effects storage
  final Map<String, Map<String, dynamic>> _elementEffects = {};

  factory CanvasEffectsSystem() => _instance;
  CanvasEffectsSystem._internal();

  /// Apply an effect to an element
  void applyEffect(
      String elementId, String effectType, Map<String, dynamic> config) {
    if (!_elementEffects.containsKey(elementId)) {
      _elementEffects[elementId] = {};
    }
    _elementEffects[elementId]![effectType] = config;
  }

  /// Apply multiple effects to an element with caching
  void applyEffects(
    Canvas canvas,
    Rect elementBounds,
    VoidCallback drawElement, {
    List<CanvasEffect> effects = const [],
    String? cacheKey,
  }) {
    if (effects.isEmpty) {
      drawElement();
      return;
    }

    final tracker = _performanceOptimizer.startTracking('applyEffects');

    try {
      // Check cache if key provided
      if (cacheKey != null) {
        final cachedPicture = _performanceOptimizer.getCachedPicture(cacheKey);
        if (cachedPicture != null) {
          canvas.drawPicture(cachedPicture);
          return;
        }
      }

      // Apply effects using performance-optimized approach
      _performanceOptimizer.optimizedDraw(canvas, cacheKey ?? 'effects', () {
        _applyEffectsInternal(
            canvas, elementBounds, drawElement, effects, cacheKey);
      });
    } finally {
      tracker.finish();
    }
  }

  /// Clear all effect caches
  void clearCache() {
    // Use performance optimizer for cache management
    _performanceOptimizer.clearAllCaches();

    // Legacy cache clearing for compatibility
    _effectCache.clear();
    _filterCache.clear();
    _shaderCache.clear();
    _cacheAccessCounter = 0;
  }

  /// Dispose of resources
  void dispose() {
    clearCache();
    _elementEffects.clear();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'effectCacheSize': _effectCache.length,
      'filterCacheSize': _filterCache.length,
      'shaderCacheSize': _shaderCache.length,
      'totalAccesses': _cacheAccessCounter,
      'maxCacheSize': maxCacheSize,
    };
  }

  /// Remove an effect from an element
  void removeEffect(String elementId, String effectType) {
    if (_elementEffects.containsKey(elementId)) {
      _elementEffects[elementId]?.remove(effectType);
    }
  }

  /// Apply blur effect
  Canvas _applyBlurEffect(
    Canvas canvas,
    Rect bounds,
    BlurEffect effect,
    VoidCallback drawElement,
  ) {
    final filterKey = '${effect.hashCode}';
    ui.ImageFilter? imageFilter = _filterCache[filterKey];

    if (imageFilter == null) {
      imageFilter = ui.ImageFilter.blur(
        sigmaX: effect.sigmaX,
        sigmaY: effect.sigmaY,
        tileMode: effect.tileMode,
      );
      _filterCache[filterKey] = imageFilter;
    }

    final paint = Paint()..imageFilter = imageFilter;
    canvas.saveLayer(bounds, paint);
    drawElement();
    canvas.restore();

    return canvas;
  }

  /// Apply color filter effect
  Canvas _applyColorFilterEffect(
    Canvas canvas,
    Rect bounds,
    ColorFilterEffect effect,
    VoidCallback drawElement,
  ) {
    final paint = Paint()..colorFilter = effect.colorFilter;

    canvas.saveLayer(bounds, paint);
    drawElement();
    canvas.restore();

    return canvas;
  }

  /// Apply distortion effect
  Canvas _applyDistortionEffect(
    Canvas canvas,
    Rect bounds,
    DistortionEffect effect,
    VoidCallback drawElement,
  ) {
    // For distortion effects, we need to use transform matrix
    canvas.save();

    final center = bounds.center;
    canvas.translate(center.dx, center.dy);

    // Apply distortion transform
    final matrix = Matrix4.identity();
    switch (effect.distortionType) {
      case DistortionType.perspective:
        matrix.setEntry(3, 2, effect.intensity);
        break;
      case DistortionType.wave:
        // Wave distortion would require custom implementation
        // This is a simplified version
        final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
        final waveOffset = math.sin(time * effect.frequency) * effect.amplitude;
        canvas.translate(waveOffset, 0);
        break;
      case DistortionType.ripple:
        // Ripple effect implementation
        final distance = effect.intensity * 10;
        final ripple = math.sin(distance) * effect.amplitude;
        canvas.scale(1 + ripple * 0.1);
        break;
    }

    if (effect.distortionType == DistortionType.perspective) {
      canvas.transform(matrix.storage);
    }

    canvas.translate(-center.dx, -center.dy);
    drawElement();
    canvas.restore();

    return canvas;
  }

  /// Apply a single effect
  Canvas _applyEffect(
    Canvas canvas,
    Rect bounds,
    CanvasEffect effect,
    VoidCallback drawElement,
  ) {
    switch (effect.type) {
      case EffectType.shadow:
        return _applyShadowEffect(
            canvas, bounds, effect as ShadowEffect, drawElement);
      case EffectType.blur:
        return _applyBlurEffect(
            canvas, bounds, effect as BlurEffect, drawElement);
      case EffectType.gradient:
        return _applyGradientEffect(
            canvas, bounds, effect as GradientEffect, drawElement);
      case EffectType.glow:
        return _applyGlowEffect(
            canvas, bounds, effect as GlowEffect, drawElement);
      case EffectType.colorFilter:
        return _applyColorFilterEffect(
            canvas, bounds, effect as ColorFilterEffect, drawElement);
      case EffectType.distortion:
        return _applyDistortionEffect(
            canvas, bounds, effect as DistortionEffect, drawElement);
    }
  }

  /// Internal method to apply effects (without caching)
  void _applyEffectsInternal(
    Canvas canvas,
    Rect elementBounds,
    VoidCallback drawElement,
    List<CanvasEffect> effects,
    String? cacheKey,
  ) {
    // Create offscreen canvas for effect composition
    final recorder = ui.PictureRecorder();
    final offscreenCanvas = Canvas(recorder, elementBounds);

    // Apply effects in order
    Canvas currentCanvas = offscreenCanvas;
    for (final effect in effects) {
      currentCanvas =
          _applyEffect(currentCanvas, elementBounds, effect, drawElement);
    }

    // Finalize and cache
    final picture = recorder.endRecording();
    if (cacheKey != null) {
      _cacheEffect(cacheKey, picture);
    }

    // Draw to main canvas
    canvas.drawPicture(picture);
  }

  /// Apply glow effect
  Canvas _applyGlowEffect(
    Canvas canvas,
    Rect bounds,
    GlowEffect effect,
    VoidCallback drawElement,
  ) {
    // Create multiple blur layers for glow
    for (int i = 0; i < effect.layers; i++) {
      final layerOpacity = effect.opacity * (1.0 - (i / effect.layers));
      final layerRadius = effect.radius * (1.0 + (i * 0.3));

      final glowPaint = Paint()
        ..color = effect.color.withOpacity(layerOpacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, layerRadius);

      canvas.saveLayer(bounds, glowPaint);
      drawElement();
      canvas.restore();
    }

    // Draw original element on top
    drawElement();
    return canvas;
  }

  /// Apply gradient effect
  Canvas _applyGradientEffect(
    Canvas canvas,
    Rect bounds,
    GradientEffect effect,
    VoidCallback drawElement,
  ) {
    final shaderKey = '${effect.hashCode}_${bounds.hashCode}';
    ui.Shader? shader = _shaderCache[shaderKey];

    if (shader == null) {
      shader = effect.gradient.createShader(bounds);
      _shaderCache[shaderKey] = shader;
    }

    final paint = Paint()
      ..shader = shader
      ..blendMode = effect.blendMode;

    // Draw element first
    drawElement();

    // Apply gradient overlay
    canvas.saveLayer(bounds, paint);
    canvas.drawRect(bounds, Paint()..color = Colors.white);
    canvas.restore();

    return canvas;
  }

  /// Apply shadow effect
  Canvas _applyShadowEffect(
    Canvas canvas,
    Rect bounds,
    ShadowEffect effect,
    VoidCallback drawElement,
  ) {
    // Create shadow layer
    final shadowPaint = Paint()
      ..color = effect.color.withOpacity(effect.opacity)
      ..maskFilter = MaskFilter.blur(effect.blurStyle, effect.blurRadius);

    // Apply shadow offset and draw
    canvas.save();
    canvas.translate(effect.offset.dx, effect.offset.dy);

    if (effect.innerShadow) {
      // Inner shadow implementation
      canvas.saveLayer(bounds, Paint());
      drawElement();
      canvas.saveLayer(bounds, Paint()..blendMode = BlendMode.srcIn);
      canvas.drawRect(bounds.inflate(effect.blurRadius), shadowPaint);
      canvas.restore();
      canvas.restore();
    } else {
      // Outer shadow
      final recorder = ui.PictureRecorder();
      final shadowCanvas = Canvas(recorder, bounds);

      // Draw element on shadow canvas
      shadowCanvas.saveLayer(bounds, shadowPaint);
      drawElement();
      shadowCanvas.restore();

      final shadowPicture = recorder.endRecording();
      canvas.drawPicture(shadowPicture);
    }

    canvas.restore();

    // Draw original element on top
    drawElement();
    return canvas;
  }

  /// Cache an effect result
  void _cacheEffect(String key, ui.Picture picture) {
    if (_effectCache.length >= maxCacheSize) {
      // Remove oldest entries (simple LRU implementation)
      final keys = _effectCache.keys.take(10).toList();
      for (final key in keys) {
        _effectCache.remove(key);
      }
    }
    _effectCache[key] = picture;
    _cacheAccessCounter++;
  }
}

/// Color filter effect implementation
class ColorFilterEffect extends CanvasEffect {
  final ColorFilter colorFilter;

  const ColorFilterEffect({
    required this.colorFilter,
    super.enabled = true,
    super.opacity = 1.0,
  }) : super(type: EffectType.colorFilter);

  @override
  int get hashCode => Object.hash(super.hashCode, colorFilter);

  ColorFilterEffect copyWith({
    ColorFilter? colorFilter,
    bool? enabled,
    double? opacity,
  }) {
    return ColorFilterEffect(
      colorFilter: colorFilter ?? this.colorFilter,
      enabled: enabled ?? this.enabled,
      opacity: opacity ?? this.opacity,
    );
  }
}

/// Distortion effect implementation
class DistortionEffect extends CanvasEffect {
  final DistortionType distortionType;
  final double intensity;
  final double amplitude;
  final double frequency;

  const DistortionEffect({
    this.distortionType = DistortionType.perspective,
    this.intensity = 0.001,
    this.amplitude = 5.0,
    this.frequency = 2.0,
    super.enabled = true,
    super.opacity = 1.0,
  }) : super(type: EffectType.distortion);

  @override
  int get hashCode => Object.hash(
        super.hashCode,
        distortionType,
        intensity,
        amplitude,
        frequency,
      );

  DistortionEffect copyWith({
    DistortionType? distortionType,
    double? intensity,
    double? amplitude,
    double? frequency,
    bool? enabled,
    double? opacity,
  }) {
    return DistortionEffect(
      distortionType: distortionType ?? this.distortionType,
      intensity: intensity ?? this.intensity,
      amplitude: amplitude ?? this.amplitude,
      frequency: frequency ?? this.frequency,
      enabled: enabled ?? this.enabled,
      opacity: opacity ?? this.opacity,
    );
  }
}

/// Distortion types enumeration
enum DistortionType {
  perspective,
  wave,
  ripple,
}

/// Predefined effect presets for common use cases
class EffectPresets {
  // Shadow presets
  static const dropShadow = ShadowEffect(
    offset: Offset(0, 2),
    blurRadius: 4,
    color: Colors.black,
    opacity: 0.25,
  );

  static const innerShadow = ShadowEffect(
    offset: Offset(0, 1),
    blurRadius: 3,
    color: Colors.black,
    opacity: 0.5,
    innerShadow: true,
  );

  static const strongShadow = ShadowEffect(
    offset: Offset(0, 8),
    blurRadius: 16,
    color: Colors.black,
    opacity: 0.3,
  );

  // Blur presets
  static const lightBlur = BlurEffect(sigmaX: 1, sigmaY: 1);
  static const mediumBlur = BlurEffect(sigmaX: 3, sigmaY: 3);
  static const heavyBlur = BlurEffect(sigmaX: 6, sigmaY: 6);

  // Glow presets
  static const softGlow = GlowEffect(
    color: Colors.white,
    radius: 4,
    layers: 2,
    opacity: 0.6,
  );

  static const brightGlow = GlowEffect(
    color: Colors.blue,
    radius: 8,
    layers: 4,
    opacity: 0.8,
  );

  // Gradient presets
  static const rainbowGradient = GradientEffect(
    gradient: LinearGradient(
      colors: [
        Colors.red,
        Colors.orange,
        Colors.yellow,
        Colors.green,
        Colors.blue,
        Colors.indigo,
        Colors.purple,
      ],
    ),
    blendMode: BlendMode.overlay,
  );

  static const goldGradient = GradientEffect(
    gradient: LinearGradient(
      colors: [
        Color(0xFFFFD700),
        Color(0xFFFFA500),
        Color(0xFFFFD700),
      ],
    ),
    blendMode: BlendMode.multiply,
  );

  // Color filter presets
  static const sepia = ColorFilterEffect(
    colorFilter: ColorFilter.matrix([
      0.393,
      0.769,
      0.189,
      0,
      0,
      0.349,
      0.686,
      0.168,
      0,
      0,
      0.272,
      0.534,
      0.131,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ]),
  );

  static const grayscale = ColorFilterEffect(
    colorFilter: ColorFilter.matrix([
      0.2126,
      0.7152,
      0.0722,
      0,
      0,
      0.2126,
      0.7152,
      0.0722,
      0,
      0,
      0.2126,
      0.7152,
      0.0722,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ]),
  );

  static const invert = ColorFilterEffect(
    colorFilter: ColorFilter.matrix([
      -1,
      0,
      0,
      0,
      255,
      0,
      -1,
      0,
      0,
      255,
      0,
      0,
      -1,
      0,
      255,
      0,
      0,
      0,
      1,
      0,
    ]),
  );
}

/// Effect types enumeration
enum EffectType {
  shadow,
  blur,
  gradient,
  glow,
  colorFilter,
  distortion,
}

/// Glow effect implementation
class GlowEffect extends CanvasEffect {
  final Color color;
  final double radius;
  final int layers;

  const GlowEffect({
    this.color = Colors.white,
    this.radius = 6.0,
    this.layers = 3,
    super.enabled = true,
    super.opacity = 0.8,
  }) : super(type: EffectType.glow);

  @override
  int get hashCode => Object.hash(super.hashCode, color, radius, layers);

  GlowEffect copyWith({
    Color? color,
    double? radius,
    int? layers,
    bool? enabled,
    double? opacity,
  }) {
    return GlowEffect(
      color: color ?? this.color,
      radius: radius ?? this.radius,
      layers: layers ?? this.layers,
      enabled: enabled ?? this.enabled,
      opacity: opacity ?? this.opacity,
    );
  }
}

/// Gradient effect implementation
class GradientEffect extends CanvasEffect {
  final Gradient gradient;
  final BlendMode blendMode;

  const GradientEffect({
    required this.gradient,
    this.blendMode = BlendMode.overlay,
    super.enabled = true,
    super.opacity = 1.0,
  }) : super(type: EffectType.gradient);

  @override
  int get hashCode => Object.hash(super.hashCode, gradient, blendMode);

  GradientEffect copyWith({
    Gradient? gradient,
    BlendMode? blendMode,
    bool? enabled,
    double? opacity,
  }) {
    return GradientEffect(
      gradient: gradient ?? this.gradient,
      blendMode: blendMode ?? this.blendMode,
      enabled: enabled ?? this.enabled,
      opacity: opacity ?? this.opacity,
    );
  }
}

/// Shadow effect implementation
class ShadowEffect extends CanvasEffect {
  final Offset offset;
  final double blurRadius;
  final Color color;
  final BlurStyle blurStyle;
  final bool innerShadow;

  const ShadowEffect({
    this.offset = const Offset(2, 2),
    this.blurRadius = 4.0,
    this.color = Colors.black,
    this.blurStyle = BlurStyle.normal,
    this.innerShadow = false,
    super.enabled = true,
    super.opacity = 0.3,
  }) : super(type: EffectType.shadow);

  @override
  int get hashCode => Object.hash(
        super.hashCode,
        offset,
        blurRadius,
        color,
        blurStyle,
        innerShadow,
      );

  ShadowEffect copyWith({
    Offset? offset,
    double? blurRadius,
    Color? color,
    BlurStyle? blurStyle,
    bool? innerShadow,
    bool? enabled,
    double? opacity,
  }) {
    return ShadowEffect(
      offset: offset ?? this.offset,
      blurRadius: blurRadius ?? this.blurRadius,
      color: color ?? this.color,
      blurStyle: blurStyle ?? this.blurStyle,
      innerShadow: innerShadow ?? this.innerShadow,
      enabled: enabled ?? this.enabled,
      opacity: opacity ?? this.opacity,
    );
  }
}
