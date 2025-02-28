import 'package:equatable/equatable.dart';

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
    return WorkEntity(
      id: json['id'] as String?,
      createTime: json['createTime'] != null
          ? DateTime.parse(json['createTime'] as String)
          : null,
      updateTime: json['updateTime'] != null
          ? DateTime.parse(json['updateTime'] as String)
          : null,
      name: json['name'] as String,
      author: json['author'] as String?,
      style: json['style'] != null
          ? WorkStyle.values.firstWhere(
              (style) => style.value == json['style'],
              orElse: () => WorkStyle.regular,
            )
          : null,
      tool: json['tool'] != null
          ? WorkTool.values.firstWhere(
              (tool) => tool.value == json['tool'],
              orElse: () => WorkTool.brush,
            )
          : null,
      imageCount: json['imageCount'] as int? ?? 0,
      creationDate: json['creationDate'] != null
          ? DateTime.parse(json['creationDate'] as String)
          : null,
      remark: json['remark'] as String?,
      images: json['images'] != null
          ? List<WorkImage>.from(
              (json['images'] as List).map(
                (x) => WorkImage.fromJson(x as Map<String, dynamic>),
              ),
            )
          : [],
      collectedChars: json['collectedChars'] != null
          ? List<WorkCollectedChar>.from(
              (json['collectedChars'] as List).map(
                (x) => WorkCollectedChar.fromJson(x as Map<String, dynamic>),
              ),
            )
          : [],
      metadata: json['metadata'] != null
          ? WorkMetadata.fromJson(json['metadata'] as Map<String, dynamic>)
          : null,
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
      'createTime': createTime?.toIso8601String(),
      'updateTime': updateTime?.toIso8601String(),
      'name': name,
      'author': author,
      'style': style?.value,
      'tool': tool?.value,
      'imageCount': imageCount,
      'creationDate': creationDate?.toIso8601String(),
      'remark': remark,
      'images': images.map((image) => image.toJson()).toList(),
      'collectedChars': collectedChars.map((char) => char.toJson()).toList(),
      'metadata': metadata?.toJson(),
    };
  }
}

class WorkMetadata extends Equatable {
  final List<String> tags;

  const WorkMetadata({
    this.tags = const [],
  });

  factory WorkMetadata.fromJson(Map<String, dynamic> json) {
    return WorkMetadata(
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  @override
  List<Object?> get props => [tags];

  WorkMetadata copyWith({
    List<String>? tags,
  }) {
    return WorkMetadata(
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tags': tags,
    };
  }
}
