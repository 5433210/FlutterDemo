// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'config_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ConfigItem _$ConfigItemFromJson(Map<String, dynamic> json) {
  return _ConfigItem.fromJson(json);
}

/// @nodoc
mixin _$ConfigItem {
  /// 配置项的唯一键
  String get key => throw _privateConstructorUsedError;

  /// 显示名称
  String get displayName => throw _privateConstructorUsedError;

  /// 排序顺序
  int get sortOrder => throw _privateConstructorUsedError;

  /// 是否为系统内置项（不可删除）
  bool get isSystem => throw _privateConstructorUsedError;

  /// 是否激活状态
  bool get isActive => throw _privateConstructorUsedError;

  /// 本地化名称映射
  Map<String, String> get localizedNames => throw _privateConstructorUsedError;

  /// 扩展属性（JSON格式）
  Map<String, dynamic> get metadata => throw _privateConstructorUsedError;

  /// 创建时间
  DateTime? get createTime => throw _privateConstructorUsedError;

  /// 更新时间
  DateTime? get updateTime => throw _privateConstructorUsedError;

  /// Serializes this ConfigItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ConfigItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConfigItemCopyWith<ConfigItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConfigItemCopyWith<$Res> {
  factory $ConfigItemCopyWith(
          ConfigItem value, $Res Function(ConfigItem) then) =
      _$ConfigItemCopyWithImpl<$Res, ConfigItem>;
  @useResult
  $Res call(
      {String key,
      String displayName,
      int sortOrder,
      bool isSystem,
      bool isActive,
      Map<String, String> localizedNames,
      Map<String, dynamic> metadata,
      DateTime? createTime,
      DateTime? updateTime});
}

