// filepath: lib/canvas/core/effects/canvas_effects.dart

import 'package:flutter/material.dart';

/// Blur effect configuration
class BlurEffect extends CanvasEffect {
  final double sigmaX;
  final double sigmaY;
  final TileMode tileMode;

  const BlurEffect({
    this.sigmaX = 4.0,
    this.sigmaY = 4.0,
    this.tileMode = TileMode.clamp,
    super.opacity = 1.0,
    super.enabled = true,
  }) : super(type: EffectType.blur);

  /// Create a gaussian blur
  factory BlurEffect.gaussian(double radius) {
    return BlurEffect(sigmaX: radius, sigmaY: radius);
  }

  /// Create a motion blur
  factory BlurEffect.motion({
    double horizontal = 0.0,
    double vertical = 4.0,
  }) {
    return BlurEffect(sigmaX: horizontal, sigmaY: vertical);
  }

  @override
  int get hashCode => Object.hash(super.hashCode, sigmaX, sigmaY, tileMode);

  @override
  bool operator ==(Object other) {
    return super == other &&
        other is BlurEffect &&
        other.sigmaX == sigmaX &&
        other.sigmaY == sigmaY &&
        other.tileMode == tileMode;
  }
}

/// Base class for all canvas effects
abstract class CanvasEffect {
  final EffectType type;
  final double opacity;
  final bool enabled;

  const CanvasEffect({
    required this.type,
    this.opacity = 1.0,
    this.enabled = true,
  });

  @override
  int get hashCode => Object.hash(type, opacity, enabled);

  @override
  bool operator ==(Object other) {
    return other is CanvasEffect &&
        other.type == type &&
        other.opacity == opacity &&
        other.enabled == enabled;
  }
}

/// Color filter effect configuration
class ColorFilterEffect extends CanvasEffect {
  final ColorFilter colorFilter;

  const ColorFilterEffect({
    required this.colorFilter,
    super.opacity = 1.0,
    super.enabled = true,
  }) : super(type: EffectType.colorFilter);

  /// Create a grayscale effect
  factory ColorFilterEffect.grayscale() {
    return ColorFilterEffect.matrix([
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
    ]);
  }

  /// Create an invert effect
  factory ColorFilterEffect.invert() {
    return ColorFilterEffect.matrix([
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
    ]);
  }

  /// Create a matrix color filter
  factory ColorFilterEffect.matrix(List<double> matrix) {
    return ColorFilterEffect(
      colorFilter: ColorFilter.matrix(matrix),
    );
  }

  /// Create a mode color filter
  factory ColorFilterEffect.mode(Color color, BlendMode blendMode) {
    return ColorFilterEffect(
      colorFilter: ColorFilter.mode(color, blendMode),
    );
  }

  /// Create a sepia effect
  factory ColorFilterEffect.sepia() {
    return ColorFilterEffect.matrix([
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
    ]);
  }

  @override
  int get hashCode => Object.hash(super.hashCode, colorFilter);

  @override
  bool operator ==(Object other) {
    return super == other &&
        other is ColorFilterEffect &&
        other.colorFilter == colorFilter;
  }
}

/// Distortion effect configuration
class DistortionEffect extends CanvasEffect {
  final DistortionType distortionType;
  final double intensity;
  final double frequency;
  final double amplitude;

  const DistortionEffect({
    this.distortionType = DistortionType.perspective,
    this.intensity = 0.001,
    this.frequency = 1.0,
    this.amplitude = 10.0,
    super.opacity = 1.0,
    super.enabled = true,
  }) : super(type: EffectType.distortion);

  /// Create a perspective distortion
  factory DistortionEffect.perspective(double intensity) {
    return DistortionEffect(
      distortionType: DistortionType.perspective,
      intensity: intensity,
    );
  }

  /// Create a ripple distortion
  factory DistortionEffect.ripple({
    double frequency = 1.0,
    double amplitude = 8.0,
  }) {
    return DistortionEffect(
      distortionType: DistortionType.ripple,
      frequency: frequency,
      amplitude: amplitude,
    );
  }

  /// Create a wave distortion
  factory DistortionEffect.wave({
    double frequency = 2.0,
    double amplitude = 5.0,
  }) {
    return DistortionEffect(
      distortionType: DistortionType.wave,
      frequency: frequency,
      amplitude: amplitude,
    );
  }

  @override
  int get hashCode => Object.hash(
        super.hashCode,
        distortionType,
        intensity,
        frequency,
        amplitude,
      );

  @override
  bool operator ==(Object other) {
    return super == other &&
        other is DistortionEffect &&
        other.distortionType == distortionType &&
        other.intensity == intensity &&
        other.frequency == frequency &&
        other.amplitude == amplitude;
  }
}

/// Distortion types enumeration
enum DistortionType {
  perspective,
  wave,
  ripple,
}

/// Effect preset configurations
class EffectPresets {
  static const List<CanvasEffect> dropShadow = [
    ShadowEffect(
      color: Colors.black,
      offset: Offset(0, 2),
      blurRadius: 4.0,
      opacity: 0.25,
    ),
  ];

  static const List<CanvasEffect> innerShadow = [
    ShadowEffect(
      color: Colors.black,
      offset: Offset(0, 1),
      blurRadius: 2.0,
      innerShadow: true,
      opacity: 0.5,
    ),
  ];

