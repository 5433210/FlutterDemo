import 'package:equatable/equatable.dart';

import 'element_content.dart';
import 'element_geometry.dart';
import 'element_style.dart';

/// 字帖元素
class PracticeElement extends Equatable {
  /// 元素ID
  final String id;

  /// 元素类型: 'chars', 'text', 'image'
  final String type;

  /// 元素几何属性（位置和尺寸）
  final ElementGeometry geometry;

  /// 元素样式属性
  final ElementStyle style;

  /// 元素内容
  final ElementContent content;

  const PracticeElement({
    required this.id,
    required this.type,
    required this.geometry,
    required this.style,
    required this.content,
  });

  /// 创建字符元素
  factory PracticeElement.chars({
    required String id,
    required ElementGeometry geometry,
    required CharsContent content,
    ElementStyle? style,
  }) {
    return PracticeElement(
      id: id,
      type: 'chars',
      geometry: geometry,
      style: style ?? const ElementStyle(),
      content: content,
    );
  }

  /// 从JSON数据创建元素
  factory PracticeElement.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;

    return PracticeElement(
      id: json['id'] as String,
      type: type,
      geometry:
          ElementGeometry.fromJson(json['geometry'] as Map<String, dynamic>),
      style: ElementStyle.fromJson(json['style'] as Map<String, dynamic>),
      content: ElementContent.fromJson(
          type, json['content'] as Map<String, dynamic>),
    );
  }

  /// 创建图像元素
  factory PracticeElement.image({
    required String id,
    required ElementGeometry geometry,
    required ImageContent content,
    ElementStyle? style,
  }) {
    return PracticeElement(
      id: id,
      type: 'image',
      geometry: geometry,
      style: style ?? const ElementStyle(),
      content: content,
    );
  }

  /// 创建文本元素
  factory PracticeElement.text({
    required String id,
    required ElementGeometry geometry,
    required TextContent content,
    ElementStyle? style,
  }) {
    return PracticeElement(
      id: id,
      type: 'text',
      geometry: geometry,
      style: style ?? const ElementStyle(),
      content: content,
    );
  }

  @override
  List<Object?> get props => [id, type, geometry, style, content];

  /// 创建一个带有更新属性的新实例
  PracticeElement copyWith({
    String? id,
    String? type,
    ElementGeometry? geometry,
    ElementStyle? style,
    ElementContent? content,
  }) {
    return PracticeElement(
      id: id ?? this.id,
      type: type ?? this.type,
      geometry: geometry ?? this.geometry,
      style: style ?? this.style,
      content: content ?? this.content,
    );
  }

  /// 移动元素
  PracticeElement move(double dx, double dy) {
    return copyWith(
      geometry: geometry.copyWith(
        x: geometry.x + dx,
        y: geometry.y + dy,
      ),
    );
  }

  /// 调整元素大小
  PracticeElement resize(double width, double height) {
    return copyWith(
      geometry: geometry.copyWith(
        width: width,
        height: height,
      ),
    );
  }

  /// 旋转元素
  PracticeElement rotate(double angle) {
    return copyWith(
      geometry: geometry.copyWith(
        rotation: geometry.rotation + angle,
      ),
    );
  }

  /// 将元素转换为JSON数据
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'geometry': geometry.toJson(),
      'style': style.toJson(),
      'content': content.toJson(),
    };
  }
}
