// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'character_image.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CharacterImage _$CharacterImageFromJson(Map<String, dynamic> json) {
  return _CharacterImage.fromJson(json);
}

/// @nodoc
mixin _$CharacterImage {
  String get id => throw _privateConstructorUsedError;
  String get originalPath => throw _privateConstructorUsedError;
  String get binaryPath => throw _privateConstructorUsedError;
  String get thumbnailPath => throw _privateConstructorUsedError;
  String? get svgPath => throw _privateConstructorUsedError; // 新增：SVG轮廓路径
  @SizeConverter()
  Size get originalSize => throw _privateConstructorUsedError;
  ProcessingOptions get options => throw _privateConstructorUsedError;

  /// Serializes this CharacterImage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CharacterImage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CharacterImageCopyWith<CharacterImage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CharacterImageCopyWith<$Res> {
  factory $CharacterImageCopyWith(
          CharacterImage value, $Res Function(CharacterImage) then) =
      _$CharacterImageCopyWithImpl<$Res, CharacterImage>;
  @useResult
  $Res call(
      {String id,
      String originalPath,
      String binaryPath,
      String thumbnailPath,
      String? svgPath,
      @SizeConverter() Size originalSize,
      ProcessingOptions options});

  $ProcessingOptionsCopyWith<$Res> get options;
}

/// @nodoc
class _$CharacterImageCopyWithImpl<$Res, $Val extends CharacterImage>
    implements $CharacterImageCopyWith<$Res> {
  _$CharacterImageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CharacterImage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? originalPath = null,
    Object? binaryPath = null,
    Object? thumbnailPath = null,
    Object? svgPath = freezed,
    Object? originalSize = null,
    Object? options = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      originalPath: null == originalPath
          ? _value.originalPath
          : originalPath // ignore: cast_nullable_to_non_nullable
              as String,
      binaryPath: null == binaryPath
          ? _value.binaryPath
          : binaryPath // ignore: cast_nullable_to_non_nullable
              as String,
      thumbnailPath: null == thumbnailPath
          ? _value.thumbnailPath
          : thumbnailPath // ignore: cast_nullable_to_non_nullable
              as String,
      svgPath: freezed == svgPath
          ? _value.svgPath
          : svgPath // ignore: cast_nullable_to_non_nullable
              as String?,
      originalSize: null == originalSize
          ? _value.originalSize
          : originalSize // ignore: cast_nullable_to_non_nullable
              as Size,
      options: null == options
          ? _value.options
          : options // ignore: cast_nullable_to_non_nullable
              as ProcessingOptions,
    ) as $Val);
  }

  /// Create a copy of CharacterImage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ProcessingOptionsCopyWith<$Res> get options {
    return $ProcessingOptionsCopyWith<$Res>(_value.options, (value) {
      return _then(_value.copyWith(options: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CharacterImageImplCopyWith<$Res>
    implements $CharacterImageCopyWith<$Res> {
  factory _$$CharacterImageImplCopyWith(_$CharacterImageImpl value,
          $Res Function(_$CharacterImageImpl) then) =
      __$$CharacterImageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String originalPath,
      String binaryPath,
      String thumbnailPath,
      String? svgPath,
      @SizeConverter() Size originalSize,
      ProcessingOptions options});

  @override
  $ProcessingOptionsCopyWith<$Res> get options;
}

/// @nodoc
class __$$CharacterImageImplCopyWithImpl<$Res>
    extends _$CharacterImageCopyWithImpl<$Res, _$CharacterImageImpl>
    implements _$$CharacterImageImplCopyWith<$Res> {
  __$$CharacterImageImplCopyWithImpl(
      _$CharacterImageImpl _value, $Res Function(_$CharacterImageImpl) _then)
      : super(_value, _then);

  /// Create a copy of CharacterImage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? originalPath = null,
    Object? binaryPath = null,
    Object? thumbnailPath = null,
    Object? svgPath = freezed,
    Object? originalSize = null,
    Object? options = null,
  }) {
    return _then(_$CharacterImageImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      originalPath: null == originalPath
          ? _value.originalPath
          : originalPath // ignore: cast_nullable_to_non_nullable
              as String,
      binaryPath: null == binaryPath
          ? _value.binaryPath
          : binaryPath // ignore: cast_nullable_to_non_nullable
              as String,
      thumbnailPath: null == thumbnailPath
          ? _value.thumbnailPath
          : thumbnailPath // ignore: cast_nullable_to_non_nullable
              as String,
      svgPath: freezed == svgPath
          ? _value.svgPath
          : svgPath // ignore: cast_nullable_to_non_nullable
              as String?,
      originalSize: null == originalSize
          ? _value.originalSize
          : originalSize // ignore: cast_nullable_to_non_nullable
              as Size,
      options: null == options
          ? _value.options
          : options // ignore: cast_nullable_to_non_nullable
              as ProcessingOptions,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CharacterImageImpl implements _CharacterImage {
  const _$CharacterImageImpl(
      {required this.id,
      required this.originalPath,
      required this.binaryPath,
      required this.thumbnailPath,
      this.svgPath,
      @SizeConverter() required this.originalSize,
      required this.options});

  factory _$CharacterImageImpl.fromJson(Map<String, dynamic> json) =>
      _$$CharacterImageImplFromJson(json);

  @override
  final String id;
  @override
  final String originalPath;
  @override
  final String binaryPath;
  @override
  final String thumbnailPath;
  @override
  final String? svgPath;
// 新增：SVG轮廓路径
  @override
  @SizeConverter()
  final Size originalSize;
  @override
  final ProcessingOptions options;

  @override
  String toString() {
    return 'CharacterImage(id: $id, originalPath: $originalPath, binaryPath: $binaryPath, thumbnailPath: $thumbnailPath, svgPath: $svgPath, originalSize: $originalSize, options: $options)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CharacterImageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.originalPath, originalPath) ||
                other.originalPath == originalPath) &&
            (identical(other.binaryPath, binaryPath) ||
                other.binaryPath == binaryPath) &&
            (identical(other.thumbnailPath, thumbnailPath) ||
                other.thumbnailPath == thumbnailPath) &&
            (identical(other.svgPath, svgPath) || other.svgPath == svgPath) &&
            (identical(other.originalSize, originalSize) ||
                other.originalSize == originalSize) &&
            (identical(other.options, options) || other.options == options));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, originalPath, binaryPath,
      thumbnailPath, svgPath, originalSize, options);

  /// Create a copy of CharacterImage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CharacterImageImplCopyWith<_$CharacterImageImpl> get copyWith =>
      __$$CharacterImageImplCopyWithImpl<_$CharacterImageImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CharacterImageImplToJson(
      this,
    );
  }
}

abstract class _CharacterImage implements CharacterImage {
  const factory _CharacterImage(
      {required final String id,
      required final String originalPath,
      required final String binaryPath,
      required final String thumbnailPath,
      final String? svgPath,
      @SizeConverter() required final Size originalSize,
      required final ProcessingOptions options}) = _$CharacterImageImpl;

  factory _CharacterImage.fromJson(Map<String, dynamic> json) =
      _$CharacterImageImpl.fromJson;

  @override
  String get id;
  @override
  String get originalPath;
  @override
  String get binaryPath;
  @override
  String get thumbnailPath;
  @override
  String? get svgPath; // 新增：SVG轮廓路径
  @override
  @SizeConverter()
  Size get originalSize;
  @override
  ProcessingOptions get options;

  /// Create a copy of CharacterImage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CharacterImageImplCopyWith<_$CharacterImageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
