// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'char_style.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CharStyle _$CharStyleFromJson(Map<String, dynamic> json) {
  return _CharStyle.fromJson(json);
}

/// @nodoc
mixin _$CharStyle {
  /// 颜色，默认黑色
  String get color => throw _privateConstructorUsedError;

  /// 不透明度，默认完全不透明
  double get opacity => throw _privateConstructorUsedError;

  /// 自定义样式属性
  Map<String, dynamic> get customStyle => throw _privateConstructorUsedError;

  /// Serializes this CharStyle to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CharStyle
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CharStyleCopyWith<CharStyle> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CharStyleCopyWith<$Res> {
  factory $CharStyleCopyWith(CharStyle value, $Res Function(CharStyle) then) =
      _$CharStyleCopyWithImpl<$Res, CharStyle>;
  @useResult
  $Res call({String color, double opacity, Map<String, dynamic> customStyle});
}

/// @nodoc
class _$CharStyleCopyWithImpl<$Res, $Val extends CharStyle>
    implements $CharStyleCopyWith<$Res> {
  _$CharStyleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CharStyle
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? color = null,
    Object? opacity = null,
    Object? customStyle = null,
  }) {
    return _then(_value.copyWith(
      color: null == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as String,
      opacity: null == opacity
          ? _value.opacity
          : opacity // ignore: cast_nullable_to_non_nullable
              as double,
      customStyle: null == customStyle
          ? _value.customStyle
          : customStyle // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CharStyleImplCopyWith<$Res>
    implements $CharStyleCopyWith<$Res> {
  factory _$$CharStyleImplCopyWith(
          _$CharStyleImpl value, $Res Function(_$CharStyleImpl) then) =
      __$$CharStyleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String color, double opacity, Map<String, dynamic> customStyle});
}

/// @nodoc
class __$$CharStyleImplCopyWithImpl<$Res>
    extends _$CharStyleCopyWithImpl<$Res, _$CharStyleImpl>
    implements _$$CharStyleImplCopyWith<$Res> {
  __$$CharStyleImplCopyWithImpl(
      _$CharStyleImpl _value, $Res Function(_$CharStyleImpl) _then)
      : super(_value, _then);

  /// Create a copy of CharStyle
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? color = null,
    Object? opacity = null,
    Object? customStyle = null,
  }) {
    return _then(_$CharStyleImpl(
      color: null == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as String,
      opacity: null == opacity
          ? _value.opacity
          : opacity // ignore: cast_nullable_to_non_nullable
              as double,
      customStyle: null == customStyle
          ? _value._customStyle
          : customStyle // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CharStyleImpl extends _CharStyle {
  const _$CharStyleImpl(
      {this.color = '#000000',
      this.opacity = 1.0,
      final Map<String, dynamic> customStyle = const {}})
      : _customStyle = customStyle,
        super._();

  factory _$CharStyleImpl.fromJson(Map<String, dynamic> json) =>
      _$$CharStyleImplFromJson(json);

  /// 颜色，默认黑色
  @override
  @JsonKey()
  final String color;

  /// 不透明度，默认完全不透明
  @override
  @JsonKey()
  final double opacity;

  /// 自定义样式属性
  final Map<String, dynamic> _customStyle;

  /// 自定义样式属性
  @override
  @JsonKey()
  Map<String, dynamic> get customStyle {
    if (_customStyle is EqualUnmodifiableMapView) return _customStyle;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_customStyle);
  }

  @override
  String toString() {
    return 'CharStyle(color: $color, opacity: $opacity, customStyle: $customStyle)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CharStyleImpl &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.opacity, opacity) || other.opacity == opacity) &&
            const DeepCollectionEquality()
                .equals(other._customStyle, _customStyle));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, color, opacity,
      const DeepCollectionEquality().hash(_customStyle));

  /// Create a copy of CharStyle
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CharStyleImplCopyWith<_$CharStyleImpl> get copyWith =>
      __$$CharStyleImplCopyWithImpl<_$CharStyleImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CharStyleImplToJson(
      this,
    );
  }
}

abstract class _CharStyle extends CharStyle {
  const factory _CharStyle(
      {final String color,
      final double opacity,
      final Map<String, dynamic> customStyle}) = _$CharStyleImpl;
  const _CharStyle._() : super._();

  factory _CharStyle.fromJson(Map<String, dynamic> json) =
      _$CharStyleImpl.fromJson;

  /// 颜色，默认黑色
  @override
  String get color;

  /// 不透明度，默认完全不透明
  @override
  double get opacity;

  /// 自定义样式属性
  @override
  Map<String, dynamic> get customStyle;

  /// Create a copy of CharStyle
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CharStyleImplCopyWith<_$CharStyleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
