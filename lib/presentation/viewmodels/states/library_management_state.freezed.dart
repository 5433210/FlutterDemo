// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'library_management_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$LibraryManagementState {
  /// 图库项目列表
  List<LibraryItem> get items => throw _privateConstructorUsedError;

  /// 所有标签
  List<String> get allTags => throw _privateConstructorUsedError;

  /// 分类列表
  List<LibraryCategory> get categories => throw _privateConstructorUsedError;

  /// 分类树
  List<LibraryCategory> get categoryTree => throw _privateConstructorUsedError;

  /// 当前选中的分类ID
  String? get selectedCategoryId => throw _privateConstructorUsedError;

  /// 搜索关键词
  String get searchQuery => throw _privateConstructorUsedError;

  /// 排序字段
  String get sortBy => throw _privateConstructorUsedError;

  /// 是否降序排序
  bool get sortDesc => throw _privateConstructorUsedError;

  /// 是否正在加载
  bool get isLoading => throw _privateConstructorUsedError;

  /// 是否处于批量选择模式
  bool get isBatchMode => throw _privateConstructorUsedError;

  /// 选中的项目ID集合
  Set<String> get selectedItems => throw _privateConstructorUsedError;

  /// 是否显示详情面板
  bool get isDetailOpen => throw _privateConstructorUsedError;

  /// 错误信息
  String? get errorMessage => throw _privateConstructorUsedError;

  /// 总数量
  int get totalCount => throw _privateConstructorUsedError;

  /// 当前页码
  int get currentPage => throw _privateConstructorUsedError;

  /// 每页数量
  int get pageSize => throw _privateConstructorUsedError;

  /// 视图模式
  ViewMode get viewMode => throw _privateConstructorUsedError;

  /// 选中的项目
  LibraryItem? get selectedItem => throw _privateConstructorUsedError;

  /// 类型筛选
  String? get typeFilter => throw _privateConstructorUsedError;

  /// 是否只显示收藏
  bool get showFavoritesOnly => throw _privateConstructorUsedError;

  /// 图片后缀筛选
  String? get formatFilter => throw _privateConstructorUsedError;

  /// 最小宽度筛选
  int? get minWidth => throw _privateConstructorUsedError;

  /// 最大宽度筛选
  int? get maxWidth => throw _privateConstructorUsedError;

  /// 最小高度筛选
  int? get minHeight => throw _privateConstructorUsedError;

  /// 最大高度筛选
  int? get maxHeight => throw _privateConstructorUsedError;

  /// 最小文件大小筛选（字节）
  int? get minSize => throw _privateConstructorUsedError;

  /// 最大文件大小筛选（字节）
  int? get maxSize => throw _privateConstructorUsedError;

  /// 入库开始日期
  DateTime? get createStartDate => throw _privateConstructorUsedError;

  /// 入库结束日期
  DateTime? get createEndDate => throw _privateConstructorUsedError;

  /// 更新开始日期
  DateTime? get updateStartDate => throw _privateConstructorUsedError;

  /// 更新结束日期
  DateTime? get updateEndDate => throw _privateConstructorUsedError;

  /// 是否显示筛选面板
  bool get showFilterPanel => throw _privateConstructorUsedError;

  /// 分类项目计数
  Map<String, int> get categoryItemCounts => throw _privateConstructorUsedError;

  /// Create a copy of LibraryManagementState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LibraryManagementStateCopyWith<LibraryManagementState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LibraryManagementStateCopyWith<$Res> {
  factory $LibraryManagementStateCopyWith(LibraryManagementState value,
          $Res Function(LibraryManagementState) then) =
      _$LibraryManagementStateCopyWithImpl<$Res, LibraryManagementState>;
  @useResult
  $Res call(
      {List<LibraryItem> items,
      List<String> allTags,
      List<LibraryCategory> categories,
      List<LibraryCategory> categoryTree,
      String? selectedCategoryId,
      String searchQuery,
      String sortBy,
      bool sortDesc,
      bool isLoading,
      bool isBatchMode,
      Set<String> selectedItems,
      bool isDetailOpen,
      String? errorMessage,
      int totalCount,
      int currentPage,
      int pageSize,
      ViewMode viewMode,
      LibraryItem? selectedItem,
      String? typeFilter,
      bool showFavoritesOnly,
      String? formatFilter,
      int? minWidth,
      int? maxWidth,
      int? minHeight,
      int? maxHeight,
      int? minSize,
      int? maxSize,
      DateTime? createStartDate,
      DateTime? createEndDate,
      DateTime? updateStartDate,
      DateTime? updateEndDate,
      bool showFilterPanel,
      Map<String, int> categoryItemCounts});

  $LibraryItemCopyWith<$Res>? get selectedItem;
}

