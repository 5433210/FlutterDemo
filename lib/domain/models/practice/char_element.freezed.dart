// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'char_element.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CharElement _$CharElementFromJson(Map<String, dynamic> json) {
  return _CharElement.fromJson(json);
}

/// @nodoc
mixin _$CharElement {
  /// 字符ID
  String get charId => throw _privateConstructorUsedError;

  /// 相对位置
  CharPosition get position => throw _privateConstructorUsedError;

  /// 变换信息
  CharTransform get transform => throw _privateConstructorUsedError;

  /// 样式信息
  CharStyle get style => throw _privateConstructorUsedError;

  /// Serializes this CharElement to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CharElement
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CharElementCopyWith<CharElement> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CharElementCopyWith<$Res> {
  factory $CharElementCopyWith(
          CharElement value, $Res Function(CharElement) then) =
      _$CharElementCopyWithImpl<$Res, CharElement>;
  @useResult
  $Res call(
      {String charId,
      CharPosition position,
      CharTransform transform,
      CharStyle style});

  $CharPositionCopyWith<$Res> get position;
  $CharTransformCopyWith<$Res> get transform;
  $CharStyleCopyWith<$Res> get style;
}

/// @nodoc
class _$CharElementCopyWithImpl<$Res, $Val extends CharElement>
    implements $CharElementCopyWith<$Res> {
  _$CharElementCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CharElement
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? charId = null,
    Object? position = null,
    Object? transform = null,
    Object? style = null,
  }) {
    return _then(_value.copyWith(
      charId: null == charId
          ? _value.charId
          : charId // ignore: cast_nullable_to_non_nullable
              as String,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as CharPosition,
      transform: null == transform
          ? _value.transform
          : transform // ignore: cast_nullable_to_non_nullable
              as CharTransform,
      style: null == style
          ? _value.style
          : style // ignore: cast_nullable_to_non_nullable
              as CharStyle,
    ) as $Val);
  }

  /// Create a copy of CharElement
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CharPositionCopyWith<$Res> get position {
    return $CharPositionCopyWith<$Res>(_value.position, (value) {
      return _then(_value.copyWith(position: value) as $Val);
    });
  }

  /// Create a copy of CharElement
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CharTransformCopyWith<$Res> get transform {
    return $CharTransformCopyWith<$Res>(_value.transform, (value) {
      return _then(_value.copyWith(transform: value) as $Val);
    });
  }

  /// Create a copy of CharElement
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CharStyleCopyWith<$Res> get style {
    return $CharStyleCopyWith<$Res>(_value.style, (value) {
      return _then(_value.copyWith(style: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CharElementImplCopyWith<$Res>
    implements $CharElementCopyWith<$Res> {
  factory _$$CharElementImplCopyWith(
          _$CharElementImpl value, $Res Function(_$CharElementImpl) then) =
      __$$CharElementImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String charId,
      CharPosition position,
      CharTransform transform,
      CharStyle style});

  @override
  $CharPositionCopyWith<$Res> get position;
  @override
  $CharTransformCopyWith<$Res> get transform;
  @override
  $CharStyleCopyWith<$Res> get style;
}

/// @nodoc
class __$$CharElementImplCopyWithImpl<$Res>
    extends _$CharElementCopyWithImpl<$Res, _$CharElementImpl>
    implements _$$CharElementImplCopyWith<$Res> {
  __$$CharElementImplCopyWithImpl(
      _$CharElementImpl _value, $Res Function(_$CharElementImpl) _then)
      : super(_value, _then);

  /// Create a copy of CharElement
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? charId = null,
    Object? position = null,
    Object? transform = null,
    Object? style = null,
  }) {
    return _then(_$CharElementImpl(
      charId: null == charId
          ? _value.charId
          : charId // ignore: cast_nullable_to_non_nullable
              as String,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as CharPosition,
      transform: null == transform
          ? _value.transform
          : transform // ignore: cast_nullable_to_non_nullable
              as CharTransform,
      style: null == style
          ? _value.style
          : style // ignore: cast_nullable_to_non_nullable
              as CharStyle,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CharElementImpl extends _CharElement {
  const _$CharElementImpl(
      {required this.charId,
      required this.position,
      this.transform = const CharTransform(),
      this.style = const CharStyle()})
      : super._();

  factory _$CharElementImpl.fromJson(Map<String, dynamic> json) =>
      _$$CharElementImplFromJson(json);

  /// 字符ID
  @override
  final String charId;

  /// 相对位置
  @override
  final CharPosition position;

  /// 变换信息
  @override
  @JsonKey()
  final CharTransform transform;

  /// 样式信息
  @override
  @JsonKey()
  final CharStyle style;

  @override
  String toString() {
    return 'CharElement(charId: $charId, position: $position, transform: $transform, style: $style)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CharElementImpl &&
            (identical(other.charId, charId) || other.charId == charId) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.transform, transform) ||
                other.transform == transform) &&
            (identical(other.style, style) || other.style == style));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, charId, position, transform, style);

  /// Create a copy of CharElement
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CharElementImplCopyWith<_$CharElementImpl> get copyWith =>
      __$$CharElementImplCopyWithImpl<_$CharElementImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CharElementImplToJson(
      this,
    );
  }
}

abstract class _CharElement extends CharElement {
  const factory _CharElement(
      {required final String charId,
      required final CharPosition position,
      final CharTransform transform,
      final CharStyle style}) = _$CharElementImpl;
  const _CharElement._() : super._();

  factory _CharElement.fromJson(Map<String, dynamic> json) =
      _$CharElementImpl.fromJson;

  /// 字符ID
  @override
  String get charId;

  /// 相对位置
  @override
  CharPosition get position;

  /// 变换信息
  @override
  CharTransform get transform;

  /// 样式信息
  @override
  CharStyle get style;

  /// Create a copy of CharElement
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CharElementImplCopyWith<_$CharElementImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
