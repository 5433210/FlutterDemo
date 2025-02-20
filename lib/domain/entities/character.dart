import 'dart:convert';

class Character {
  final String id;
  final String workId;
  final String char;
  final String? pinyin;
  final Map<String, dynamic> sourceRegion;
  final Map<String, dynamic> image;
  final Map<String, dynamic>? metadata;
  final DateTime createTime;
  final DateTime updateTime;

  Character({
    required this.id,
    required this.workId,
    required this.char,
    this.pinyin,
    required this.sourceRegion,
    required this.image,
    this.metadata,
    required this.createTime,
    required this.updateTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'work_id': workId,
      'char': char,
      'pinyin': pinyin,
      'source_region': jsonEncode(sourceRegion),
      'image': jsonEncode(image),
      'metadata': metadata != null ? jsonEncode(metadata) : null,
      'create_time': createTime.millisecondsSinceEpoch,
      'update_time': updateTime.millisecondsSinceEpoch,
    };
  }

  static Character fromMap(Map<String, dynamic> map) {
    return Character(
      id: map['id'],
      workId: map['work_id'],
      char: map['char'],
      pinyin: map['pinyin'],
      sourceRegion: map['source_region'] != null 
          ? jsonDecode(map['source_region']) 
          : {},
      image: map['image'] != null 
          ? jsonDecode(map['image']) 
          : {},
      metadata: map['metadata'] != null 
          ? jsonDecode(map['metadata']) 
          : null,
      createTime: DateTime.fromMillisecondsSinceEpoch(map['create_time']),
      updateTime: DateTime.fromMillisecondsSinceEpoch(map['update_time']),
    );
  }
}

