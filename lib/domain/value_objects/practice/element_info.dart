import 'element_content.dart';

class ElementInfo {
  final String id;
  final String type;  // chars/text/image
  final ElementGeometry geometry;
  final ElementStyle style;
  final ElementContent content;

   ElementInfo({
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'geometry': geometry.toJson(),
    'style': style.toJson(),
    'content': content.toJson(),
  };

  factory ElementInfo.fromJson(Map<String, dynamic> json) => ElementInfo(
    id: json['id'] as String,
    type: json['type'] as String,
    geometry: ElementGeometry.fromJson(json['geometry'] as Map<String, dynamic>),
    style: ElementStyle.fromJson(json['style'] as Map<String, dynamic>),
    content: ElementContent.fromJson(
      json['content'] as Map<String, dynamic>,
      json['type'] as String,
    ),
  );
}

class ElementGeometry {
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;

   ElementGeometry({
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

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'rotation': rotation,
  };

  factory ElementGeometry.fromJson(Map<String, dynamic> json) => ElementGeometry(
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    width: (json['width'] as num).toDouble(),
    height: (json['height'] as num).toDouble(),
    rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
  );
}

class ElementStyle {
  final double opacity;
  final bool visible;

   ElementStyle({
    this.opacity = 1.0,
    this.visible = true,
  }) {
    if (opacity < 0 || opacity > 1) {
      throw ArgumentError('Opacity must be between 0 and 1');
    }
  }

  Map<String, dynamic> toJson() => {
    'opacity': opacity,
    'visible': visible,
  };

  factory ElementStyle.fromJson(Map<String, dynamic> json) => ElementStyle(
    opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
    visible: json['visible'] as bool? ?? true,
  );
}