// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'element_style.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ElementStyle _$ElementStyleFromJson(Map<String, dynamic> json) {
  return _ElementStyle.fromJson(json);
}

/// @nodoc
mixin _$ElementStyle {
  /// 透明度
  double get opacity => throw _privateConstructorUsedError;

  /// 是否可见
  bool get visible => throw _privateConstructorUsedError;

  /// 是否锁定
  bool get locked => throw _privateConstructorUsedError;

  /// 自定义样式属性
  Map<String, dynamic> get properties => throw _privateConstructorUsedError;

  /// Serializes this ElementStyle to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ElementStyle
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ElementStyleCopyWith<ElementStyle> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ElementStyleCopyWith<$Res> {
  factory $ElementStyleCopyWith(
          ElementStyle value, $Res Function(ElementStyle) then) =
      _$ElementStyleCopyWithImpl<$Res, ElementStyle>;
  @useResult
  $Res call(
      {double opacity,
      bool visible,
      bool locked,
      Map<String, dynamic> properties});
}

/// @nodoc
class _$ElementStyleCopyWithImpl<$Res, $Val extends ElementStyle>
    implements $ElementStyleCopyWith<$Res> {
  _$ElementStyleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ElementStyle
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? opacity = null,
    Object? visible = null,
    Object? locked = null,
    Object? properties = null,
  }) {
    return _then(_value.copyWith(
      opacity: null == opacity
          ? _value.opacity
          : opacity // ignore: cast_nullable_to_non_nullable
              as double,
      visible: null == visible
          ? _value.visible
          : visible // ignore: cast_nullable_to_non_nullable
              as bool,
      locked: null == locked
          ? _value.locked
          : locked // ignore: cast_nullable_to_non_nullable
              as bool,
      properties: null == properties
          ? _value.properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ElementStyleImplCopyWith<$Res>
    implements $ElementStyleCopyWith<$Res> {
  factory _$$ElementStyleImplCopyWith(
          _$ElementStyleImpl value, $Res Function(_$ElementStyleImpl) then) =
      __$$ElementStyleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double opacity,
      bool visible,
      bool locked,
      Map<String, dynamic> properties});
}

/// @nodoc
class __$$ElementStyleImplCopyWithImpl<$Res>
    extends _$ElementStyleCopyWithImpl<$Res, _$ElementStyleImpl>
    implements _$$ElementStyleImplCopyWith<$Res> {
  __$$ElementStyleImplCopyWithImpl(
      _$ElementStyleImpl _value, $Res Function(_$ElementStyleImpl) _then)
      : super(_value, _then);

  /// Create a copy of ElementStyle
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? opacity = null,
    Object? visible = null,
    Object? locked = null,
    Object? properties = null,
  }) {
    return _then(_$ElementStyleImpl(
      opacity: null == opacity
          ? _value.opacity
          : opacity // ignore: cast_nullable_to_non_nullable
              as double,
      visible: null == visible
          ? _value.visible
          : visible // ignore: cast_nullable_to_non_nullable
              as bool,
      locked: null == locked
          ? _value.locked
          : locked // ignore: cast_nullable_to_non_nullable
              as bool,
      properties: null == properties
          ? _value._properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ElementStyleImpl extends _ElementStyle {
  const _$ElementStyleImpl(
      {this.opacity = 1.0,
      this.visible = true,
      this.locked = false,
      final Map<String, dynamic> properties = const {}})
      : _properties = properties,
        super._();

  factory _$ElementStyleImpl.fromJson(Map<String, dynamic> json) =>
      _$$ElementStyleImplFromJson(json);

  /// 透明度
  @override
  @JsonKey()
  final double opacity;

  /// 是否可见
  @override
  @JsonKey()
  final bool visible;

  /// 是否锁定
  @override
  @JsonKey()
  final bool locked;

  /// 自定义样式属性
  final Map<String, dynamic> _properties;

  /// 自定义样式属性
  @override
  @JsonKey()
  Map<String, dynamic> get properties {
    if (_properties is EqualUnmodifiableMapView) return _properties;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_properties);
  }

  @override
  String toString() {
    return 'ElementStyle(opacity: $opacity, visible: $visible, locked: $locked, properties: $properties)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ElementStyleImpl &&
            (identical(other.opacity, opacity) || other.opacity == opacity) &&
            (identical(other.visible, visible) || other.visible == visible) &&
            (identical(other.locked, locked) || other.locked == locked) &&
            const DeepCollectionEquality()
                .equals(other._properties, _properties));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, opacity, visible, locked,
      const DeepCollectionEquality().hash(_properties));

  /// Create a copy of ElementStyle
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ElementStyleImplCopyWith<_$ElementStyleImpl> get copyWith =>
      __$$ElementStyleImplCopyWithImpl<_$ElementStyleImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ElementStyleImplToJson(
      this,
    );
  }
}

abstract class _ElementStyle extends ElementStyle {
  const factory _ElementStyle(
      {final double opacity,
      final bool visible,
      final bool locked,
      final Map<String, dynamic> properties}) = _$ElementStyleImpl;
  const _ElementStyle._() : super._();

  factory _ElementStyle.fromJson(Map<String, dynamic> json) =
      _$ElementStyleImpl.fromJson;

  /// 透明度
  @override
  double get opacity;

  /// 是否可见
  @override
  bool get visible;

  /// 是否锁定
  @override
  bool get locked;

  /// 自定义样式属性
  @override
  Map<String, dynamic> get properties;

  /// Create a copy of ElementStyle
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ElementStyleImplCopyWith<_$ElementStyleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
