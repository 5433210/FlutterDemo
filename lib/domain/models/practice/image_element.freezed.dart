// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'image_element.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ImageElement _$ImageElementFromJson(Map<String, dynamic> json) {
  return _ImageElement.fromJson(json);
}

/// @nodoc
mixin _$ImageElement {
  /// 图片ID
  String get imageId => throw _privateConstructorUsedError;

  /// 图片URL
  String get url => throw _privateConstructorUsedError;

  /// 图片原始宽度
  int get width => throw _privateConstructorUsedError;

  /// 图片原始高度
  int get height => throw _privateConstructorUsedError;

  /// 图片MIME类型
  String get mimeType => throw _privateConstructorUsedError;

  /// 不透明度
  double get opacity => throw _privateConstructorUsedError;

  /// 自定义属性
  Map<String, dynamic> get customProps => throw _privateConstructorUsedError;

  /// Serializes this ImageElement to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ImageElement
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ImageElementCopyWith<ImageElement> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ImageElementCopyWith<$Res> {
  factory $ImageElementCopyWith(
          ImageElement value, $Res Function(ImageElement) then) =
      _$ImageElementCopyWithImpl<$Res, ImageElement>;
  @useResult
  $Res call(
      {String imageId,
      String url,
      int width,
      int height,
      String mimeType,
      double opacity,
      Map<String, dynamic> customProps});
}

/// @nodoc
class _$ImageElementCopyWithImpl<$Res, $Val extends ImageElement>
    implements $ImageElementCopyWith<$Res> {
  _$ImageElementCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ImageElement
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? imageId = null,
    Object? url = null,
    Object? width = null,
    Object? height = null,
    Object? mimeType = null,
    Object? opacity = null,
    Object? customProps = null,
  }) {
    return _then(_value.copyWith(
      imageId: null == imageId
          ? _value.imageId
          : imageId // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
      mimeType: null == mimeType
          ? _value.mimeType
          : mimeType // ignore: cast_nullable_to_non_nullable
              as String,
      opacity: null == opacity
          ? _value.opacity
          : opacity // ignore: cast_nullable_to_non_nullable
              as double,
      customProps: null == customProps
          ? _value.customProps
          : customProps // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ImageElementImplCopyWith<$Res>
    implements $ImageElementCopyWith<$Res> {
  factory _$$ImageElementImplCopyWith(
          _$ImageElementImpl value, $Res Function(_$ImageElementImpl) then) =
      __$$ImageElementImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String imageId,
      String url,
      int width,
      int height,
      String mimeType,
      double opacity,
      Map<String, dynamic> customProps});
}

/// @nodoc
class __$$ImageElementImplCopyWithImpl<$Res>
    extends _$ImageElementCopyWithImpl<$Res, _$ImageElementImpl>
    implements _$$ImageElementImplCopyWith<$Res> {
  __$$ImageElementImplCopyWithImpl(
      _$ImageElementImpl _value, $Res Function(_$ImageElementImpl) _then)
      : super(_value, _then);

  /// Create a copy of ImageElement
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? imageId = null,
    Object? url = null,
    Object? width = null,
    Object? height = null,
    Object? mimeType = null,
    Object? opacity = null,
    Object? customProps = null,
  }) {
    return _then(_$ImageElementImpl(
      imageId: null == imageId
          ? _value.imageId
          : imageId // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
      mimeType: null == mimeType
          ? _value.mimeType
          : mimeType // ignore: cast_nullable_to_non_nullable
              as String,
      opacity: null == opacity
          ? _value.opacity
          : opacity // ignore: cast_nullable_to_non_nullable
              as double,
      customProps: null == customProps
          ? _value._customProps
          : customProps // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ImageElementImpl extends _ImageElement {
  const _$ImageElementImpl(
      {required this.imageId,
      required this.url,
      required this.width,
      required this.height,
      this.mimeType = 'image/jpeg',
      this.opacity = 1.0,
      final Map<String, dynamic> customProps = const {}})
      : _customProps = customProps,
        super._();

  factory _$ImageElementImpl.fromJson(Map<String, dynamic> json) =>
      _$$ImageElementImplFromJson(json);

  /// 图片ID
  @override
  final String imageId;

  /// 图片URL
  @override
  final String url;

  /// 图片原始宽度
  @override
  final int width;

  /// 图片原始高度
  @override
  final int height;

  /// 图片MIME类型
  @override
  @JsonKey()
  final String mimeType;

  /// 不透明度
  @override
  @JsonKey()
  final double opacity;

  /// 自定义属性
  final Map<String, dynamic> _customProps;

  /// 自定义属性
  @override
  @JsonKey()
  Map<String, dynamic> get customProps {
    if (_customProps is EqualUnmodifiableMapView) return _customProps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_customProps);
  }

  @override
  String toString() {
    return 'ImageElement(imageId: $imageId, url: $url, width: $width, height: $height, mimeType: $mimeType, opacity: $opacity, customProps: $customProps)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ImageElementImpl &&
            (identical(other.imageId, imageId) || other.imageId == imageId) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.mimeType, mimeType) ||
                other.mimeType == mimeType) &&
            (identical(other.opacity, opacity) || other.opacity == opacity) &&
            const DeepCollectionEquality()
                .equals(other._customProps, _customProps));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, imageId, url, width, height,
      mimeType, opacity, const DeepCollectionEquality().hash(_customProps));

  /// Create a copy of ImageElement
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ImageElementImplCopyWith<_$ImageElementImpl> get copyWith =>
      __$$ImageElementImplCopyWithImpl<_$ImageElementImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ImageElementImplToJson(
      this,
    );
  }
}

abstract class _ImageElement extends ImageElement {
  const factory _ImageElement(
      {required final String imageId,
      required final String url,
      required final int width,
      required final int height,
      final String mimeType,
      final double opacity,
      final Map<String, dynamic> customProps}) = _$ImageElementImpl;
  const _ImageElement._() : super._();

  factory _ImageElement.fromJson(Map<String, dynamic> json) =
      _$ImageElementImpl.fromJson;

  /// 图片ID
  @override
  String get imageId;

  /// 图片URL
  @override
  String get url;

  /// 图片原始宽度
  @override
  int get width;

  /// 图片原始高度
  @override
  int get height;

  /// 图片MIME类型
  @override
  String get mimeType;

  /// 不透明度
  @override
  double get opacity;

  /// 自定义属性
  @override
  Map<String, dynamic> get customProps;

  /// Create a copy of ImageElement
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ImageElementImplCopyWith<_$ImageElementImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
