// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'practice_page.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PracticePage _$PracticePageFromJson(Map<String, dynamic> json) {
  return _PracticePage.fromJson(json);
}

/// @nodoc
mixin _$PracticePage {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int get index => throw _privateConstructorUsedError;
  double get width => throw _privateConstructorUsedError;
  double get height => throw _privateConstructorUsedError;
  String get orientation => throw _privateConstructorUsedError; // 添加方向属性，默认为纵向
  String get backgroundType => throw _privateConstructorUsedError;
  String? get backgroundImage => throw _privateConstructorUsedError;
  String get backgroundColor => throw _privateConstructorUsedError;
  String? get backgroundTexture => throw _privateConstructorUsedError;
  double get backgroundOpacity => throw _privateConstructorUsedError;
  @EdgeInsetsConverter()
  EdgeInsets get margin => throw _privateConstructorUsedError;
  List<PracticeLayer> get layers => throw _privateConstructorUsedError;

  /// Serializes this PracticePage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PracticePage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PracticePageCopyWith<PracticePage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PracticePageCopyWith<$Res> {
  factory $PracticePageCopyWith(
          PracticePage value, $Res Function(PracticePage) then) =
      _$PracticePageCopyWithImpl<$Res, PracticePage>;
  @useResult
  $Res call(
      {String id,
      String name,
      int index,
      double width,
      double height,
      String orientation,
      String backgroundType,
      String? backgroundImage,
      String backgroundColor,
      String? backgroundTexture,
      double backgroundOpacity,
      @EdgeInsetsConverter() EdgeInsets margin,
      List<PracticeLayer> layers});
}

/// @nodoc
class _$PracticePageCopyWithImpl<$Res, $Val extends PracticePage>
    implements $PracticePageCopyWith<$Res> {
  _$PracticePageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PracticePage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? index = null,
    Object? width = null,
    Object? height = null,
    Object? orientation = null,
    Object? backgroundType = null,
    Object? backgroundImage = freezed,
    Object? backgroundColor = null,
    Object? backgroundTexture = freezed,
    Object? backgroundOpacity = null,
    Object? margin = null,
    Object? layers = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      index: null == index
          ? _value.index
          : index // ignore: cast_nullable_to_non_nullable
              as int,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as double,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as double,
      orientation: null == orientation
          ? _value.orientation
          : orientation // ignore: cast_nullable_to_non_nullable
              as String,
      backgroundType: null == backgroundType
          ? _value.backgroundType
          : backgroundType // ignore: cast_nullable_to_non_nullable
              as String,
      backgroundImage: freezed == backgroundImage
          ? _value.backgroundImage
          : backgroundImage // ignore: cast_nullable_to_non_nullable
              as String?,
      backgroundColor: null == backgroundColor
          ? _value.backgroundColor
          : backgroundColor // ignore: cast_nullable_to_non_nullable
              as String,
      backgroundTexture: freezed == backgroundTexture
          ? _value.backgroundTexture
          : backgroundTexture // ignore: cast_nullable_to_non_nullable
              as String?,
      backgroundOpacity: null == backgroundOpacity
          ? _value.backgroundOpacity
          : backgroundOpacity // ignore: cast_nullable_to_non_nullable
              as double,
      margin: null == margin
          ? _value.margin
          : margin // ignore: cast_nullable_to_non_nullable
              as EdgeInsets,
      layers: null == layers
          ? _value.layers
          : layers // ignore: cast_nullable_to_non_nullable
              as List<PracticeLayer>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PracticePageImplCopyWith<$Res>
    implements $PracticePageCopyWith<$Res> {
  factory _$$PracticePageImplCopyWith(
          _$PracticePageImpl value, $Res Function(_$PracticePageImpl) then) =
      __$$PracticePageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      int index,
      double width,
      double height,
      String orientation,
      String backgroundType,
      String? backgroundImage,
      String backgroundColor,
      String? backgroundTexture,
      double backgroundOpacity,
      @EdgeInsetsConverter() EdgeInsets margin,
      List<PracticeLayer> layers});
}

