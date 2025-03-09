// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sort_option.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SortOption _$SortOptionFromJson(Map<String, dynamic> json) {
  return _SortOption.fromJson(json);
}

/// @nodoc
mixin _$SortOption {
  @JsonKey(fromJson: _sortFieldFromJson, toJson: _sortFieldToJson)
  SortField get field => throw _privateConstructorUsedError;
  bool get descending => throw _privateConstructorUsedError;

  /// Serializes this SortOption to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SortOption
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SortOptionCopyWith<SortOption> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SortOptionCopyWith<$Res> {
  factory $SortOptionCopyWith(
          SortOption value, $Res Function(SortOption) then) =
      _$SortOptionCopyWithImpl<$Res, SortOption>;
  @useResult
  $Res call(
      {@JsonKey(fromJson: _sortFieldFromJson, toJson: _sortFieldToJson)
      SortField field,
      bool descending});
}

/// @nodoc
class _$SortOptionCopyWithImpl<$Res, $Val extends SortOption>
    implements $SortOptionCopyWith<$Res> {
  _$SortOptionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SortOption
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field = null,
    Object? descending = null,
  }) {
    return _then(_value.copyWith(
      field: null == field
          ? _value.field
          : field // ignore: cast_nullable_to_non_nullable
              as SortField,
      descending: null == descending
          ? _value.descending
          : descending // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SortOptionImplCopyWith<$Res>
    implements $SortOptionCopyWith<$Res> {
  factory _$$SortOptionImplCopyWith(
          _$SortOptionImpl value, $Res Function(_$SortOptionImpl) then) =
      __$$SortOptionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(fromJson: _sortFieldFromJson, toJson: _sortFieldToJson)
      SortField field,
      bool descending});
}

/// @nodoc
class __$$SortOptionImplCopyWithImpl<$Res>
    extends _$SortOptionCopyWithImpl<$Res, _$SortOptionImpl>
    implements _$$SortOptionImplCopyWith<$Res> {
  __$$SortOptionImplCopyWithImpl(
      _$SortOptionImpl _value, $Res Function(_$SortOptionImpl) _then)
      : super(_value, _then);

  /// Create a copy of SortOption
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field = null,
    Object? descending = null,
  }) {
    return _then(_$SortOptionImpl(
      field: null == field
          ? _value.field
          : field // ignore: cast_nullable_to_non_nullable
              as SortField,
      descending: null == descending
          ? _value.descending
          : descending // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SortOptionImpl extends _SortOption {
  const _$SortOptionImpl(
      {@JsonKey(fromJson: _sortFieldFromJson, toJson: _sortFieldToJson)
      this.field = SortField.createTime,
      this.descending = true})
      : super._();

  factory _$SortOptionImpl.fromJson(Map<String, dynamic> json) =>
      _$$SortOptionImplFromJson(json);

  @override
  @JsonKey(fromJson: _sortFieldFromJson, toJson: _sortFieldToJson)
  final SortField field;
  @override
  @JsonKey()
  final bool descending;

  @override
  String toString() {
    return 'SortOption(field: $field, descending: $descending)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SortOptionImpl &&
            (identical(other.field, field) || other.field == field) &&
            (identical(other.descending, descending) ||
                other.descending == descending));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, field, descending);

  /// Create a copy of SortOption
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SortOptionImplCopyWith<_$SortOptionImpl> get copyWith =>
      __$$SortOptionImplCopyWithImpl<_$SortOptionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SortOptionImplToJson(
      this,
    );
  }
}

abstract class _SortOption extends SortOption {
  const factory _SortOption(
      {@JsonKey(fromJson: _sortFieldFromJson, toJson: _sortFieldToJson)
      final SortField field,
      final bool descending}) = _$SortOptionImpl;
  const _SortOption._() : super._();

  factory _SortOption.fromJson(Map<String, dynamic> json) =
      _$SortOptionImpl.fromJson;

  @override
  @JsonKey(fromJson: _sortFieldFromJson, toJson: _sortFieldToJson)
  SortField get field;
  @override
  bool get descending;

  /// Create a copy of SortOption
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SortOptionImplCopyWith<_$SortOptionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
