import 'dart:convert';
import 'dart:ui' show Rect;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/work_style.dart';
import '../../enums/work_tool.dart';
import 'character_region.dart';
import 'processing_options.dart' show ProcessingOptions;

part 'character_view.freezed.dart';
part 'character_view.g.dart';

/// 字符视图模型，包含了字符相关的作品信息
@freezed
class CharacterView with _$CharacterView {
  /// Default constructor
  const factory CharacterView({
    /// 唯一标识符
    required String id,

    /// 字符内容（简体字）
    required String character,

    /// 作品ID
    required String workId,

    /// 页面ID
    required String pageId,

    /// 作品名称
    required String title,
    WorkTool? tool,
    WorkStyle? style,

    /// 作者
    String? author,

    /// 作品创建时间
    DateTime? creationTime,

    /// 字符收集时间
    required DateTime collectionTime,

    /// 字符最近更新时间
    required DateTime updateTime,

    /// 是否收藏
    @Default(false) bool isFavorite,

    /// 标签列表
    @Default([]) List<String> tags,

    /// 字符区域信息
    required CharacterRegion region,
  }) = _CharacterView;

  /// Create from JSON
  factory CharacterView.fromJson(Map<String, dynamic> json) =>
      _$CharacterViewFromJson(json);

  /// Create from entity and work maps
  factory CharacterView.fromMaps(
    Map<String, dynamic> characterMap,
    Map<String, dynamic> workMap,
  ) {
    // Parse character tags if stored as JSON string
    final tagsData = characterMap['tags'];
    List<String> tags = [];

    if (tagsData is String && tagsData.isNotEmpty) {
      try {
        tags = (jsonDecode(tagsData) as List<dynamic>).cast<String>();
      } catch (e) {
        // Handle parsing error
      }
    } else if (tagsData is List) {
      tags = tagsData.cast<String>();
    }

    // Parse region
    final regionData = characterMap['region'];
    late CharacterRegion region;

    if (regionData is String) {
      region = CharacterRegion.fromJson(jsonDecode(regionData));
    } else if (regionData is Map<String, dynamic>) {
      region = CharacterRegion.fromJson(regionData);
    } else {
      region = CharacterRegion(
        id: characterMap['id'] as String,
        pageId: characterMap['pageId'] as String,
        rect: const Rect.fromLTRB(0, 0, 0, 0),
        options: const ProcessingOptions(),
      );
    }

    // Create view model combining character and work data
    return CharacterView(
        id: characterMap['id'] as String,
        character: characterMap['character'] as String,
        workId: characterMap['workId'] as String,
        pageId: characterMap['pageId'] as String,
        title: workMap['title'] as String? ?? '未知作品',
        author: workMap['author'] as String?,
        creationTime: workMap['creationTime'] != null
            ? DateTime.parse(workMap['creationTime'] as String)
            : null,
        collectionTime: DateTime.parse(characterMap['createTime'] as String),
        updateTime: DateTime.parse(characterMap['updateTime'] as String),
        isFavorite: (characterMap['isFavorite'] as int) == 1,
        tags: tags,
        region: region,
        tool: WorkTool.fromString(workMap['tool'] as String),
        style: WorkStyle.fromString(workMap['style'] as String));
  }

  const CharacterView._(); // Private constructor for getter methods
}
