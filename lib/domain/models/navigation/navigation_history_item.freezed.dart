// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'navigation_history_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

NavigationHistoryItem _$NavigationHistoryItemFromJson(
    Map<String, dynamic> json) {
  return _NavigationHistoryItem.fromJson(json);
}

/// @nodoc
mixin _$NavigationHistoryItem {
  int get sectionIndex => throw _privateConstructorUsedError;
  String? get routePath => throw _privateConstructorUsedError;
  Map<String, dynamic>? get routeParams => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;

  /// Serializes this NavigationHistoryItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NavigationHistoryItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NavigationHistoryItemCopyWith<NavigationHistoryItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NavigationHistoryItemCopyWith<$Res> {
  factory $NavigationHistoryItemCopyWith(NavigationHistoryItem value,
          $Res Function(NavigationHistoryItem) then) =
      _$NavigationHistoryItemCopyWithImpl<$Res, NavigationHistoryItem>;
  @useResult
  $Res call(
      {int sectionIndex,
      String? routePath,
      Map<String, dynamic>? routeParams,
      DateTime timestamp});
}

/// @nodoc
class _$NavigationHistoryItemCopyWithImpl<$Res,
        $Val extends NavigationHistoryItem>
    implements $NavigationHistoryItemCopyWith<$Res> {
  _$NavigationHistoryItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NavigationHistoryItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sectionIndex = null,
    Object? routePath = freezed,
    Object? routeParams = freezed,
    Object? timestamp = null,
  }) {
    return _then(_value.copyWith(
      sectionIndex: null == sectionIndex
          ? _value.sectionIndex
          : sectionIndex // ignore: cast_nullable_to_non_nullable
              as int,
      routePath: freezed == routePath
          ? _value.routePath
          : routePath // ignore: cast_nullable_to_non_nullable
              as String?,
      routeParams: freezed == routeParams
          ? _value.routeParams
          : routeParams // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NavigationHistoryItemImplCopyWith<$Res>
    implements $NavigationHistoryItemCopyWith<$Res> {
  factory _$$NavigationHistoryItemImplCopyWith(
          _$NavigationHistoryItemImpl value,
          $Res Function(_$NavigationHistoryItemImpl) then) =
      __$$NavigationHistoryItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int sectionIndex,
      String? routePath,
      Map<String, dynamic>? routeParams,
      DateTime timestamp});
}

/// @nodoc
class __$$NavigationHistoryItemImplCopyWithImpl<$Res>
    extends _$NavigationHistoryItemCopyWithImpl<$Res,
        _$NavigationHistoryItemImpl>
    implements _$$NavigationHistoryItemImplCopyWith<$Res> {
  __$$NavigationHistoryItemImplCopyWithImpl(_$NavigationHistoryItemImpl _value,
      $Res Function(_$NavigationHistoryItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of NavigationHistoryItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sectionIndex = null,
    Object? routePath = freezed,
    Object? routeParams = freezed,
    Object? timestamp = null,
  }) {
    return _then(_$NavigationHistoryItemImpl(
      sectionIndex: null == sectionIndex
          ? _value.sectionIndex
          : sectionIndex // ignore: cast_nullable_to_non_nullable
              as int,
      routePath: freezed == routePath
          ? _value.routePath
          : routePath // ignore: cast_nullable_to_non_nullable
              as String?,
      routeParams: freezed == routeParams
          ? _value._routeParams
          : routeParams // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NavigationHistoryItemImpl implements _NavigationHistoryItem {
  const _$NavigationHistoryItemImpl(
      {required this.sectionIndex,
      this.routePath,
      final Map<String, dynamic>? routeParams,
      required this.timestamp})
      : _routeParams = routeParams;

  factory _$NavigationHistoryItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$NavigationHistoryItemImplFromJson(json);

  @override
  final int sectionIndex;
  @override
  final String? routePath;
  final Map<String, dynamic>? _routeParams;
  @override
  Map<String, dynamic>? get routeParams {
    final value = _routeParams;
    if (value == null) return null;
    if (_routeParams is EqualUnmodifiableMapView) return _routeParams;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final DateTime timestamp;

  @override
  String toString() {
    return 'NavigationHistoryItem(sectionIndex: $sectionIndex, routePath: $routePath, routeParams: $routeParams, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NavigationHistoryItemImpl &&
            (identical(other.sectionIndex, sectionIndex) ||
                other.sectionIndex == sectionIndex) &&
            (identical(other.routePath, routePath) ||
                other.routePath == routePath) &&
            const DeepCollectionEquality()
                .equals(other._routeParams, _routeParams) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, sectionIndex, routePath,
      const DeepCollectionEquality().hash(_routeParams), timestamp);

  /// Create a copy of NavigationHistoryItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NavigationHistoryItemImplCopyWith<_$NavigationHistoryItemImpl>
      get copyWith => __$$NavigationHistoryItemImplCopyWithImpl<
          _$NavigationHistoryItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NavigationHistoryItemImplToJson(
      this,
    );
  }
}

abstract class _NavigationHistoryItem implements NavigationHistoryItem {
  const factory _NavigationHistoryItem(
      {required final int sectionIndex,
      final String? routePath,
      final Map<String, dynamic>? routeParams,
      required final DateTime timestamp}) = _$NavigationHistoryItemImpl;

  factory _NavigationHistoryItem.fromJson(Map<String, dynamic> json) =
      _$NavigationHistoryItemImpl.fromJson;

  @override
  int get sectionIndex;
  @override
  String? get routePath;
  @override
  Map<String, dynamic>? get routeParams;
  @override
  DateTime get timestamp;

  /// Create a copy of NavigationHistoryItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NavigationHistoryItemImplCopyWith<_$NavigationHistoryItemImpl>
      get copyWith => throw _privateConstructorUsedError;
}
