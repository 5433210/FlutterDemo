import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'library_category.freezed.dart';
part 'library_category.g.dart';

/// 图库分类
@freezed
class LibraryCategory with _$LibraryCategory {
  const factory LibraryCategory({
    /// ID
    required String id,

    /// 名称
    required String name,

    /// 父分类ID
    String? parentId,

    /// 排序顺序
    @Default(0) int sortOrder,

    /// 子分类列表
    @Default([]) List<LibraryCategory> children,

    /// 创建时间
    required DateTime createdAt,

    /// 更新时间
    required DateTime updatedAt,
  }) = _LibraryCategory;

  /// 从 JSON 创建
  factory LibraryCategory.fromJson(Map<String, dynamic> json) =>
      _$LibraryCategoryFromJson(json);

  /// 创建新实例
  factory LibraryCategory.create({
    required String name,
    String? parentId,
    int? sortOrder,
    List<LibraryCategory>? children,
  }) {
    final now = DateTime.now();
    return LibraryCategory(
      id: const Uuid().v4(),
      name: name,
      parentId: parentId,
      sortOrder: sortOrder ?? 0,
      children: children ?? [],
      createdAt: now,
      updatedAt: now,
    );
  }
}
