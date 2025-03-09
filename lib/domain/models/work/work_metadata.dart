import 'package:equatable/equatable.dart';

import '../../../domain/enums/work_style.dart';
import '../../../domain/enums/work_tool.dart';

/// 作品元数据
class WorkMetadata extends Equatable {
  /// 名称
  final String name;

  /// 作者
  final String author;

  /// 创作日期
  final DateTime? creationDate;

  /// 备注
  final String? remark;

  /// 风格
  final WorkStyle style;

  /// 工具
  final WorkTool tool;

  /// 标签
  final Set<String> tags;

  /// 创建作品元数据
  const WorkMetadata({
    required this.name,
    required this.author,
    required this.style,
    required this.tool,
    this.creationDate,
    this.remark,
    Set<String>? tags,
  }) : tags = tags ?? const {};

  /// 从JSON创建
  factory WorkMetadata.fromJson(Map<String, dynamic> json) {
    return WorkMetadata(
      name: json['name'] as String,
      author: json['author'] as String,
      style: WorkStyle.values.byName(json['style'] as String),
      tool: WorkTool.values.byName(json['tool'] as String),
      creationDate: json['creationDate'] == null
          ? null
          : DateTime.parse(json['creationDate'] as String),
      remark: json['remark'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toSet() ??
          {},
    );
  }

  /// 检查是否有任何标签
  bool get hasTags => tags.isNotEmpty;

  @override
  List<Object?> get props => [
        name,
        author,
        style,
        tool,
        creationDate,
        remark,
        tags,
      ];

  /// 添加标签
  WorkMetadata addTag(String tag) {
    final newTags = Set<String>.from(tags)..add(tag);
    return copyWith(tags: newTags);
  }

  /// 复制
  WorkMetadata copyWith({
    String? name,
    String? author,
    WorkStyle? style,
    WorkTool? tool,
    DateTime? creationDate,
    String? remark,
    Set<String>? tags,
  }) {
    return WorkMetadata(
      name: name ?? this.name,
      author: author ?? this.author,
      style: style ?? this.style,
      tool: tool ?? this.tool,
      creationDate: creationDate ?? this.creationDate,
      remark: remark ?? this.remark,
      tags: tags ?? this.tags,
    );
  }

  /// 是否包含标签
  bool hasTag(String tag) => tags.contains(tag);

  /// 移除标签
  WorkMetadata removeTag(String tag) {
    final newTags = Set<String>.from(tags)..remove(tag);
    return copyWith(tags: newTags);
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'author': author,
      'style': style.name,
      'tool': tool.name,
      'creationDate': creationDate?.toIso8601String(),
      'remark': remark,
      'tags': tags.toList(),
    };
  }

  @override
  String toString() => 'WorkMetadata(name: $name, author: $author)';

  /// 更新标签
  WorkMetadata updateTags(Set<String> newTags) {
    return copyWith(tags: newTags);
  }
}