/// @nodoc
class _$ConfigItemCopyWithImpl<$Res, $Val extends ConfigItem>
    implements $ConfigItemCopyWith<$Res> {
  _$ConfigItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ConfigItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? key = null,
    Object? displayName = null,
    Object? sortOrder = null,
    Object? isSystem = null,
    Object? isActive = null,
    Object? localizedNames = null,
    Object? metadata = null,
    Object? createTime = freezed,
    Object? updateTime = freezed,
  }) {
    return _then(_value.copyWith(
      key: null == key
          ? _value.key
          : key // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      isSystem: null == isSystem
          ? _value.isSystem
          : isSystem // ignore: cast_nullable_to_non_nullable
              as bool,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      localizedNames: null == localizedNames
          ? _value.localizedNames
          : localizedNames // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      metadata: null == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      createTime: freezed == createTime
          ? _value.createTime
          : createTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updateTime: freezed == updateTime
          ? _value.updateTime
          : updateTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ConfigItemImplCopyWith<$Res>
    implements $ConfigItemCopyWith<$Res> {
  factory _$$ConfigItemImplCopyWith(
          _$ConfigItemImpl value, $Res Function(_$ConfigItemImpl) then) =
      __$$ConfigItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String key,
      String displayName,
      int sortOrder,
      bool isSystem,
      bool isActive,
      Map<String, String> localizedNames,
      Map<String, dynamic> metadata,
      DateTime? createTime,
      DateTime? updateTime});
}

/// @nodoc
class __$$ConfigItemImplCopyWithImpl<$Res>
    extends _$ConfigItemCopyWithImpl<$Res, _$ConfigItemImpl>
    implements _$$ConfigItemImplCopyWith<$Res> {
  __$$ConfigItemImplCopyWithImpl(
      _$ConfigItemImpl _value, $Res Function(_$ConfigItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of ConfigItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? key = null,
    Object? displayName = null,
    Object? sortOrder = null,
    Object? isSystem = null,
    Object? isActive = null,
    Object? localizedNames = null,
    Object? metadata = null,
    Object? createTime = freezed,
    Object? updateTime = freezed,
  }) {
    return _then(_$ConfigItemImpl(
      key: null == key
          ? _value.key
          : key // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      isSystem: null == isSystem
          ? _value.isSystem
          : isSystem // ignore: cast_nullable_to_non_nullable
              as bool,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      localizedNames: null == localizedNames
          ? _value._localizedNames
          : localizedNames // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      metadata: null == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      createTime: freezed == createTime
          ? _value.createTime
          : createTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updateTime: freezed == updateTime
          ? _value.updateTime
          : updateTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ConfigItemImpl extends _ConfigItem {
  const _$ConfigItemImpl(
      {required this.key,
      required this.displayName,
      this.sortOrder = 0,
      this.isSystem = false,
      this.isActive = true,
      final Map<String, String> localizedNames = const {},
      final Map<String, dynamic> metadata = const {},
      this.createTime,
      this.updateTime})
      : _localizedNames = localizedNames,
        _metadata = metadata,
        super._();

  factory _$ConfigItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConfigItemImplFromJson(json);

  /// 配置项的唯一键
  @override
  final String key;

  /// 显示名称
  @override
  final String displayName;

  /// 排序顺序
  @override
  @JsonKey()
  final int sortOrder;

  /// 是否为系统内置项（不可删除）
  @override
  @JsonKey()
  final bool isSystem;

  /// 是否激活状态
  @override
  @JsonKey()
  final bool isActive;

  /// 本地化名称映射
  final Map<String, String> _localizedNames;

  /// 本地化名称映射
  @override
  @JsonKey()
  Map<String, String> get localizedNames {
    if (_localizedNames is EqualUnmodifiableMapView) return _localizedNames;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_localizedNames);
  }

  /// 扩展属性（JSON格式）
  final Map<String, dynamic> _metadata;

  /// 扩展属性（JSON格式）
  @override
  @JsonKey()
  Map<String, dynamic> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  /// 创建时间
  @override
  final DateTime? createTime;

  /// 更新时间
  @override
  final DateTime? updateTime;

  @override
  String toString() {
    return 'ConfigItem(key: $key, displayName: $displayName, sortOrder: $sortOrder, isSystem: $isSystem, isActive: $isActive, localizedNames: $localizedNames, metadata: $metadata, createTime: $createTime, updateTime: $updateTime)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConfigItemImpl &&
            (identical(other.key, key) || other.key == key) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.isSystem, isSystem) ||
                other.isSystem == isSystem) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            const DeepCollectionEquality()
                .equals(other._localizedNames, _localizedNames) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata) &&
            (identical(other.createTime, createTime) ||
                other.createTime == createTime) &&
            (identical(other.updateTime, updateTime) ||
                other.updateTime == updateTime));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      key,
      displayName,
      sortOrder,
      isSystem,
      isActive,
      const DeepCollectionEquality().hash(_localizedNames),
      const DeepCollectionEquality().hash(_metadata),
      createTime,
      updateTime);

  /// Create a copy of ConfigItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConfigItemImplCopyWith<_$ConfigItemImpl> get copyWith =>
      __$$ConfigItemImplCopyWithImpl<_$ConfigItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ConfigItemImplToJson(
      this,
    );
  }
}

abstract class _ConfigItem extends ConfigItem {
  const factory _ConfigItem(
      {required final String key,
      required final String displayName,
      final int sortOrder,
      final bool isSystem,
      final bool isActive,
      final Map<String, String> localizedNames,
      final Map<String, dynamic> metadata,
      final DateTime? createTime,
      final DateTime? updateTime}) = _$ConfigItemImpl;
  const _ConfigItem._() : super._();

  factory _ConfigItem.fromJson(Map<String, dynamic> json) =
      _$ConfigItemImpl.fromJson;

  /// 配置项的唯一键
  @override
  String get key;

  /// 显示名称
  @override
  String get displayName;

  /// 排序顺序
  @override
  int get sortOrder;

  /// 是否为系统内置项（不可删除）
  @override
  bool get isSystem;

  /// 是否激活状态
  @override
  bool get isActive;

  /// 本地化名称映射
  @override
  Map<String, String> get localizedNames;

  /// 扩展属性（JSON格式）
  @override
  Map<String, dynamic> get metadata;

  /// 创建时间
  @override
  DateTime? get createTime;

  /// 更新时间
  @override
  DateTime? get updateTime;

  /// Create a copy of ConfigItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConfigItemImplCopyWith<_$ConfigItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ConfigCategory _$ConfigCategoryFromJson(Map<String, dynamic> json) {
  return _ConfigCategory.fromJson(json);
}

