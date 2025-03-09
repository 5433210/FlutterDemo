import 'package:freezed_annotation/freezed_annotation.dart';

import 'character_region.dart';

part 'character_entity.freezed.dart';
part 'character_entity.g.dart';

/// 表示一个采集的汉字字形
@freezed
class CharacterEntity with _$CharacterEntity {
  const factory CharacterEntity({
    /// ID
    String? id,

    /// 汉字
    required String char,

    /// 所属作品ID
    String? workId,

    /// 字形区域
    CharacterRegion? region,

    /// 标签列表
    @Default([]) List<String> tags,

    /// 创建时间
    DateTime? createTime,

    /// 更新时间
    DateTime? updateTime,
  }) = _CharacterEntity;

  /// 从JSON创建实例
  factory CharacterEntity.fromJson(Map<String, dynamic> json) =>
      _$CharacterEntityFromJson(json);

  const CharacterEntity._();

  /// 用于显示的文本描述
  @override
  String toString() => 'CharacterEntity(char: $char, workId: $workId)';
}
