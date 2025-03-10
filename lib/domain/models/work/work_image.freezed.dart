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
  /// ID
  String get id => throw _privateConstructorUsedError;

  /// 关联的作品ID
  String get workId => throw _privateConstructorUsedError;

  /// 导入时的原始路径
  String get originalPath => throw _privateConstructorUsedError;

  /// 图片路径
  String get path => throw _privateConstructorUsedError;

  /// 缩略图路径
  String get thumbnailPath => throw _privateConstructorUsedError;

  /// 在作品中的序号
  int get index => throw _privateConstructorUsedError;

  /// 图片宽度
  int get width => throw _privateConstructorUsedError;

  /// 图片高度
  int get height => throw _privateConstructorUsedError;

  /// 文件格式
  String get format => throw _privateConstructorUsedError;

  /// 文件大小(字节)
  int get size => throw _privateConstructorUsedError;

  /// 创建时间
  DateTime get createTime => throw _privateConstructorUsedError;

  /// 更新时间
  DateTime get updateTime => throw _privateConstructorUsedError;

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
  $Res call(
      {String id,
      String workId,
      String originalPath,
      String path,
      String thumbnailPath,
      int index,
      int width,
      int height,
      String format,
      int size,
      DateTime createTime,
      DateTime updateTime});
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
    Object? id = null,
    Object? workId = null,
    Object? originalPath = null,
    Object? path = null,
    Object? thumbnailPath = null,
    Object? index = null,
    Object? width = null,
    Object? height = null,
    Object? format = null,
    Object? size = null,
    Object? createTime = null,
    Object? updateTime = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      workId: null == workId
          ? _value.workId
          : workId // ignore: cast_nullable_to_non_nullable
              as String,
      originalPath: null == originalPath
          ? _value.originalPath
          : originalPath // ignore: cast_nullable_to_non_nullable
              as String,
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
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
      format: null == format
          ? _value.format
          : format // ignore: cast_nullable_to_non_nullable
              as String,
      size: null == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as int,
      createTime: null == createTime
          ? _value.createTime
          : createTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updateTime: null == updateTime
          ? _value.updateTime
          : updateTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
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
  $Res call(
      {String id,
      String workId,
      String originalPath,
      String path,
      String thumbnailPath,
      int index,
      int width,
      int height,
      String format,
      int size,
      DateTime createTime,
      DateTime updateTime});
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
    Object? id = null,
    Object? workId = null,
    Object? originalPath = null,
    Object? path = null,
    Object? thumbnailPath = null,
    Object? index = null,
    Object? width = null,
    Object? height = null,
    Object? format = null,
    Object? size = null,
    Object? createTime = null,
    Object? updateTime = null,
  }) {
    return _then(_$WorkImageImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      workId: null == workId
          ? _value.workId
          : workId // ignore: cast_nullable_to_non_nullable
              as String,
      originalPath: null == originalPath
          ? _value.originalPath
          : originalPath // ignore: cast_nullable_to_non_nullable
              as String,
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
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
      format: null == format
          ? _value.format
          : format // ignore: cast_nullable_to_non_nullable
              as String,
      size: null == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as int,
      createTime: null == createTime
          ? _value.createTime
          : createTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updateTime: null == updateTime
          ? _value.updateTime
          : updateTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkImageImpl extends _WorkImage {
  _$WorkImageImpl(
      {required this.id,
      required this.workId,
      required this.originalPath,
      required this.path,
      required this.thumbnailPath,
      required this.index,
      required this.width,
      required this.height,
      required this.format,
      required this.size,
      required this.createTime,
      required this.updateTime})
      : super._();

  factory _$WorkImageImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkImageImplFromJson(json);

  /// ID
  @override
  final String id;

  /// 关联的作品ID
  @override
  final String workId;

  /// 导入时的原始路径
  @override
  final String originalPath;

  /// 图片路径
  @override
  final String path;

  /// 缩略图路径
  @override
  final String thumbnailPath;

  /// 在作品中的序号
  @override
  final int index;

  /// 图片宽度
  @override
  final int width;

  /// 图片高度
  @override
  final int height;

  /// 文件格式
  @override
  final String format;

  /// 文件大小(字节)
  @override
  final int size;

  /// 创建时间
  @override
  final DateTime createTime;

  /// 更新时间
  @override
  final DateTime updateTime;

  @override
  String toString() {
    return 'WorkImage(id: $id, workId: $workId, originalPath: $originalPath, path: $path, thumbnailPath: $thumbnailPath, index: $index, width: $width, height: $height, format: $format, size: $size, createTime: $createTime, updateTime: $updateTime)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkImageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.workId, workId) || other.workId == workId) &&
            (identical(other.originalPath, originalPath) ||
                other.originalPath == originalPath) &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.thumbnailPath, thumbnailPath) ||
                other.thumbnailPath == thumbnailPath) &&
            (identical(other.index, index) || other.index == index) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.format, format) || other.format == format) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.createTime, createTime) ||
                other.createTime == createTime) &&
            (identical(other.updateTime, updateTime) ||
                other.updateTime == updateTime));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      workId,
      originalPath,
      path,
      thumbnailPath,
      index,
      width,
      height,
      format,
      size,
      createTime,
      updateTime);

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
  factory _WorkImage(
      {required final String id,
      required final String workId,
      required final String originalPath,
      required final String path,
      required final String thumbnailPath,
      required final int index,
      required final int width,
      required final int height,
      required final String format,
      required final int size,
      required final DateTime createTime,
      required final DateTime updateTime}) = _$WorkImageImpl;
  _WorkImage._() : super._();

  factory _WorkImage.fromJson(Map<String, dynamic> json) =
      _$WorkImageImpl.fromJson;

  /// ID
  @override
  String get id;

  /// 关联的作品ID
  @override
  String get workId;

  /// 导入时的原始路径
  @override
  String get originalPath;

  /// 图片路径
  @override
  String get path;

  /// 缩略图路径
  @override
  String get thumbnailPath;

  /// 在作品中的序号
  @override
  int get index;

  /// 图片宽度
  @override
  int get width;

  /// 图片高度
  @override
  int get height;

  /// 文件格式
  @override
  String get format;

  /// 文件大小(字节)
  @override
  int get size;

  /// 创建时间
  @override
  DateTime get createTime;

  /// 更新时间
  @override
  DateTime get updateTime;

  /// Create a copy of WorkImage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WorkImageImplCopyWith<_$WorkImageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
