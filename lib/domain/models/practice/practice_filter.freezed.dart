// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'practice_filter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PracticeFilter _$PracticeFilterFromJson(Map<String, dynamic> json) {
  return _PracticeFilter.fromJson(json);
}

/// @nodoc
mixin _$PracticeFilter {
  /// 标题关键词
  String? get keyword => throw _privateConstructorUsedError;

  /// 标签列表
  List<String> get tags => throw _privateConstructorUsedError;

  /// 开始时间
  DateTime? get startTime => throw _privateConstructorUsedError;

  /// 结束时间
  DateTime? get endTime => throw _privateConstructorUsedError;

  /// 状态
  String? get status => throw _privateConstructorUsedError;

  /// 分页大小
  int get limit => throw _privateConstructorUsedError;

  /// 偏移量
  int get offset => throw _privateConstructorUsedError;

  /// 排序字段
  String get sortField => throw _privateConstructorUsedError;

  /// 排序方向(asc/desc)
  String get sortOrder => throw _privateConstructorUsedError;

  /// 是否只显示收藏
  bool get isFavorite => throw _privateConstructorUsedError;

  /// Serializes this PracticeFilter to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PracticeFilter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PracticeFilterCopyWith<PracticeFilter> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PracticeFilterCopyWith<$Res> {
  factory $PracticeFilterCopyWith(
          PracticeFilter value, $Res Function(PracticeFilter) then) =
      _$PracticeFilterCopyWithImpl<$Res, PracticeFilter>;
  @useResult
  $Res call(
      {String? keyword,
      List<String> tags,
      DateTime? startTime,
      DateTime? endTime,
      String? status,
      int limit,
      int offset,
      String sortField,
      String sortOrder,
      bool isFavorite});
}

