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
      LibraryItem? selectedItem});

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
      LibraryItem? selectedItem});

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
      this.sortBy = 'name',
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
      this.selectedItem})
      : _items = items,
        _allTags = allTags,
        _categories = categories,
        _categoryTree = categoryTree,
        _selectedItems = selectedItems;

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

  @override
  String toString() {
    return 'LibraryManagementState(items: $items, allTags: $allTags, categories: $categories, categoryTree: $categoryTree, selectedCategoryId: $selectedCategoryId, searchQuery: $searchQuery, sortBy: $sortBy, sortDesc: $sortDesc, isLoading: $isLoading, isBatchMode: $isBatchMode, selectedItems: $selectedItems, isDetailOpen: $isDetailOpen, errorMessage: $errorMessage, totalCount: $totalCount, currentPage: $currentPage, pageSize: $pageSize, viewMode: $viewMode, selectedItem: $selectedItem)';
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
                other.selectedItem == selectedItem));
  }

  @override
  int get hashCode => Object.hash(
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
      selectedItem);

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
      final LibraryItem? selectedItem}) = _$LibraryManagementStateImpl;

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

  /// Create a copy of LibraryManagementState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LibraryManagementStateImplCopyWith<_$LibraryManagementStateImpl>
      get copyWith => throw _privateConstructorUsedError;
}
