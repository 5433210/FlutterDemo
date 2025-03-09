// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'character_region.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CharacterRegion _$CharacterRegionFromJson(Map<String, dynamic> json) {
  return _CharacterRegion.fromJson(json);
}

/// @nodoc
mixin _$CharacterRegion {
  /// X坐标
  double get left => throw _privateConstructorUsedError;

  /// Y坐标
  double get top => throw _privateConstructorUsedError;

  /// 宽度
  double get width => throw _privateConstructorUsedError;

  /// 高度
  double get height => throw _privateConstructorUsedError;

  /// 旋转角度
  double get rotation => throw _privateConstructorUsedError;

  /// 页码索引
  int get pageIndex => throw _privateConstructorUsedError;

  /// 是否已保存
  bool get isSaved => throw _privateConstructorUsedError;

  /// 标签
  String? get label => throw _privateConstructorUsedError;

  /// 图片路径
  String get imagePath => throw _privateConstructorUsedError;

  /// 区域颜色
  @JsonKey(ignore: true)
  Color? get color => throw _privateConstructorUsedError;

  /// Serializes this CharacterRegion to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CharacterRegion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CharacterRegionCopyWith<CharacterRegion> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CharacterRegionCopyWith<$Res> {
  factory $CharacterRegionCopyWith(
          CharacterRegion value, $Res Function(CharacterRegion) then) =
      _$CharacterRegionCopyWithImpl<$Res, CharacterRegion>;
  @useResult
  $Res call(
      {double left,
      double top,
      double width,
      double height,
      double rotation,
      int pageIndex,
      bool isSaved,
      String? label,
      String imagePath,
      @JsonKey(ignore: true) Color? color});
}