  static const List<CanvasEffect> glassMorphism = [
    BlurEffect(sigmaX: 10.0, sigmaY: 10.0),
    ColorFilterEffect(
      colorFilter: ColorFilter.mode(Colors.white24, BlendMode.overlay),
    ),
  ];

  static const List<CanvasEffect> neonGlow = [
    GlowEffect(
      color: Colors.cyan,
      radius: 12.0,
      layers: 5,
      opacity: 0.9,
    ),
    ShadowEffect(
      color: Colors.cyan,
      offset: Offset.zero,
      blurRadius: 20.0,
      opacity: 0.6,
    ),
  ];

  static const List<CanvasEffect> retro = [
    ColorFilterEffect(
      colorFilter: ColorFilter.mode(Colors.orange, BlendMode.overlay),
    ),
    ShadowEffect(
      color: Colors.deepOrange,
      offset: Offset(2, 2),
      blurRadius: 0,
      opacity: 0.8,
    ),
  ];
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

/// Glow effect configuration
class GlowEffect extends CanvasEffect {
  final Color color;
  final double radius;
  final int layers;

  const GlowEffect({
    this.color = Colors.white,
    this.radius = 8.0,
    this.layers = 3,
    super.opacity = 0.8,
    super.enabled = true,
  }) : super(type: EffectType.glow);

  /// Create a neon glow
  factory GlowEffect.neon({
    Color color = Colors.cyan,
    double radius = 12.0,
    double opacity = 0.9,
  }) {
    return GlowEffect(
      color: color,
      radius: radius,
      layers: 5,
      opacity: opacity,
    );
  }

  /// Create an outer glow
  factory GlowEffect.outer({
    Color color = Colors.white,
    double radius = 8.0,
    double opacity = 0.8,
  }) {
    return GlowEffect(
      color: color,
      radius: radius,
      opacity: opacity,
    );
  }

  @override
  int get hashCode => Object.hash(super.hashCode, color, radius, layers);

  @override
  bool operator ==(Object other) {
    return super == other &&
        other is GlowEffect &&
        other.color == color &&
        other.radius == radius &&
        other.layers == layers;
  }
}

/// Gradient effect configuration
class GradientEffect extends CanvasEffect {
  final Gradient gradient;
  final BlendMode blendMode;

  const GradientEffect({
    required this.gradient,
    this.blendMode = BlendMode.overlay,
    super.opacity = 1.0,
    super.enabled = true,
  }) : super(type: EffectType.gradient);

  /// Create a linear gradient effect
  factory GradientEffect.linear({
    required List<Color> colors,
    Alignment begin = Alignment.topLeft,
    Alignment end = Alignment.bottomRight,
    List<double>? stops,
    BlendMode blendMode = BlendMode.overlay,
  }) {
    return GradientEffect(
      gradient: LinearGradient(
        colors: colors,
        begin: begin,
        end: end,
        stops: stops,
      ),
      blendMode: blendMode,
    );
  }

  /// Create a radial gradient effect
  factory GradientEffect.radial({
    required List<Color> colors,
    Alignment center = Alignment.center,
    double radius = 0.5,
    List<double>? stops,
    BlendMode blendMode = BlendMode.overlay,
  }) {
    return GradientEffect(
      gradient: RadialGradient(
        colors: colors,
        center: center,
        radius: radius,
        stops: stops,
      ),
      blendMode: blendMode,
    );
  }

  @override
  int get hashCode => Object.hash(super.hashCode, gradient, blendMode);

  @override
  bool operator ==(Object other) {
    return super == other &&
        other is GradientEffect &&
        other.gradient == gradient &&
        other.blendMode == blendMode;
  }
}

/// Shadow effect configuration
class ShadowEffect extends CanvasEffect {
  final Color color;
  final Offset offset;
  final double blurRadius;
  final BlurStyle blurStyle;
  final bool innerShadow;

  const ShadowEffect({
    this.color = Colors.black,
    this.offset = const Offset(2, 2),
    this.blurRadius = 4.0,
    this.blurStyle = BlurStyle.normal,
    this.innerShadow = false,
    super.opacity = 0.5,
    super.enabled = true,
  }) : super(type: EffectType.shadow);

  /// Create a drop shadow
  factory ShadowEffect.dropShadow({
    Color color = Colors.black,
    Offset offset = const Offset(0, 2),
    double blurRadius = 4.0,
    double opacity = 0.25,
  }) {
    return ShadowEffect(
      color: color,
      offset: offset,
      blurRadius: blurRadius,
      opacity: opacity,
    );
  }

  /// Create an inner shadow
  factory ShadowEffect.innerShadow({
    Color color = Colors.black,
    Offset offset = const Offset(0, 1),
    double blurRadius = 2.0,
    double opacity = 0.5,
  }) {
    return ShadowEffect(
      color: color,
      offset: offset,
      blurRadius: blurRadius,
      innerShadow: true,
      opacity: opacity,
    );
  }

  @override
  int get hashCode => Object.hash(
        super.hashCode,
        color,
        offset,
        blurRadius,
        blurStyle,
        innerShadow,
      );

  @override
  bool operator ==(Object other) {
    return super == other &&
        other is ShadowEffect &&
        other.color == color &&
        other.offset == offset &&
        other.blurRadius == blurRadius &&
        other.blurStyle == blurStyle &&
        other.innerShadow == innerShadow;
  }
}
