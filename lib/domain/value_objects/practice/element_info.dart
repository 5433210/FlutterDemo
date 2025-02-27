import 'dart:convert';

import 'element_content.dart';

class PracticeElementGeometry {
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;

  PracticeElementGeometry({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.rotation = 0,
  }) {
    if (width <= 0 || height <= 0) {
      throw ArgumentError('Width and height must be positive');
    }
  }

  factory PracticeElementGeometry.fromJson(Map<String, dynamic> json) =>
      PracticeElementGeometry(
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        width: (json['width'] as num).toDouble(),
        height: (json['height'] as num).toDouble(),
        rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
      );

  /// Create an instance from a JSON string
  factory PracticeElementGeometry.fromJsonString(String jsonString) {
    return PracticeElementGeometry.fromJson(
      json.decode(jsonString) as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'rotation': rotation,
      };

  /// Convert to a JSON string
  String toJsonString() => json.encode(toJson());
}

class PracticeElementInfo {
  final String id;
  final String type; // chars/text/image
  final PracticeElementGeometry geometry;
  final PracticeElementStyle style;
  final PracticeElementContent content;

  PracticeElementInfo({
    required this.id,
    required this.type,
    required this.geometry,
    required this.style,
    required this.content,
  }) {
    if (!['chars', 'text', 'image'].contains(type)) {
      throw ArgumentError('Type must be chars, text or image');
    }
  }

  factory PracticeElementInfo.fromJson(Map<String, dynamic> json) =>
      PracticeElementInfo(
        id: json['id'] as String,
        type: json['type'] as String,
        geometry: PracticeElementGeometry.fromJson(
            json['geometry'] as Map<String, dynamic>),
        style: PracticeElementStyle.fromJson(
            json['style'] as Map<String, dynamic>),
        content: PracticeElementContent.fromJson(
          json['content'] as Map<String, dynamic>,
          json['type'] as String,
        ),
      );

  /// Create an instance from a JSON string
  factory PracticeElementInfo.fromJsonString(String jsonString) {
    return PracticeElementInfo.fromJson(
      json.decode(jsonString) as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'geometry': geometry.toJson(),
        'style': style.toJson(),
        'content': content.toJson(),
      };

  /// Convert to a JSON string
  String toJsonString() => json.encode(toJson());
}

class PracticeElementStyle {
  final double opacity;
  final bool visible;

  PracticeElementStyle({
    this.opacity = 1.0,
    this.visible = true,
  }) {
    if (opacity < 0 || opacity > 1) {
      throw ArgumentError('Opacity must be between 0 and 1');
    }
  }

  factory PracticeElementStyle.fromJson(Map<String, dynamic> json) =>
      PracticeElementStyle(
        opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
        visible: json['visible'] as bool? ?? true,
      );

  /// Create an instance from a JSON string
  factory PracticeElementStyle.fromJsonString(String jsonString) {
    return PracticeElementStyle.fromJson(
      json.decode(jsonString) as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() => {
        'opacity': opacity,
        'visible': visible,
      };

  /// Convert to a JSON string
  String toJsonString() => json.encode(toJson());
}
