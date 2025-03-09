import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'character_region.freezed.dart';
part 'character_region.g.dart';

/// 字形区域信息
@freezed
class CharacterRegion with _$CharacterRegion {
  const factory CharacterRegion({
    /// X坐标
    required double left,

    /// Y坐标
    required double top,

    /// 宽度
    required double width,

    /// 高度
    required double height,

    /// 旋转角度
    @Default(0.0) double rotation,

    /// 页码索引
    required int pageIndex,

    /// 是否已保存
    @Default(false) bool isSaved,

    /// 标签
    String? label,

    /// 图片路径
    required String imagePath,

    /// 区域颜色
    @JsonKey(ignore: true) Color? color,
  }) = _CharacterRegion;

  /// 从JSON创建实例
  factory CharacterRegion.fromJson(Map<String, dynamic> json) =>
      _$CharacterRegionFromJson(json);

  const CharacterRegion._();

  /// 矩形区域
  Rect get rect => Rect.fromLTWH(left, top, width, height);

  /// 用于显示的文本描述
  @override
  String toString() => 'CharacterRegion($left,$top,$width,$height)';
}