/// @nodoc
class _$LibraryManagementStateCopyWithImpl<$Res,
        $Val extends LibraryManagementState>
    implements $LibraryManagementStateCopyWith<$Res> {
  _$LibraryManagementStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LibraryManagementState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? allTags = null,
    Object? categories = null,
    Object? categoryTree = null,
    Object? selectedCategoryId = freezed,
    Object? searchQuery = null,
    Object? sortBy = null,
    Object? sortDesc = null,
    Object? isLoading = null,
    Object? isBatchMode = null,
    Object? selectedItems = null,
    Object? isDetailOpen = null,
    Object? errorMessage = freezed,
    Object? totalCount = null,
    Object? currentPage = null,
    Object? pageSize = null,
    Object? viewMode = null,
    Object? selectedItem = freezed,
    Object? typeFilter = freezed,
    Object? showFavoritesOnly = null,
    Object? formatFilter = freezed,
    Object? minWidth = freezed,
    Object? maxWidth = freezed,
    Object? minHeight = freezed,
    Object? maxHeight = freezed,
    Object? minSize = freezed,
    Object? maxSize = freezed,
    Object? createStartDate = freezed,
    Object? createEndDate = freezed,
    Object? updateStartDate = freezed,
    Object? updateEndDate = freezed,
    Object? showFilterPanel = null,
    Object? categoryItemCounts = null,
  }) {
    return _then(_value.copyWith(
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<LibraryItem>,
      allTags: null == allTags
          ? _value.allTags
          : allTags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      categories: null == categories
          ? _value.categories
          : categories // ignore: cast_nullable_to_non_nullable
              as List<LibraryCategory>,
      categoryTree: null == categoryTree
          ? _value.categoryTree
          : categoryTree // ignore: cast_nullable_to_non_nullable
              as List<LibraryCategory>,
      selectedCategoryId: freezed == selectedCategoryId
          ? _value.selectedCategoryId
          : selectedCategoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      searchQuery: null == searchQuery
          ? _value.searchQuery
          : searchQuery // ignore: cast_nullable_to_non_nullable
              as String,
      sortBy: null == sortBy
          ? _value.sortBy
          : sortBy // ignore: cast_nullable_to_non_nullable
              as String,
      sortDesc: null == sortDesc
          ? _value.sortDesc
          : sortDesc // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isBatchMode: null == isBatchMode
          ? _value.isBatchMode
          : isBatchMode // ignore: cast_nullable_to_non_nullable
              as bool,
      selectedItems: null == selectedItems
          ? _value.selectedItems
          : selectedItems // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      isDetailOpen: null == isDetailOpen
          ? _value.isDetailOpen
          : isDetailOpen // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      totalCount: null == totalCount
          ? _value.totalCount
          : totalCount // ignore: cast_nullable_to_non_nullable
              as int,
      currentPage: null == currentPage
          ? _value.currentPage
          : currentPage // ignore: cast_nullable_to_non_nullable
              as int,
      pageSize: null == pageSize
          ? _value.pageSize
          : pageSize // ignore: cast_nullable_to_non_nullable
              as int,
      viewMode: null == viewMode
          ? _value.viewMode
          : viewMode // ignore: cast_nullable_to_non_nullable
              as ViewMode,
      selectedItem: freezed == selectedItem
          ? _value.selectedItem
          : selectedItem // ignore: cast_nullable_to_non_nullable
              as LibraryItem?,
      typeFilter: freezed == typeFilter
          ? _value.typeFilter
          : typeFilter // ignore: cast_nullable_to_non_nullable
              as String?,
      showFavoritesOnly: null == showFavoritesOnly
          ? _value.showFavoritesOnly
          : showFavoritesOnly // ignore: cast_nullable_to_non_nullable
              as bool,
      formatFilter: freezed == formatFilter
          ? _value.formatFilter
          : formatFilter // ignore: cast_nullable_to_non_nullable
              as String?,
      minWidth: freezed == minWidth
          ? _value.minWidth
          : minWidth // ignore: cast_nullable_to_non_nullable
              as int?,
      maxWidth: freezed == maxWidth
          ? _value.maxWidth
          : maxWidth // ignore: cast_nullable_to_non_nullable
              as int?,
      minHeight: freezed == minHeight
          ? _value.minHeight
          : minHeight // ignore: cast_nullable_to_non_nullable
              as int?,
      maxHeight: freezed == maxHeight
          ? _value.maxHeight
          : maxHeight // ignore: cast_nullable_to_non_nullable
              as int?,
      minSize: freezed == minSize
          ? _value.minSize
          : minSize // ignore: cast_nullable_to_non_nullable
              as int?,
      maxSize: freezed == maxSize
          ? _value.maxSize
          : maxSize // ignore: cast_nullable_to_non_nullable
              as int?,
      createStartDate: freezed == createStartDate
          ? _value.createStartDate
          : createStartDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createEndDate: freezed == createEndDate
          ? _value.createEndDate
          : createEndDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updateStartDate: freezed == updateStartDate
          ? _value.updateStartDate
          : updateStartDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updateEndDate: freezed == updateEndDate
          ? _value.updateEndDate
          : updateEndDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      showFilterPanel: null == showFilterPanel
          ? _value.showFilterPanel
          : showFilterPanel // ignore: cast_nullable_to_non_nullable
              as bool,
      categoryItemCounts: null == categoryItemCounts
          ? _value.categoryItemCounts
          : categoryItemCounts // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
    ) as $Val);
  }

  /// Create a copy of LibraryManagementState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LibraryItemCopyWith<$Res>? get selectedItem {
    if (_value.selectedItem == null) {
      return null;
    }

    return $LibraryItemCopyWith<$Res>(_value.selectedItem!, (value) {
      return _then(_value.copyWith(selectedItem: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$LibraryManagementStateImplCopyWith<$Res>
    implements $LibraryManagementStateCopyWith<$Res> {
  factory _$$LibraryManagementStateImplCopyWith(
          _$LibraryManagementStateImpl value,
          $Res Function(_$LibraryManagementStateImpl) then) =
      __$$LibraryManagementStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<LibraryItem> items,
      List<String> allTags,
      List<LibraryCategory> categories,
      List<LibraryCategory> categoryTree,
      String? selectedCategoryId,
      String searchQuery,
      String sortBy,
      bool sortDesc,
      bool isLoading,
      bool isBatchMode,
      Set<String> selectedItems,
      bool isDetailOpen,
      String? errorMessage,
      int totalCount,
      int currentPage,
      int pageSize,
      ViewMode viewMode,
      LibraryItem? selectedItem,
      String? typeFilter,
      bool showFavoritesOnly,
      String? formatFilter,
      int? minWidth,
      int? maxWidth,
      int? minHeight,
      int? maxHeight,
      int? minSize,
      int? maxSize,
      DateTime? createStartDate,
      DateTime? createEndDate,
      DateTime? updateStartDate,
      DateTime? updateEndDate,
      bool showFilterPanel,
      Map<String, int> categoryItemCounts});

  @override
  $LibraryItemCopyWith<$Res>? get selectedItem;
}

/// @nodoc
class __$$LibraryManagementStateImplCopyWithImpl<$Res>
    extends _$LibraryManagementStateCopyWithImpl<$Res,
        _$LibraryManagementStateImpl>
    implements _$$LibraryManagementStateImplCopyWith<$Res> {
  __$$LibraryManagementStateImplCopyWithImpl(
      _$LibraryManagementStateImpl _value,
      $Res Function(_$LibraryManagementStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of LibraryManagementState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? allTags = null,
    Object? categories = null,
    Object? categoryTree = null,
    Object? selectedCategoryId = freezed,
    Object? searchQuery = null,
    Object? sortBy = null,
    Object? sortDesc = null,
    Object? isLoading = null,
    Object? isBatchMode = null,
    Object? selectedItems = null,
    Object? isDetailOpen = null,
    Object? errorMessage = freezed,
    Object? totalCount = null,
    Object? currentPage = null,
    Object? pageSize = null,
    Object? viewMode = null,
    Object? selectedItem = freezed,
    Object? typeFilter = freezed,
    Object? showFavoritesOnly = null,
    Object? formatFilter = freezed,
    Object? minWidth = freezed,
    Object? maxWidth = freezed,
    Object? minHeight = freezed,
    Object? maxHeight = freezed,
    Object? minSize = freezed,
    Object? maxSize = freezed,
    Object? createStartDate = freezed,
    Object? createEndDate = freezed,
    Object? updateStartDate = freezed,
    Object? updateEndDate = freezed,
    Object? showFilterPanel = null,
    Object? categoryItemCounts = null,
  }) {
    return _then(_$LibraryManagementStateImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<LibraryItem>,
      allTags: null == allTags
          ? _value._allTags
          : allTags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      categories: null == categories
          ? _value._categories
          : categories // ignore: cast_nullable_to_non_nullable
              as List<LibraryCategory>,
      categoryTree: null == categoryTree
          ? _value._categoryTree
          : categoryTree // ignore: cast_nullable_to_non_nullable
              as List<LibraryCategory>,
      selectedCategoryId: freezed == selectedCategoryId
          ? _value.selectedCategoryId
          : selectedCategoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      searchQuery: null == searchQuery
          ? _value.searchQuery
          : searchQuery // ignore: cast_nullable_to_non_nullable
              as String,
      sortBy: null == sortBy
          ? _value.sortBy
          : sortBy // ignore: cast_nullable_to_non_nullable
              as String,
      sortDesc: null == sortDesc
          ? _value.sortDesc
          : sortDesc // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isBatchMode: null == isBatchMode
          ? _value.isBatchMode
          : isBatchMode // ignore: cast_nullable_to_non_nullable
              as bool,
      selectedItems: null == selectedItems
          ? _value._selectedItems
          : selectedItems // ignore: cast_nullable_to_non_nullable
              as Set<String>,
      isDetailOpen: null == isDetailOpen
          ? _value.isDetailOpen
          : isDetailOpen // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      totalCount: null == totalCount
          ? _value.totalCount
          : totalCount // ignore: cast_nullable_to_non_nullable
              as int,
      currentPage: null == currentPage
          ? _value.currentPage
          : currentPage // ignore: cast_nullable_to_non_nullable
              as int,
      pageSize: null == pageSize
          ? _value.pageSize
          : pageSize // ignore: cast_nullable_to_non_nullable
              as int,
      viewMode: null == viewMode
          ? _value.viewMode
          : viewMode // ignore: cast_nullable_to_non_nullable
              as ViewMode,
      selectedItem: freezed == selectedItem
          ? _value.selectedItem
          : selectedItem // ignore: cast_nullable_to_non_nullable
              as LibraryItem?,
      typeFilter: freezed == typeFilter
          ? _value.typeFilter
          : typeFilter // ignore: cast_nullable_to_non_nullable
              as String?,
      showFavoritesOnly: null == showFavoritesOnly
          ? _value.showFavoritesOnly
          : showFavoritesOnly // ignore: cast_nullable_to_non_nullable
              as bool,
      formatFilter: freezed == formatFilter
          ? _value.formatFilter
          : formatFilter // ignore: cast_nullable_to_non_nullable
              as String?,
      minWidth: freezed == minWidth
          ? _value.minWidth
          : minWidth // ignore: cast_nullable_to_non_nullable
              as int?,
      maxWidth: freezed == maxWidth
          ? _value.maxWidth
          : maxWidth // ignore: cast_nullable_to_non_nullable
              as int?,
      minHeight: freezed == minHeight
          ? _value.minHeight
          : minHeight // ignore: cast_nullable_to_non_nullable
              as int?,
      maxHeight: freezed == maxHeight
          ? _value.maxHeight
          : maxHeight // ignore: cast_nullable_to_non_nullable
              as int?,
      minSize: freezed == minSize
          ? _value.minSize
          : minSize // ignore: cast_nullable_to_non_nullable
              as int?,
      maxSize: freezed == maxSize
          ? _value.maxSize
          : maxSize // ignore: cast_nullable_to_non_nullable
              as int?,
      createStartDate: freezed == createStartDate
          ? _value.createStartDate
          : createStartDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createEndDate: freezed == createEndDate
          ? _value.createEndDate
          : createEndDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updateStartDate: freezed == updateStartDate
          ? _value.updateStartDate
          : updateStartDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updateEndDate: freezed == updateEndDate
          ? _value.updateEndDate
          : updateEndDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      showFilterPanel: null == showFilterPanel
          ? _value.showFilterPanel
          : showFilterPanel // ignore: cast_nullable_to_non_nullable
              as bool,
      categoryItemCounts: null == categoryItemCounts
          ? _value._categoryItemCounts
          : categoryItemCounts // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
    ));
  }
}

/// @nodoc

class _$LibraryManagementStateImpl implements _LibraryManagementState {
  const _$LibraryManagementStateImpl(
      {final List<LibraryItem> items = const [],
      final List<String> allTags = const [],
      final List<LibraryCategory> categories = const [],
      final List<LibraryCategory> categoryTree = const [],
      this.selectedCategoryId,
      this.searchQuery = '',
      this.sortBy = 'fileName',
      this.sortDesc = false,
      this.isLoading = false,
      this.isBatchMode = false,
      final Set<String> selectedItems = const {},
      this.isDetailOpen = false,
      this.errorMessage,
      this.totalCount = 0,
      this.currentPage = 1,
      this.pageSize = 20,
      this.viewMode = ViewMode.grid,
      this.selectedItem,
      this.typeFilter,
      this.showFavoritesOnly = false,
      this.formatFilter,
      this.minWidth,
      this.maxWidth,
      this.minHeight,
      this.maxHeight,
      this.minSize,
      this.maxSize,
      this.createStartDate,
      this.createEndDate,
      this.updateStartDate,
      this.updateEndDate,
      this.showFilterPanel = true,
      final Map<String, int> categoryItemCounts = const {}})
      : _items = items,
        _allTags = allTags,
        _categories = categories,
        _categoryTree = categoryTree,
        _selectedItems = selectedItems,
        _categoryItemCounts = categoryItemCounts;

  /// 图库项目列表
  final List<LibraryItem> _items;

  /// 图库项目列表
  @override
  @JsonKey()
  List<LibraryItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  /// 所有标签
  final List<String> _allTags;

  /// 所有标签
  @override
  @JsonKey()
  List<String> get allTags {
    if (_allTags is EqualUnmodifiableListView) return _allTags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_allTags);
  }

  /// 分类列表
  final List<LibraryCategory> _categories;

  /// 分类列表
  @override
  @JsonKey()
  List<LibraryCategory> get categories {
    if (_categories is EqualUnmodifiableListView) return _categories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_categories);
  }

  /// 分类树
  final List<LibraryCategory> _categoryTree;

  /// 分类树
  @override
  @JsonKey()
  List<LibraryCategory> get categoryTree {
    if (_categoryTree is EqualUnmodifiableListView) return _categoryTree;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_categoryTree);
  }

  /// 当前选中的分类ID
  @override
  final String? selectedCategoryId;

  /// 搜索关键词
  @override
  @JsonKey()
  final String searchQuery;

  /// 排序字段
  @override
  @JsonKey()
  final String sortBy;

  /// 是否降序排序
  @override
  @JsonKey()
  final bool sortDesc;

  /// 是否正在加载
  @override
  @JsonKey()
  final bool isLoading;

  /// 是否处于批量选择模式
  @override
  @JsonKey()
  final bool isBatchMode;

  /// 选中的项目ID集合
  final Set<String> _selectedItems;

  /// 选中的项目ID集合
  @override
  @JsonKey()
  Set<String> get selectedItems {
    if (_selectedItems is EqualUnmodifiableSetView) return _selectedItems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_selectedItems);
  }

  /// 是否显示详情面板
  @override
  @JsonKey()
  final bool isDetailOpen;

  /// 错误信息
  @override
  final String? errorMessage;

  /// 总数量
  @override
  @JsonKey()
  final int totalCount;

  /// 当前页码
  @override
  @JsonKey()
  final int currentPage;

  /// 每页数量
  @override
  @JsonKey()
  final int pageSize;

  /// 视图模式
  @override
  @JsonKey()
  final ViewMode viewMode;

  /// 选中的项目
  @override
  final LibraryItem? selectedItem;

  /// 类型筛选
  @override
  final String? typeFilter;

  /// 是否只显示收藏
  @override
  @JsonKey()
  final bool showFavoritesOnly;

  /// 图片后缀筛选
  @override
  final String? formatFilter;

  /// 最小宽度筛选
  @override
  final int? minWidth;

  /// 最大宽度筛选
  @override
  final int? maxWidth;

  /// 最小高度筛选
  @override
  final int? minHeight;

  /// 最大高度筛选
  @override
  final int? maxHeight;

  /// 最小文件大小筛选（字节）
  @override
  final int? minSize;

  /// 最大文件大小筛选（字节）
  @override
  final int? maxSize;

  /// 入库开始日期
  @override
  final DateTime? createStartDate;

  /// 入库结束日期
  @override
  final DateTime? createEndDate;

  /// 更新开始日期
  @override
  final DateTime? updateStartDate;

  /// 更新结束日期
  @override
  final DateTime? updateEndDate;

  /// 是否显示筛选面板
  @override
  @JsonKey()
  final bool showFilterPanel;

  /// 分类项目计数
  final Map<String, int> _categoryItemCounts;

  /// 分类项目计数
  @override
  @JsonKey()
  Map<String, int> get categoryItemCounts {
    if (_categoryItemCounts is EqualUnmodifiableMapView)
      return _categoryItemCounts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_categoryItemCounts);
  }

  @override
  String toString() {
    return 'LibraryManagementState(items: $items, allTags: $allTags, categories: $categories, categoryTree: $categoryTree, selectedCategoryId: $selectedCategoryId, searchQuery: $searchQuery, sortBy: $sortBy, sortDesc: $sortDesc, isLoading: $isLoading, isBatchMode: $isBatchMode, selectedItems: $selectedItems, isDetailOpen: $isDetailOpen, errorMessage: $errorMessage, totalCount: $totalCount, currentPage: $currentPage, pageSize: $pageSize, viewMode: $viewMode, selectedItem: $selectedItem, typeFilter: $typeFilter, showFavoritesOnly: $showFavoritesOnly, formatFilter: $formatFilter, minWidth: $minWidth, maxWidth: $maxWidth, minHeight: $minHeight, maxHeight: $maxHeight, minSize: $minSize, maxSize: $maxSize, createStartDate: $createStartDate, createEndDate: $createEndDate, updateStartDate: $updateStartDate, updateEndDate: $updateEndDate, showFilterPanel: $showFilterPanel, categoryItemCounts: $categoryItemCounts)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LibraryManagementStateImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            const DeepCollectionEquality().equals(other._allTags, _allTags) &&
            const DeepCollectionEquality()
                .equals(other._categories, _categories) &&
            const DeepCollectionEquality()
                .equals(other._categoryTree, _categoryTree) &&
            (identical(other.selectedCategoryId, selectedCategoryId) ||
                other.selectedCategoryId == selectedCategoryId) &&
            (identical(other.searchQuery, searchQuery) ||
                other.searchQuery == searchQuery) &&
            (identical(other.sortBy, sortBy) || other.sortBy == sortBy) &&
            (identical(other.sortDesc, sortDesc) ||
                other.sortDesc == sortDesc) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isBatchMode, isBatchMode) ||
                other.isBatchMode == isBatchMode) &&
            const DeepCollectionEquality()
                .equals(other._selectedItems, _selectedItems) &&
            (identical(other.isDetailOpen, isDetailOpen) ||
                other.isDetailOpen == isDetailOpen) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.totalCount, totalCount) ||
                other.totalCount == totalCount) &&
            (identical(other.currentPage, currentPage) ||
                other.currentPage == currentPage) &&
            (identical(other.pageSize, pageSize) ||
                other.pageSize == pageSize) &&
            (identical(other.viewMode, viewMode) ||
                other.viewMode == viewMode) &&
            (identical(other.selectedItem, selectedItem) ||
                other.selectedItem == selectedItem) &&
            (identical(other.typeFilter, typeFilter) ||
                other.typeFilter == typeFilter) &&
            (identical(other.showFavoritesOnly, showFavoritesOnly) ||
                other.showFavoritesOnly == showFavoritesOnly) &&
            (identical(other.formatFilter, formatFilter) ||
                other.formatFilter == formatFilter) &&
            (identical(other.minWidth, minWidth) ||
                other.minWidth == minWidth) &&
            (identical(other.maxWidth, maxWidth) ||
                other.maxWidth == maxWidth) &&
            (identical(other.minHeight, minHeight) ||
                other.minHeight == minHeight) &&
            (identical(other.maxHeight, maxHeight) ||
                other.maxHeight == maxHeight) &&
            (identical(other.minSize, minSize) || other.minSize == minSize) &&
            (identical(other.maxSize, maxSize) || other.maxSize == maxSize) &&
            (identical(other.createStartDate, createStartDate) ||
                other.createStartDate == createStartDate) &&
            (identical(other.createEndDate, createEndDate) ||
                other.createEndDate == createEndDate) &&
            (identical(other.updateStartDate, updateStartDate) ||
                other.updateStartDate == updateStartDate) &&
            (identical(other.updateEndDate, updateEndDate) ||
                other.updateEndDate == updateEndDate) &&
            (identical(other.showFilterPanel, showFilterPanel) ||
                other.showFilterPanel == showFilterPanel) &&
            const DeepCollectionEquality()
                .equals(other._categoryItemCounts, _categoryItemCounts));
  }

  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        const DeepCollectionEquality().hash(_items),
        const DeepCollectionEquality().hash(_allTags),
        const DeepCollectionEquality().hash(_categories),
        const DeepCollectionEquality().hash(_categoryTree),
        selectedCategoryId,
        searchQuery,
        sortBy,
        sortDesc,
        isLoading,
        isBatchMode,
        const DeepCollectionEquality().hash(_selectedItems),
        isDetailOpen,
        errorMessage,
        totalCount,
        currentPage,
        pageSize,
        viewMode,
        selectedItem,
        typeFilter,
        showFavoritesOnly,
        formatFilter,
        minWidth,
        maxWidth,
        minHeight,
        maxHeight,
        minSize,
        maxSize,
        createStartDate,
        createEndDate,
        updateStartDate,
        updateEndDate,
        showFilterPanel,
        const DeepCollectionEquality().hash(_categoryItemCounts)
      ]);

  /// Create a copy of LibraryManagementState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LibraryManagementStateImplCopyWith<_$LibraryManagementStateImpl>
      get copyWith => __$$LibraryManagementStateImplCopyWithImpl<
          _$LibraryManagementStateImpl>(this, _$identity);
}

