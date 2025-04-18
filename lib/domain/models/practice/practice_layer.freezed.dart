// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'practice_layer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PracticeLayer _$PracticeLayerFromJson(Map<String, dynamic> json) {
  return _PracticeLayer.fromJson(json);
}

/// @nodoc
mixin _$PracticeLayer {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int get order => throw _privateConstructorUsedError;
  bool get isVisible => throw _privateConstructorUsedError;
  bool get isLocked => throw _privateConstructorUsedError;
  List<PracticeElement> get elements => throw _privateConstructorUsedError;
  double get opacity => throw _privateConstructorUsedError;
  String? get backgroundImage => throw _privateConstructorUsedError;

  /// Serializes this PracticeLayer to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PracticeLayer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PracticeLayerCopyWith<PracticeLayer> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PracticeLayerCopyWith<$Res> {
  factory $PracticeLayerCopyWith(
          PracticeLayer value, $Res Function(PracticeLayer) then) =
      _$PracticeLayerCopyWithImpl<$Res, PracticeLayer>;
  @useResult
  $Res call(
      {String id,
      String name,
      int order,
      bool isVisible,
      bool isLocked,
      List<PracticeElement> elements,
      double opacity,
      String? backgroundImage});
}

/// @nodoc
class _$PracticeLayerCopyWithImpl<$Res, $Val extends PracticeLayer>
    implements $PracticeLayerCopyWith<$Res> {
  _$PracticeLayerCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PracticeLayer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? order = null,
    Object? isVisible = null,
    Object? isLocked = null,
    Object? elements = null,
    Object? opacity = null,
    Object? backgroundImage = freezed,
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
      order: null == order
          ? _value.order
          : order // ignore: cast_nullable_to_non_nullable
              as int,
      isVisible: null == isVisible
          ? _value.isVisible
          : isVisible // ignore: cast_nullable_to_non_nullable
              as bool,
      isLocked: null == isLocked
          ? _value.isLocked
          : isLocked // ignore: cast_nullable_to_non_nullable
              as bool,
      elements: null == elements
          ? _value.elements
          : elements // ignore: cast_nullable_to_non_nullable
              as List<PracticeElement>,
      opacity: null == opacity
          ? _value.opacity
          : opacity // ignore: cast_nullable_to_non_nullable
              as double,
      backgroundImage: freezed == backgroundImage
          ? _value.backgroundImage
          : backgroundImage // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PracticeLayerImplCopyWith<$Res>
    implements $PracticeLayerCopyWith<$Res> {
  factory _$$PracticeLayerImplCopyWith(
          _$PracticeLayerImpl value, $Res Function(_$PracticeLayerImpl) then) =
      __$$PracticeLayerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      int order,
      bool isVisible,
      bool isLocked,
      List<PracticeElement> elements,
      double opacity,
      String? backgroundImage});
}

/// @nodoc
class __$$PracticeLayerImplCopyWithImpl<$Res>
    extends _$PracticeLayerCopyWithImpl<$Res, _$PracticeLayerImpl>
    implements _$$PracticeLayerImplCopyWith<$Res> {
  __$$PracticeLayerImplCopyWithImpl(
      _$PracticeLayerImpl _value, $Res Function(_$PracticeLayerImpl) _then)
      : super(_value, _then);

  /// Create a copy of PracticeLayer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? order = null,
    Object? isVisible = null,
    Object? isLocked = null,
    Object? elements = null,
    Object? opacity = null,
    Object? backgroundImage = freezed,
  }) {
    return _then(_$PracticeLayerImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      order: null == order
          ? _value.order
          : order // ignore: cast_nullable_to_non_nullable
              as int,
      isVisible: null == isVisible
          ? _value.isVisible
          : isVisible // ignore: cast_nullable_to_non_nullable
              as bool,
      isLocked: null == isLocked
          ? _value.isLocked
          : isLocked // ignore: cast_nullable_to_non_nullable
              as bool,
      elements: null == elements
          ? _value._elements
          : elements // ignore: cast_nullable_to_non_nullable
              as List<PracticeElement>,
      opacity: null == opacity
          ? _value.opacity
          : opacity // ignore: cast_nullable_to_non_nullable
              as double,
      backgroundImage: freezed == backgroundImage
          ? _value.backgroundImage
          : backgroundImage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PracticeLayerImpl implements _PracticeLayer {
  const _$PracticeLayerImpl(
      {required this.id,
      required this.name,
      required this.order,
      this.isVisible = true,
      this.isLocked = false,
      final List<PracticeElement> elements = const <PracticeElement>[],
      this.opacity = 1.0,
      this.backgroundImage})
      : _elements = elements;

  factory _$PracticeLayerImpl.fromJson(Map<String, dynamic> json) =>
      _$$PracticeLayerImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final int order;
  @override
  @JsonKey()
  final bool isVisible;
  @override
  @JsonKey()
  final bool isLocked;
  final List<PracticeElement> _elements;
  @override
  @JsonKey()
  List<PracticeElement> get elements {
    if (_elements is EqualUnmodifiableListView) return _elements;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_elements);
  }

  @override
  @JsonKey()
  final double opacity;
  @override
  final String? backgroundImage;

  @override
  String toString() {
    return 'PracticeLayer(id: $id, name: $name, order: $order, isVisible: $isVisible, isLocked: $isLocked, elements: $elements, opacity: $opacity, backgroundImage: $backgroundImage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PracticeLayerImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.order, order) || other.order == order) &&
            (identical(other.isVisible, isVisible) ||
                other.isVisible == isVisible) &&
            (identical(other.isLocked, isLocked) ||
                other.isLocked == isLocked) &&
            const DeepCollectionEquality().equals(other._elements, _elements) &&
            (identical(other.opacity, opacity) || other.opacity == opacity) &&
            (identical(other.backgroundImage, backgroundImage) ||
                other.backgroundImage == backgroundImage));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      order,
      isVisible,
      isLocked,
      const DeepCollectionEquality().hash(_elements),
      opacity,
      backgroundImage);

  /// Create a copy of PracticeLayer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PracticeLayerImplCopyWith<_$PracticeLayerImpl> get copyWith =>
      __$$PracticeLayerImplCopyWithImpl<_$PracticeLayerImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PracticeLayerImplToJson(
      this,
    );
  }
}

abstract class _PracticeLayer implements PracticeLayer {
  const factory _PracticeLayer(
      {required final String id,
      required final String name,
      required final int order,
      final bool isVisible,
      final bool isLocked,
      final List<PracticeElement> elements,
      final double opacity,
      final String? backgroundImage}) = _$PracticeLayerImpl;

  factory _PracticeLayer.fromJson(Map<String, dynamic> json) =
      _$PracticeLayerImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  int get order;
  @override
  bool get isVisible;
  @override
  bool get isLocked;
  @override
  List<PracticeElement> get elements;
  @override
  double get opacity;
  @override
  String? get backgroundImage;

  /// Create a copy of PracticeLayer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PracticeLayerImplCopyWith<_$PracticeLayerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
