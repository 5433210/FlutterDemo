import 'package:freezed_annotation/freezed_annotation.dart';

import 'char_position.dart';
import 'char_style.dart';
import 'char_transform.dart';

part 'char_element.freezed.dart';
part 'char_element.g.dart';

/// 字符元素
@freezed
class CharElement with _$CharElement {
  const factory CharElement({
    /// 字符ID
    required String charId,

    /// 相对位置
    required CharPosition position,

    /// 变换信息
    @Default(CharTransform()) CharTransform transform,

    /// 样式信息
    @Default(CharStyle()) CharStyle style,
  }) = _CharElement;

  /// 从JSON创建实例
  factory CharElement.fromJson(Map<String, dynamic> json) =>
      _$CharElementFromJson(json);

  /// 创建标准字符元素
  factory CharElement.standard({
    required String charId,
    double offsetX = 0,
    double offsetY = 0,
  }) {
    return CharElement(
      charId: charId,
      position: CharPosition(
        offsetX: offsetX,
        offsetY: offsetY,
      ),
    );
  }

  const CharElement._();

  /// 移动字符
  CharElement move(double dx, double dy) {
    return copyWith(
      position: position.copyWith(
        offsetX: position.offsetX + dx,
        offsetY: position.offsetY + dy,
      ),
    );
  }

  /// 旋转字符
  CharElement rotate(double angle) {
    return copyWith(
      transform: transform.rotate(angle),
    );
  }

  /// 缩放字符
  CharElement scale(double sx, double sy) {
    return copyWith(
      transform: transform.scale(sx, sy),
    );
  }

  /// 设置颜色
  CharElement setColor(String color) {
    return copyWith(
      style: style.setColor(color),
    );
  }

  /// 设置自定义样式
  CharElement setCustomStyle(String key, dynamic value) {
    return copyWith(
      style: style.setCustomStyle(key, value),
    );
  }

  /// 设置不透明度
  CharElement setOpacity(double opacity) {
    return copyWith(
      style: style.setOpacity(opacity),
    );
  }
}
