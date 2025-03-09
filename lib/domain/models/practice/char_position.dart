import 'package:freezed_annotation/freezed_annotation.dart';

part 'char_position.freezed.dart';
part 'char_position.g.dart';

/// 字符位置
@freezed
class CharPosition with _$CharPosition {
  const factory CharPosition({
    /// X轴偏移量
    required double offsetX,

    /// Y轴偏移量
    required double offsetY,
  }) = _CharPosition;

  /// 从JSON创建实例
  factory CharPosition.fromJson(Map<String, dynamic> json) =>
      _$CharPositionFromJson(json);

  const CharPosition._();
}
