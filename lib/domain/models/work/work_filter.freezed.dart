// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'work_filter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

WorkFilter _$WorkFilterFromJson(Map<String, dynamic> json) {
  return _WorkFilter.fromJson(json);
}

/// @nodoc
mixin _$WorkFilter {
  /// 搜索关键字
  String? get keyword => throw _privateConstructorUsedError;

  /// 作品风格
  @JsonKey(fromJson: _workStyleFilterFromJson, toJson: _workStyleToJson)
  WorkStyle? get style => throw _privateConstructorUsedError;

  /// 创作工具
  @JsonKey(fromJson: _workToolFilterFromJson, toJson: _workToolToJson)
  WorkTool? get tool => throw _privateConstructorUsedError;

  /// 标签
  List<String> get tags => throw _privateConstructorUsedError;

  /// 创作日期区间
  @JsonKey(fromJson: _dateRangeFromJson, toJson: _dateRangeToJson)
  DateTimeRange? get dateRange => throw _privateConstructorUsedError;

  /// 创建时间区间
  @JsonKey(
      name: 'create_time_range',
      fromJson: _dateRangeFromJson,
      toJson: _dateRangeToJson)
  DateTimeRange? get createTimeRange => throw _privateConstructorUsedError;

  /// 修改时间区间
  @JsonKey(
      name: 'update_time_range',
      fromJson: _dateRangeFromJson,
      toJson: _dateRangeToJson)
  DateTimeRange? get updateTimeRange => throw _privateConstructorUsedError;

  /// 日期预设
  @JsonKey(fromJson: _dateRangePresetFromJson, toJson: _dateRangePresetToJson)
  DateRangePreset get datePreset => throw _privateConstructorUsedError;

  /// 排序选项
  SortOption get sortOption => throw _privateConstructorUsedError;

  /// Serializes this WorkFilter to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WorkFilter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WorkFilterCopyWith<WorkFilter> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkFilterCopyWith<$Res> {
  factory $WorkFilterCopyWith(
          WorkFilter value, $Res Function(WorkFilter) then) =
      _$WorkFilterCopyWithImpl<$Res, WorkFilter>;
  @useResult
  $Res call(
      {String? keyword,
      @JsonKey(fromJson: _workStyleFilterFromJson, toJson: _workStyleToJson)
      WorkStyle? style,
      @JsonKey(fromJson: _workToolFilterFromJson, toJson: _workToolToJson)
      WorkTool? tool,
      List<String> tags,
      @JsonKey(fromJson: _dateRangeFromJson, toJson: _dateRangeToJson)
      DateTimeRange? dateRange,
      @JsonKey(
          name: 'create_time_range',
          fromJson: _dateRangeFromJson,
          toJson: _dateRangeToJson)
      DateTimeRange? createTimeRange,
      @JsonKey(
          name: 'update_time_range',
          fromJson: _dateRangeFromJson,
          toJson: _dateRangeToJson)
      DateTimeRange? updateTimeRange,
      @JsonKey(
          fromJson: _dateRangePresetFromJson, toJson: _dateRangePresetToJson)
      DateRangePreset datePreset,
      SortOption sortOption});

  $SortOptionCopyWith<$Res> get sortOption;
}

/// @nodoc
class _$WorkFilterCopyWithImpl<$Res, $Val extends WorkFilter>
    implements $WorkFilterCopyWith<$Res> {
  _$WorkFilterCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WorkFilter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? keyword = freezed,
    Object? style = freezed,
    Object? tool = freezed,
    Object? tags = null,
    Object? dateRange = freezed,
    Object? createTimeRange = freezed,
    Object? updateTimeRange = freezed,
    Object? datePreset = null,
    Object? sortOption = null,
  }) {
    return _then(_value.copyWith(
      keyword: freezed == keyword
          ? _value.keyword
          : keyword // ignore: cast_nullable_to_non_nullable
              as String?,
      style: freezed == style
          ? _value.style
          : style // ignore: cast_nullable_to_non_nullable
              as WorkStyle?,
      tool: freezed == tool
          ? _value.tool
          : tool // ignore: cast_nullable_to_non_nullable
              as WorkTool?,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      dateRange: freezed == dateRange
          ? _value.dateRange
          : dateRange // ignore: cast_nullable_to_non_nullable
              as DateTimeRange?,
      createTimeRange: freezed == createTimeRange
          ? _value.createTimeRange
          : createTimeRange // ignore: cast_nullable_to_non_nullable
              as DateTimeRange?,
      updateTimeRange: freezed == updateTimeRange
          ? _value.updateTimeRange
          : updateTimeRange // ignore: cast_nullable_to_non_nullable
              as DateTimeRange?,
      datePreset: null == datePreset
          ? _value.datePreset
          : datePreset // ignore: cast_nullable_to_non_nullable
              as DateRangePreset,
      sortOption: null == sortOption
          ? _value.sortOption
          : sortOption // ignore: cast_nullable_to_non_nullable
              as SortOption,
    ) as $Val);
  }

  /// Create a copy of WorkFilter
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
abstract class _$$WorkFilterImplCopyWith<$Res>
    implements $WorkFilterCopyWith<$Res> {
  factory _$$WorkFilterImplCopyWith(
          _$WorkFilterImpl value, $Res Function(_$WorkFilterImpl) then) =
      __$$WorkFilterImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? keyword,
      @JsonKey(fromJson: _workStyleFilterFromJson, toJson: _workStyleToJson)
      WorkStyle? style,
      @JsonKey(fromJson: _workToolFilterFromJson, toJson: _workToolToJson)
      WorkTool? tool,
      List<String> tags,
      @JsonKey(fromJson: _dateRangeFromJson, toJson: _dateRangeToJson)
      DateTimeRange? dateRange,
      @JsonKey(
          name: 'create_time_range',
          fromJson: _dateRangeFromJson,
          toJson: _dateRangeToJson)
      DateTimeRange? createTimeRange,
      @JsonKey(
          name: 'update_time_range',
          fromJson: _dateRangeFromJson,
          toJson: _dateRangeToJson)
      DateTimeRange? updateTimeRange,
      @JsonKey(
          fromJson: _dateRangePresetFromJson, toJson: _dateRangePresetToJson)
      DateRangePreset datePreset,
      SortOption sortOption});

  @override
  $SortOptionCopyWith<$Res> get sortOption;
}