/// @nodoc
class _$CharacterRegionCopyWithImpl<$Res, $Val extends CharacterRegion>
    implements $CharacterRegionCopyWith<$Res> {
  _$CharacterRegionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CharacterRegion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? left = null,
    Object? top = null,
    Object? width = null,
    Object? height = null,
    Object? rotation = null,
    Object? pageIndex = null,
    Object? isSaved = null,
    Object? label = freezed,
    Object? imagePath = null,
    Object? color = freezed,
  }) {
    return _then(_value.copyWith(
      left: null == left
          ? _value.left
          : left // ignore: cast_nullable_to_non_nullable
              as double,
      top: null == top
          ? _value.top
          : top // ignore: cast_nullable_to_non_nullable
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
      pageIndex: null == pageIndex
          ? _value.pageIndex
          : pageIndex // ignore: cast_nullable_to_non_nullable
              as int,
      isSaved: null == isSaved
          ? _value.isSaved
          : isSaved // ignore: cast_nullable_to_non_nullable
              as bool,
      label: freezed == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String?,
      imagePath: null == imagePath
          ? _value.imagePath
          : imagePath // ignore: cast_nullable_to_non_nullable
              as String,
      color: freezed == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as Color?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CharacterRegionImplCopyWith<$Res>
    implements $CharacterRegionCopyWith<$Res> {
  factory _$$CharacterRegionImplCopyWith(_$CharacterRegionImpl value,
          $Res Function(_$CharacterRegionImpl) then) =
      __$$CharacterRegionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double left,
      double top,
      double width,
      double height,
      double rotation,
      int pageIndex,
      bool isSaved,
      String? label,
      String imagePath,
      @JsonKey(ignore: true) Color? color});
}

/// @nodoc
class __$$CharacterRegionImplCopyWithImpl<$Res>
    extends _$CharacterRegionCopyWithImpl<$Res, _$CharacterRegionImpl>
    implements _$$CharacterRegionImplCopyWith<$Res> {
  __$$CharacterRegionImplCopyWithImpl(
      _$CharacterRegionImpl _value, $Res Function(_$CharacterRegionImpl) _then)
      : super(_value, _then);

  /// Create a copy of CharacterRegion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? left = null,
    Object? top = null,
    Object? width = null,
    Object? height = null,
    Object? rotation = null,
    Object? pageIndex = null,
    Object? isSaved = null,
    Object? label = freezed,
    Object? imagePath = null,
    Object? color = freezed,
  }) {
    return _then(_$CharacterRegionImpl(
      left: null == left
          ? _value.left
          : left // ignore: cast_nullable_to_non_nullable
              as double,
      top: null == top
          ? _value.top
          : top // ignore: cast_nullable_to_non_nullable
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
      pageIndex: null == pageIndex
          ? _value.pageIndex
          : pageIndex // ignore: cast_nullable_to_non_nullable
              as int,
      isSaved: null == isSaved
          ? _value.isSaved
          : isSaved // ignore: cast_nullable_to_non_nullable
              as bool,
      label: freezed == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String?,
      imagePath: null == imagePath
          ? _value.imagePath
          : imagePath // ignore: cast_nullable_to_non_nullable
              as String,
      color: freezed == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as Color?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CharacterRegionImpl extends _CharacterRegion {
  const _$CharacterRegionImpl(
      {required this.left,
      required this.top,
      required this.width,
      required this.height,
      this.rotation = 0.0,
      required this.pageIndex,
      this.isSaved = false,
      this.label,
      required this.imagePath,
      @JsonKey(ignore: true) this.color})
      : super._();

  factory _$CharacterRegionImpl.fromJson(Map<String, dynamic> json) =>
      _$$CharacterRegionImplFromJson(json);

  /// X坐标
  @override
  final double left;

  /// Y坐标
  @override
  final double top;

  /// 宽度
  @override
  final double width;

  /// 高度
  @override
  final double height;

  /// 旋转角度
  @override
  @JsonKey()
  final double rotation;

  /// 页码索引
  @override
  final int pageIndex;

  /// 是否已保存
  @override
  @JsonKey()
  final bool isSaved;

  /// 标签
  @override
  final String? label;

  /// 图片路径
  @override
  final String imagePath;

  /// 区域颜色
  @override
  @JsonKey(ignore: true)
  final Color? color;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CharacterRegionImpl &&
            (identical(other.left, left) || other.left == left) &&
            (identical(other.top, top) || other.top == top) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.rotation, rotation) ||
                other.rotation == rotation) &&
            (identical(other.pageIndex, pageIndex) ||
                other.pageIndex == pageIndex) &&
            (identical(other.isSaved, isSaved) || other.isSaved == isSaved) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.imagePath, imagePath) ||
                other.imagePath == imagePath) &&
            (identical(other.color, color) || other.color == color));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, left, top, width, height,
      rotation, pageIndex, isSaved, label, imagePath, color);

  /// Create a copy of CharacterRegion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CharacterRegionImplCopyWith<_$CharacterRegionImpl> get copyWith =>
      __$$CharacterRegionImplCopyWithImpl<_$CharacterRegionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CharacterRegionImplToJson(
      this,
    );
  }
}

abstract class _CharacterRegion extends CharacterRegion {
  const factory _CharacterRegion(
      {required final double left,
      required final double top,
      required final double width,
      required final double height,
      final double rotation,
      required final int pageIndex,
      final bool isSaved,
      final String? label,
      required final String imagePath,
      @JsonKey(ignore: true) final Color? color}) = _$CharacterRegionImpl;
  const _CharacterRegion._() : super._();

  factory _CharacterRegion.fromJson(Map<String, dynamic> json) =
      _$CharacterRegionImpl.fromJson;

  /// X坐标
  @override
  double get left;

  /// Y坐标
  @override
  double get top;

  /// 宽度
  @override
  double get width;

  /// 高度
  @override
  double get height;

  /// 旋转角度
  @override
  double get rotation;

  /// 页码索引
  @override
  int get pageIndex;

  /// 是否已保存
  @override
  bool get isSaved;

  /// 标签
  @override
  String? get label;

  /// 图片路径
  @override
  String get imagePath;

  /// 区域颜色
  @override
  @JsonKey(ignore: true)
  Color? get color;

  /// Create a copy of CharacterRegion
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CharacterRegionImplCopyWith<_$CharacterRegionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
