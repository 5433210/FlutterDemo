import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

/// Collection direction enum
enum CollectionDirection {
  horizontal,
  vertical,
  horizontalReversed,
  verticalReversed
}

/// 集字内容元素
class CollectionElement extends PracticeElement {
  String characters;
  CollectionDirection direction;
  CollectionDirection flowDirection;
  double characterSpacing;
  double lineSpacing;
  EdgeInsets padding;
  String fontColor;
  String backgroundColor;
  double characterSize;
  String defaultImageType;
  List<Map<String, dynamic>> characterImages;
  Alignment alignment;

  CollectionElement({
    required super.id,
    required super.x,
    required super.y,
    required super.width,
    required super.height,
    super.rotation,
    required super.layerId,
    super.isLocked,
    super.opacity,
    this.characters = '',
    this.direction = CollectionDirection.horizontal,
    this.flowDirection = CollectionDirection.horizontal,
    this.characterSpacing = 10.0,
    this.lineSpacing = 10.0,
    this.padding = const EdgeInsets.all(8.0),
    this.fontColor = '#000000',
    this.backgroundColor = '#FFFFFF',
    this.characterSize = 50.0,
    this.defaultImageType = 'standard',
    this.characterImages = const [],
    this.alignment = Alignment.center,
  }) : super(type: 'collection');

  factory CollectionElement.fromMap(Map<String, dynamic> map) {
    return CollectionElement(
      id: map['id'] as String? ?? '',
      x: (map['x'] as num?)?.toDouble() ?? 0.0,
      y: (map['y'] as num?)?.toDouble() ?? 0.0,
      width: (map['width'] as num?)?.toDouble() ?? 300.0,
      height: (map['height'] as num?)?.toDouble() ?? 200.0,
      rotation: (map['rotation'] as num?)?.toDouble() ?? 0.0,
      layerId: map['layerId'] as String? ?? '',
      isLocked: map['isLocked'] as bool? ?? false,
      opacity: (map['opacity'] as num?)?.toDouble() ?? 1.0,
      characters: map['characters'] as String? ?? '',
      direction: CollectionDirectionExt.fromString(
          map['direction'] as String? ?? 'horizontal'),
      flowDirection: CollectionDirectionExt.fromString(
          map['flowDirection'] as String? ?? 'horizontal'),
      characterSpacing: (map['characterSpacing'] as num?)?.toDouble() ?? 10.0,
      lineSpacing: (map['lineSpacing'] as num?)?.toDouble() ?? 10.0,
      padding: _parsePadding(
          map['padding'] as Map<String, dynamic>? ?? _defaultPaddingMap()),
      fontColor: map['fontColor'] as String? ?? '#000000',
      backgroundColor: map['backgroundColor'] as String? ?? '#FFFFFF',
      characterSize: (map['characterSize'] as num?)?.toDouble() ?? 50.0,
      defaultImageType: map['defaultImageType'] as String? ?? 'standard',
      characterImages:
          _parseCharacterImages(map['characterImages'] as List<dynamic>? ?? []),
      alignment: _parseAlignment(map['alignment'] as String? ?? 'center'),
    );
  }

  @override
  CollectionElement copyWith({
    String? id,
    String? type,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    String? layerId,
    bool? isLocked,
    double? opacity,
    String? characters,
    CollectionDirection? direction,
    CollectionDirection? flowDirection,
    double? characterSpacing,
    double? lineSpacing,
    EdgeInsets? padding,
    String? fontColor,
    String? backgroundColor,
    double? characterSize,
    String? defaultImageType,
    List<Map<String, dynamic>>? characterImages,
    Alignment? alignment,
  }) {
    return CollectionElement(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      layerId: layerId ?? this.layerId,
      isLocked: isLocked ?? this.isLocked,
      opacity: opacity ?? this.opacity,
      characters: characters ?? this.characters,
      direction: direction ?? this.direction,
      flowDirection: flowDirection ?? this.flowDirection,
      characterSpacing: characterSpacing ?? this.characterSpacing,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      padding: padding ?? this.padding,
      fontColor: fontColor ?? this.fontColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      characterSize: characterSize ?? this.characterSize,
      defaultImageType: defaultImageType ?? this.defaultImageType,
      characterImages: characterImages ?? this.characterImages,
      alignment: alignment ?? this.alignment,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'rotation': rotation,
      'layerId': layerId,
      'isLocked': isLocked,
      'opacity': opacity,
      'characters': characters,
      'direction': direction.toShortString(),
      'flowDirection': flowDirection.toShortString(),
      'characterSpacing': characterSpacing,
      'lineSpacing': lineSpacing,
      'padding': _paddingToMap(padding),
      'fontColor': fontColor,
      'backgroundColor': backgroundColor,
      'characterSize': characterSize,
      'defaultImageType': defaultImageType,
      'characterImages': characterImages,
      'alignment': _alignmentToString(alignment),
    };
  }

