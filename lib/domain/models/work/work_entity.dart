import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/work_status.dart';
import '../../enums/work_style.dart';
import '../../enums/work_tool.dart';
import '../character/character_entity.dart';
import 'work_image.dart';

part 'work_entity.freezed.dart';
part 'work_entity.g.dart';

WorkStyle _workStyleFromJson(dynamic value) => WorkStyle.fromValue(value);

/// 枚举序列化辅助方法
String _workStyleToJson(WorkStyle style) => style.value;
WorkTool _workToolFromJson(dynamic value) => WorkTool.fromValue(value);
String _workToolToJson(WorkTool tool) => tool.value;

/// 作品实体
@freezed
class WorkEntity with _$WorkEntity {
  const factory WorkEntity({
    /// ID
    required String id,

    /// 标题
    required String title,

    /// 作者
    required String author,

    /// 备注
    String? remark,

    /// 字体
    @JsonKey(fromJson: _workStyleFromJson, toJson: _workStyleToJson)
    required WorkStyle style,

    /// 工具
    @JsonKey(fromJson: _workToolFromJson, toJson: _workToolToJson)
    required WorkTool tool,

    /// 创作日期
    @JsonKey(name: 'creation_date') required DateTime creationDate,

    /// 创建时间
    @JsonKey(name: 'create_time') required DateTime createTime,

    /// 修改时间
    @JsonKey(name: 'update_time') required DateTime updateTime,

    /// 状态
    @Default(WorkStatus.draft) WorkStatus status,

    /// 首图ID
    String? firstImageId,

    /// 图片最后更新时间
    DateTime? lastImageUpdateTime,

    /// 图片列表
    @Default([]) List<WorkImage> images,

    /// 关联字符列表
    @JsonKey(name: 'collected_chars')
    @Default([])
    List<CharacterEntity> collectedChars,

    /// 标签列表
    @Default([]) List<String> tags,

    /// 图片数量
    int? imageCount,
  }) = _WorkEntity;

  factory WorkEntity.fromJson(Map<String, dynamic> json) =>
      _$WorkEntityFromJson(json);

  const WorkEntity._();

  /// 获取首图
  WorkImage? get firstImage => images.isEmpty ? null : images[0];

  /// 获取图片总数量
  int get totalImages => imageCount ?? images.length;

  /// 添加关联字
  WorkEntity addCollectedChar(CharacterEntity char) {
    if (collectedChars.contains(char)) return this;
    return copyWith(collectedChars: [...collectedChars, char]);
  }

  /// 添加标签
  WorkEntity addTag(String tag) {
    if (tags.contains(tag)) return this;
    return copyWith(tags: [...tags, tag]);
  }

  /// 移除关联字
  WorkEntity removeCollectedChar(CharacterEntity char) {
    return copyWith(
        collectedChars: collectedChars.where((c) => c != char).toList());
  }

  /// 移除标签
  WorkEntity removeTag(String tag) {
    return copyWith(tags: tags.where((t) => t != tag).toList());
  }

  /// 更新首图
  WorkEntity updateFirstImage(String? firstImageId) =>
      copyWith(firstImageId: firstImageId);

  /// 更新标签
  WorkEntity updateTags(List<String> newTags) {
    return copyWith(tags: newTags);
  }
}
