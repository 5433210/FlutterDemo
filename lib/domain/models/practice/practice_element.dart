import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'practice_element_base.dart';

part 'practice_element.freezed.dart';

// Convert Alignment to string
String _alignmentToString(Alignment alignment) {
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

// Convert BoxFit to string
String _boxFitToString(BoxFit fit) {
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

// Convert EdgeInsets for crop to map
Map<String, dynamic> _cropToMap(EdgeInsets crop) {
  return {
    'left': crop.left,
    'top': crop.top,
    'right': crop.right,
    'bottom': crop.bottom,
  };
}

// Default crop map
Map<String, dynamic> _defaultCropMap() {
  return {
    'left': 0.0,
    'top': 0.0,
    'right': 0.0,
    'bottom': 0.0,
  };
}

// Default padding map
Map<String, dynamic> _defaultPaddingMap() {
  return {
    'left': 8.0,
    'top': 8.0,
    'right': 8.0,
    'bottom': 8.0,
  };
}

// Convert EdgeInsets to map
Map<String, dynamic> _paddingToMap(EdgeInsets padding) {
  return {
    'left': padding.left,
    'top': padding.top,
    'right': padding.right,
    'bottom': padding.bottom,
  };
}

// Parse Alignment from string
Alignment _parseAlignment(String value) {
  switch (value) {
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

// Parse BoxFit from string
BoxFit _parseBoxFit(String value) {
  switch (value) {
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
    case 'scaleDown':
      return BoxFit.scaleDown;
    default:
      return BoxFit.contain;
  }
}

// Parse character images from list
List<Map<String, dynamic>> _parseCharacterImages(List<dynamic> list) {
  return list
      .whereType<Map<String, dynamic>>()
      .map((map) => Map<String, dynamic>.from(map))
      .toList();
}

// Parse EdgeInsets for crop from map
EdgeInsets _parseCrop(Map<String, dynamic> map) {
  return EdgeInsets.only(
    left: (map['left'] as num?)?.toDouble() ?? 0.0,
    top: (map['top'] as num?)?.toDouble() ?? 0.0,
    right: (map['right'] as num?)?.toDouble() ?? 0.0,
    bottom: (map['bottom'] as num?)?.toDouble() ?? 0.0,
  );
}

// Parse EdgeInsets from map
EdgeInsets _parsePadding(Map<String, dynamic> map) {
  return EdgeInsets.only(
    left: (map['left'] as num?)?.toDouble() ?? 0.0,
    top: (map['top'] as num?)?.toDouble() ?? 0.0,
    right: (map['right'] as num?)?.toDouble() ?? 0.0,
    bottom: (map['bottom'] as num?)?.toDouble() ?? 0.0,
  );
}

/// Helper functions for parsing and serializing

// Parse TextAlign from string
TextAlign _parseTextAlign(String value) {
  switch (value) {
    case 'center':
      return TextAlign.center;
    case 'right':
      return TextAlign.right;
    case 'justify':
      return TextAlign.justify;
    case 'start':
      return TextAlign.start;
    case 'end':
      return TextAlign.end;
    default:
      return TextAlign.left;
  }
}

// Convert TextAlign to string
String _textAlignToString(TextAlign align) {
  switch (align) {
    case TextAlign.center:
      return 'center';
    case TextAlign.right:
      return 'right';
    case TextAlign.justify:
      return 'justify';
    case TextAlign.start:
      return 'start';
    case TextAlign.end:
      return 'end';
    default:
      return 'left';
  }
}

/// Collection direction enum
enum CollectionDirection {
  horizontal,
  vertical,
  horizontalReversed,
  verticalReversed
}

/// 字帖编辑内容元素
@Freezed(makeCollectionsUnmodifiable: false)
class PracticeElement with _$PracticeElement {
  /// 集字元素
  const factory PracticeElement.collection({
    // 基础属性
    required String id,
    required double x,
    required double y,
    required double width,
    required double height,
    @Default(0.0) double rotation,
    required String layerId,
    @Default(false) bool isLocked,
    @Default(1.0) double opacity,

    // 集字特有属性
    @Default('') String characters,
    @Default(CollectionDirection.horizontal) CollectionDirection direction,
    @Default(CollectionDirection.horizontal) CollectionDirection flowDirection,
    @Default(10.0) double characterSpacing,
    @Default(10.0) double lineSpacing,
    @Default(EdgeInsets.all(8.0)) EdgeInsets padding,
    @Default('#000000') String fontColor,
    @Default('#FFFFFF') String backgroundColor,
    @Default(50.0) double characterSize,
    @Default('standard') String defaultImageType,
    @Default([]) List<Map<String, dynamic>> characterImages,
    @Default(Alignment.center) Alignment alignment,
  }) = CollectionElement;

  /// 从JSON创建实例
  factory PracticeElement.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? '';

    switch (type) {
      case 'text':
        return PracticeElement.text(
          id: json['id'] as String? ?? '',
          x: (json['x'] as num?)?.toDouble() ?? 0.0,
          y: (json['y'] as num?)?.toDouble() ?? 0.0,
          width: (json['width'] as num?)?.toDouble() ?? 100.0,
          height: (json['height'] as num?)?.toDouble() ?? 100.0,
          rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
          layerId: json['layerId'] as String? ?? '',
          isLocked: json['isLocked'] as bool? ?? false,
          opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
          text: json['text'] as String? ?? '',
          fontSize: (json['fontSize'] as num?)?.toDouble() ?? 14.0,
          fontFamily: json['fontFamily'] as String? ?? 'Arial',
          fontColor: json['fontColor'] as String? ?? '#000000',
          backgroundColor: json['backgroundColor'] as String? ?? '#FFFFFF',
          textAlign: _parseTextAlign(json['textAlign'] as String? ?? 'left'),
          lineSpacing: (json['lineSpacing'] as num?)?.toDouble() ?? 1.0,
          letterSpacing: (json['letterSpacing'] as num?)?.toDouble() ?? 0.0,
          padding: _parsePadding(
              json['padding'] as Map<String, dynamic>? ?? _defaultPaddingMap()),
        );
      case 'image':
        return PracticeElement.image(
          id: json['id'] as String? ?? '',
          x: (json['x'] as num?)?.toDouble() ?? 0.0,
          y: (json['y'] as num?)?.toDouble() ?? 0.0,
          width: (json['width'] as num?)?.toDouble() ?? 100.0,
          height: (json['height'] as num?)?.toDouble() ?? 100.0,
          rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
          layerId: json['layerId'] as String? ?? '',
          isLocked: json['isLocked'] as bool? ?? false,
          opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
          imageUrl: json['imageUrl'] as String? ?? '',
          crop: _parseCrop(
              json['crop'] as Map<String, dynamic>? ?? _defaultCropMap()),
          flipHorizontal: json['flipHorizontal'] as bool? ?? false,
          flipVertical: json['flipVertical'] as bool? ?? false,
          fit: _parseBoxFit(json['fit'] as String? ?? 'contain'),
        );
      case 'collection':
        return PracticeElement.collection(
          id: json['id'] as String? ?? '',
          x: (json['x'] as num?)?.toDouble() ?? 0.0,
          y: (json['y'] as num?)?.toDouble() ?? 0.0,
          width: (json['width'] as num?)?.toDouble() ?? 300.0,
          height: (json['height'] as num?)?.toDouble() ?? 200.0,
          rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
          layerId: json['layerId'] as String? ?? '',
          isLocked: json['isLocked'] as bool? ?? false,
          opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
          characters: json['characters'] as String? ?? '',
          direction: CollectionDirectionExt.fromString(
              json['direction'] as String? ?? 'horizontal'),
          flowDirection: CollectionDirectionExt.fromString(
              json['flowDirection'] as String? ?? 'horizontal'),
          characterSpacing:
              (json['characterSpacing'] as num?)?.toDouble() ?? 10.0,
          lineSpacing: (json['lineSpacing'] as num?)?.toDouble() ?? 10.0,
          padding: _parsePadding(
              json['padding'] as Map<String, dynamic>? ?? _defaultPaddingMap()),
          fontColor: json['fontColor'] as String? ?? '#000000',
          backgroundColor: json['backgroundColor'] as String? ?? '#FFFFFF',
          characterSize: (json['characterSize'] as num?)?.toDouble() ?? 50.0,
          defaultImageType: json['defaultImageType'] as String? ?? 'standard',
          characterImages: _parseCharacterImages(
              json['characterImages'] as List<dynamic>? ?? []),
          alignment: _parseAlignment(json['alignment'] as String? ?? 'center'),
        );
      case 'group':
        final List<dynamic> childrenJson =
            json['children'] as List<dynamic>? ?? [];
        final List<PracticeElement> parsedChildren = [];

        for (final childJson in childrenJson) {
          if (childJson is Map<String, dynamic>) {
            try {
              parsedChildren.add(PracticeElement.fromJson(childJson));
            } catch (e) {
              // Skip invalid children
            }
          }
        }

        return PracticeElement.group(
          id: json['id'] as String? ?? '',
          x: (json['x'] as num?)?.toDouble() ?? 0.0,
          y: (json['y'] as num?)?.toDouble() ?? 0.0,
          width: (json['width'] as num?)?.toDouble() ?? 100.0,
          height: (json['height'] as num?)?.toDouble() ?? 100.0,
          rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
          layerId: json['layerId'] as String? ?? '',
          isLocked: json['isLocked'] as bool? ?? false,
          opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
          children: parsedChildren,
        );
      default:
        throw Exception('Unknown element type: $type');
    }
  }

  /// 组合元素
  const factory PracticeElement.group({
    // 基础属性
    required String id,
    required double x,
    required double y,
    required double width,
    required double height,
    @Default(0.0) double rotation,
    required String layerId,
    @Default(false) bool isLocked,
    @Default(1.0) double opacity,

    // 组合特有属性
    @Default([]) List<PracticeElement> children,
  }) = GroupElement;

  /// 图片元素
  const factory PracticeElement.image({
    // 基础属性
    required String id,
    required double x,
    required double y,
    required double width,
    required double height,
    @Default(0.0) double rotation,
    required String layerId,
    @Default(false) bool isLocked,
    @Default(1.0) double opacity,

    // 图片特有属性
    @Default('') String imageUrl,
    @Default(EdgeInsets.zero) EdgeInsets crop,
    @Default(false) bool flipHorizontal,
    @Default(false) bool flipVertical,
    @Default(BoxFit.contain) BoxFit fit,
  }) = ImageElement;

  /// 文本元素
  const factory PracticeElement.text({
    // 基础属性
    required String id,
    required double x,
    required double y,
    required double width,
    required double height,
    @Default(0.0) double rotation,
    required String layerId,
    @Default(false) bool isLocked,
    @Default(1.0) double opacity,

    // 文本特有属性
    @Default('') String text,
    @Default(14.0) double fontSize,
    @Default('Arial') String fontFamily,
    @Default('#000000') String fontColor,
    @Default('#FFFFFF') String backgroundColor,
    @Default(TextAlign.left) TextAlign textAlign,
    @Default(1.0) double lineSpacing,
    @Default(0.0) double letterSpacing,
    @Default(EdgeInsets.all(8.0)) EdgeInsets padding,
  }) = TextElement;

  /// 私有构造函数，用于添加扩展方法
  const PracticeElement._();

  /// 获取元素基础属性
  PracticeElementBase get base => PracticeElementBase(
        id: id,
        x: x,
        y: y,
        width: width,
        height: height,
        rotation: rotation,
        layerId: layerId,
        isLocked: isLocked,
        opacity: opacity,
      );

  /// 获取元素的中心点
  Offset get center => base.center;

  /// 获取元素的边界矩形
  Rect get rect => base.rect;

  /// 获取元素的变换矩阵
  Matrix4 get transform => base.transform;

  /// 获取元素类型
  String get type => when(
        text: (_,
                __,
                ___,
                ____,
                _____,
                ______,
                _______,
                ________,
                _________,
                __________,
                ___________,
                ____________,
                _____________,
                ______________,
                _______________,
                ________________,
                _________________,
                __________________) =>
            'text',
        image: (_,
                __,
                ___,
                ____,
                _____,
                ______,
                _______,
                ________,
                _________,
                __________,
                ___________,
                ____________,
                _____________,
                ______________) =>
            'image',
        collection: (_,
                __,
                ___,
                ____,
                _____,
                ______,
                _______,
                ________,
                _________,
                __________,
                ___________,
                ____________,
                _____________,
                ______________,
                _______________,
                ________________,
                _________________,
                __________________,
                ___________________,
                ____________________,
                _____________________) =>
            'collection',
        group: (_, __, ___, ____, _____, ______, _______, ________, _________,
                __________) =>
            'group',
      );

  /// 检查点是否在元素内
  bool containsPoint(Offset point) => base.containsPoint(point);

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return when(
      text: (id,
          x,
          y,
          width,
          height,
          rotation,
          layerId,
          isLocked,
          opacity,
          text,
          fontSize,
          fontFamily,
          fontColor,
          backgroundColor,
          textAlign,
          lineSpacing,
          letterSpacing,
          padding) {
        return {
          'id': id,
          'type': 'text',
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
      },
      image: (id, x, y, width, height, rotation, layerId, isLocked, opacity,
          imageUrl, crop, flipHorizontal, flipVertical, fit) {
        return {
          'id': id,
          'type': 'image',
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
      },
      collection: (
        id,
        x,
        y,
        width,
        height,
        rotation,
        layerId,
        isLocked,
        opacity,
        characters,
        direction,
        flowDirection,
        characterSpacing,
        lineSpacing,
        padding,
        fontColor,
        backgroundColor,
        characterSize,
        defaultImageType,
        characterImages,
        alignment,
      ) {
        return {
          'id': id,
          'type': 'collection',
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
      },
      group: (id, x, y, width, height, rotation, layerId, isLocked, opacity,
          children) {
        return {
          'id': id,
          'type': 'group',
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
      },
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return toJson();
  }

  /// 从Map创建实例 (向后兼容)
  static PracticeElement fromMap(Map<String, dynamic> map) {
    return PracticeElement.fromJson(map);
  }
}

/// Extension for CollectionDirection
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

  static CollectionDirection fromString(String value) {
    switch (value) {
      case 'horizontal':
        return CollectionDirection.horizontal;
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
