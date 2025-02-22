import 'dart:convert';
import 'package:flutter/foundation.dart';

@immutable
class Work {
  final String? id;
  final String? name;
  final String? author;
  final String? style;
  final String? tool;
  final DateTime? creationDate;  
  final int? imageCount;
  final DateTime? createTime;    
  final DateTime? updateTime;    
  final Map<String, dynamic>? metadata;  // Added metadata field

  const Work({
    this.id,
    this.name,
    this.author,
    this.style,
    this.tool,
    this.creationDate,
    this.imageCount = 0,
    this.createTime,
    this.updateTime,
    this.metadata,  // Added to constructor
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'author': author,
    'style': style,
    'tool': tool,
    'creation_date': creationDate?.toIso8601String(),    
    'imageCount': imageCount,
    'createTime': createTime?.toIso8601String(),
    'updateTime': updateTime?.toIso8601String(),
    'metadata': metadata != null ? jsonEncode(metadata) : null,  // Serialize metadata
  };

  factory Work.fromJson(Map<String, dynamic> json) => Work(
    id: json['id'] as String?,
    name: json['name'] as String?,
    author: json['author'] as String?,
    style: json['style'] as String?,
    tool: json['tool'] as String?,
    creationDate: _parseDateTime(json['creation_date']),    
    imageCount: json['imageCount'] as int? ?? 0,
    createTime: _parseDateTime(json['createTime']) ?? DateTime.now(),
    updateTime: _parseDateTime(json['updateTime']) ?? DateTime.now(),
    metadata: json['metadata'] != null 
        ? jsonDecode(json['metadata'] as String) as Map<String, dynamic>
        : null,  // Deserialize metadata
  );

  // Alias for JSON methods
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'author': author,
      'style': style,
      'tool': tool,
      'creationDate': creationDate?.toIso8601String(),
      'imageCount': imageCount,
      'createTime': createTime?.toIso8601String(),
      'updateTime': updateTime?.toIso8601String(),
      'metadata': metadata != null ? jsonEncode(metadata) : null,  // Serialize metadata
    };
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    try {
      if (value is int) {
        // Handle microseconds since epoch
        return DateTime.fromMicrosecondsSinceEpoch(value);
      }
      return DateTime.parse(value.toString());
    } catch (e) {
      return null;
    }
  }

  factory Work.fromMap(Map<String, dynamic> map) {
    return Work(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      author: map['author'],
      style: map['style'],
      tool: map['tool'],
      creationDate: _parseDateTime(map['creationDate']),
      imageCount: map['imageCount'] ?? 0,
      createTime: _parseDateTime(map['createTime']),
      updateTime: _parseDateTime(map['updateTime']),
      metadata: map['metadata'] != null 
          ? jsonDecode(map['metadata'] as String) as Map<String, dynamic>
          : null,  // Deserialize metadata
    );
  }

  // Add copyWith method to support metadata updates
  Work copyWith({
    String? id,
    String? name,
    String? author,
    String? style,
    String? tool,
    DateTime? creationDate,
    int? imageCount,
    DateTime? createTime,
    DateTime? updateTime,
    Map<String, dynamic>? metadata,
  }) {
    return Work(
      id: id ?? this.id,
      name: name ?? this.name,
      author: author ?? this.author,
      style: style ?? this.style,
      tool: tool ?? this.tool,
      creationDate: creationDate ?? this.creationDate,
      imageCount: imageCount ?? this.imageCount,
      createTime: createTime ?? this.createTime,
      updateTime: updateTime ?? this.updateTime,
      metadata: metadata ?? this.metadata,
    );
  }
}