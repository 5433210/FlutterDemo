import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../infrastructure/utils/json_converters.dart';

part 'library_item.freezed.dart';
part 'library_item.g.dart';

/// 图库项目
@freezed
class LibraryItem with _$LibraryItem {
  const factory LibraryItem({
    /// ID
    required String id,

    /// 文件名称
    required String fileName,

    /// 类型
    required String type,

    /// 格式
    required String format,

    /// 文件路径
    required String path,

    /// 宽度
    required int width,

    /// 高度
    required int height,

    /// 文件大小（字节）
    required int fileSize,

    /// 标签列表
    @Default([]) List<String> tags,

    /// 分类列表
    @Default([]) List<String> categories,

    /// 元数据
    @Default({}) Map<String, dynamic> metadata,

    /// 是否收藏
    @Default(false) bool isFavorite,

    /// 备注信息
    @Default('') String remarks,

    /// 缩略图数据
    @Uint8ListConverter() Uint8List? thumbnail,

    /// 文件创建时间
    required DateTime fileCreatedAt,

    /// 文件修改时间
    required DateTime fileUpdatedAt,
  }) = _LibraryItem;

  /// 创建新实例
  factory LibraryItem.create({
    required String name,
    required String type,
    required String format,
    required String path,
    required int width,
    required int height,
    required int size,
    List<String>? tags,
    List<String>? categories,
    Map<String, dynamic>? metadata,
    bool? isFavorite,
    String? remarks,
    Uint8List? thumbnail,
  }) {
    final now = DateTime.now();
    return LibraryItem(
      id: const Uuid().v4(),
      fileName: name,
      type: type,
      format: format,
      path: path,
      width: width,
      height: height,
      fileSize: size,
      tags: tags ?? [],
      categories: categories ?? [],
      metadata: metadata ?? {},
      isFavorite: isFavorite ?? false,
      remarks: remarks ?? '',
      thumbnail: thumbnail,
      fileCreatedAt: now,
      fileUpdatedAt: now,
    );
  }

  /// 从 JSON 创建
  factory LibraryItem.fromJson(Map<String, dynamic> json) =>
      _$LibraryItemFromJson(json);
}