  static String _alignmentToString(Alignment alignment) {
    if (alignment == Alignment.topLeft) return 'topLeft';
    if (alignment == Alignment.topCenter) return 'topCenter';
    if (alignment == Alignment.topRight) return 'topRight';
    if (alignment == Alignment.centerLeft) return 'centerLeft';
    if (alignment == Alignment.centerRight) return 'centerRight';
    if (alignment == Alignment.bottomLeft) return 'bottomLeft';
    if (alignment == Alignment.bottomCenter) return 'bottomCenter';
    if (alignment == Alignment.bottomRight) return 'bottomRight';
    return 'center';
  }

  static Map<String, dynamic> _defaultPaddingMap() {
    return {
      'left': 8.0,
      'top': 8.0,
      'right': 8.0,
      'bottom': 8.0,
    };
  }

  static Map<String, dynamic> _paddingToMap(EdgeInsets padding) {
    return {
      'left': padding.left,
      'top': padding.top,
      'right': padding.right,
      'bottom': padding.bottom,
    };
  }

  static Alignment _parseAlignment(String align) {
    switch (align) {
      case 'topLeft':
        return Alignment.topLeft;
      case 'topCenter':
        return Alignment.topCenter;
      case 'topRight':
        return Alignment.topRight;
      case 'centerLeft':
        return Alignment.centerLeft;
      case 'centerRight':
        return Alignment.centerRight;
      case 'bottomLeft':
        return Alignment.bottomLeft;
      case 'bottomCenter':
        return Alignment.bottomCenter;
      case 'bottomRight':
        return Alignment.bottomRight;
      default:
        return Alignment.center;
    }
  }

  static List<Map<String, dynamic>> _parseCharacterImages(List<dynamic> list) {
    return list.map((item) => item as Map<String, dynamic>).toList();
  }

  static EdgeInsets _parsePadding(Map<String, dynamic> map) {
    return EdgeInsets.only(
      left: (map['left'] as num?)?.toDouble() ?? 8.0,
      top: (map['top'] as num?)?.toDouble() ?? 8.0,
      right: (map['right'] as num?)?.toDouble() ?? 8.0,
      bottom: (map['bottom'] as num?)?.toDouble() ?? 8.0,
    );
  }
}

