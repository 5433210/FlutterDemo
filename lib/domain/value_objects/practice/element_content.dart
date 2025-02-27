import 'dart:convert';

class CharacterElementContent extends PracticeElementContent {
  final String char;
  final String? characterId;

  CharacterElementContent({
    required this.char,
    this.characterId,
  }) : super(type: 'chars');

  factory CharacterElementContent.fromJson(Map<String, dynamic> json) {
    return CharacterElementContent(
      char: json['char'] as String,
      characterId: json['characterId'] as String?,
    );
  }

  /// Create an instance from a JSON string
  factory CharacterElementContent.fromJsonString(String jsonString) {
    return CharacterElementContent.fromJson(
      json.decode(jsonString) as Map<String, dynamic>,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'char': char,
        'characterId': characterId,
      };

  /// Convert to a JSON string
  @override
  String toJsonString() => json.encode(toJson());
}

class ImageElementContent extends PracticeElementContent {
  final String path;

  ImageElementContent({
    required this.path,
  }) : super(type: 'image');

  factory ImageElementContent.fromJson(Map<String, dynamic> json) {
    return ImageElementContent(
      path: json['path'] as String,
    );
  }

  /// Create an instance from a JSON string
  factory ImageElementContent.fromJsonString(String jsonString) {
    return ImageElementContent.fromJson(
      json.decode(jsonString) as Map<String, dynamic>,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'path': path,
      };

  /// Convert to a JSON string
  @override
  String toJsonString() => json.encode(toJson());
}

class PracticeCharInfo {
  final String charId;
  final PracticeCharPosition position;
  final PracticeCharTransform transform;
  final PracticeCharStyle style;

  const PracticeCharInfo({
    required this.charId,
    required this.position,
    required this.transform,
    required this.style,
  });

