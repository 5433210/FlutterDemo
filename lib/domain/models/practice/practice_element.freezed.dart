// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'practice_element.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PracticeElement _$PracticeElementFromJson(Map<String, dynamic> json) {
  return _PracticeElement.fromJson(json);
}

/// @nodoc
mixin _$PracticeElement {
  /// 元素ID
  String get id => throw _privateConstructorUsedError;

  /// 元素类型
  @JsonKey(name: 'type')
  String get elementType => throw _privateConstructorUsedError;

  /// 元素几何属性
  ElementGeometry get geometry => throw _privateConstructorUsedError;

  /// 元素样式
  ElementStyle get style => throw _privateConstructorUsedError;

  /// 元素内容
  ElementContent get content => throw _privateConstructorUsedError;

  /// 创建时间
  int get createTime => throw _privateConstructorUsedError;

  /// 更新时间
  int get updateTime => throw _privateConstructorUsedError;

  /// Serializes this PracticeElement to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PracticeElement
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PracticeElementCopyWith<PracticeElement> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PracticeElementCopyWith<$Res> {
  factory $PracticeElementCopyWith(
          PracticeElement value, $Res Function(PracticeElement) then) =
      _$PracticeElementCopyWithImpl<$Res, PracticeElement>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'type') String elementType,
      ElementGeometry geometry,
      ElementStyle style,
      ElementContent content,
      int createTime,
      int updateTime});

  $ElementGeometryCopyWith<$Res> get geometry;
  $ElementStyleCopyWith<$Res> get style;
  $ElementContentCopyWith<$Res> get content;
}

