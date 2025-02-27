import 'dart:convert';

import 'package:equatable/equatable.dart';

import '../value_objects/practice/page_info.dart';

/// Practice entity containing pages of practice items
class Practice extends Equatable {
  final String? id;
  final String title;
  final List<PracticePageInfo> pages;
  final DateTime createTime;
  final DateTime updateTime;
  final Map<String, dynamic>? metadata;

  const Practice({
    this.id,
    required this.title,
    required this.pages,
    required this.createTime,
    required this.updateTime,
    this.metadata,
  });

  /// Create from JSON map (alias for fromMap for consistency with other entities)
  factory Practice.fromJson(Map<String, dynamic> json) =>
      Practice.fromMap(json);

  /// Create an instance from a JSON string
  factory Practice.fromJsonString(String jsonString) {
    return Practice.fromMap(json.decode(jsonString) as Map<String, dynamic>);
  }

  /// Create an instance from a map
  factory Practice.fromMap(Map<String, dynamic> map) {
    return Practice(
      id: map['id'] as String?,
      title: map['title'] as String,
      pages: ((map['pages'] as List?) ?? [])
          .map((page) => PracticePageInfo.fromMap(page as Map<String, dynamic>))
          .toList(),
      createTime: DateTime.fromMillisecondsSinceEpoch(
          map['createTime'] as int? ?? DateTime.now().millisecondsSinceEpoch),
      updateTime: DateTime.fromMillisecondsSinceEpoch(
          map['updateTime'] as int? ?? DateTime.now().millisecondsSinceEpoch),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        pages,
        createTime,
        updateTime,
        metadata,
      ];

  Practice copyWith({
    String? id,
    String? title,
    List<PracticePageInfo>? pages,
    DateTime? createTime,
    DateTime? updateTime,
    Map<String, dynamic>? metadata,
  }) {
    return Practice(
      id: id ?? this.id,
      title: title ?? this.title,
      pages: pages ?? this.pages,
      createTime: createTime ?? this.createTime,
      updateTime: updateTime ?? this.updateTime,
      metadata: metadata ?? this.metadata,
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
      'title': title,
      'pages': pages.map((page) => page.toMap()).toList(),
      'createTime': createTime.millisecondsSinceEpoch,
      'updateTime': updateTime.millisecondsSinceEpoch,
      'metadata': metadata,
    };
  }
}
