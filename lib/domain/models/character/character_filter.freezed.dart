// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'character_filter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CharacterFilter _$CharacterFilterFromJson(Map<String, dynamic> json) {
  return _CharacterFilter.fromJson(json);
}

/// @nodoc
mixin _$CharacterFilter {
  /// 搜索文本（对应简体字、作品名称、作者等）
  String? get searchText => throw _privateConstructorUsedError;

  /// 是否仅显示收藏的字符
  bool? get isFavorite => throw _privateConstructorUsedError;

  /// 作品ID筛选
  String? get workId => throw _privateConstructorUsedError;
  String? get pageId => throw _privateConstructorUsedError;

  /// 作品风格
  @JsonKey(fromJson: _workStyleFilterFromJson, toJson: _workStyleToJson)
  String? get style => throw _privateConstructorUsedError;

  /// 创作工具
  @JsonKey(fromJson: _workToolFilterFromJson, toJson: _workToolToJson)
  String? get tool => throw _privateConstructorUsedError;

  /// 创作时间筛选预设
  @JsonKey(fromJson: _dateRangePresetFromJson, toJson: _dateRangePresetToJson)
  DateRangePreset get creationDatePreset => throw _privateConstructorUsedError;

  /// 创作时间范围（自定义时间段）
  @JsonKey(fromJson: _dateRangeFromJson, toJson: _dateRangeToJson)
  DateTimeRange? get creationDateRange => throw _privateConstructorUsedError;

  /// 收集时间筛选预设
  @JsonKey(fromJson: _dateRangePresetFromJson, toJson: _dateRangePresetToJson)
  DateRangePreset get collectionDatePreset =>
      throw _privateConstructorUsedError;

  /// 收集时间范围（自定义时间段）
  @JsonKey(fromJson: _dateRangeFromJson, toJson: _dateRangeToJson)
  DateTimeRange? get collectionDateRange => throw _privateConstructorUsedError;

  /// 标签筛选
  List<String> get tags => throw _privateConstructorUsedError;

  /// 排序选项
  SortOption get sortOption => throw _privateConstructorUsedError;

  /// 分页限制
  int? get limit => throw _privateConstructorUsedError;

  /// 分页偏移
  int? get offset => throw _privateConstructorUsedError;

  /// Serializes this CharacterFilter to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CharacterFilter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CharacterFilterCopyWith<CharacterFilter> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CharacterFilterCopyWith<$Res> {
  factory $CharacterFilterCopyWith(
          CharacterFilter value, $Res Function(CharacterFilter) then) =
      _$CharacterFilterCopyWithImpl<$Res, CharacterFilter>;
  @useResult
  $Res call(
      {String? searchText,
      bool? isFavorite,
      String? workId,
      String? pageId,
      @JsonKey(fromJson: _workStyleFilterFromJson, toJson: _workStyleToJson)
      String? style,
      @JsonKey(fromJson: _workToolFilterFromJson, toJson: _workToolToJson)
      String? tool,
      @JsonKey(
          fromJson: _dateRangePresetFromJson, toJson: _dateRangePresetToJson)
      DateRangePreset creationDatePreset,
      @JsonKey(fromJson: _dateRangeFromJson, toJson: _dateRangeToJson)
      DateTimeRange? creationDateRange,
      @JsonKey(
          fromJson: _dateRangePresetFromJson, toJson: _dateRangePresetToJson)
      DateRangePreset collectionDatePreset,
      @JsonKey(fromJson: _dateRangeFromJson, toJson: _dateRangeToJson)
      DateTimeRange? collectionDateRange,
      List<String> tags,
      SortOption sortOption,
      int? limit,
      int? offset});

  $SortOptionCopyWith<$Res> get sortOption;
}

