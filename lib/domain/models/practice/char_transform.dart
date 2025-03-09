import 'package:freezed_annotation/freezed_annotation.dart';

part 'char_transform.freezed.dart';
part 'char_transform.g.dart';

/// 字符变换
@freezed
class CharTransform with _$CharTransform {
  const factory CharTransform({
    /// X轴缩放
    @Default(1.0) double scaleX,

    /// Y轴缩放
    @Default(1.0) double scaleY,

    /// 旋转角度
    @Default(0.0) double rotation,
  }) = _CharTransform;

  /// 从JSON创建实例
  factory CharTransform.fromJson(Map<String, dynamic> json) =>
      _$CharTransformFromJson(json);

  const CharTransform._();

  /// 旋转
  CharTransform rotate(double angle) {
    return copyWith(
      rotation: rotation + angle,
    );
  }

  /// 按比例缩放
  CharTransform scale(double sx, double sy) {
    return copyWith(
      scaleX: scaleX * sx,
      scaleY: scaleY * sy,
    );
  }
}
