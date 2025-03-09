// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'work_image.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

WorkImage _$WorkImageFromJson(Map<String, dynamic> json) {
  return _WorkImage.fromJson(json);
}

/// @nodoc
mixin _$WorkImage {
  /// 图片路径
  String get path => throw _privateConstructorUsedError;
  String get thumbnailPath => throw _privateConstructorUsedError;

  /// 在作品中的序号
  int get index => throw _privateConstructorUsedError;

  /// Serializes this WorkImage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WorkImage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WorkImageCopyWith<WorkImage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkImageCopyWith<$Res> {
  factory $WorkImageCopyWith(WorkImage value, $Res Function(WorkImage) then) =
      _$WorkImageCopyWithImpl<$Res, WorkImage>;
  @useResult
  $Res call({String path, String thumbnailPath, int index});
}

/// @nodoc
class _$WorkImageCopyWithImpl<$Res, $Val extends WorkImage>
    implements $WorkImageCopyWith<$Res> {
  _$WorkImageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WorkImage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? path = null,
    Object? thumbnailPath = null,
    Object? index = null,
  }) {
    return _then(_value.copyWith(
      path: null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      thumbnailPath: null == thumbnailPath
          ? _value.thumbnailPath
          : thumbnailPath // ignore: cast_nullable_to_non_nullable
              as String,
      index: null == index
          ? _value.index
          : index // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WorkImageImplCopyWith<$Res>
    implements $WorkImageCopyWith<$Res> {
  factory _$$WorkImageImplCopyWith(
          _$WorkImageImpl value, $Res Function(_$WorkImageImpl) then) =
      __$$WorkImageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String path, String thumbnailPath, int index});
}

/// @nodoc
class __$$WorkImageImplCopyWithImpl<$Res>
    extends _$WorkImageCopyWithImpl<$Res, _$WorkImageImpl>
    implements _$$WorkImageImplCopyWith<$Res> {
  __$$WorkImageImplCopyWithImpl(
      _$WorkImageImpl _value, $Res Function(_$WorkImageImpl) _then)
      : super(_value, _then);

  /// Create a copy of WorkImage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? path = null,
    Object? thumbnailPath = null,
    Object? index = null,
  }) {
    return _then(_$WorkImageImpl(
      path: null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      thumbnailPath: null == thumbnailPath
          ? _value.thumbnailPath
          : thumbnailPath // ignore: cast_nullable_to_non_nullable
              as String,
      index: null == index
          ? _value.index
          : index // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkImageImpl extends _WorkImage {
  const _$WorkImageImpl(
      {required this.path, required this.thumbnailPath, required this.index})
      : super._();

  factory _$WorkImageImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkImageImplFromJson(json);

  /// 图片路径
  @override
  final String path;
  @override
  final String thumbnailPath;

  /// 在作品中的序号
  @override
  final int index;

  @override
  String toString() {
    return 'WorkImage(path: $path, thumbnailPath: $thumbnailPath, index: $index)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkImageImpl &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.thumbnailPath, thumbnailPath) ||
                other.thumbnailPath == thumbnailPath) &&
            (identical(other.index, index) || other.index == index));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, path, thumbnailPath, index);

  /// Create a copy of WorkImage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkImageImplCopyWith<_$WorkImageImpl> get copyWith =>
      __$$WorkImageImplCopyWithImpl<_$WorkImageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkImageImplToJson(
      this,
    );
  }
}

abstract class _WorkImage extends WorkImage {
  const factory _WorkImage(
      {required final String path,
      required final String thumbnailPath,
      required final int index}) = _$WorkImageImpl;
  const _WorkImage._() : super._();

  factory _WorkImage.fromJson(Map<String, dynamic> json) =
      _$WorkImageImpl.fromJson;

  /// 图片路径
  @override
  String get path;
  @override
  String get thumbnailPath;

  /// 在作品中的序号
  @override
  int get index;

  /// Create a copy of WorkImage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WorkImageImplCopyWith<_$WorkImageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
