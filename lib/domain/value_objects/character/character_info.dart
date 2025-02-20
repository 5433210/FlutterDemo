import 'package:demo/domain/value_objects/character/source_region.dart';

import 'char_image_info.dart';
import 'usage_info.dart';

class CharacterInfo {
  final CharValue char;
  final String? style;
  final String? tool;
  final SourceRegion sourceRegion;
  final CharImageInfo image;
  final List<String> tags;
  final List<UsageInfo> usage;

  const CharacterInfo({
    required this.char,
    this.style,
    this.tool,
    required this.sourceRegion,
    required this.image,
    this.tags = const [],
    this.usage = const [],
  });

  Map<String, dynamic> toJson() => {
    'char': char.toJson(),
    'style': style,
    'tool': tool,
    'sourceRegion': sourceRegion.toJson(),
    'image': image.toJson(),
    'tags': tags,
    'usage': usage.map((u) => u.toJson()).toList(),
  }..removeWhere((_, value) => value == null);

  factory CharacterInfo.fromJson(Map<String, dynamic> json) => CharacterInfo(
    char: CharValue.fromJson(json['char'] as Map<String, dynamic>),
    style: json['style'] as String?,
    tool: json['tool'] as String?,
    sourceRegion: SourceRegion.fromJson(json['sourceRegion'] as Map<String, dynamic>),
    image: CharImageInfo.fromJson(json['image'] as Map<String, dynamic>),
    tags: (json['tags'] as List?)?.map((e) => e as String).toList() ?? [],
    usage: (json['usage'] as List?)
        ?.map((e) => UsageInfo.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
  );
}

class CharValue {
  final String simplified;
  final String? traditional;

  CharValue({
    required this.simplified,
    this.traditional,
  }) {
    if (simplified.length != 1) {
      throw ArgumentError('Simplified must be a single character');
    }
  }

  Map<String, dynamic> toJson() => {
    'simplified': simplified,
    'traditional': traditional,
  }..removeWhere((_, value) => value == null);

  factory CharValue.fromJson(Map<String, dynamic> json) => CharValue(
    simplified: json['simplified'] as String,
    traditional: json['traditional'] as String?,
  );
}