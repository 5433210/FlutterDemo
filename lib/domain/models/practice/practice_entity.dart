import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'practice_entity.freezed.dart';
part 'practice_entity.g.dart';

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

    /// 页数 - 数据库存储字段，与pages.length保持同步
    @Default(0) int pageCount,

    /// 元数据 - JSON格式存储的扩展信息
    @Default({}) Map<String, dynamic> metadata,

    /// 缩略图数据 (BLOB)
    @JsonKey(fromJson: _bytesFromJson, toJson: _bytesToJson)
    Uint8List? thumbnail,
  }) = _PracticeEntity;

  /// 新建练习，自动生成ID和时间戳
  factory PracticeEntity.create({
    required String title,
    List<String> tags = const [],
    String status = 'active',
    Map<String, dynamic> metadata = const {},
  }) {
    final now = DateTime.now();
    return PracticeEntity(
      id: const Uuid().v4(),
      title: title,
      tags: tags,
      status: status,
      pageCount: 0, // 新建时页数为0
      metadata: metadata, // 初始化元数据
      createTime: now,
      updateTime: now,
    );
  }

  /// 从JSON创建实例
  factory PracticeEntity.fromJson(Map<String, dynamic> json) =>
      _$PracticeEntityFromJson(json);

  /// 私有构造函数
  const PracticeEntity._();

  /// 获取metadata中的指定值
  T? getMetadata<T>(String key) {
    final value = metadata[key];
    return value is T ? value : null;
  }

  /// 设置metadata中的值（注意：需要等待freezed重新生成后才能使用）
  // PracticeEntity setMetadata(String key, dynamic value) {
  //   final newMetadata = Map<String, dynamic>.from(metadata);
  //   newMetadata[key] = value;
  //   return copyWith(
  //     metadata: newMetadata,
  //     updateTime: DateTime.now(),
  //   );
  // }

  /// 批量更新metadata（注意：需要等待freezed重新生成后才能使用）
  // PracticeEntity updateMetadata(Map<String, dynamic> updates) {
  //   final newMetadata = Map<String, dynamic>.from(metadata);
  //   newMetadata.addAll(updates);
  //   return copyWith(
  //     metadata: newMetadata,
  //     updateTime: DateTime.now(),
  //   );
  // }

  /// 获取下一个可用的页面索引
  int get nextPageIndex {
    if (pages.isEmpty) return 0;
    final lastPage = pages.last;
    return (lastPage['index'] as int?) ?? 0 + 1;
  }

  /// 获取实际页面数量（优先使用数据库存储的pageCount，fallback到计算值）
  int get actualPageCount => pageCount > 0 ? pageCount : pages.length;

  /// 添加页面
  PracticeEntity addPage(Map<String, dynamic> page) {
    final newPages = [...pages, page];
    return copyWith(
      pages: newPages,
      pageCount: newPages.length,
      updateTime: DateTime.now(),
    );
  }

  /// 删除页面
  PracticeEntity removePage(int index) {
    final newPages = pages.where((p) => (p['index'] as int?) != index).toList();
    return copyWith(
      pages: newPages,
      pageCount: newPages.length,
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

    final newPages =
        pages.map((p) => (p['index'] as int?) == pageIndex ? page : p).toList();

    return copyWith(
      pages: newPages,
      pageCount: newPages.length,
      updateTime: DateTime.now(),
    );
  }
}

/// JSON到Uint8List转换函数
Uint8List? _bytesFromJson(dynamic value) {
  if (value == null) return null;
  if (value is List<int>) {
    return Uint8List.fromList(value);
  }
  if (value is String && value.isNotEmpty) {
    // 处理base64编码的情况
    try {
      return Uint8List.fromList(value.codeUnits);
    } catch (e) {
      return null;
    }
  }
  return null;
}

/// Uint8List到JSON转换函数
List<int>? _bytesToJson(Uint8List? bytes) {
  return bytes?.toList();
}