/// @nodoc
class __$$PracticePageImplCopyWithImpl<$Res>
    extends _$PracticePageCopyWithImpl<$Res, _$PracticePageImpl>
    implements _$$PracticePageImplCopyWith<$Res> {
  __$$PracticePageImplCopyWithImpl(
      _$PracticePageImpl _value, $Res Function(_$PracticePageImpl) _then)
      : super(_value, _then);

  /// Create a copy of PracticePage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? index = null,
    Object? width = null,
    Object? height = null,
    Object? orientation = null,
    Object? backgroundType = null,
    Object? backgroundImage = freezed,
    Object? backgroundColor = null,
    Object? backgroundTexture = freezed,
    Object? backgroundOpacity = null,
    Object? margin = null,
    Object? layers = null,
  }) {
    return _then(_$PracticePageImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      index: null == index
          ? _value.index
          : index // ignore: cast_nullable_to_non_nullable
              as int,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as double,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as double,
      orientation: null == orientation
          ? _value.orientation
          : orientation // ignore: cast_nullable_to_non_nullable
              as String,
      backgroundType: null == backgroundType
          ? _value.backgroundType
          : backgroundType // ignore: cast_nullable_to_non_nullable
              as String,
      backgroundImage: freezed == backgroundImage
          ? _value.backgroundImage
          : backgroundImage // ignore: cast_nullable_to_non_nullable
              as String?,
      backgroundColor: null == backgroundColor
          ? _value.backgroundColor
          : backgroundColor // ignore: cast_nullable_to_non_nullable
              as String,
      backgroundTexture: freezed == backgroundTexture
          ? _value.backgroundTexture
          : backgroundTexture // ignore: cast_nullable_to_non_nullable
              as String?,
      backgroundOpacity: null == backgroundOpacity
          ? _value.backgroundOpacity
          : backgroundOpacity // ignore: cast_nullable_to_non_nullable
              as double,
      margin: null == margin
          ? _value.margin
          : margin // ignore: cast_nullable_to_non_nullable
              as EdgeInsets,
      layers: null == layers
          ? _value._layers
          : layers // ignore: cast_nullable_to_non_nullable
              as List<PracticeLayer>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PracticePageImpl extends _PracticePage {
  const _$PracticePageImpl(
      {required this.id,
      this.name = '',
      this.index = 0,
      this.width = 210.0,
      this.height = 297.0,
      this.orientation = 'portrait',
      this.backgroundType = 'color',
      this.backgroundImage,
      this.backgroundColor = '#FFFFFF',
      this.backgroundTexture,
      this.backgroundOpacity = 1.0,
      @EdgeInsetsConverter() this.margin = const EdgeInsets.all(20.0),
      final List<PracticeLayer> layers = const <PracticeLayer>[]})
      : _layers = layers,
        super._();

  factory _$PracticePageImpl.fromJson(Map<String, dynamic> json) =>
      _$$PracticePageImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey()
  final String name;
  @override
  @JsonKey()
  final int index;
  @override
  @JsonKey()
  final double width;
  @override
  @JsonKey()
  final double height;
  @override
  @JsonKey()
  final String orientation;
// 添加方向属性，默认为纵向
  @override
  @JsonKey()
  final String backgroundType;
  @override
  final String? backgroundImage;
  @override
  @JsonKey()
  final String backgroundColor;
  @override
  final String? backgroundTexture;
  @override
  @JsonKey()
  final double backgroundOpacity;
  @override
  @JsonKey()
  @EdgeInsetsConverter()
  final EdgeInsets margin;
  final List<PracticeLayer> _layers;
  @override
  @JsonKey()
  List<PracticeLayer> get layers {
    if (_layers is EqualUnmodifiableListView) return _layers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_layers);
  }

  @override
  String toString() {
    return 'PracticePage(id: $id, name: $name, index: $index, width: $width, height: $height, orientation: $orientation, backgroundType: $backgroundType, backgroundImage: $backgroundImage, backgroundColor: $backgroundColor, backgroundTexture: $backgroundTexture, backgroundOpacity: $backgroundOpacity, margin: $margin, layers: $layers)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PracticePageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.index, index) || other.index == index) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.orientation, orientation) ||
                other.orientation == orientation) &&
            (identical(other.backgroundType, backgroundType) ||
                other.backgroundType == backgroundType) &&
            (identical(other.backgroundImage, backgroundImage) ||
                other.backgroundImage == backgroundImage) &&
            (identical(other.backgroundColor, backgroundColor) ||
                other.backgroundColor == backgroundColor) &&
            (identical(other.backgroundTexture, backgroundTexture) ||
                other.backgroundTexture == backgroundTexture) &&
            (identical(other.backgroundOpacity, backgroundOpacity) ||
                other.backgroundOpacity == backgroundOpacity) &&
            (identical(other.margin, margin) || other.margin == margin) &&
            const DeepCollectionEquality().equals(other._layers, _layers));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      index,
      width,
      height,
      orientation,
      backgroundType,
      backgroundImage,
      backgroundColor,
      backgroundTexture,
      backgroundOpacity,
      margin,
      const DeepCollectionEquality().hash(_layers));

  /// Create a copy of PracticePage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PracticePageImplCopyWith<_$PracticePageImpl> get copyWith =>
      __$$PracticePageImplCopyWithImpl<_$PracticePageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PracticePageImplToJson(
      this,
    );
  }
}

abstract class _PracticePage extends PracticePage {
  const factory _PracticePage(
      {required final String id,
      final String name,
      final int index,
      final double width,
      final double height,
      final String orientation,
      final String backgroundType,
      final String? backgroundImage,
      final String backgroundColor,
      final String? backgroundTexture,
      final double backgroundOpacity,
      @EdgeInsetsConverter() final EdgeInsets margin,
      final List<PracticeLayer> layers}) = _$PracticePageImpl;
  const _PracticePage._() : super._();

  factory _PracticePage.fromJson(Map<String, dynamic> json) =
      _$PracticePageImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  int get index;
  @override
  double get width;
  @override
  double get height;
  @override
  String get orientation; // 添加方向属性，默认为纵向
  @override
  String get backgroundType;
  @override
  String? get backgroundImage;
  @override
  String get backgroundColor;
  @override
  String? get backgroundTexture;
  @override
  double get backgroundOpacity;
  @override
  @EdgeInsetsConverter()
  EdgeInsets get margin;
  @override
  List<PracticeLayer> get layers;

  /// Create a copy of PracticePage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PracticePageImplCopyWith<_$PracticePageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