/// @nodoc
class _$PracticeFilterCopyWithImpl<$Res, $Val extends PracticeFilter>
    implements $PracticeFilterCopyWith<$Res> {
  _$PracticeFilterCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PracticeFilter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? keyword = freezed,
    Object? tags = null,
    Object? startTime = freezed,
    Object? endTime = freezed,
    Object? status = freezed,
    Object? limit = null,
    Object? offset = null,
    Object? sortField = null,
    Object? sortOrder = null,
    Object? isFavorite = null,
  }) {
    return _then(_value.copyWith(
      keyword: freezed == keyword
          ? _value.keyword
          : keyword // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      startTime: freezed == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endTime: freezed == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      status: freezed == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String?,
      limit: null == limit
          ? _value.limit
          : limit // ignore: cast_nullable_to_non_nullable
              as int,
      offset: null == offset
          ? _value.offset
          : offset // ignore: cast_nullable_to_non_nullable
              as int,
      sortField: null == sortField
          ? _value.sortField
          : sortField // ignore: cast_nullable_to_non_nullable
              as String,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as String,
      isFavorite: null == isFavorite
          ? _value.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PracticeFilterImplCopyWith<$Res>
    implements $PracticeFilterCopyWith<$Res> {
  factory _$$PracticeFilterImplCopyWith(_$PracticeFilterImpl value,
          $Res Function(_$PracticeFilterImpl) then) =
      __$$PracticeFilterImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? keyword,
      List<String> tags,
      DateTime? startTime,
      DateTime? endTime,
      String? status,
      int limit,
      int offset,
      String sortField,
      String sortOrder,
      bool isFavorite});
}

/// @nodoc
class __$$PracticeFilterImplCopyWithImpl<$Res>
    extends _$PracticeFilterCopyWithImpl<$Res, _$PracticeFilterImpl>
    implements _$$PracticeFilterImplCopyWith<$Res> {
  __$$PracticeFilterImplCopyWithImpl(
      _$PracticeFilterImpl _value, $Res Function(_$PracticeFilterImpl) _then)
      : super(_value, _then);

  /// Create a copy of PracticeFilter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? keyword = freezed,
    Object? tags = null,
    Object? startTime = freezed,
    Object? endTime = freezed,
    Object? status = freezed,
    Object? limit = null,
    Object? offset = null,
    Object? sortField = null,
    Object? sortOrder = null,
    Object? isFavorite = null,
  }) {
    return _then(_$PracticeFilterImpl(
      keyword: freezed == keyword
          ? _value.keyword
          : keyword // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      startTime: freezed == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endTime: freezed == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      status: freezed == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String?,
      limit: null == limit
          ? _value.limit
          : limit // ignore: cast_nullable_to_non_nullable
              as int,
      offset: null == offset
          ? _value.offset
          : offset // ignore: cast_nullable_to_non_nullable
              as int,
      sortField: null == sortField
          ? _value.sortField
          : sortField // ignore: cast_nullable_to_non_nullable
              as String,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as String,
      isFavorite: null == isFavorite
          ? _value.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PracticeFilterImpl extends _PracticeFilter {
  const _$PracticeFilterImpl(
      {this.keyword,
      final List<String> tags = const [],
      this.startTime,
      this.endTime,
      this.status,
      this.limit = 20,
      this.offset = 0,
      this.sortField = 'updateTime',
      this.sortOrder = 'desc',
      this.isFavorite = false})
      : _tags = tags,
        super._();

  factory _$PracticeFilterImpl.fromJson(Map<String, dynamic> json) =>
      _$$PracticeFilterImplFromJson(json);

  /// 标题关键词
  @override
  final String? keyword;

  /// 标签列表
  final List<String> _tags;

  /// 标签列表
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  /// 开始时间
  @override
  final DateTime? startTime;

  /// 结束时间
  @override
  final DateTime? endTime;

  /// 状态
  @override
  final String? status;

  /// 分页大小
  @override
  @JsonKey()
  final int limit;

  /// 偏移量
  @override
  @JsonKey()
  final int offset;

  /// 排序字段
  @override
  @JsonKey()
  final String sortField;

  /// 排序方向(asc/desc)
  @override
  @JsonKey()
  final String sortOrder;

  /// 是否只显示收藏
  @override
  @JsonKey()
  final bool isFavorite;

  @override
  String toString() {
    return 'PracticeFilter(keyword: $keyword, tags: $tags, startTime: $startTime, endTime: $endTime, status: $status, limit: $limit, offset: $offset, sortField: $sortField, sortOrder: $sortOrder, isFavorite: $isFavorite)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PracticeFilterImpl &&
            (identical(other.keyword, keyword) || other.keyword == keyword) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.limit, limit) || other.limit == limit) &&
            (identical(other.offset, offset) || other.offset == offset) &&
            (identical(other.sortField, sortField) ||
                other.sortField == sortField) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.isFavorite, isFavorite) ||
                other.isFavorite == isFavorite));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      keyword,
      const DeepCollectionEquality().hash(_tags),
      startTime,
      endTime,
      status,
      limit,
      offset,
      sortField,
      sortOrder,
      isFavorite);

  /// Create a copy of PracticeFilter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PracticeFilterImplCopyWith<_$PracticeFilterImpl> get copyWith =>
      __$$PracticeFilterImplCopyWithImpl<_$PracticeFilterImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PracticeFilterImplToJson(
      this,
    );
  }
}

abstract class _PracticeFilter extends PracticeFilter {
  const factory _PracticeFilter(
      {final String? keyword,
      final List<String> tags,
      final DateTime? startTime,
      final DateTime? endTime,
      final String? status,
      final int limit,
      final int offset,
      final String sortField,
      final String sortOrder,
      final bool isFavorite}) = _$PracticeFilterImpl;
  const _PracticeFilter._() : super._();

  factory _PracticeFilter.fromJson(Map<String, dynamic> json) =
      _$PracticeFilterImpl.fromJson;

  /// 标题关键词
  @override
  String? get keyword;

  /// 标签列表
  @override
  List<String> get tags;

  /// 开始时间
  @override
  DateTime? get startTime;

  /// 结束时间
  @override
  DateTime? get endTime;

  /// 状态
  @override
  String? get status;

  /// 分页大小
  @override
  int get limit;

  /// 偏移量
  @override
  int get offset;

  /// 排序字段
  @override
  String get sortField;

  /// 排序方向(asc/desc)
  @override
  String get sortOrder;

  /// 是否只显示收藏
  @override
  bool get isFavorite;

  /// Create a copy of PracticeFilter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PracticeFilterImplCopyWith<_$PracticeFilterImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
