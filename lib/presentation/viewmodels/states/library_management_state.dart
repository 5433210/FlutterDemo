import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/entities/library_category.dart';
import '../../../domain/entities/library_item.dart';

part 'library_management_state.freezed.dart';

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

    /// 类型筛选
    String? typeFilter,

    /// 是否只显示收藏
    @Default(false) bool showFavoritesOnly,

    /// 图片后缀筛选
    String? formatFilter,

    /// 最小宽度筛选
    int? minWidth,

    /// 最大宽度筛选
    int? maxWidth,

    /// 最小高度筛选
    int? minHeight,

    /// 最大高度筛选
    int? maxHeight,

    /// 最小文件大小筛选（字节）
    int? minSize,

    /// 最大文件大小筛选（字节）
    int? maxSize,

    /// 入库开始日期
    DateTime? createStartDate,

    /// 入库结束日期
    DateTime? createEndDate,

    /// 更新开始日期
    DateTime? updateStartDate,

    /// 更新结束日期
    DateTime? updateEndDate,

    /// 是否显示筛选面板
    @Default(true) bool showFilterPanel,

    /// 分类项目计数
    @Default({}) Map<String, int> categoryItemCounts,
  }) = _LibraryManagementState;

  /// 初始状态
  factory LibraryManagementState.initial() => const LibraryManagementState();
}

/// 视图模式
enum ViewMode {
  /// 网格视图
  grid,

  /// 列表视图
  list,
}
