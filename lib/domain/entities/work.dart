import 'package:flutter/foundation.dart';

@immutable
class Work {
  final String? id;
  final String? name;
  final String? author;
  final String? style;
  final String? tool;
  final DateTime? creationDate;
  final DateTime? importDate;
  final int? imageCount;
  final DateTime? createTime;    // 数据创建时间
  final DateTime? updateTime;    // 数据更新时间

  const Work({
    this.id,
    this.name,
    this.author,
    this.style,
    this.tool,
    this.creationDate,
    this.importDate,
    this.imageCount = 0,
    this.createTime,
    this.updateTime,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'author': author,
    'style': style,
    'tool': tool,
    'creation_date': creationDate?.toIso8601String(),
    'import_date': importDate?.toIso8601String(),
    'image_count': imageCount,
    'create_time': createTime?.toIso8601String(),
    'update_time': updateTime?.toIso8601String(),
  };

  factory Work.fromJson(Map<String, dynamic> json) => Work(
    id: json['id'] as String?,
    name: json['name'] as String?,
    author: json['author'] as String?,
    style: json['style'] as String?,
    tool: json['tool'] as String?,
    creationDate: _parseDateTime(json['creation_date']),
    importDate: _parseDateTime(json['import_date']),
    imageCount: json['image_count'] as int? ?? 0,
    createTime: _parseDateTime(json['create_time']) ?? DateTime.now(),
    updateTime: _parseDateTime(json['update_time']) ?? DateTime.now(),
  );

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      return null;
    }
  }

  // Alias for JSON methods
  Map<String, dynamic> toMap() => toJson();
  factory Work.fromMap(Map<String, dynamic> map) => Work.fromJson(map);
}