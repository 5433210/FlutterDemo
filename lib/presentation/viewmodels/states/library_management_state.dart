import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/entities/library_item.dart';
import '../../../domain/entities/library_category.dart';

part 'library_management_state.freezed.dart';

/// 视图模式
enum ViewMode {
  /// 网格视图
  grid,

  /// 列表视图
  list,
}

/// 图库管理状态
@freezed
class LibraryManagementState with _$LibraryManagementState {
  const factory LibraryManagementState({
    /// 图库项目列表
    @Default([]) List<LibraryItem> items,

    /// 所有标签
    @Default([]) List<String> allTags,

    /// 分类列表
    @Default([]) List<LibraryCategory> categories,

    /// 分类树
    @Default([]) List<LibraryCategory> categoryTree,

    /// 当前选中的分类ID
    String? selectedCategoryId,

    /// 搜索关键词
    @Default('') String searchQuery,

    /// 排序字段
    @Default('name') String sortBy,

    /// 是否降序排序
    @Default(false) bool sortDesc,

    /// 是否正在加载
    @Default(false) bool isLoading,

    /// 是否处于批量选择模式
    @Default(false) bool isBatchMode,

    /// 选中的项目ID集合
    @Default({}) Set<String> selectedItems,

    /// 是否显示详情面板
    @Default(false) bool isDetailOpen,

    /// 错误信息
    String? errorMessage,

    /// 总数量
    @Default(0) int totalCount,

    /// 当前页码
    @Default(1) int currentPage,

    /// 每页数量
    @Default(20) int pageSize,

    /// 视图模式
    @Default(ViewMode.grid) ViewMode viewMode,

    /// 选中的项目
    LibraryItem? selectedItem,
  }) = _LibraryManagementState;

  /// 初始状态
  factory LibraryManagementState.initial() => const LibraryManagementState();
}