abstract class _LibraryManagementState implements LibraryManagementState {
  const factory _LibraryManagementState(
          {final List<LibraryItem> items,
          final List<String> allTags,
          final List<LibraryCategory> categories,
          final List<LibraryCategory> categoryTree,
          final String? selectedCategoryId,
          final String searchQuery,
          final String sortBy,
          final bool sortDesc,
          final bool isLoading,
          final bool isBatchMode,
          final Set<String> selectedItems,
          final bool isDetailOpen,
          final String? errorMessage,
          final int totalCount,
          final int currentPage,
          final int pageSize,
          final ViewMode viewMode,
          final LibraryItem? selectedItem,
          final String? typeFilter,
          final bool showFavoritesOnly,
          final String? formatFilter,
          final int? minWidth,
          final int? maxWidth,
          final int? minHeight,
          final int? maxHeight,
          final int? minSize,
          final int? maxSize,
          final DateTime? createStartDate,
          final DateTime? createEndDate,
          final DateTime? updateStartDate,
          final DateTime? updateEndDate,
          final bool showFilterPanel,
          final Map<String, int> categoryItemCounts}) =
      _$LibraryManagementStateImpl;

  /// 图库项目列表
  @override
  List<LibraryItem> get items;

  /// 所有标签
  @override
  List<String> get allTags;

