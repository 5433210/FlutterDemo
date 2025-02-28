import 'dart:convert';

import 'package:equatable/equatable.dart';

/// Entity representing a character in the system
class Character extends Equatable {
  final String? id;
  final String char;
  final String? pinyin;
  final String? workId;
  final String? workName;
  final String? image;
  final Map<String, dynamic>? sourceRegion;
  final DateTime? createTime;
  final Map<String, dynamic>? metadata;

  const Character({
    this.id,
    required this.char,
    this.pinyin,
    this.workId,
    this.workName,
    this.image,
    this.sourceRegion,
    this.createTime,
    this.metadata,
  });

  /// Create from JSON map (alias for fromMap for consistency with other entities)
  factory Character.fromJson(Map<String, dynamic> json) =>
      Character.fromMap(json);

  /// Create an instance from a JSON string
  factory Character.fromJsonString(String jsonString) {
    return Character.fromMap(json.decode(jsonString) as Map<String, dynamic>);
  }

  /// Create an instance from a map
  factory Character.fromMap(Map<String, dynamic> map) {
    return Character(
      id: map['id'] as String?,
      char: map['char'] as String,
      pinyin: map['pinyin'] as String?,
      workId: map['workId'] as String?,
      workName: map['workName'] as String?,
      image: map['image'] as String?,
      sourceRegion: map['sourceRegion'] != null
          ? Map<String, dynamic>.from(map['sourceRegion'] as Map)
          : null,
      createTime: map['createTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createTime'] as int)
          : null,
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        char,
        pinyin,
        workId,
        workName,
        image,
        sourceRegion,
        createTime,
        metadata,
      ];

  Character copyWith({
    String? id,
    String? char,
    // ...
  }) {
    return Character(
      id: id ?? this.id,
      char: char ?? this.char,
      // ...
    );
  }

  /// Convert to JSON map (alias for toMap for consistency with other entities)
  Map<String, dynamic> toJson() => toMap();

  /// Convert to a JSON string
  String toJsonString() => json.encode(toMap());

  /// Convert to a map for persistence
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'char': char,
      'pinyin': pinyin,
      'workId': workId,
      'workName': workName,
      'image': image,
      'sourceRegion': sourceRegion,
      'createTime': createTime?.millisecondsSinceEpoch,
      'metadata': metadata,
    };
  }
}
