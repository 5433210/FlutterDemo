import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../../domain/enums/work_style.dart';
import '../../../domain/enums/work_tool.dart';
import 'work_collected_char.dart';
import 'work_image.dart';

class WorkEntity extends Equatable {
  final String? id;
  final DateTime? createTime;
  final DateTime? updateTime;
  final String name;
  final String? author;
  final WorkStyle? style;
  final WorkTool? tool;
  final int imageCount;
  final DateTime? creationDate;
  final String? remark;
  final List<WorkImage> images;
  final List<WorkCollectedChar> collectedChars;
  final WorkMetadata? metadata;

  const WorkEntity({
    this.id,
    this.createTime,
    this.updateTime,
    required this.name,
    this.author,
    this.style,
    this.tool,
    this.imageCount = 0,
    this.creationDate,
    this.remark,
    this.images = const [],
    this.collectedChars = const [],
    this.metadata,
  });

  factory WorkEntity.fromJson(Map<String, dynamic> json) {
    List<WorkImage> images = [];
    if (json.containsKey('images') && json['images'] is List) {
      images = (json['images'] as List).map((img) {
        final imgMap = img as Map<String, dynamic>;
        return WorkImage(
          index: imgMap['index'] as int,
          original: imgMap.containsKey('originalPath')
              ? ImageDetail(
                  path: imgMap['originalPath'] as String,
                  width: 0, // 简化处理，这些值实际应用时会再次加载
                  height: 0,
                  format: '',
                  size: 0,
                )
              : null,
          imported: imgMap.containsKey('importedPath')
              ? ImageDetail(
                  path: imgMap['importedPath'] as String,
                  width: 0, // 简化处理
                  height: 0,
                  format: '',
                  size: 0,
                )
              : null,
          thumbnail: imgMap.containsKey('thumbnailPath')
              ? ImageThumbnail(
                  path: imgMap['thumbnailPath'] as String,
                  width: 0, // 简化处理
                  height: 0,
                )
              : null,
        );
      }).toList();
    }

    List<WorkCollectedChar> collectedChars = [];
    if (json.containsKey('collectedChars') && json['collectedChars'] is List) {
      collectedChars = (json['collectedChars'] as List).map((char) {
        final charMap = char as Map<String, dynamic>;
        final regionMap = charMap['region'] as Map<String, dynamic>;
        return WorkCollectedChar(
          id: charMap['id'] as String? ?? '',
          createTime:
              DateTime.fromMillisecondsSinceEpoch(charMap['createTime'] as int),
          region: SourceRegion(
            index: regionMap['index'] as int,
            x: (regionMap['x'] as num).toInt(),
            y: (regionMap['y'] as num).toInt(),
            width: (regionMap['width'] as num).toInt(),
            height: (regionMap['height'] as num).toInt(),
          ),
        );
      }).toList();
    }

    WorkMetadata? metadata;
    if (json.containsKey('metadata') && json['metadata'] != null) {
      metadata = WorkMetadata.fromMap(json['metadata'] as Map<String, dynamic>);
    }

    WorkStyle? style;
    if (json.containsKey('style') && json['style'] != null) {
      final styleValue = json['style'] as String;
      style = WorkStyle.values.firstWhere(
        (s) => s.value == styleValue,
        orElse: () => WorkStyle.regular,
      );
    }

    WorkTool? tool;
    if (json.containsKey('tool') && json['tool'] != null) {
      final toolValue = json['tool'] as String;
      tool = WorkTool.values.firstWhere(
        (t) => t.value == toolValue,
        orElse: () => WorkTool.brush,
      );
    }

    return WorkEntity(
      id: json['id'] as String?,
      name: json['name'] as String? ?? '',
      author: json['author'] as String?,
      style: style,
      tool: tool,
      imageCount: json['imageCount'] as int? ?? 0,
      creationDate:
          json.containsKey('creationDate') && json['creationDate'] != null
              ? DateTime.fromMillisecondsSinceEpoch(json['creationDate'] as int)
              : null,
      createTime: json.containsKey('createTime') && json['createTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createTime'] as int)
          : null,
      updateTime: json.containsKey('updateTime') && json['updateTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updateTime'] as int)
          : null,
      remark: json['remark'] as String?,
      images: images,
      collectedChars: collectedChars,
      metadata: metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        createTime,
        updateTime,
        name,
        author,
        style,
        tool,
        imageCount,
        creationDate,
        remark,
        images,
        collectedChars,
        metadata,
      ];

  // 添加安全的 getter 方法
  List<String> get tags {
    try {
      return metadata?.tags ?? [];
    } catch (e) {
      debugPrint('获取标签失败: $e');
      return [];
    }
  }

  WorkEntity copyWith({
    String? id,
    DateTime? createTime,
    DateTime? updateTime,
    String? name,
    String? author,
    WorkStyle? style,
    WorkTool? tool,
    int? imageCount,
    DateTime? creationDate,
    String? remark,
    List<WorkImage>? images,
    List<WorkCollectedChar>? collectedChars,
    WorkMetadata? metadata,
  }) {
    return WorkEntity(
      id: id ?? this.id,
      createTime: createTime ?? this.createTime,
      updateTime: updateTime ?? this.updateTime,
      name: name ?? this.name,
      author: author ?? this.author,
      style: style ?? this.style,
      tool: tool ?? this.tool,
      imageCount: imageCount ?? this.imageCount,
      creationDate: creationDate ?? this.creationDate,
      remark: remark ?? this.remark,
      images: images ?? this.images,
      collectedChars: collectedChars ?? this.collectedChars,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'author': author,
      'style': style?.value,
      'tool': tool?.value,
      'imageCount': imageCount,
      'creationDate': creationDate?.millisecondsSinceEpoch,
      'createTime': createTime?.millisecondsSinceEpoch,
      'updateTime': updateTime?.millisecondsSinceEpoch,
      'remark': remark,
      // 图片和字形引用可能很复杂，可以保存简单引用或ID列表
      'images': images
          .map((img) => {
                'index': img.index,
                'originalPath': img.original?.path,
                'importedPath': img.imported?.path,
                'thumbnailPath': img.thumbnail?.path,
              })
          .toList(),
      'collectedChars': collectedChars
          .map((char) => {
                'id': char.id,
                'createTime': char.createTime.millisecondsSinceEpoch,
                'region': {
                  'index': char.region.index,
                  'x': char.region.x,
                  'y': char.region.y,
                  'width': char.region.width,
                  'height': char.region.height,
                }
              })
          .toList(),
      'metadata': metadata?.toJson(),
    };
  }
}