/// @nodoc
class _$PracticeElementCopyWithImpl<$Res, $Val extends PracticeElement>
    implements $PracticeElementCopyWith<$Res> {
  _$PracticeElementCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PracticeElement
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? elementType = null,
    Object? geometry = null,
    Object? style = null,
    Object? content = null,
    Object? createTime = null,
    Object? updateTime = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      elementType: null == elementType
          ? _value.elementType
          : elementType // ignore: cast_nullable_to_non_nullable
              as String,
      geometry: null == geometry
          ? _value.geometry
          : geometry // ignore: cast_nullable_to_non_nullable
              as ElementGeometry,
      style: null == style
          ? _value.style
          : style // ignore: cast_nullable_to_non_nullable
              as ElementStyle,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as ElementContent,
      createTime: null == createTime
          ? _value.createTime
          : createTime // ignore: cast_nullable_to_non_nullable
              as int,
      updateTime: null == updateTime
          ? _value.updateTime
          : updateTime // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }

  /// Create a copy of PracticeElement
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ElementGeometryCopyWith<$Res> get geometry {
    return $ElementGeometryCopyWith<$Res>(_value.geometry, (value) {
      return _then(_value.copyWith(geometry: value) as $Val);
    });
  }

  /// Create a copy of PracticeElement
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ElementStyleCopyWith<$Res> get style {
    return $ElementStyleCopyWith<$Res>(_value.style, (value) {
      return _then(_value.copyWith(style: value) as $Val);
    });
  }

  /// Create a copy of PracticeElement
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ElementContentCopyWith<$Res> get content {
    return $ElementContentCopyWith<$Res>(_value.content, (value) {
      return _then(_value.copyWith(content: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PracticeElementImplCopyWith<$Res>
    implements $PracticeElementCopyWith<$Res> {
  factory _$$PracticeElementImplCopyWith(_$PracticeElementImpl value,
          $Res Function(_$PracticeElementImpl) then) =
      __$$PracticeElementImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'type') String elementType,
      ElementGeometry geometry,
      ElementStyle style,
      ElementContent content,
      int createTime,
      int updateTime});

  @override
  $ElementGeometryCopyWith<$Res> get geometry;
  @override
  $ElementStyleCopyWith<$Res> get style;
  @override
  $ElementContentCopyWith<$Res> get content;
}

/// @nodoc
class __$$PracticeElementImplCopyWithImpl<$Res>
    extends _$PracticeElementCopyWithImpl<$Res, _$PracticeElementImpl>
    implements _$$PracticeElementImplCopyWith<$Res> {
  __$$PracticeElementImplCopyWithImpl(
      _$PracticeElementImpl _value, $Res Function(_$PracticeElementImpl) _then)
      : super(_value, _then);

  /// Create a copy of PracticeElement
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? elementType = null,
    Object? geometry = null,
    Object? style = null,
    Object? content = null,
    Object? createTime = null,
    Object? updateTime = null,
  }) {
    return _then(_$PracticeElementImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      elementType: null == elementType
          ? _value.elementType
          : elementType // ignore: cast_nullable_to_non_nullable
              as String,
      geometry: null == geometry
          ? _value.geometry
          : geometry // ignore: cast_nullable_to_non_nullable
              as ElementGeometry,
      style: null == style
          ? _value.style
          : style // ignore: cast_nullable_to_non_nullable
              as ElementStyle,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as ElementContent,
      createTime: null == createTime
          ? _value.createTime
          : createTime // ignore: cast_nullable_to_non_nullable
              as int,
      updateTime: null == updateTime
          ? _value.updateTime
          : updateTime // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PracticeElementImpl extends _PracticeElement {
  const _$PracticeElementImpl(
      {required this.id,
      @JsonKey(name: 'type') required this.elementType,
      required this.geometry,
      required this.style,
      required this.content,
      this.createTime = 0,
      this.updateTime = 0})
      : super._();

  factory _$PracticeElementImpl.fromJson(Map<String, dynamic> json) =>
      _$$PracticeElementImplFromJson(json);

  /// 元素ID
  @override
  final String id;

  /// 元素类型
  @override
  @JsonKey(name: 'type')
  final String elementType;

  /// 元素几何属性
  @override
  final ElementGeometry geometry;

  /// 元素样式
  @override
  final ElementStyle style;

  /// 元素内容
  @override
  final ElementContent content;

  /// 创建时间
  @override
  @JsonKey()
  final int createTime;

  /// 更新时间
  @override
  @JsonKey()
  final int updateTime;

  @override
  String toString() {
    return 'PracticeElement(id: $id, elementType: $elementType, geometry: $geometry, style: $style, content: $content, createTime: $createTime, updateTime: $updateTime)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PracticeElementImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.elementType, elementType) ||
                other.elementType == elementType) &&
            (identical(other.geometry, geometry) ||
                other.geometry == geometry) &&
            (identical(other.style, style) || other.style == style) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.createTime, createTime) ||
                other.createTime == createTime) &&
            (identical(other.updateTime, updateTime) ||
                other.updateTime == updateTime));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, elementType, geometry, style,
      content, createTime, updateTime);

  /// Create a copy of PracticeElement
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PracticeElementImplCopyWith<_$PracticeElementImpl> get copyWith =>
      __$$PracticeElementImplCopyWithImpl<_$PracticeElementImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PracticeElementImplToJson(
      this,
    );
  }
}

abstract class _PracticeElement extends PracticeElement {
  const factory _PracticeElement(
      {required final String id,
      @JsonKey(name: 'type') required final String elementType,
      required final ElementGeometry geometry,
      required final ElementStyle style,
      required final ElementContent content,
      final int createTime,
      final int updateTime}) = _$PracticeElementImpl;
  const _PracticeElement._() : super._();

  factory _PracticeElement.fromJson(Map<String, dynamic> json) =
      _$PracticeElementImpl.fromJson;

  /// 元素ID
  @override
  String get id;

  /// 元素类型
  @override
  @JsonKey(name: 'type')
  String get elementType;

  /// 元素几何属性
  @override
  ElementGeometry get geometry;

  /// 元素样式
  @override
  ElementStyle get style;

  /// 元素内容
  @override
  ElementContent get content;

  /// 创建时间
  @override
  int get createTime;

  /// 更新时间
  @override
  int get updateTime;

  /// Create a copy of PracticeElement
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PracticeElementImplCopyWith<_$PracticeElementImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
