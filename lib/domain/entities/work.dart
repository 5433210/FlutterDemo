import 'dart:convert';

import 'package:flutter/foundation.dart';

class Work {
  String? id;
  String? name;
  String? author;
  String? style;
  String? tool;
  DateTime? creationDate;
  int? imageCount;
  DateTime? createTime;
  DateTime? updateTime;
  String? remark; // 添加备注字段
  dynamic metadata; // 修改 metadata 定义为任意类型

  Work({
    this.id,
    this.name,
    this.author,
    this.style,
    this.tool,
    this.creationDate,
    this.imageCount = 0,
    this.createTime,
    this.updateTime,
    this.remark, // 添加到构造函数
    this.metadata,
  });

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
        remark: json['remark'] as String?, // 从 JSON 解析
        metadata: json['metadata'], // 不做类型转换
      );

  factory Work.fromMap(Map<String, dynamic> map) {
    return Work(
      id: map['id'] as String?,
      name: map['name'] as String?,
      author: map['author'] as String?,
      style: map['style'] as String?,
      tool: map['tool'] as String?,
      creationDate: _parseDateTime(map['creationDate']),
      imageCount: map['imageCount'] as int? ?? 0,
      createTime: _parseDateTime(map['createTime']) ?? DateTime.now(),
      updateTime: _parseDateTime(map['updateTime']) ?? DateTime.now(),
      remark: map['remark'] as String?, // 从 map 解析
      metadata: map['metadata'], // 不做类型转换
    );
  }

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
    String? remark, // 添加到 copyWith
    dynamic metadata,
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
      remark: remark ?? this.remark, // 处理 remark 字段
      metadata: metadata ?? this.metadata,
    );
  }

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
        'remark': remark, // 加入 JSON 输出
        'metadata': metadata, // 直接使用原始值
      };

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
      'remark': remark, // 加入 map 输出
      'metadata': metadata, // 直接使用原始值
    };
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is int) {
      // 确保使用正确的时间戳单位
      return DateTime.fromMillisecondsSinceEpoch(value); // 使用毫秒
    }
    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      debugPrint('Failed to parse date: $value');
      return null;
    }
  }

  // 添加安全解析元数据的静态方法
  static Map<String, dynamic>? _parseMetadata(dynamic value) {
    if (value == null) return null;

    try {
      if (value is String) {
        // 字符串情况：尝试解析 JSON
        try {
          return jsonDecode(value) as Map<String, dynamic>;
        } catch (e) {
          debugPrint('Failed to parse metadata string: $e');
          return {}; // 返回空 Map 而不是 null
        }
      } else if (value is Map) {
        // 已经是 Map 的情况
        return Map<String, dynamic>.from(value);
      }
    } catch (e) {
      debugPrint('Error handling metadata: $e');
    }

    return {}; // 返回空 Map 作为默认值
  }
}