/// @nodoc
class __$$WorkFilterImplCopyWithImpl<$Res>
    extends _$WorkFilterCopyWithImpl<$Res, _$WorkFilterImpl>
    implements _$$WorkFilterImplCopyWith<$Res> {
  __$$WorkFilterImplCopyWithImpl(
      _$WorkFilterImpl _value, $Res Function(_$WorkFilterImpl) _then)
      : super(_value, _then);

  /// Create a copy of WorkFilter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? keyword = freezed,
    Object? style = freezed,
    Object? tool = freezed,
    Object? tags = null,
    Object? dateRange = freezed,
    Object? createTimeRange = freezed,
    Object? updateTimeRange = freezed,
    Object? datePreset = null,
    Object? sortOption = null,
  }) {
    return _then(_$WorkFilterImpl(
      keyword: freezed == keyword
          ? _value.keyword
          : keyword // ignore: cast_nullable_to_non_nullable
              as String?,
      style: freezed == style
          ? _value.style
          : style // ignore: cast_nullable_to_non_nullable
              as WorkStyle?,
      tool: freezed == tool
          ? _value.tool
          : tool // ignore: cast_nullable_to_non_nullable
              as WorkTool?,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      dateRange: freezed == dateRange
          ? _value.dateRange
          : dateRange // ignore: cast_nullable_to_non_nullable
              as DateTimeRange?,
      createTimeRange: freezed == createTimeRange
          ? _value.createTimeRange
          : createTimeRange // ignore: cast_nullable_to_non_nullable
              as DateTimeRange?,
      updateTimeRange: freezed == updateTimeRange
          ? _value.updateTimeRange
          : updateTimeRange // ignore: cast_nullable_to_non_nullable
              as DateTimeRange?,
      datePreset: null == datePreset
          ? _value.datePreset
          : datePreset // ignore: cast_nullable_to_non_nullable
              as DateRangePreset,
      sortOption: null == sortOption
          ? _value.sortOption
          : sortOption // ignore: cast_nullable_to_non_nullable
              as SortOption,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkFilterImpl extends _WorkFilter {
  const _$WorkFilterImpl(
      {this.keyword,
      @JsonKey(fromJson: _workStyleFilterFromJson, toJson: _workStyleToJson)
      this.style,
      @JsonKey(fromJson: _workToolFilterFromJson, toJson: _workToolToJson)
      this.tool,
      final List<String> tags = const [],
      @JsonKey(fromJson: _dateRangeFromJson, toJson: _dateRangeToJson)
      this.dateRange,
      @JsonKey(
          name: 'create_time_range',
          fromJson: _dateRangeFromJson,
          toJson: _dateRangeToJson)
      this.createTimeRange,
      @JsonKey(
          name: 'update_time_range',
          fromJson: _dateRangeFromJson,
          toJson: _dateRangeToJson)
      this.updateTimeRange,
      @JsonKey(
          fromJson: _dateRangePresetFromJson, toJson: _dateRangePresetToJson)
      this.datePreset = DateRangePreset.all,
      this.sortOption = const SortOption()})
      : _tags = tags,
        super._();

  factory _$WorkFilterImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkFilterImplFromJson(json);

  /// 搜索关键字
  @override
  final String? keyword;

  /// 作品风格
  @override
  @JsonKey(fromJson: _workStyleFilterFromJson, toJson: _workStyleToJson)
  final WorkStyle? style;

  /// 创作工具
  @override
  @JsonKey(fromJson: _workToolFilterFromJson, toJson: _workToolToJson)
  final WorkTool? tool;

  /// 标签
  final List<String> _tags;

  /// 标签
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  /// 创作日期区间
  @override
  @JsonKey(fromJson: _dateRangeFromJson, toJson: _dateRangeToJson)
  final DateTimeRange? dateRange;

  /// 创建时间区间
  @override
  @JsonKey(
      name: 'create_time_range',
      fromJson: _dateRangeFromJson,
      toJson: _dateRangeToJson)
  final DateTimeRange? createTimeRange;

  /// 修改时间区间
  @override
  @JsonKey(
      name: 'update_time_range',
      fromJson: _dateRangeFromJson,
      toJson: _dateRangeToJson)
  final DateTimeRange? updateTimeRange;

  /// 日期预设
  @override
  @JsonKey(fromJson: _dateRangePresetFromJson, toJson: _dateRangePresetToJson)
  final DateRangePreset datePreset;

  /// 排序选项
  @override
  @JsonKey()
  final SortOption sortOption;

  @override
  String toString() {
    return 'WorkFilter(keyword: $keyword, style: $style, tool: $tool, tags: $tags, dateRange: $dateRange, createTimeRange: $createTimeRange, updateTimeRange: $updateTimeRange, datePreset: $datePreset, sortOption: $sortOption)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkFilterImpl &&
            (identical(other.keyword, keyword) || other.keyword == keyword) &&
            (identical(other.style, style) || other.style == style) &&
            (identical(other.tool, tool) || other.tool == tool) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.dateRange, dateRange) ||
                other.dateRange == dateRange) &&
            (identical(other.createTimeRange, createTimeRange) ||
                other.createTimeRange == createTimeRange) &&
            (identical(other.updateTimeRange, updateTimeRange) ||
                other.updateTimeRange == updateTimeRange) &&
            (identical(other.datePreset, datePreset) ||
                other.datePreset == datePreset) &&
            (identical(other.sortOption, sortOption) ||
                other.sortOption == sortOption));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      keyword,
      style,
      tool,
      const DeepCollectionEquality().hash(_tags),
      dateRange,
      createTimeRange,
      updateTimeRange,
      datePreset,
      sortOption);

  /// Create a copy of WorkFilter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkFilterImplCopyWith<_$WorkFilterImpl> get copyWith =>
      __$$WorkFilterImplCopyWithImpl<_$WorkFilterImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkFilterImplToJson(
      this,
    );
  }
}

