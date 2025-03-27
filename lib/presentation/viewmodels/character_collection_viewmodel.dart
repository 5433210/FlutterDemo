import 'package:flutter/material.dart';

class CharacterViewModel {
  final String id;
  final String pageId;
  final String character;
  final Rect rect;
  final String thumbnailPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;

  const CharacterViewModel({
    required this.id,
    required this.pageId,
    required this.character,
    required this.rect,
    required this.thumbnailPath,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
  });

  // 从数据库实体创建
  factory CharacterViewModel.fromEntity(Map<String, dynamic> entity) {
    return CharacterViewModel(
      id: entity['id'] as String,
      pageId: entity['page_id'] as String,
      character: entity['character'] as String,
      rect: Rect.fromLTWH(
        entity['rect_x'] as double,
        entity['rect_y'] as double,
        entity['rect_width'] as double,
        entity['rect_height'] as double,
      ),
      thumbnailPath: entity['thumbnail_path'] as String,
      createdAt: DateTime.parse(entity['created_at'] as String),
      updatedAt: DateTime.parse(entity['updated_at'] as String),
      isFavorite: (entity['is_favorite'] as int?) == 1,
    );
  }

  // 创建副本并更新部分属性
  CharacterViewModel copyWith({
    String? id,
    String? pageId,
    String? character,
    Rect? rect,
    String? thumbnailPath,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
  }) {
    return CharacterViewModel(
      id: id ?? this.id,
      pageId: pageId ?? this.pageId,
      character: character ?? this.character,
      rect: rect ?? this.rect,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
