import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'practice_entity.freezed.dart';
part 'practice_entity.g.dart';

// Note: Base64 conversion utilities kept for backward compatibility
/// 将 Base64 字符串转换为 Uint8List
Uint8List? _uint8ListFromJson(String? base64String) {
  if (base64String == null) return null;
  try {
    return base64Decode(base64String);
  } catch (e) {
    debugPrint('Error decoding base64 string: $e');
    return null;
  }
}

/// 将 Uint8List 转换为 Base64 字符串
String? _uint8ListToJson(Uint8List? data) {
  if (data == null) return null;
  try {
    return base64Encode(data);
  } catch (e) {
    debugPrint('Error encoding Uint8List to base64: $e');
    return null;
  }
}

/// 字帖练习实体
@freezed
class PracticeEntity with _$PracticeEntity {
  /// 创建实例
  const factory PracticeEntity({
    /// ID
    required String id,

    /// 标题
    required String title,

    /// 页面列表 - 存储完整的页面内容
    @Default([]) List<Map<String, dynamic>> pages,

    /// 标签列表
    @Default([]) List<String> tags,

    /// 状态
    @Default('active') String status,

    /// 创建时间
    required DateTime createTime,

    /// 更新时间
    required DateTime updateTime,

    /// 是否收藏
    @Default(false) bool isFavorite,
  }) = _PracticeEntity;

  /// 新建练习，自动生成ID和时间戳
  factory PracticeEntity.create({
    required String title,
    List<String> tags = const [],
    String status = 'active',
  }) {
    final now = DateTime.now();
    return PracticeEntity(
      id: const Uuid().v4(),
      title: title,
      tags: tags,
      status: status,
      createTime: now,
      updateTime: now,
    );
  }

  /// 从JSON创建实例
  factory PracticeEntity.fromJson(Map<String, dynamic> json) =>
      _$PracticeEntityFromJson(json);

  /// 私有构造函数
  const PracticeEntity._();

  /// 获取下一个可用的页面索引
  int get nextPageIndex {
    if (pages.isEmpty) return 0;
    final lastPage = pages.last;
    return (lastPage['index'] as int?) ?? 0 + 1;
  }

  /// 获取页面数量
  int get pageCount => pages.length;

  /// 添加页面
  PracticeEntity addPage(Map<String, dynamic> page) {
    return copyWith(
      pages: [...pages, page],
      updateTime: DateTime.now(),
    );
  }

  /// 删除页面
  PracticeEntity removePage(int index) {
    return copyWith(
      pages: pages.where((p) => (p['index'] as int?) != index).toList(),
      updateTime: DateTime.now(),
    );
  }

  /// 用于显示的文本描述
  @override
  String toString() => 'PracticeEntity(id: $id, title: $title)';

  /// 更新页面
  PracticeEntity updatePage(Map<String, dynamic> page) {
    final pageIndex = page['index'] as int?;
    if (pageIndex == null) return this;

    return copyWith(
      pages: pages
          .map((p) => (p['index'] as int?) == pageIndex ? page : p)
          .toList(),
      updateTime: DateTime.now(),
    );
  }
}