/// @nodoc
mixin _$ConfigCategory {
  /// 分类标识
  String get category => throw _privateConstructorUsedError;

  /// 分类显示名称
  String get displayName => throw _privateConstructorUsedError;

  /// 配置项列表
  List<ConfigItem> get items => throw _privateConstructorUsedError;

  /// 更新时间
  DateTime? get updateTime => throw _privateConstructorUsedError;

  /// Serializes this ConfigCategory to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ConfigCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConfigCategoryCopyWith<ConfigCategory> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConfigCategoryCopyWith<$Res> {
  factory $ConfigCategoryCopyWith(
          ConfigCategory value, $Res Function(ConfigCategory) then) =
      _$ConfigCategoryCopyWithImpl<$Res, ConfigCategory>;
  @useResult
  $Res call(
      {String category,
      String displayName,
      List<ConfigItem> items,
      DateTime? updateTime});
}

/// @nodoc
class _$ConfigCategoryCopyWithImpl<$Res, $Val extends ConfigCategory>
    implements $ConfigCategoryCopyWith<$Res> {
  _$ConfigCategoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ConfigCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? category = null,
    Object? displayName = null,
    Object? items = null,
    Object? updateTime = freezed,
  }) {
    return _then(_value.copyWith(
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<ConfigItem>,
      updateTime: freezed == updateTime
          ? _value.updateTime
          : updateTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ConfigCategoryImplCopyWith<$Res>
    implements $ConfigCategoryCopyWith<$Res> {
  factory _$$ConfigCategoryImplCopyWith(_$ConfigCategoryImpl value,
          $Res Function(_$ConfigCategoryImpl) then) =
      __$$ConfigCategoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String category,
      String displayName,
      List<ConfigItem> items,
      DateTime? updateTime});
}

/// @nodoc
class __$$ConfigCategoryImplCopyWithImpl<$Res>
    extends _$ConfigCategoryCopyWithImpl<$Res, _$ConfigCategoryImpl>
    implements _$$ConfigCategoryImplCopyWith<$Res> {
  __$$ConfigCategoryImplCopyWithImpl(
      _$ConfigCategoryImpl _value, $Res Function(_$ConfigCategoryImpl) _then)
      : super(_value, _then);

  /// Create a copy of ConfigCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? category = null,
    Object? displayName = null,
    Object? items = null,
    Object? updateTime = freezed,
  }) {
    return _then(_$ConfigCategoryImpl(
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<ConfigItem>,
      updateTime: freezed == updateTime
          ? _value.updateTime
          : updateTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ConfigCategoryImpl extends _ConfigCategory {
  const _$ConfigCategoryImpl(
      {required this.category,
      required this.displayName,
      final List<ConfigItem> items = const [],
      this.updateTime})
      : _items = items,
        super._();

  factory _$ConfigCategoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConfigCategoryImplFromJson(json);

  /// 分类标识
  @override
  final String category;

  /// 分类显示名称
  @override
  final String displayName;

  /// 配置项列表
  final List<ConfigItem> _items;

  /// 配置项列表
  @override
  @JsonKey()
  List<ConfigItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  /// 更新时间
  @override
  final DateTime? updateTime;

  @override
  String toString() {
    return 'ConfigCategory(category: $category, displayName: $displayName, items: $items, updateTime: $updateTime)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConfigCategoryImpl &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.updateTime, updateTime) ||
                other.updateTime == updateTime));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, category, displayName,
      const DeepCollectionEquality().hash(_items), updateTime);

  /// Create a copy of ConfigCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConfigCategoryImplCopyWith<_$ConfigCategoryImpl> get copyWith =>
      __$$ConfigCategoryImplCopyWithImpl<_$ConfigCategoryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ConfigCategoryImplToJson(
      this,
    );
  }
}

abstract class _ConfigCategory extends ConfigCategory {
  const factory _ConfigCategory(
      {required final String category,
      required final String displayName,
      final List<ConfigItem> items,
      final DateTime? updateTime}) = _$ConfigCategoryImpl;
  const _ConfigCategory._() : super._();

  factory _ConfigCategory.fromJson(Map<String, dynamic> json) =
      _$ConfigCategoryImpl.fromJson;

  /// 分类标识
  @override
  String get category;

  /// 分类显示名称
  @override
  String get displayName;

  /// 配置项列表
  @override
  List<ConfigItem> get items;

  /// 更新时间
  @override
  DateTime? get updateTime;

  /// Create a copy of ConfigCategory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConfigCategoryImplCopyWith<_$ConfigCategoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
