import 'package:freezed_annotation/freezed_annotation.dart';

import 'element_content.dart';
import 'element_geometry.dart';
import 'element_style.dart';

part 'practice_element.freezed.dart';
part 'practice_element.g.dart';

/// 练习元素
@freezed
class PracticeElement with _$PracticeElement {
  const factory PracticeElement({
    /// 元素ID
    required String id,

    /// 元素类型
    @JsonKey(name: 'type') required String elementType,

    /// 元素几何属性
    required ElementGeometry geometry,

    /// 元素样式
    required ElementStyle style,

    /// 元素内容
    required ElementContent content,

    /// 创建时间
    @Default(0) int createTime,

    /// 更新时间
    @Default(0) int updateTime,
  }) = _PracticeElement;

  /// 创建字符元素
  factory PracticeElement.chars({
    required String id,
    required ElementContent content,
    ElementGeometry? geometry,
    ElementStyle? style,
  }) {
    return PracticeElement(
      id: id,
      elementType: 'chars',
      geometry: geometry ?? const ElementGeometry(),
      style: style ?? const ElementStyle(),
      content: content,
      createTime: DateTime.now().millisecondsSinceEpoch,
      updateTime: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// 从JSON创建实例
  factory PracticeElement.fromJson(Map<String, dynamic> json) =>
      _$PracticeElementFromJson(json);

  /// 创建图片元素
  factory PracticeElement.image({
    required String id,
    required ElementContent content,
    ElementGeometry? geometry,
    ElementStyle? style,
  }) {
    return PracticeElement(
      id: id,
      elementType: 'image',
      geometry: geometry ?? const ElementGeometry(),
      style: style ?? const ElementStyle(),
      content: content,
      createTime: DateTime.now().millisecondsSinceEpoch,
      updateTime: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// 创建文本元素
  factory PracticeElement.text({
    required String id,
    required ElementContent content,
    ElementGeometry? geometry,
    ElementStyle? style,
  }) {
    return PracticeElement(
      id: id,
      elementType: 'text',
      geometry: geometry ?? const ElementGeometry(),
      style: style ?? const ElementStyle(),
      content: content,
      createTime: DateTime.now().millisecondsSinceEpoch,
      updateTime: DateTime.now().millisecondsSinceEpoch,
    );
  }

  const PracticeElement._();

  /// 移动元素
  PracticeElement move(double dx, double dy) {
    return copyWith(
      geometry: geometry.move(dx, dy),
      updateTime: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// 调整大小
  PracticeElement resize(double width, double height) {
    return copyWith(
      geometry: geometry.resize(width, height),
      updateTime: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// 旋转
  PracticeElement rotate(double angle) {
    return copyWith(
      geometry: geometry.rotate(angle),
      updateTime: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// 更新时间戳
  PracticeElement touch() {
    return copyWith(
      updateTime: DateTime.now().millisecondsSinceEpoch,
    );
  }
}
