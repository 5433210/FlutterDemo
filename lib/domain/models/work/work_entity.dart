import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/work_status.dart';
import '../character/character_entity.dart';
import 'work_image.dart';

part 'work_entity.freezed.dart';
part 'work_entity.g.dart';

/// 作品实体
@freezed
class WorkEntity with _$WorkEntity {
  factory WorkEntity({
    /// ID
    required String id,

    /// 标题
    required String title,

    /// 作者
    required String author,

    /// 备注
    String? remark,

    /// 字体风格 (动态配置)
    @Default('') String style,

    /// 书写工具 (动态配置)
    @Default('') String tool,

    /// 创建时间
    required DateTime createTime,

    /// 修改时间
    required DateTime updateTime,

    /// 是否收藏
    @Default(false) bool isFavorite,

    /// 图片最后更新时间
    DateTime? lastImageUpdateTime,

    /// 状态
    @Default(WorkStatus.draft) WorkStatus status,

    /// 首图ID
    String? firstImageId,

    /// 图片列表
    @Default([]) List<WorkImage> images,

    /// 关联字符列表
    @Default([]) List<CharacterEntity> collectedChars,

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

  /// 切换收藏状态
  WorkEntity toggleFavorite() {
    return copyWith(isFavorite: !isFavorite);
  }

  /// 更新首图
  WorkEntity updateFirstImage(String? firstImageId) =>
      copyWith(firstImageId: firstImageId);

  /// 更新标签
  WorkEntity updateTags(List<String> newTags) {
    return copyWith(tags: newTags);
  }
}
