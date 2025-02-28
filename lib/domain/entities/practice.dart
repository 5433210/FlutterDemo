import 'package:equatable/equatable.dart';

/// 字帖实体类
///
/// 这个类是领域中最简化的字帖表示，用于与数据库交互
/// 更丰富的业务逻辑在 PracticeEntity 值对象中实现
class Practice extends Equatable {
  /// 唯一标识符
  final String? id;

  /// 创建时间
  final DateTime? createTime;

  /// 更新时间
  final DateTime? updateTime;

  /// 标题
  final String title;

  /// 状态 (draft/completed)
  final String status;

  /// 页面数据 - 以JSON字符串形式存储
  final List<String> pages;

  /// 元数据 - 简化为标签列表
  final List<String> metadata;

  const Practice({
    this.id,
    this.createTime,
    this.updateTime,
    required this.title,
    this.status = 'draft',
    this.pages = const [],
    this.metadata = const [],
  });

  factory Practice.fromJson(Map<String, dynamic> json) {
    return Practice(
      id: json['id'] as String?,
      createTime: json['createTime'] != null
          ? DateTime.parse(json['createTime'] as String)
          : null,
      updateTime: json['updateTime'] != null
          ? DateTime.parse(json['updateTime'] as String)
          : null,
      title: json['title'] as String,
      status: json['status'] as String? ?? 'draft',
      pages: json['pages'] != null
          ? (json['pages'] as List).map((e) => e as String).toList()
          : const [],
      metadata: json['metadata'] != null
          ? (json['metadata'] as List).map((e) => e as String).toList()
          : const [],
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

  Practice copyWith({
    String? id,
    DateTime? createTime,
    DateTime? updateTime,
    String? title,
    String? status,
    List<String>? pages,
    List<String>? metadata,
  }) {
    return Practice(
      id: id ?? this.id,
      createTime: createTime ?? this.createTime,
      updateTime: updateTime ?? this.updateTime,
      title: title ?? this.title,
      status: status ?? this.status,
      pages: pages ?? this.pages,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createTime': createTime?.toIso8601String(),
      'updateTime': updateTime?.toIso8601String(),
      'title': title,
      'status': status,
      'pages': pages,
      'metadata': metadata,
    };
  }
}
