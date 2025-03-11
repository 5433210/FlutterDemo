// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'element_content.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ElementContent _$ElementContentFromJson(Map<String, dynamic> json) {
  switch (json['runtimeType']) {
    case 'chars':
      return CharsContent.fromJson(json);
    case 'image':
      return ImageContent.fromJson(json);
    case 'text':
      return TextContent.fromJson(json);

    default:
      throw CheckedFromJsonException(json, 'runtimeType', 'ElementContent',
          'Invalid union type "${json['runtimeType']}"!');
  }
}

/// @nodoc
mixin _$ElementContent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<CharElement> chars) chars,
    required TResult Function(ImageElement image) image,
    required TResult Function(TextElement text) text,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<CharElement> chars)? chars,
    TResult? Function(ImageElement image)? image,
    TResult? Function(TextElement text)? text,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<CharElement> chars)? chars,
    TResult Function(ImageElement image)? image,
    TResult Function(TextElement text)? text,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CharsContent value) chars,
    required TResult Function(ImageContent value) image,
    required TResult Function(TextContent value) text,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CharsContent value)? chars,
    TResult? Function(ImageContent value)? image,
    TResult? Function(TextContent value)? text,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CharsContent value)? chars,
    TResult Function(ImageContent value)? image,
    TResult Function(TextContent value)? text,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this ElementContent to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ElementContentCopyWith<$Res> {
  factory $ElementContentCopyWith(
          ElementContent value, $Res Function(ElementContent) then) =
      _$ElementContentCopyWithImpl<$Res, ElementContent>;
}

/// @nodoc
class _$ElementContentCopyWithImpl<$Res, $Val extends ElementContent>
    implements $ElementContentCopyWith<$Res> {
  _$ElementContentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ElementContent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$CharsContentImplCopyWith<$Res> {
  factory _$$CharsContentImplCopyWith(
          _$CharsContentImpl value, $Res Function(_$CharsContentImpl) then) =
      __$$CharsContentImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<CharElement> chars});
}

