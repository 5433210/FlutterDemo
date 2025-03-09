// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'char_position.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CharPosition _$CharPositionFromJson(Map<String, dynamic> json) {
  return _CharPosition.fromJson(json);
}

/// @nodoc
mixin _$CharPosition {
  /// X轴偏移量
  double get offsetX => throw _privateConstructorUsedError;

  /// Y轴偏移量
  double get offsetY => throw _privateConstructorUsedError;

  /// Serializes this CharPosition to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CharPosition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CharPositionCopyWith<CharPosition> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CharPositionCopyWith<$Res> {
  factory $CharPositionCopyWith(
          CharPosition value, $Res Function(CharPosition) then) =
      _$CharPositionCopyWithImpl<$Res, CharPosition>;
  @useResult
  $Res call({double offsetX, double offsetY});
}

/// @nodoc
class _$CharPositionCopyWithImpl<$Res, $Val extends CharPosition>
    implements $CharPositionCopyWith<$Res> {
  _$CharPositionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CharPosition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? offsetX = null,
    Object? offsetY = null,
  }) {
    return _then(_value.copyWith(
      offsetX: null == offsetX
          ? _value.offsetX
          : offsetX // ignore: cast_nullable_to_non_nullable
              as double,
      offsetY: null == offsetY
          ? _value.offsetY
          : offsetY // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CharPositionImplCopyWith<$Res>
    implements $CharPositionCopyWith<$Res> {
  factory _$$CharPositionImplCopyWith(
          _$CharPositionImpl value, $Res Function(_$CharPositionImpl) then) =
      __$$CharPositionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double offsetX, double offsetY});
}

/// @nodoc
class __$$CharPositionImplCopyWithImpl<$Res>
    extends _$CharPositionCopyWithImpl<$Res, _$CharPositionImpl>
    implements _$$CharPositionImplCopyWith<$Res> {
  __$$CharPositionImplCopyWithImpl(
      _$CharPositionImpl _value, $Res Function(_$CharPositionImpl) _then)
      : super(_value, _then);

  /// Create a copy of CharPosition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? offsetX = null,
    Object? offsetY = null,
  }) {
    return _then(_$CharPositionImpl(
      offsetX: null == offsetX
          ? _value.offsetX
          : offsetX // ignore: cast_nullable_to_non_nullable
              as double,
      offsetY: null == offsetY
          ? _value.offsetY
          : offsetY // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CharPositionImpl extends _CharPosition {
  const _$CharPositionImpl({required this.offsetX, required this.offsetY})
      : super._();

  factory _$CharPositionImpl.fromJson(Map<String, dynamic> json) =>
      _$$CharPositionImplFromJson(json);

  /// X轴偏移量
  @override
  final double offsetX;

  /// Y轴偏移量
  @override
  final double offsetY;

  @override
  String toString() {
    return 'CharPosition(offsetX: $offsetX, offsetY: $offsetY)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CharPositionImpl &&
            (identical(other.offsetX, offsetX) || other.offsetX == offsetX) &&
            (identical(other.offsetY, offsetY) || other.offsetY == offsetY));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, offsetX, offsetY);

  /// Create a copy of CharPosition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CharPositionImplCopyWith<_$CharPositionImpl> get copyWith =>
      __$$CharPositionImplCopyWithImpl<_$CharPositionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CharPositionImplToJson(
      this,
    );
  }
}

abstract class _CharPosition extends CharPosition {
  const factory _CharPosition(
      {required final double offsetX,
      required final double offsetY}) = _$CharPositionImpl;
  const _CharPosition._() : super._();

  factory _CharPosition.fromJson(Map<String, dynamic> json) =
      _$CharPositionImpl.fromJson;

  /// X轴偏移量
  @override
  double get offsetX;

  /// Y轴偏移量
  @override
  double get offsetY;

  /// Create a copy of CharPosition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CharPositionImplCopyWith<_$CharPositionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
