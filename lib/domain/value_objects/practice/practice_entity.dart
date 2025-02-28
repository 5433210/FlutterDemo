import 'package:equatable/equatable.dart';

import 'practice_page.dart';

/// 字帖实体类，表示一个完整的字帖
class PracticeEntity extends Equatable {
  /// 字帖唯一标识符
  final String? id;

  /// 创建时间
  final DateTime? createTime;

  /// 更新时间
  final DateTime? updateTime;

  /// 字帖标题
  final String title;

  /// 字帖状态 (draft/completed)
  final String status;

  /// 字帖页面列表
  final List<PracticePage> pages;

  /// 元数据
  final PracticeMetadata? metadata;

  const PracticeEntity({
    this.id,
    this.createTime,
    this.updateTime,
    required this.title,
    required this.status,
    required this.pages,
    this.metadata,
  });

  /// 从JSON数据创建字帖实体
  factory PracticeEntity.fromJson(Map<String, dynamic> json) {
    return PracticeEntity(
      id: json['id'] as String?,
      createTime: json['createTime'] != null
          ? DateTime.parse(json['createTime'] as String)
          : null,
      updateTime: json['updateTime'] != null
          ? DateTime.parse(json['updateTime'] as String)
          : null,
      title: json['title'] as String,
      status: json['status'] as String,
      pages: json['pages'] != null
          ? List<PracticePage>.from(
              (json['pages'] as List).map(
                (x) => PracticePage.fromJson(x as Map<String, dynamic>),
              ),
            )
          : [],
      metadata: json['metadata'] != null
          ? PracticeMetadata.fromJson(json['metadata'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        createTime,
        updateTime,
        title,
        status,
        pages,
        metadata,
      ];

  /// 创建一个带有更新属性的新实例
  PracticeEntity copyWith({
    String? id,
    DateTime? createTime,
    DateTime? updateTime,
    String? title,
    String? status,
    List<PracticePage>? pages,
    PracticeMetadata? metadata,
  }) {
    return PracticeEntity(
      id: id ?? this.id,
      createTime: createTime ?? this.createTime,
      updateTime: updateTime ?? this.updateTime,
      title: title ?? this.title,
      status: status ?? this.status,
      pages: pages ?? this.pages,
      metadata: metadata ?? this.metadata,
    );
  }

  /// 将字帖实体转换为JSON数据
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createTime': createTime?.toIso8601String(),
      'updateTime': updateTime?.toIso8601String(),
      'title': title,
      'status': status,
      'pages': pages.map((page) => page.toJson()).toList(),
      'metadata': metadata?.toJson(),
    };
  }
}

/// 字帖元数据
class PracticeMetadata extends Equatable {
  /// 标签列表
  final List<String> tags;

  const PracticeMetadata({
    this.tags = const [],
  });

  /// 从JSON数据创建元数据
  factory PracticeMetadata.fromJson(Map<String, dynamic> json) {
    return PracticeMetadata(
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : const [],
    );
  }

  @override
  List<Object?> get props => [tags];

  /// 创建一个带有更新属性的新实例
  PracticeMetadata copyWith({
    List<String>? tags,
  }) {
    return PracticeMetadata(
      tags: tags ?? this.tags,
    );
  }

  /// 将元数据转换为JSON数据
  Map<String, dynamic> toJson() {
    return {
      'tags': tags,
    };
  }
}
