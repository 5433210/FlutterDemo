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
  /// 图层ID
  String get id => throw _privateConstructorUsedError;

  /// 图层类型
  PracticeLayerType get type => throw _privateConstructorUsedError;

  /// 图片路径
  String get imagePath => throw _privateConstructorUsedError;

  /// 图层名称
  String? get name => throw _privateConstructorUsedError;

  /// 图层描述
  String? get description => throw _privateConstructorUsedError;

  /// 图层可见性
  bool get visible => throw _privateConstructorUsedError;

  /// 图层锁定状态
  bool get locked => throw _privateConstructorUsedError;

  /// 图层不透明度
  double get opacity => throw _privateConstructorUsedError;

  /// 图层顺序
  int get order => throw _privateConstructorUsedError;

  /// 图层元素列表
  List<PracticeElement> get elements => throw _privateConstructorUsedError;

  /// 图层创建时间
  DateTime get createTime => throw _privateConstructorUsedError;

  /// 图层更新时间
  DateTime get updateTime => throw _privateConstructorUsedError;

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
      PracticeLayerType type,
      String imagePath,
      String? name,
      String? description,
      bool visible,
      bool locked,
      double opacity,
      int order,
      List<PracticeElement> elements,
      DateTime createTime,
      DateTime updateTime});
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
    Object? type = null,
    Object? imagePath = null,
    Object? name = freezed,
    Object? description = freezed,
    Object? visible = null,
    Object? locked = null,
    Object? opacity = null,
    Object? order = null,
    Object? elements = null,
    Object? createTime = null,
    Object? updateTime = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as PracticeLayerType,
      imagePath: null == imagePath
          ? _value.imagePath
          : imagePath // ignore: cast_nullable_to_non_nullable
              as String,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      visible: null == visible
          ? _value.visible
          : visible // ignore: cast_nullable_to_non_nullable
              as bool,
      locked: null == locked
          ? _value.locked
          : locked // ignore: cast_nullable_to_non_nullable
              as bool,
      opacity: null == opacity
          ? _value.opacity
          : opacity // ignore: cast_nullable_to_non_nullable
              as double,
      order: null == order
          ? _value.order
          : order // ignore: cast_nullable_to_non_nullable
              as int,
      elements: null == elements
          ? _value.elements
          : elements // ignore: cast_nullable_to_non_nullable
              as List<PracticeElement>,
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
abstract class _$$PracticeLayerImplCopyWith<$Res>
    implements $PracticeLayerCopyWith<$Res> {
  factory _$$PracticeLayerImplCopyWith(
          _$PracticeLayerImpl value, $Res Function(_$PracticeLayerImpl) then) =
      __$$PracticeLayerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      PracticeLayerType type,
      String imagePath,
      String? name,
      String? description,
      bool visible,
      bool locked,
      double opacity,
      int order,
      List<PracticeElement> elements,
      DateTime createTime,
      DateTime updateTime});
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
    Object? type = null,
    Object? imagePath = null,
    Object? name = freezed,
    Object? description = freezed,
    Object? visible = null,
    Object? locked = null,
    Object? opacity = null,
    Object? order = null,
    Object? elements = null,
    Object? createTime = null,
    Object? updateTime = null,
  }) {
    return _then(_$PracticeLayerImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as PracticeLayerType,
      imagePath: null == imagePath
          ? _value.imagePath
          : imagePath // ignore: cast_nullable_to_non_nullable
              as String,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      visible: null == visible
          ? _value.visible
          : visible // ignore: cast_nullable_to_non_nullable
              as bool,
      locked: null == locked
          ? _value.locked
          : locked // ignore: cast_nullable_to_non_nullable
              as bool,
      opacity: null == opacity
          ? _value.opacity
          : opacity // ignore: cast_nullable_to_non_nullable
              as double,
      order: null == order
          ? _value.order
          : order // ignore: cast_nullable_to_non_nullable
              as int,
      elements: null == elements
          ? _value._elements
          : elements // ignore: cast_nullable_to_non_nullable
              as List<PracticeElement>,
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
class _$PracticeLayerImpl extends _PracticeLayer {
  const _$PracticeLayerImpl(
      {required this.id,
      required this.type,
      required this.imagePath,
      this.name,
      this.description,
      this.visible = true,
      this.locked = false,
      this.opacity = 1.0,
      this.order = 0,
      final List<PracticeElement> elements = const [],
      required this.createTime,
      required this.updateTime})
      : _elements = elements,
        super._();

  factory _$PracticeLayerImpl.fromJson(Map<String, dynamic> json) =>
      _$$PracticeLayerImplFromJson(json);

  /// 图层ID
  @override
  final String id;

  /// 图层类型
  @override
  final PracticeLayerType type;

  /// 图片路径
  @override
  final String imagePath;

  /// 图层名称
  @override
  final String? name;

  /// 图层描述
  @override
  final String? description;

  /// 图层可见性
  @override
  @JsonKey()
  final bool visible;

  /// 图层锁定状态
  @override
  @JsonKey()
  final bool locked;

  /// 图层不透明度
  @override
  @JsonKey()
  final double opacity;

  /// 图层顺序
  @override
  @JsonKey()
  final int order;

  /// 图层元素列表
  final List<PracticeElement> _elements;

  /// 图层元素列表
  @override
  @JsonKey()
  List<PracticeElement> get elements {
    if (_elements is EqualUnmodifiableListView) return _elements;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_elements);
  }

  /// 图层创建时间
  @override
  final DateTime createTime;

  /// 图层更新时间
  @override
  final DateTime updateTime;

  @override
  String toString() {
    return 'PracticeLayer(id: $id, type: $type, imagePath: $imagePath, name: $name, description: $description, visible: $visible, locked: $locked, opacity: $opacity, order: $order, elements: $elements, createTime: $createTime, updateTime: $updateTime)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PracticeLayerImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.imagePath, imagePath) ||
                other.imagePath == imagePath) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.visible, visible) || other.visible == visible) &&
            (identical(other.locked, locked) || other.locked == locked) &&
            (identical(other.opacity, opacity) || other.opacity == opacity) &&
            (identical(other.order, order) || other.order == order) &&
            const DeepCollectionEquality().equals(other._elements, _elements) &&
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
      type,
      imagePath,
      name,
      description,
      visible,
      locked,
      opacity,
      order,
      const DeepCollectionEquality().hash(_elements),
      createTime,
      updateTime);

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