/// JSON converter for EdgeInsets
class EdgeInsetsConverter
    implements JsonConverter<EdgeInsets, Map<String, dynamic>> {
  const EdgeInsetsConverter();

  @override
  EdgeInsets fromJson(Map<String, dynamic> json) {
    return EdgeInsets.only(
      left: (json['left'] as num?)?.toDouble() ?? 0.0,
      top: (json['top'] as num?)?.toDouble() ?? 0.0,
      right: (json['right'] as num?)?.toDouble() ?? 0.0,
      bottom: (json['bottom'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  Map<String, dynamic> toJson(EdgeInsets insets) {
    return {
      'left': insets.left,
      'top': insets.top,
      'right': insets.right,
      'bottom': insets.bottom,
    };
  }
}

/// 组合内容元素
class GroupElement extends PracticeElement {
  List<PracticeElement> children;

  GroupElement({
    required super.id,
    required super.x,
    required super.y,
    required super.width,
    required super.height,
    super.rotation,
    required super.layerId,
    super.isLocked,
    super.opacity,
    this.children = const [],
  }) : super(type: 'group');

  factory GroupElement.fromMap(Map<String, dynamic> map) {
    final List<dynamic> childrenMaps = map['children'] as List<dynamic>? ?? [];
    final List<PracticeElement> parsedChildren = childrenMaps.map((childMap) {
      final childMapTyped = childMap as Map<String, dynamic>;
      // 更新相对坐标
      final relativeX = (childMapTyped['relativeX'] as num?)?.toDouble() ?? 0.0;
      final relativeY = (childMapTyped['relativeY'] as num?)?.toDouble() ?? 0.0;
      childMapTyped['x'] = relativeX;
      childMapTyped['y'] = relativeY;
      return PracticeElement.fromMap(childMapTyped);
    }).toList();

    return GroupElement(
      id: map['id'] as String? ?? '',
      x: (map['x'] as num?)?.toDouble() ?? 0.0,
      y: (map['y'] as num?)?.toDouble() ?? 0.0,
      width: (map['width'] as num?)?.toDouble() ?? 100.0,
      height: (map['height'] as num?)?.toDouble() ?? 100.0,
      rotation: (map['rotation'] as num?)?.toDouble() ?? 0.0,
      layerId: map['layerId'] as String? ?? '',
      isLocked: map['isLocked'] as bool? ?? false,
      opacity: (map['opacity'] as num?)?.toDouble() ?? 1.0,
      children: parsedChildren,
    );
  }

  @override
  GroupElement copyWith({
    String? id,
    String? type,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    String? layerId,
    bool? isLocked,
    double? opacity,
    List<PracticeElement>? children,
  }) {
    return GroupElement(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      layerId: layerId ?? this.layerId,
      isLocked: isLocked ?? this.isLocked,
      opacity: opacity ?? this.opacity,
      children: children ?? this.children,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'rotation': rotation,
      'layerId': layerId,
      'isLocked': isLocked,
      'opacity': opacity,
      'children': children.map((child) {
        // 转换为相对坐标
        final childMap = child.toMap();
        childMap['relativeX'] = child.x;
        childMap['relativeY'] = child.y;
        return childMap;
      }).toList(),
    };
  }
}

/// 图片内容元素
class ImageElement extends PracticeElement {
  String imageUrl;
  EdgeInsets crop;
  bool flipHorizontal;
  bool flipVertical;
  BoxFit fit;

  ImageElement({
    required super.id,
    required super.x,
    required super.y,
    required super.width,
    required super.height,
    super.rotation,
    required super.layerId,
    super.isLocked,
    super.opacity,
    this.imageUrl = '',
    this.crop = EdgeInsets.zero,
    this.flipHorizontal = false,
    this.flipVertical = false,
    this.fit = BoxFit.contain,
  }) : super(type: 'image');

  factory ImageElement.fromMap(Map<String, dynamic> map) {
    return ImageElement(
      id: map['id'] as String? ?? '',
      x: (map['x'] as num?)?.toDouble() ?? 0.0,
      y: (map['y'] as num?)?.toDouble() ?? 0.0,
      width: (map['width'] as num?)?.toDouble() ?? 100.0,
      height: (map['height'] as num?)?.toDouble() ?? 100.0,
      rotation: (map['rotation'] as num?)?.toDouble() ?? 0.0,
      layerId: map['layerId'] as String? ?? '',
      isLocked: map['isLocked'] as bool? ?? false,
      opacity: (map['opacity'] as num?)?.toDouble() ?? 1.0,
      imageUrl: map['imageUrl'] as String? ?? '',
      crop:
          _parseCrop(map['crop'] as Map<String, dynamic>? ?? _defaultCropMap()),
      flipHorizontal: map['flipHorizontal'] as bool? ?? false,
      flipVertical: map['flipVertical'] as bool? ?? false,
      fit: _parseBoxFit(map['fit'] as String? ?? 'contain'),
    );
  }

  @override
  ImageElement copyWith({
    String? id,
    String? type,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    String? layerId,
    bool? isLocked,
    double? opacity,
    String? imageUrl,
    EdgeInsets? crop,
    bool? flipHorizontal,
    bool? flipVertical,
    BoxFit? fit,
  }) {
    return ImageElement(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      layerId: layerId ?? this.layerId,
      isLocked: isLocked ?? this.isLocked,
      opacity: opacity ?? this.opacity,
      imageUrl: imageUrl ?? this.imageUrl,
      crop: crop ?? this.crop,
      flipHorizontal: flipHorizontal ?? this.flipHorizontal,
      flipVertical: flipVertical ?? this.flipVertical,
      fit: fit ?? this.fit,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'rotation': rotation,
      'layerId': layerId,
      'isLocked': isLocked,
      'opacity': opacity,
      'imageUrl': imageUrl,
      'crop': _cropToMap(crop),
      'flipHorizontal': flipHorizontal,
      'flipVertical': flipVertical,
      'fit': _boxFitToString(fit),
    };
  }

  static String _boxFitToString(BoxFit fit) {
    switch (fit) {
      case BoxFit.fill:
        return 'fill';
      case BoxFit.cover:
        return 'cover';
      case BoxFit.fitWidth:
        return 'fitWidth';
      case BoxFit.fitHeight:
        return 'fitHeight';
      case BoxFit.none:
        return 'none';
      case BoxFit.scaleDown:
        return 'scaleDown';
      default:
        return 'contain';
    }
  }

  static Map<String, dynamic> _cropToMap(EdgeInsets crop) {
    return {
      'left': crop.left,
      'top': crop.top,
      'right': crop.right,
      'bottom': crop.bottom,
    };
  }

  static Map<String, dynamic> _defaultCropMap() {
    return {
      'left': 0.0,
      'top': 0.0,
      'right': 0.0,
      'bottom': 0.0,
    };
  }

  static BoxFit _parseBoxFit(String fit) {
    switch (fit) {
      case 'fill':
        return BoxFit.fill;
      case 'cover':
        return BoxFit.cover;
      case 'fitWidth':
        return BoxFit.fitWidth;
      case 'fitHeight':
        return BoxFit.fitHeight;
      case 'none':
        return BoxFit.none;
      case BoxFit.scaleDown:
        return BoxFit.scaleDown;
      default:
        return BoxFit.contain;
    }
  }

  static EdgeInsets _parseCrop(Map<String, dynamic> map) {
    return EdgeInsets.only(
      left: (map['left'] as num?)?.toDouble() ?? 0.0,
      top: (map['top'] as num?)?.toDouble() ?? 0.0,
      right: (map['right'] as num?)?.toDouble() ?? 0.0,
      bottom: (map['bottom'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// 字帖编辑内容元素基类
abstract class PracticeElement {
  String id;
  String type;
  double x;
  double y;
  double width;
  double height;
  double rotation;
  String layerId;
  bool isLocked;
  double opacity;

  PracticeElement({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.rotation = 0.0,
    required this.layerId,
    this.isLocked = false,
    this.opacity = 1.0,
  });

  // 复制并更新属性
  PracticeElement copyWith({
    String? id,
    String? type,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    String? layerId,
    bool? isLocked,
    double? opacity,
  });

  // 转换为Map，用于序列化
  Map<String, dynamic> toMap();

  // 从Map创建实例
  static PracticeElement fromMap(Map<String, dynamic> map) {
    final type = map['type'] as String? ?? '';

    switch (type) {
      case 'text':
        return TextElement.fromMap(map);
      case 'image':
        return ImageElement.fromMap(map);
      case 'collection':
        return CollectionElement.fromMap(map);
      case 'group':
        return GroupElement.fromMap(map);
      default:
        throw Exception('Unknown element type: $type');
    }
  }
}

/// JSON converter for PracticeElement
class PracticeElementConverter
    implements JsonConverter<PracticeElement, Map<String, dynamic>> {
  const PracticeElementConverter();

  @override
  PracticeElement fromJson(Map<String, dynamic> json) {
    return PracticeElement.fromMap(json);
  }

  @override
  Map<String, dynamic> toJson(PracticeElement element) {
    return element.toMap();
  }
}

/// 文本内容元素
class TextElement extends PracticeElement {
  String text;
  double fontSize;
  String fontFamily;
  String fontColor;
  String backgroundColor;
  TextAlign textAlign;
  double lineSpacing;
  double letterSpacing;
  EdgeInsets padding;

  TextElement({
    required super.id,
    required super.x,
    required super.y,
    required super.width,
    required super.height,
    super.rotation,
    required super.layerId,
    super.isLocked,
    super.opacity,
    this.text = '',
    this.fontSize = 14.0,
    this.fontFamily = 'Arial',
    this.fontColor = '#000000',
    this.backgroundColor = '#FFFFFF',
    this.textAlign = TextAlign.left,
    this.lineSpacing = 1.0,
    this.letterSpacing = 0.0,
    this.padding = const EdgeInsets.all(8.0),
  }) : super(type: 'text');

  factory TextElement.fromMap(Map<String, dynamic> map) {
    return TextElement(
      id: map['id'] as String? ?? '',
      x: (map['x'] as num?)?.toDouble() ?? 0.0,
      y: (map['y'] as num?)?.toDouble() ?? 0.0,
      width: (map['width'] as num?)?.toDouble() ?? 100.0,
      height: (map['height'] as num?)?.toDouble() ?? 50.0,
      rotation: (map['rotation'] as num?)?.toDouble() ?? 0.0,
      layerId: map['layerId'] as String? ?? '',
      isLocked: map['isLocked'] as bool? ?? false,
      opacity: (map['opacity'] as num?)?.toDouble() ?? 1.0,
      text: map['text'] as String? ?? '',
      fontSize: (map['fontSize'] as num?)?.toDouble() ?? 14.0,
      fontFamily: map['fontFamily'] as String? ?? 'Arial',
      fontColor: map['fontColor'] as String? ?? '#000000',
      backgroundColor: map['backgroundColor'] as String? ?? '#FFFFFF',
      textAlign: _parseTextAlign(map['textAlign'] as String? ?? 'left'),
      lineSpacing: (map['lineSpacing'] as num?)?.toDouble() ?? 1.0,
      letterSpacing: (map['letterSpacing'] as num?)?.toDouble() ?? 0.0,
      padding: _parsePadding(
          map['padding'] as Map<String, dynamic>? ?? _defaultPaddingMap()),
    );
  }

  @override
  TextElement copyWith({
    String? id,
    String? type,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    String? layerId,
    bool? isLocked,
    double? opacity,
    String? text,
    double? fontSize,
    String? fontFamily,
    String? fontColor,
    String? backgroundColor,
    TextAlign? textAlign,
    double? lineSpacing,
    double? letterSpacing,
    EdgeInsets? padding,
  }) {
    return TextElement(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      layerId: layerId ?? this.layerId,
      isLocked: isLocked ?? this.isLocked,
      opacity: opacity ?? this.opacity,
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      fontColor: fontColor ?? this.fontColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textAlign: textAlign ?? this.textAlign,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      padding: padding ?? this.padding,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'rotation': rotation,
      'layerId': layerId,
      'isLocked': isLocked,
      'opacity': opacity,
      'text': text,
      'fontSize': fontSize,
      'fontFamily': fontFamily,
      'fontColor': fontColor,
      'backgroundColor': backgroundColor,
      'textAlign': _textAlignToString(textAlign),
      'lineSpacing': lineSpacing,
      'letterSpacing': letterSpacing,
      'padding': _paddingToMap(padding),
    };
  }

  static Map<String, dynamic> _defaultPaddingMap() {
    return {
      'left': 8.0,
      'top': 8.0,
      'right': 8.0,
      'bottom': 8.0,
    };
  }

  static Map<String, dynamic> _paddingToMap(EdgeInsets padding) {
    return {
      'left': padding.left,
      'top': padding.top,
      'right': padding.right,
      'bottom': padding.bottom,
    };
  }

  static EdgeInsets _parsePadding(Map<String, dynamic> map) {
    return EdgeInsets.only(
      left: (map['left'] as num?)?.toDouble() ?? 8.0,
      top: (map['top'] as num?)?.toDouble() ?? 8.0,
      right: (map['right'] as num?)?.toDouble() ?? 8.0,
      bottom: (map['bottom'] as num?)?.toDouble() ?? 8.0,
    );
  }

  static TextAlign _parseTextAlign(String align) {
    switch (align) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      case 'justify':
        return TextAlign.justify;
      default:
        return TextAlign.left;
    }
  }

  static String _textAlignToString(TextAlign align) {
    switch (align) {
      case TextAlign.center:
        return 'center';
      case TextAlign.right:
        return 'right';
      case TextAlign.justify:
        return 'justify';
      default:
        return 'left';
    }
  }
}

extension CollectionDirectionExt on CollectionDirection {
  String toShortString() {
    switch (this) {
      case CollectionDirection.horizontal:
        return 'horizontal';
      case CollectionDirection.vertical:
        return 'vertical';
      case CollectionDirection.horizontalReversed:
        return 'horizontalReversed';
      case CollectionDirection.verticalReversed:
        return 'verticalReversed';
    }
  }

  static CollectionDirection fromString(String dir) {
    switch (dir) {
      case 'vertical':
        return CollectionDirection.vertical;
      case 'horizontalReversed':
        return CollectionDirection.horizontalReversed;
      case 'verticalReversed':
        return CollectionDirection.verticalReversed;
      default:
        return CollectionDirection.horizontal;
    }
  }
}