/// @nodoc
class __$$CharsContentImplCopyWithImpl<$Res>
    extends _$ElementContentCopyWithImpl<$Res, _$CharsContentImpl>
    implements _$$CharsContentImplCopyWith<$Res> {
  __$$CharsContentImplCopyWithImpl(
      _$CharsContentImpl _value, $Res Function(_$CharsContentImpl) _then)
      : super(_value, _then);

  /// Create a copy of ElementContent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chars = null,
  }) {
    return _then(_$CharsContentImpl(
      chars: null == chars
          ? _value.chars
          : chars // ignore: cast_nullable_to_non_nullable
              as List<CharElement>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CharsContentImpl extends CharsContent {
  _$CharsContentImpl({this.chars = const [], final String? $type})
      : $type = $type ?? 'chars',
        super._();

  factory _$CharsContentImpl.fromJson(Map<String, dynamic> json) =>
      _$$CharsContentImplFromJson(json);

  /// 字符列表
  @override
  @JsonKey()
  List<CharElement> chars;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'ElementContent.chars(chars: $chars)';
  }

  /// Create a copy of ElementContent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CharsContentImplCopyWith<_$CharsContentImpl> get copyWith =>
      __$$CharsContentImplCopyWithImpl<_$CharsContentImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<CharElement> chars) chars,
    required TResult Function(ImageElement image) image,
    required TResult Function(TextElement text) text,
  }) {
    return chars(this.chars);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<CharElement> chars)? chars,
    TResult? Function(ImageElement image)? image,
    TResult? Function(TextElement text)? text,
  }) {
    return chars?.call(this.chars);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<CharElement> chars)? chars,
    TResult Function(ImageElement image)? image,
    TResult Function(TextElement text)? text,
    required TResult orElse(),
  }) {
    if (chars != null) {
      return chars(this.chars);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CharsContent value) chars,
    required TResult Function(ImageContent value) image,
    required TResult Function(TextContent value) text,
  }) {
    return chars(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CharsContent value)? chars,
    TResult? Function(ImageContent value)? image,
    TResult? Function(TextContent value)? text,
  }) {
    return chars?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CharsContent value)? chars,
    TResult Function(ImageContent value)? image,
    TResult Function(TextContent value)? text,
    required TResult orElse(),
  }) {
    if (chars != null) {
      return chars(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$CharsContentImplToJson(
      this,
    );
  }
}

abstract class CharsContent extends ElementContent {
  factory CharsContent({List<CharElement> chars}) = _$CharsContentImpl;
  CharsContent._() : super._();

  factory CharsContent.fromJson(Map<String, dynamic> json) =
      _$CharsContentImpl.fromJson;

  /// 字符列表
  List<CharElement> get chars;

  /// 字符列表
  set chars(List<CharElement> value);

  /// Create a copy of ElementContent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CharsContentImplCopyWith<_$CharsContentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ImageContentImplCopyWith<$Res> {
  factory _$$ImageContentImplCopyWith(
          _$ImageContentImpl value, $Res Function(_$ImageContentImpl) then) =
      __$$ImageContentImplCopyWithImpl<$Res>;
  @useResult
  $Res call({ImageElement image});

  $ImageElementCopyWith<$Res> get image;
}

/// @nodoc
class __$$ImageContentImplCopyWithImpl<$Res>
    extends _$ElementContentCopyWithImpl<$Res, _$ImageContentImpl>
    implements _$$ImageContentImplCopyWith<$Res> {
  __$$ImageContentImplCopyWithImpl(
      _$ImageContentImpl _value, $Res Function(_$ImageContentImpl) _then)
      : super(_value, _then);

  /// Create a copy of ElementContent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? image = null,
  }) {
    return _then(_$ImageContentImpl(
      image: null == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as ImageElement,
    ));
  }

  /// Create a copy of ElementContent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ImageElementCopyWith<$Res> get image {
    return $ImageElementCopyWith<$Res>(_value.image, (value) {
      return _then(_value.copyWith(image: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class _$ImageContentImpl extends ImageContent {
  _$ImageContentImpl({required this.image, final String? $type})
      : $type = $type ?? 'image',
        super._();

  factory _$ImageContentImpl.fromJson(Map<String, dynamic> json) =>
      _$$ImageContentImplFromJson(json);

  /// 图片对象
  @override
  ImageElement image;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'ElementContent.image(image: $image)';
  }

  /// Create a copy of ElementContent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ImageContentImplCopyWith<_$ImageContentImpl> get copyWith =>
      __$$ImageContentImplCopyWithImpl<_$ImageContentImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<CharElement> chars) chars,
    required TResult Function(ImageElement image) image,
    required TResult Function(TextElement text) text,
  }) {
    return image(this.image);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<CharElement> chars)? chars,
    TResult? Function(ImageElement image)? image,
    TResult? Function(TextElement text)? text,
  }) {
    return image?.call(this.image);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<CharElement> chars)? chars,
    TResult Function(ImageElement image)? image,
    TResult Function(TextElement text)? text,
    required TResult orElse(),
  }) {
    if (image != null) {
      return image(this.image);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CharsContent value) chars,
    required TResult Function(ImageContent value) image,
    required TResult Function(TextContent value) text,
  }) {
    return image(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CharsContent value)? chars,
    TResult? Function(ImageContent value)? image,
    TResult? Function(TextContent value)? text,
  }) {
    return image?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CharsContent value)? chars,
    TResult Function(ImageContent value)? image,
    TResult Function(TextContent value)? text,
    required TResult orElse(),
  }) {
    if (image != null) {
      return image(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ImageContentImplToJson(
      this,
    );
  }
}

abstract class ImageContent extends ElementContent {
  factory ImageContent({required ImageElement image}) = _$ImageContentImpl;
  ImageContent._() : super._();

  factory ImageContent.fromJson(Map<String, dynamic> json) =
      _$ImageContentImpl.fromJson;

  /// 图片对象
  ImageElement get image;

  /// 图片对象
  set image(ImageElement value);

  /// Create a copy of ElementContent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ImageContentImplCopyWith<_$ImageContentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$TextContentImplCopyWith<$Res> {
  factory _$$TextContentImplCopyWith(
          _$TextContentImpl value, $Res Function(_$TextContentImpl) then) =
      __$$TextContentImplCopyWithImpl<$Res>;
  @useResult
  $Res call({TextElement text});

  $TextElementCopyWith<$Res> get text;
}

/// @nodoc
class __$$TextContentImplCopyWithImpl<$Res>
    extends _$ElementContentCopyWithImpl<$Res, _$TextContentImpl>
    implements _$$TextContentImplCopyWith<$Res> {
  __$$TextContentImplCopyWithImpl(
      _$TextContentImpl _value, $Res Function(_$TextContentImpl) _then)
      : super(_value, _then);

  /// Create a copy of ElementContent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? text = null,
  }) {
    return _then(_$TextContentImpl(
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as TextElement,
    ));
  }

  /// Create a copy of ElementContent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TextElementCopyWith<$Res> get text {
    return $TextElementCopyWith<$Res>(_value.text, (value) {
      return _then(_value.copyWith(text: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class _$TextContentImpl extends TextContent {
  _$TextContentImpl({required this.text, final String? $type})
      : $type = $type ?? 'text',
        super._();

  factory _$TextContentImpl.fromJson(Map<String, dynamic> json) =>
      _$$TextContentImplFromJson(json);

  /// 文本对象
  @override
  TextElement text;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'ElementContent.text(text: $text)';
  }

  /// Create a copy of ElementContent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TextContentImplCopyWith<_$TextContentImpl> get copyWith =>
      __$$TextContentImplCopyWithImpl<_$TextContentImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<CharElement> chars) chars,
    required TResult Function(ImageElement image) image,
    required TResult Function(TextElement text) text,
  }) {
    return text(this.text);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<CharElement> chars)? chars,
    TResult? Function(ImageElement image)? image,
    TResult? Function(TextElement text)? text,
  }) {
    return text?.call(this.text);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<CharElement> chars)? chars,
    TResult Function(ImageElement image)? image,
    TResult Function(TextElement text)? text,
    required TResult orElse(),
  }) {
    if (text != null) {
      return text(this.text);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CharsContent value) chars,
    required TResult Function(ImageContent value) image,
    required TResult Function(TextContent value) text,
  }) {
    return text(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CharsContent value)? chars,
    TResult? Function(ImageContent value)? image,
    TResult? Function(TextContent value)? text,
  }) {
    return text?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CharsContent value)? chars,
    TResult Function(ImageContent value)? image,
    TResult Function(TextContent value)? text,
    required TResult orElse(),
  }) {
    if (text != null) {
      return text(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$TextContentImplToJson(
      this,
    );
  }
}

abstract class TextContent extends ElementContent {
  factory TextContent({required TextElement text}) = _$TextContentImpl;
  TextContent._() : super._();

  factory TextContent.fromJson(Map<String, dynamic> json) =
      _$TextContentImpl.fromJson;

  /// 文本对象
  TextElement get text;

  /// 文本对象
  set text(TextElement value);

  /// Create a copy of ElementContent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TextContentImplCopyWith<_$TextContentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