  factory PracticeCharInfo.fromJson(Map<String, dynamic> json) =>
      PracticeCharInfo(
        charId: json['charId'] as String,
        position: PracticeCharPosition.fromJson(
            json['position'] as Map<String, dynamic>),
        transform: PracticeCharTransform.fromJson(
            json['transform'] as Map<String, dynamic>),
        style:
            PracticeCharStyle.fromJson(json['style'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'charId': charId,
        'position': position.toJson(),
        'transform': transform.toJson(),
        'style': style.toJson(),
      };
}

class PracticeCharPosition {
  final double offsetX;
  final double offsetY;

  const PracticeCharPosition({
    required this.offsetX,
    required this.offsetY,
  });

  factory PracticeCharPosition.fromJson(Map<String, dynamic> json) =>
      PracticeCharPosition(
        offsetX: (json['offsetX'] as num).toDouble(),
        offsetY: (json['offsetY'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'offsetX': offsetX,
        'offsetY': offsetY,
      };
}

class PracticeCharsContent implements PracticeElementContent {
  final List<PracticeCharInfo> chars;

  const PracticeCharsContent({required this.chars});

  factory PracticeCharsContent.fromJson(List<dynamic> json) =>
      PracticeCharsContent(
        chars: json
            .map((e) => PracticeCharInfo.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  String get type => 'chars';

  @override
  Map<String, dynamic> toJson() => {
        'chars': chars.map((c) => c.toJson()).toList(),
      };

  @override
  String toJsonString() => json.encode(toJson());
}

class PracticeCharStyle {
  final String color;
  final double opacity;

  PracticeCharStyle({
    this.color = '#000000',
    this.opacity = 1.0,
  }) {
    if (opacity < 0 || opacity > 1) {
      throw ArgumentError('Opacity must be between 0 and 1');
    }
  }

  factory PracticeCharStyle.fromJson(Map<String, dynamic> json) =>
      PracticeCharStyle(
        color: json['color'] as String? ?? '#000000',
        opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      );

  Map<String, dynamic> toJson() => {
        'color': color,
        'opacity': opacity,
      };
}

class PracticeCharTransform {
  final double scaleX;
  final double scaleY;
  final double rotation;

  PracticeCharTransform({
    this.scaleX = 1.0,
    this.scaleY = 1.0,
    this.rotation = 0.0,
  }) {
    if (scaleX <= 0 || scaleY <= 0) {
      throw ArgumentError('Scale values must be positive');
    }
  }

  factory PracticeCharTransform.fromJson(Map<String, dynamic> json) =>
      PracticeCharTransform(
        scaleX: (json['scaleX'] as num?)?.toDouble() ?? 1.0,
        scaleY: (json['scaleY'] as num?)?.toDouble() ?? 1.0,
        rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
        'scaleX': scaleX,
        'scaleY': scaleY,
        'rotation': rotation,
      };
}

/// Base class for practice element content
abstract class PracticeElementContent {
  /// Type of content (e.g., 'chars', 'text', 'image')
  final String type;

  PracticeElementContent({required this.type});

  /// Create the appropriate content type based on the type string
  factory PracticeElementContent.fromJson(
      Map<String, dynamic> json, String type) {
    switch (type) {
      case 'chars':
        return CharacterElementContent.fromJson(json);
      case 'text':
        return TextElementContent.fromJson(json);
      case 'image':
        return ImageElementContent.fromJson(json);
      default:
        throw ArgumentError('Unknown content type: $type');
    }
  }

  /// Create an instance from a JSON string
  factory PracticeElementContent.fromJsonString(String jsonString) {
    final map = json.decode(jsonString) as Map<String, dynamic>;
    return PracticeElementContent.fromJson(map, map['type'] as String);
  }

  /// Convert to a JSON map
  Map<String, dynamic> toJson();

  /// Convert to a JSON string
  String toJsonString() => json.encode(toJson());
}

class PracticeElementContentFactory {
  static PracticeElementContent fromJson(
      Map<String, dynamic> json, String type) {
    switch (type) {
      case 'chars':
        return PracticeCharsContent.fromJson(json['chars'] as List);
      case 'text':
        return PracticeTextContent.fromJson(
            json['text'] as Map<String, dynamic>);
      case 'image':
        return PracticeImageContent.fromJson(
            json['image'] as Map<String, dynamic>);
      default:
        throw ArgumentError('Unknown element type: $type');
    }
  }
}

class PracticeImageContent implements PracticeElementContent {
  final String path;

  const PracticeImageContent({required this.path});

  factory PracticeImageContent.fromJson(Map<String, dynamic> json) =>
      PracticeImageContent(
        path: json['path'] as String,
      );

  @override
  String get type => 'image';

  @override
  Map<String, dynamic> toJson() => {
        'image': {'path': path},
      };

  @override
  String toJsonString() => json.encode(toJson());
}

class PracticeTextContent implements PracticeElementContent {
  final String content;
  final String fontFamily;
  final double fontSize;
  final String color;
  final String alignment;

  const PracticeTextContent({
    required this.content,
    required this.fontFamily,
    required this.fontSize,
    this.color = '#000000',
    this.alignment = 'left',
  });

  factory PracticeTextContent.fromJson(Map<String, dynamic> json) =>
      PracticeTextContent(
        content: json['content'] as String,
        fontFamily: json['fontFamily'] as String,
        fontSize: (json['fontSize'] as num).toDouble(),
        color: json['color'] as String? ?? '#000000',
        alignment: json['alignment'] as String? ?? 'left',
      );

  @override
  String get type => 'text';

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

  @override
  String toJsonString() => json.encode(toJson());
}

class TextElementContent extends PracticeElementContent {
  final String text;

  TextElementContent({
    required this.text,
  }) : super(type: 'text');

  factory TextElementContent.fromJson(Map<String, dynamic> json) {
    return TextElementContent(
      text: json['text'] as String,
    );
  }

  /// Create an instance from a JSON string
  factory TextElementContent.fromJsonString(String jsonString) {
    return TextElementContent.fromJson(
      json.decode(jsonString) as Map<String, dynamic>,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'text': text,
      };

  /// Convert to a JSON string
  @override
  String toJsonString() => json.encode(toJson());
}