/// @nodoc
class _$CharacterFilterCopyWithImpl<$Res, $Val extends CharacterFilter>
    implements $CharacterFilterCopyWith<$Res> {
  _$CharacterFilterCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CharacterFilter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? searchText = freezed,
    Object? isFavorite = freezed,
    Object? workId = freezed,
    Object? pageId = freezed,
    Object? style = freezed,
    Object? tool = freezed,
    Object? creationDatePreset = null,
    Object? creationDateRange = freezed,
    Object? collectionDatePreset = null,
    Object? collectionDateRange = freezed,
    Object? tags = null,
    Object? sortOption = null,
    Object? limit = freezed,
    Object? offset = freezed,
  }) {
    return _then(_value.copyWith(
      searchText: freezed == searchText
          ? _value.searchText
          : searchText // ignore: cast_nullable_to_non_nullable
              as String?,
      isFavorite: freezed == isFavorite
          ? _value.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool?,
      workId: freezed == workId
          ? _value.workId
          : workId // ignore: cast_nullable_to_non_nullable
              as String?,
      pageId: freezed == pageId
          ? _value.pageId
          : pageId // ignore: cast_nullable_to_non_nullable
              as String?,
      style: freezed == style
          ? _value.style
          : style // ignore: cast_nullable_to_non_nullable
              as String?,
      tool: freezed == tool
          ? _value.tool
          : tool // ignore: cast_nullable_to_non_nullable
              as String?,
      creationDatePreset: null == creationDatePreset
          ? _value.creationDatePreset
          : creationDatePreset // ignore: cast_nullable_to_non_nullable
              as DateRangePreset,
      creationDateRange: freezed == creationDateRange
          ? _value.creationDateRange
          : creationDateRange // ignore: cast_nullable_to_non_nullable
              as DateTimeRange?,
      collectionDatePreset: null == collectionDatePreset
          ? _value.collectionDatePreset
          : collectionDatePreset // ignore: cast_nullable_to_non_nullable
              as DateRangePreset,
      collectionDateRange: freezed == collectionDateRange
          ? _value.collectionDateRange
          : collectionDateRange // ignore: cast_nullable_to_non_nullable
              as DateTimeRange?,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      sortOption: null == sortOption
          ? _value.sortOption
          : sortOption // ignore: cast_nullable_to_non_nullable
              as SortOption,
      limit: freezed == limit
          ? _value.limit
          : limit // ignore: cast_nullable_to_non_nullable
              as int?,
      offset: freezed == offset
          ? _value.offset
          : offset // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }

  /// Create a copy of CharacterFilter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SortOptionCopyWith<$Res> get sortOption {
    return $SortOptionCopyWith<$Res>(_value.sortOption, (value) {
      return _then(_value.copyWith(sortOption: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CharacterFilterImplCopyWith<$Res>
    implements $CharacterFilterCopyWith<$Res> {
  factory _$$CharacterFilterImplCopyWith(_$CharacterFilterImpl value,
          $Res Function(_$CharacterFilterImpl) then) =
      __$$CharacterFilterImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? searchText,
      bool? isFavorite,
      String? workId,
      String? pageId,
      @JsonKey(fromJson: _workStyleFilterFromJson, toJson: _workStyleToJson)
      String? style,
      @JsonKey(fromJson: _workToolFilterFromJson, toJson: _workToolToJson)
      String? tool,
      @JsonKey(
          fromJson: _dateRangePresetFromJson, toJson: _dateRangePresetToJson)
      DateRangePreset creationDatePreset,
      @JsonKey(fromJson: _dateRangeFromJson, toJson: _dateRangeToJson)
      DateTimeRange? creationDateRange,
      @JsonKey(
          fromJson: _dateRangePresetFromJson, toJson: _dateRangePresetToJson)
      DateRangePreset collectionDatePreset,
      @JsonKey(fromJson: _dateRangeFromJson, toJson: _dateRangeToJson)
      DateTimeRange? collectionDateRange,
      List<String> tags,
      SortOption sortOption,
      int? limit,
      int? offset});

  @override
  $SortOptionCopyWith<$Res> get sortOption;
}

/// @nodoc
class __$$CharacterFilterImplCopyWithImpl<$Res>
    extends _$CharacterFilterCopyWithImpl<$Res, _$CharacterFilterImpl>
    implements _$$CharacterFilterImplCopyWith<$Res> {
  __$$CharacterFilterImplCopyWithImpl(
      _$CharacterFilterImpl _value, $Res Function(_$CharacterFilterImpl) _then)
      : super(_value, _then);

  /// Create a copy of CharacterFilter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? searchText = freezed,
    Object? isFavorite = freezed,
    Object? workId = freezed,
    Object? pageId = freezed,
    Object? style = freezed,
    Object? tool = freezed,
    Object? creationDatePreset = null,
    Object? creationDateRange = freezed,
    Object? collectionDatePreset = null,
    Object? collectionDateRange = freezed,
    Object? tags = null,
    Object? sortOption = null,
    Object? limit = freezed,
    Object? offset = freezed,
  }) {
    return _then(_$CharacterFilterImpl(
      searchText: freezed == searchText
          ? _value.searchText
          : searchText // ignore: cast_nullable_to_non_nullable
              as String?,
      isFavorite: freezed == isFavorite
          ? _value.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool?,
      workId: freezed == workId
          ? _value.workId
          : workId // ignore: cast_nullable_to_non_nullable
              as String?,
      pageId: freezed == pageId
          ? _value.pageId
          : pageId // ignore: cast_nullable_to_non_nullable
              as String?,
      style: freezed == style
          ? _value.style
          : style // ignore: cast_nullable_to_non_nullable
              as String?,
      tool: freezed == tool
          ? _value.tool
          : tool // ignore: cast_nullable_to_non_nullable
              as String?,
      creationDatePreset: null == creationDatePreset
          ? _value.creationDatePreset
          : creationDatePreset // ignore: cast_nullable_to_non_nullable
              as DateRangePreset,
      creationDateRange: freezed == creationDateRange
          ? _value.creationDateRange
          : creationDateRange // ignore: cast_nullable_to_non_nullable
              as DateTimeRange?,
      collectionDatePreset: null == collectionDatePreset
          ? _value.collectionDatePreset
          : collectionDatePreset // ignore: cast_nullable_to_non_nullable
              as DateRangePreset,
      collectionDateRange: freezed == collectionDateRange
          ? _value.collectionDateRange
          : collectionDateRange // ignore: cast_nullable_to_non_nullable
              as DateTimeRange?,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      sortOption: null == sortOption
          ? _value.sortOption
          : sortOption // ignore: cast_nullable_to_non_nullable
              as SortOption,
      limit: freezed == limit
          ? _value.limit
          : limit // ignore: cast_nullable_to_non_nullable
              as int?,
      offset: freezed == offset
          ? _value.offset
          : offset // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CharacterFilterImpl extends _CharacterFilter {
  const _$CharacterFilterImpl(
      {this.searchText,
      this.isFavorite,
      this.workId,
      this.pageId,
      @JsonKey(fromJson: _workStyleFilterFromJson, toJson: _workStyleToJson)
      this.style,
      @JsonKey(fromJson: _workToolFilterFromJson, toJson: _workToolToJson)
      this.tool,
      @JsonKey(
          fromJson: _dateRangePresetFromJson, toJson: _dateRangePresetToJson)
      this.creationDatePreset = DateRangePreset.all,
      @JsonKey(fromJson: _dateRangeFromJson, toJson: _dateRangeToJson)
      this.creationDateRange,
      @JsonKey(
          fromJson: _dateRangePresetFromJson, toJson: _dateRangePresetToJson)
      this.collectionDatePreset = DateRangePreset.all,
      @JsonKey(fromJson: _dateRangeFromJson, toJson: _dateRangeToJson)
      this.collectionDateRange,
      final List<String> tags = const [],
      this.sortOption = const SortOption(),
      this.limit,
      this.offset})
      : _tags = tags,
        super._();

  factory _$CharacterFilterImpl.fromJson(Map<String, dynamic> json) =>
      _$$CharacterFilterImplFromJson(json);

  /// 搜索文本（对应简体字、作品名称、作者等）
  @override
  final String? searchText;

  /// 是否仅显示收藏的字符
  @override
  final bool? isFavorite;

  /// 作品ID筛选
  @override
  final String? workId;
  @override
  final String? pageId;

  /// 作品风格
  @override
  @JsonKey(fromJson: _workStyleFilterFromJson, toJson: _workStyleToJson)
  final String? style;

  /// 创作工具
  @override
  @JsonKey(fromJson: _workToolFilterFromJson, toJson: _workToolToJson)
  final String? tool;

  /// 创作时间筛选预设
  @override
  @JsonKey(fromJson: _dateRangePresetFromJson, toJson: _dateRangePresetToJson)
  final DateRangePreset creationDatePreset;

  /// 创作时间范围（自定义时间段）
  @override
  @JsonKey(fromJson: _dateRangeFromJson, toJson: _dateRangeToJson)
  final DateTimeRange? creationDateRange;

  /// 收集时间筛选预设
  @override
  @JsonKey(fromJson: _dateRangePresetFromJson, toJson: _dateRangePresetToJson)
  final DateRangePreset collectionDatePreset;

  /// 收集时间范围（自定义时间段）
  @override
  @JsonKey(fromJson: _dateRangeFromJson, toJson: _dateRangeToJson)
  final DateTimeRange? collectionDateRange;

  /// 标签筛选
  final List<String> _tags;

  /// 标签筛选
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  /// 排序选项
  @override
  @JsonKey()
  final SortOption sortOption;

  /// 分页限制
  @override
  final int? limit;

  /// 分页偏移
  @override
  final int? offset;

  @override
  String toString() {
    return 'CharacterFilter(searchText: $searchText, isFavorite: $isFavorite, workId: $workId, pageId: $pageId, style: $style, tool: $tool, creationDatePreset: $creationDatePreset, creationDateRange: $creationDateRange, collectionDatePreset: $collectionDatePreset, collectionDateRange: $collectionDateRange, tags: $tags, sortOption: $sortOption, limit: $limit, offset: $offset)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CharacterFilterImpl &&
            (identical(other.searchText, searchText) ||
                other.searchText == searchText) &&
            (identical(other.isFavorite, isFavorite) ||
                other.isFavorite == isFavorite) &&
            (identical(other.workId, workId) || other.workId == workId) &&
            (identical(other.pageId, pageId) || other.pageId == pageId) &&
            (identical(other.style, style) || other.style == style) &&
            (identical(other.tool, tool) || other.tool == tool) &&
            (identical(other.creationDatePreset, creationDatePreset) ||
                other.creationDatePreset == creationDatePreset) &&
            (identical(other.creationDateRange, creationDateRange) ||
                other.creationDateRange == creationDateRange) &&
            (identical(other.collectionDatePreset, collectionDatePreset) ||
                other.collectionDatePreset == collectionDatePreset) &&
            (identical(other.collectionDateRange, collectionDateRange) ||
                other.collectionDateRange == collectionDateRange) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.sortOption, sortOption) ||
                other.sortOption == sortOption) &&
            (identical(other.limit, limit) || other.limit == limit) &&
            (identical(other.offset, offset) || other.offset == offset));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      searchText,
      isFavorite,
      workId,
      pageId,
      style,
      tool,
      creationDatePreset,
      creationDateRange,
      collectionDatePreset,
      collectionDateRange,
      const DeepCollectionEquality().hash(_tags),
      sortOption,
      limit,
      offset);

  /// Create a copy of CharacterFilter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CharacterFilterImplCopyWith<_$CharacterFilterImpl> get copyWith =>
      __$$CharacterFilterImplCopyWithImpl<_$CharacterFilterImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CharacterFilterImplToJson(
      this,
    );
  }
}

abstract class _CharacterFilter extends CharacterFilter {
  const factory _CharacterFilter(
      {final String? searchText,
      final bool? isFavorite,
      final String? workId,
      final String? pageId,
      @JsonKey(fromJson: _workStyleFilterFromJson, toJson: _workStyleToJson)
      final String? style,
      @JsonKey(fromJson: _workToolFilterFromJson, toJson: _workToolToJson)
      final String? tool,
      @JsonKey(
          fromJson: _dateRangePresetFromJson, toJson: _dateRangePresetToJson)
      final DateRangePreset creationDatePreset,
      @JsonKey(fromJson: _dateRangeFromJson, toJson: _dateRangeToJson)
      final DateTimeRange? creationDateRange,
      @JsonKey(
          fromJson: _dateRangePresetFromJson, toJson: _dateRangePresetToJson)
      final DateRangePreset collectionDatePreset,
      @JsonKey(fromJson: _dateRangeFromJson, toJson: _dateRangeToJson)
      final DateTimeRange? collectionDateRange,
      final List<String> tags,
      final SortOption sortOption,
      final int? limit,
      final int? offset}) = _$CharacterFilterImpl;
  const _CharacterFilter._() : super._();

  factory _CharacterFilter.fromJson(Map<String, dynamic> json) =
      _$CharacterFilterImpl.fromJson;

  /// 搜索文本（对应简体字、作品名称、作者等）
  @override
  String? get searchText;

  /// 是否仅显示收藏的字符
  @override
  bool? get isFavorite;

  /// 作品ID筛选
  @override
  String? get workId;
  @override
  String? get pageId;

  /// 作品风格
  @override
  @JsonKey(fromJson: _workStyleFilterFromJson, toJson: _workStyleToJson)
  String? get style;

  /// 创作工具
  @override
  @JsonKey(fromJson: _workToolFilterFromJson, toJson: _workToolToJson)
  String? get tool;

  /// 创作时间筛选预设
  @override
  @JsonKey(fromJson: _dateRangePresetFromJson, toJson: _dateRangePresetToJson)
  DateRangePreset get creationDatePreset;

  /// 创作时间范围（自定义时间段）
  @override
  @JsonKey(fromJson: _dateRangeFromJson, toJson: _dateRangeToJson)
  DateTimeRange? get creationDateRange;

  /// 收集时间筛选预设
  @override
  @JsonKey(fromJson: _dateRangePresetFromJson, toJson: _dateRangePresetToJson)
  DateRangePreset get collectionDatePreset;

  /// 收集时间范围（自定义时间段）
  @override
  @JsonKey(fromJson: _dateRangeFromJson, toJson: _dateRangeToJson)
  DateTimeRange? get collectionDateRange;

  /// 标签筛选
  @override
  List<String> get tags;

  /// 排序选项
  @override
  SortOption get sortOption;

  /// 分页限制
  @override
  int? get limit;

  /// 分页偏移
  @override
  int? get offset;

  /// Create a copy of CharacterFilter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CharacterFilterImplCopyWith<_$CharacterFilterImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
