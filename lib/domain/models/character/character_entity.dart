import 'package:freezed_annotation/freezed_annotation.dart';

import 'character_region.dart';

part 'character_entity.freezed.dart';
part 'character_entity.g.dart';

@freezed
class CharacterEntity with _$CharacterEntity {
  const factory CharacterEntity({
    required String id,
    required String workId,
    required String pageId,
    required String character,
    required CharacterRegion region,
    required DateTime createTime,
    required DateTime updateTime,
    @Default(false) bool isFavorite,
    @Default([]) List<String> tags,
    String? note,
    @Default({}) Map<String, dynamic> metadata,
  }) = _CharacterEntity;

  factory CharacterEntity.create({
    required String workId,
    required String pageId,
    required CharacterRegion region,
    String character = '',
    List<String> tags = const [],
    String? note,
    Map<String, dynamic> metadata = const {},
  }) {
    final now = DateTime.now();
    return CharacterEntity(
      id: region.id,
      workId: workId,
      pageId: pageId,
      character: character,
      region: region,
      createTime: now,
      updateTime: now,
      tags: tags,
      note: note,
      metadata: metadata,
    );
  }

  factory CharacterEntity.fromJson(Map<String, dynamic> json) =>
      _$CharacterEntityFromJson(json);
}
