// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'char_transform.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CharTransform _$CharTransformFromJson(Map<String, dynamic> json) {
  return _CharTransform.fromJson(json);
}

/// @nodoc
mixin _$CharTransform {
  /// X轴缩放
  double get scaleX => throw _privateConstructorUsedError;

  /// Y轴缩放
  double get scaleY => throw _privateConstructorUsedError;

  /// 旋转角度
  double get rotation => throw _privateConstructorUsedError;

  /// Serializes this CharTransform to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CharTransform
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CharTransformCopyWith<CharTransform> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CharTransformCopyWith<$Res> {
  factory $CharTransformCopyWith(
          CharTransform value, $Res Function(CharTransform) then) =
      _$CharTransformCopyWithImpl<$Res, CharTransform>;
  @useResult
  $Res call({double scaleX, double scaleY, double rotation});
}

/// @nodoc
class _$CharTransformCopyWithImpl<$Res, $Val extends CharTransform>
    implements $CharTransformCopyWith<$Res> {
  _$CharTransformCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CharTransform
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? scaleX = null,
    Object? scaleY = null,
    Object? rotation = null,
  }) {
    return _then(_value.copyWith(
      scaleX: null == scaleX
          ? _value.scaleX
          : scaleX // ignore: cast_nullable_to_non_nullable
              as double,
      scaleY: null == scaleY
          ? _value.scaleY
          : scaleY // ignore: cast_nullable_to_non_nullable
              as double,
      rotation: null == rotation
          ? _value.rotation
          : rotation // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CharTransformImplCopyWith<$Res>
    implements $CharTransformCopyWith<$Res> {
  factory _$$CharTransformImplCopyWith(
          _$CharTransformImpl value, $Res Function(_$CharTransformImpl) then) =
      __$$CharTransformImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double scaleX, double scaleY, double rotation});
}

/// @nodoc
class __$$CharTransformImplCopyWithImpl<$Res>
    extends _$CharTransformCopyWithImpl<$Res, _$CharTransformImpl>
    implements _$$CharTransformImplCopyWith<$Res> {
  __$$CharTransformImplCopyWithImpl(
      _$CharTransformImpl _value, $Res Function(_$CharTransformImpl) _then)
      : super(_value, _then);

  /// Create a copy of CharTransform
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? scaleX = null,
    Object? scaleY = null,
    Object? rotation = null,
  }) {
    return _then(_$CharTransformImpl(
      scaleX: null == scaleX
          ? _value.scaleX
          : scaleX // ignore: cast_nullable_to_non_nullable
              as double,
      scaleY: null == scaleY
          ? _value.scaleY
          : scaleY // ignore: cast_nullable_to_non_nullable
              as double,
      rotation: null == rotation
          ? _value.rotation
          : rotation // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CharTransformImpl extends _CharTransform {
  const _$CharTransformImpl(
      {this.scaleX = 1.0, this.scaleY = 1.0, this.rotation = 0.0})
      : super._();

  factory _$CharTransformImpl.fromJson(Map<String, dynamic> json) =>
      _$$CharTransformImplFromJson(json);

  /// X轴缩放
  @override
  @JsonKey()
  final double scaleX;

  /// Y轴缩放
  @override
  @JsonKey()
  final double scaleY;

  /// 旋转角度
  @override
  @JsonKey()
  final double rotation;

  @override
  String toString() {
    return 'CharTransform(scaleX: $scaleX, scaleY: $scaleY, rotation: $rotation)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CharTransformImpl &&
            (identical(other.scaleX, scaleX) || other.scaleX == scaleX) &&
            (identical(other.scaleY, scaleY) || other.scaleY == scaleY) &&
            (identical(other.rotation, rotation) ||
                other.rotation == rotation));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, scaleX, scaleY, rotation);

  /// Create a copy of CharTransform
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CharTransformImplCopyWith<_$CharTransformImpl> get copyWith =>
      __$$CharTransformImplCopyWithImpl<_$CharTransformImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CharTransformImplToJson(
      this,
    );
  }
}

abstract class _CharTransform extends CharTransform {
  const factory _CharTransform(
      {final double scaleX,
      final double scaleY,
      final double rotation}) = _$CharTransformImpl;
  const _CharTransform._() : super._();

  factory _CharTransform.fromJson(Map<String, dynamic> json) =
      _$CharTransformImpl.fromJson;

  /// X轴缩放
  @override
  double get scaleX;

  /// Y轴缩放
  @override
  double get scaleY;

  /// 旋转角度
  @override
  double get rotation;

  /// Create a copy of CharTransform
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CharTransformImplCopyWith<_$CharTransformImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
