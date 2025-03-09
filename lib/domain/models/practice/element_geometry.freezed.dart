// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'element_geometry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ElementGeometry _$ElementGeometryFromJson(Map<String, dynamic> json) {
  return _ElementGeometry.fromJson(json);
}

/// @nodoc
mixin _$ElementGeometry {
  /// X坐标
  double get x => throw _privateConstructorUsedError;

  /// Y坐标
  double get y => throw _privateConstructorUsedError;

  /// 宽度
  double get width => throw _privateConstructorUsedError;

  /// 高度
  double get height => throw _privateConstructorUsedError;

  /// 旋转角度(弧度)
  double get rotation => throw _privateConstructorUsedError;

  /// 缩放
  double get scale => throw _privateConstructorUsedError;

  /// Serializes this ElementGeometry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ElementGeometry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ElementGeometryCopyWith<ElementGeometry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ElementGeometryCopyWith<$Res> {
  factory $ElementGeometryCopyWith(
          ElementGeometry value, $Res Function(ElementGeometry) then) =
      _$ElementGeometryCopyWithImpl<$Res, ElementGeometry>;
  @useResult
  $Res call(
      {double x,
      double y,
      double width,
      double height,
      double rotation,
      double scale});
}

/// @nodoc
class _$ElementGeometryCopyWithImpl<$Res, $Val extends ElementGeometry>
    implements $ElementGeometryCopyWith<$Res> {
  _$ElementGeometryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ElementGeometry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? x = null,
    Object? y = null,
    Object? width = null,
    Object? height = null,
    Object? rotation = null,
    Object? scale = null,
  }) {
    return _then(_value.copyWith(
      x: null == x
          ? _value.x
          : x // ignore: cast_nullable_to_non_nullable
              as double,
      y: null == y
          ? _value.y
          : y // ignore: cast_nullable_to_non_nullable
              as double,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as double,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as double,
      rotation: null == rotation
          ? _value.rotation
          : rotation // ignore: cast_nullable_to_non_nullable
              as double,
      scale: null == scale
          ? _value.scale
          : scale // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ElementGeometryImplCopyWith<$Res>
    implements $ElementGeometryCopyWith<$Res> {
  factory _$$ElementGeometryImplCopyWith(_$ElementGeometryImpl value,
          $Res Function(_$ElementGeometryImpl) then) =
      __$$ElementGeometryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double x,
      double y,
      double width,
      double height,
      double rotation,
      double scale});
}

/// @nodoc
class __$$ElementGeometryImplCopyWithImpl<$Res>
    extends _$ElementGeometryCopyWithImpl<$Res, _$ElementGeometryImpl>
    implements _$$ElementGeometryImplCopyWith<$Res> {
  __$$ElementGeometryImplCopyWithImpl(
      _$ElementGeometryImpl _value, $Res Function(_$ElementGeometryImpl) _then)
      : super(_value, _then);

  /// Create a copy of ElementGeometry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? x = null,
    Object? y = null,
    Object? width = null,
    Object? height = null,
    Object? rotation = null,
    Object? scale = null,
  }) {
    return _then(_$ElementGeometryImpl(
      x: null == x
          ? _value.x
          : x // ignore: cast_nullable_to_non_nullable
              as double,
      y: null == y
          ? _value.y
          : y // ignore: cast_nullable_to_non_nullable
              as double,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as double,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as double,
      rotation: null == rotation
          ? _value.rotation
          : rotation // ignore: cast_nullable_to_non_nullable
              as double,
      scale: null == scale
          ? _value.scale
          : scale // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ElementGeometryImpl extends _ElementGeometry {
  const _$ElementGeometryImpl(
      {this.x = 0.0,
      this.y = 0.0,
      this.width = 100.0,
      this.height = 100.0,
      this.rotation = 0.0,
      this.scale = 1.0})
      : super._();

  factory _$ElementGeometryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ElementGeometryImplFromJson(json);

  /// X坐标
  @override
  @JsonKey()
  final double x;

  /// Y坐标
  @override
  @JsonKey()
  final double y;

  /// 宽度
  @override
  @JsonKey()
  final double width;

  /// 高度
  @override
  @JsonKey()
  final double height;

  /// 旋转角度(弧度)
  @override
  @JsonKey()
  final double rotation;

  /// 缩放
  @override
  @JsonKey()
  final double scale;

  @override
  String toString() {
    return 'ElementGeometry(x: $x, y: $y, width: $width, height: $height, rotation: $rotation, scale: $scale)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ElementGeometryImpl &&
            (identical(other.x, x) || other.x == x) &&
            (identical(other.y, y) || other.y == y) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.rotation, rotation) ||
                other.rotation == rotation) &&
            (identical(other.scale, scale) || other.scale == scale));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, x, y, width, height, rotation, scale);

  /// Create a copy of ElementGeometry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ElementGeometryImplCopyWith<_$ElementGeometryImpl> get copyWith =>
      __$$ElementGeometryImplCopyWithImpl<_$ElementGeometryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ElementGeometryImplToJson(
      this,
    );
  }
}

abstract class _ElementGeometry extends ElementGeometry {
  const factory _ElementGeometry(
      {final double x,
      final double y,
      final double width,
      final double height,
      final double rotation,
      final double scale}) = _$ElementGeometryImpl;
  const _ElementGeometry._() : super._();

  factory _ElementGeometry.fromJson(Map<String, dynamic> json) =
      _$ElementGeometryImpl.fromJson;

  /// X坐标
  @override
  double get x;

  /// Y坐标
  @override
  double get y;

  /// 宽度
  @override
  double get width;

  /// 高度
  @override
  double get height;

  /// 旋转角度(弧度)
  @override
  double get rotation;

  /// 缩放
  @override
  double get scale;

  /// Create a copy of ElementGeometry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ElementGeometryImplCopyWith<_$ElementGeometryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