class WorkMetadata {
  final List<String> tags;

  const WorkMetadata({this.tags = const []});

  factory WorkMetadata.fromJson(String source) {
    try {
      final map = jsonDecode(source) as Map<String, dynamic>;
      return WorkMetadata.fromMap(map);
    } catch (e) {
      debugPrint('WorkMetadata fromJson 错误: $e');
      return const WorkMetadata(tags: []);
    }
  }

  factory WorkMetadata.fromMap(Map<String, dynamic> map) {
    try {
      final tagsData = map['tags'];
      List<String> tags = [];

      if (tagsData != null) {
        if (tagsData is List) {
          // 明确转换每个元素为 String 类型
          tags = tagsData.map<String>((item) => item.toString()).toList();
        }
      }

      return WorkMetadata(tags: tags);
    } catch (e) {
      debugPrint('WorkMetadata fromMap 错误: $e');
      return const WorkMetadata(tags: []);
    }
  }

  String toJson() {
    try {
      return jsonEncode(toMap());
    } catch (e) {
      debugPrint('WorkMetadata toJson 错误: $e');
      return '{"tags":[]}'; // 返回有效的JSON字符串
    }
  }

  // 添加更健壮的序列化与反序列化方法
  Map<String, dynamic> toMap() {
    return {
      'tags': tags,
    };
  }

  @override
  String toString() {
    return 'WorkMetadata{tags: $tags}';
  }
}
