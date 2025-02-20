abstract class ElementContent {
  Map<String, dynamic> toJson();

  static fromJson(Map<String, dynamic> json, String json2) {}
}

class ElementContentFactory {
  static ElementContent fromJson(Map<String, dynamic> json, String type) {
    switch (type) {
      case 'chars':
        return CharsContent.fromJson(json['chars'] as List);
      case 'text':
        return TextContent.fromJson(json['text'] as Map<String, dynamic>);
      case 'image':
        return ImageContent.fromJson(json['image'] as Map<String, dynamic>);
      default:
        throw ArgumentError('Unknown element type: $type');
    }
  }
}

class CharsContent implements ElementContent {
  final List<CharInfo> chars;

  const CharsContent({required this.chars});

  @override
  Map<String, dynamic> toJson() => {
    'chars': chars.map((c) => c.toJson()).toList(),
  };

  factory CharsContent.fromJson(List<dynamic> json) => CharsContent(
    chars: json.map((e) => CharInfo.fromJson(e as Map<String, dynamic>)).toList(),
  );
}

class CharInfo {
  final String charId;
  final CharPosition position;
  final CharTransform transform;
  final CharStyle style;

  const CharInfo({
    required this.charId,
    required this.position,
    required this.transform,
    required this.style,
  });

  Map<String, dynamic> toJson() => {
    'charId': charId,
    'position': position.toJson(),
    'transform': transform.toJson(),
    'style': style.toJson(),
  };

  factory CharInfo.fromJson(Map<String, dynamic> json) => CharInfo(
    charId: json['charId'] as String,
    position: CharPosition.fromJson(json['position'] as Map<String, dynamic>),
    transform: CharTransform.fromJson(json['transform'] as Map<String, dynamic>),
    style: CharStyle.fromJson(json['style'] as Map<String, dynamic>),
  );
}

class CharPosition {
  final double offsetX;
  final double offsetY;

  const CharPosition({
    required this.offsetX,
    required this.offsetY,
  });

  Map<String, dynamic> toJson() => {
    'offsetX': offsetX,
    'offsetY': offsetY,
  };

  factory CharPosition.fromJson(Map<String, dynamic> json) => CharPosition(
    offsetX: (json['offsetX'] as num).toDouble(),
    offsetY: (json['offsetY'] as num).toDouble(),
  );
}

class CharTransform {
  final double scaleX;
  final double scaleY;
  final double rotation;

  CharTransform({
    this.scaleX = 1.0,
    this.scaleY = 1.0,
    this.rotation = 0.0,
  }) {
    if (scaleX <= 0 || scaleY <= 0) {
      throw ArgumentError('Scale values must be positive');
    }
  }

  Map<String, dynamic> toJson() => {
    'scaleX': scaleX,
    'scaleY': scaleY,
    'rotation': rotation,
  };

  factory CharTransform.fromJson(Map<String, dynamic> json) => CharTransform(
    scaleX: (json['scaleX'] as num?)?.toDouble() ?? 1.0,
    scaleY: (json['scaleY'] as num?)?.toDouble() ?? 1.0,
    rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
  );
}

class CharStyle {
  final String color;
  final double opacity;

  CharStyle({
    this.color = '#000000',
    this.opacity = 1.0,
  }) {
    if (opacity < 0 || opacity > 1) {
      throw ArgumentError('Opacity must be between 0 and 1');
    }
  }

  Map<String, dynamic> toJson() => {
    'color': color,
    'opacity': opacity,
  };

  factory CharStyle.fromJson(Map<String, dynamic> json) => CharStyle(
    color: json['color'] as String? ?? '#000000',
    opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
  );
}

class TextContent implements ElementContent {
  final String content;
  final String fontFamily;
  final double fontSize;
  final String color;
  final String alignment;

  const TextContent({
    required this.content,
    required this.fontFamily,
    required this.fontSize,
    this.color = '#000000',
    this.alignment = 'left',
  });

  @override
  Map<String, dynamic> toJson() => {
    'text': {
      'content': content,
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'color': color,
      'alignment': alignment,
    },
  };

  factory TextContent.fromJson(Map<String, dynamic> json) => TextContent(
    content: json['content'] as String,
    fontFamily: json['fontFamily'] as String,
    fontSize: (json['fontSize'] as num).toDouble(),
    color: json['color'] as String? ?? '#000000',
    alignment: json['alignment'] as String? ?? 'left',
  );
}

class ImageContent implements ElementContent {
  final String path;

  const ImageContent({required this.path});

  @override
  Map<String, dynamic> toJson() => {
    'image': {'path': path},
  };

  factory ImageContent.fromJson(Map<String, dynamic> json) => ImageContent(
    path: json['path'] as String,
  );
}