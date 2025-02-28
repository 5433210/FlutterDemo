import 'package:equatable/equatable.dart';

import 'character_image.dart';
import 'character_usage.dart';
import 'source_region.dart';

class CharacterEntity extends Equatable {
  final String? id;
  final DateTime? createTime;
  final DateTime? updateTime;
  final String workId;
  final CharValue char;
  final String? style;
  final String? tool;
  final SourceRegion sourceRegion;
  final CharacterImage image;
  final CharacterMetadata? metadata;
  final List<CharacterUsage> usage;

  const CharacterEntity({
    this.id,
    this.createTime,
    this.updateTime,
    required this.workId,
    required this.char,
    this.style,
    this.tool,
    required this.sourceRegion,
    required this.image,
    this.metadata,
    this.usage = const [],
  });

  factory CharacterEntity.fromJson(Map<String, dynamic> json) {
    return CharacterEntity(
      id: json['id'] as String?,
      createTime: json['createTime'] != null
          ? DateTime.parse(json['createTime'] as String)
          : null,
      updateTime: json['updateTime'] != null
          ? DateTime.parse(json['updateTime'] as String)
          : null,
      workId: json['workId'] as String,
      char: CharValue.fromJson(json['char'] as Map<String, dynamic>),
      style: json['style'] as String?,
      tool: json['tool'] as String?,
      sourceRegion:
          SourceRegion.fromJson(json['sourceRegion'] as Map<String, dynamic>),
      image: CharacterImage.fromJson(json['image'] as Map<String, dynamic>),
      metadata: json['metadata'] != null
          ? CharacterMetadata.fromJson(json['metadata'] as Map<String, dynamic>)
          : null,
      usage: json['usage'] != null
          ? List<CharacterUsage>.from(
              (json['usage'] as List).map(
                (x) => CharacterUsage.fromJson(x as Map<String, dynamic>),
              ),
            )
          : [],
    );
  }

  @override
  List<Object?> get props => [
        id,
        createTime,
        updateTime,
        workId,
        char,
        style,
        tool,
        sourceRegion,
        image,
        metadata,
        usage,
      ];

  CharacterEntity copyWith({
    String? id,
    DateTime? createTime,
    DateTime? updateTime,
    String? workId,
    CharValue? char,
    String? style,
    String? tool,
    SourceRegion? sourceRegion,
    CharacterImage? image,
    CharacterMetadata? metadata,
    List<CharacterUsage>? usage,
  }) {
    return CharacterEntity(
      id: id ?? this.id,
      createTime: createTime ?? this.createTime,
      updateTime: updateTime ?? this.updateTime,
      workId: workId ?? this.workId,
      char: char ?? this.char,
      style: style ?? this.style,
      tool: tool ?? this.tool,
      sourceRegion: sourceRegion ?? this.sourceRegion,
      image: image ?? this.image,
      metadata: metadata ?? this.metadata,
      usage: usage ?? this.usage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createTime': createTime?.toIso8601String(),
      'updateTime': updateTime?.toIso8601String(),
      'workId': workId,
      'char': char.toJson(),
      'style': style,
      'tool': tool,
      'sourceRegion': sourceRegion.toJson(),
      'image': image.toJson(),
      'metadata': metadata?.toJson(),
      'usage': usage.map((u) => u.toJson()).toList(),
    };
  }
}

class CharacterMetadata extends Equatable {
  final List<String> tags;

  const CharacterMetadata({
    this.tags = const [],
  });

  factory CharacterMetadata.fromJson(Map<String, dynamic> json) {
    return CharacterMetadata(
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  @override
  List<Object?> get props => [tags];

  CharacterMetadata copyWith({
    List<String>? tags,
  }) {
    return CharacterMetadata(
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tags': tags,
    };
  }
}

class CharValue extends Equatable {
  final String simplified;
  final String? traditional;

  const CharValue({
    required this.simplified,
    this.traditional,
  });

  factory CharValue.fromJson(Map<String, dynamic> json) {
    return CharValue(
      simplified: json['simplified'] as String,
      traditional: json['traditional'] as String?,
    );
  }

  @override
  List<Object?> get props => [simplified, traditional];

  CharValue copyWith({
    String? simplified,
    String? traditional,
  }) {
    return CharValue(
      simplified: simplified ?? this.simplified,
      traditional: traditional ?? this.traditional,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'simplified': simplified,
      'traditional': traditional,
    };
  }
}