  /// 分类列表
  @override
  List<LibraryCategory> get categories;

  /// 分类树
  @override
  List<LibraryCategory> get categoryTree;

  /// 当前选中的分类ID
  @override
  String? get selectedCategoryId;

  /// 搜索关键词
  @override
  String get searchQuery;

  /// 排序字段
  @override
  String get sortBy;

  /// 是否降序排序
  @override
  bool get sortDesc;

  /// 是否正在加载
  @override
  bool get isLoading;

  /// 是否处于批量选择模式
  @override
  bool get isBatchMode;

  /// 选中的项目ID集合
  @override
  Set<String> get selectedItems;

  /// 是否显示详情面板
  @override
  bool get isDetailOpen;

  /// 错误信息
  @override
  String? get errorMessage;

  /// 总数量
  @override
  int get totalCount;

  /// 当前页码
  @override
  int get currentPage;

  /// 每页数量
  @override
  int get pageSize;

  /// 视图模式
  @override
  ViewMode get viewMode;

  /// 选中的项目
  @override
  LibraryItem? get selectedItem;

  /// 类型筛选
  @override
  String? get typeFilter;

  /// 是否只显示收藏
  @override
  bool get showFavoritesOnly;

  /// 图片后缀筛选
  @override
  String? get formatFilter;

  /// 最小宽度筛选
  @override
  int? get minWidth;

  /// 最大宽度筛选
  @override
  int? get maxWidth;

  /// 最小高度筛选
  @override
  int? get minHeight;

  /// 最大高度筛选
  @override
  int? get maxHeight;

  /// 最小文件大小筛选（字节）
  @override
  int? get minSize;

  /// 最大文件大小筛选（字节）
  @override
  int? get maxSize;

  /// 入库开始日期
  @override
  DateTime? get createStartDate;

  /// 入库结束日期
  @override
  DateTime? get createEndDate;

  /// 更新开始日期
  @override
  DateTime? get updateStartDate;

  /// 更新结束日期
  @override
  DateTime? get updateEndDate;

  /// 是否显示筛选面板
  @override
  bool get showFilterPanel;

  /// 分类项目计数
  @override
  Map<String, int> get categoryItemCounts;

  /// Create a copy of LibraryManagementState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LibraryManagementStateImplCopyWith<_$LibraryManagementStateImpl>
      get copyWith => throw _privateConstructorUsedError;
}