abstract class _PracticeLayer extends PracticeLayer {
  const factory _PracticeLayer(
      {required final String id,
      required final PracticeLayerType type,
      required final String imagePath,
      final String? name,
      final String? description,
      final bool visible,
      final bool locked,
      final double opacity,
      final int order,
      final List<PracticeElement> elements,
      required final DateTime createTime,
      required final DateTime updateTime}) = _$PracticeLayerImpl;
  const _PracticeLayer._() : super._();

  factory _PracticeLayer.fromJson(Map<String, dynamic> json) =
      _$PracticeLayerImpl.fromJson;

  /// 图层ID
  @override
  String get id;

  /// 图层类型
  @override
  PracticeLayerType get type;

  /// 图片路径
  @override
  String get imagePath;

  /// 图层名称
  @override
  String? get name;

  /// 图层描述
  @override
  String? get description;

  /// 图层可见性
  @override
  bool get visible;

  /// 图层锁定状态
  @override
  bool get locked;

  /// 图层不透明度
  @override
  double get opacity;

  /// 图层顺序
  @override
  int get order;

  /// 图层元素列表
  @override
  List<PracticeElement> get elements;

  /// 图层创建时间
  @override
  DateTime get createTime;

  /// 图层更新时间
  @override
  DateTime get updateTime;

  /// Create a copy of PracticeLayer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PracticeLayerImplCopyWith<_$PracticeLayerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