abstract class _WorkFilter extends WorkFilter {
  const factory _WorkFilter(
      {final String? keyword,
      @JsonKey(fromJson: _workStyleFilterFromJson, toJson: _workStyleToJson)
      final WorkStyle? style,
      @JsonKey(fromJson: _workToolFilterFromJson, toJson: _workToolToJson)
      final WorkTool? tool,
      final List<String> tags,
      @JsonKey(fromJson: _dateRangeFromJson, toJson: _dateRangeToJson)
      final DateTimeRange? dateRange,
      @JsonKey(
          name: 'create_time_range',
          fromJson: _dateRangeFromJson,
          toJson: _dateRangeToJson)
      final DateTimeRange? createTimeRange,
      @JsonKey(
          name: 'update_time_range',
          fromJson: _dateRangeFromJson,
          toJson: _dateRangeToJson)
      final DateTimeRange? updateTimeRange,
      @JsonKey(
          fromJson: _dateRangePresetFromJson, toJson: _dateRangePresetToJson)
      final DateRangePreset datePreset,
      final SortOption sortOption}) = _$WorkFilterImpl;
  const _WorkFilter._() : super._();

  factory _WorkFilter.fromJson(Map<String, dynamic> json) =
      _$WorkFilterImpl.fromJson;

  /// 搜索关键字
  @override
  String? get keyword;

  /// 作品风格
  @override
  @JsonKey(fromJson: _workStyleFilterFromJson, toJson: _workStyleToJson)
  WorkStyle? get style;

  /// 创作工具
  @override
  @JsonKey(fromJson: _workToolFilterFromJson, toJson: _workToolToJson)
  WorkTool? get tool;

  /// 标签
  @override
  List<String> get tags;

  /// 创作日期区间
  @override
  @JsonKey(fromJson: _dateRangeFromJson, toJson: _dateRangeToJson)
  DateTimeRange? get dateRange;

  /// 创建时间区间
  @override
  @JsonKey(
      name: 'create_time_range',
      fromJson: _dateRangeFromJson,
      toJson: _dateRangeToJson)
  DateTimeRange? get createTimeRange;

  /// 修改时间区间
  @override
  @JsonKey(
      name: 'update_time_range',
      fromJson: _dateRangeFromJson,
      toJson: _dateRangeToJson)
  DateTimeRange? get updateTimeRange;

  /// 日期预设
  @override
  @JsonKey(fromJson: _dateRangePresetFromJson, toJson: _dateRangePresetToJson)
  DateRangePreset get datePreset;

  /// 排序选项
  @override
  SortOption get sortOption;

  /// Create a copy of WorkFilter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WorkFilterImplCopyWith<_$WorkFilterImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
