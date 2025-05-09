// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'library_category.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

LibraryCategory _$LibraryCategoryFromJson(Map<String, dynamic> json) {
  return _LibraryCategory.fromJson(json);
}

/// @nodoc
mixin _$LibraryCategory {
  /// ID
  String get id => throw _privateConstructorUsedError;

  /// 名称
  String get name => throw _privateConstructorUsedError;

  /// 父分类ID
  String? get parentId => throw _privateConstructorUsedError;

  /// 排序顺序
  int get sortOrder => throw _privateConstructorUsedError;

  /// 子分类列表
  List<LibraryCategory> get children => throw _privateConstructorUsedError;

  /// 创建时间
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// 更新时间
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this LibraryCategory to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LibraryCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LibraryCategoryCopyWith<LibraryCategory> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LibraryCategoryCopyWith<$Res> {
  factory $LibraryCategoryCopyWith(
          LibraryCategory value, $Res Function(LibraryCategory) then) =
      _$LibraryCategoryCopyWithImpl<$Res, LibraryCategory>;
  @useResult
  $Res call(
      {String id,
      String name,
      String? parentId,
      int sortOrder,
      List<LibraryCategory> children,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class _$LibraryCategoryCopyWithImpl<$Res, $Val extends LibraryCategory>
    implements $LibraryCategoryCopyWith<$Res> {
  _$LibraryCategoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LibraryCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? parentId = freezed,
    Object? sortOrder = null,
    Object? children = null,
    Object? createdAt = null,
    Object? updatedAt = null,
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
      parentId: freezed == parentId
          ? _value.parentId
          : parentId // ignore: cast_nullable_to_non_nullable
              as String?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      children: null == children
          ? _value.children
          : children // ignore: cast_nullable_to_non_nullable
              as List<LibraryCategory>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LibraryCategoryImplCopyWith<$Res>
    implements $LibraryCategoryCopyWith<$Res> {
  factory _$$LibraryCategoryImplCopyWith(_$LibraryCategoryImpl value,
          $Res Function(_$LibraryCategoryImpl) then) =
      __$$LibraryCategoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String? parentId,
      int sortOrder,
      List<LibraryCategory> children,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class __$$LibraryCategoryImplCopyWithImpl<$Res>
    extends _$LibraryCategoryCopyWithImpl<$Res, _$LibraryCategoryImpl>
    implements _$$LibraryCategoryImplCopyWith<$Res> {
  __$$LibraryCategoryImplCopyWithImpl(
      _$LibraryCategoryImpl _value, $Res Function(_$LibraryCategoryImpl) _then)
      : super(_value, _then);

  /// Create a copy of LibraryCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? parentId = freezed,
    Object? sortOrder = null,
    Object? children = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$LibraryCategoryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      parentId: freezed == parentId
          ? _value.parentId
          : parentId // ignore: cast_nullable_to_non_nullable
              as String?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      children: null == children
          ? _value._children
          : children // ignore: cast_nullable_to_non_nullable
              as List<LibraryCategory>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LibraryCategoryImpl implements _LibraryCategory {
  const _$LibraryCategoryImpl(
      {required this.id,
      required this.name,
      this.parentId,
      this.sortOrder = 0,
      final List<LibraryCategory> children = const [],
      required this.createdAt,
      required this.updatedAt})
      : _children = children;

  factory _$LibraryCategoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$LibraryCategoryImplFromJson(json);

  /// ID
  @override
  final String id;

  /// 名称
  @override
  final String name;

  /// 父分类ID
  @override
  final String? parentId;

  /// 排序顺序
  @override
  @JsonKey()
  final int sortOrder;

  /// 子分类列表
  final List<LibraryCategory> _children;

  /// 子分类列表
  @override
  @JsonKey()
  List<LibraryCategory> get children {
    if (_children is EqualUnmodifiableListView) return _children;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_children);
  }

  /// 创建时间
  @override
  final DateTime createdAt;

  /// 更新时间
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'LibraryCategory(id: $id, name: $name, parentId: $parentId, sortOrder: $sortOrder, children: $children, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LibraryCategoryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.parentId, parentId) ||
                other.parentId == parentId) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            const DeepCollectionEquality().equals(other._children, _children) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, parentId, sortOrder,
      const DeepCollectionEquality().hash(_children), createdAt, updatedAt);

  /// Create a copy of LibraryCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LibraryCategoryImplCopyWith<_$LibraryCategoryImpl> get copyWith =>
      __$$LibraryCategoryImplCopyWithImpl<_$LibraryCategoryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LibraryCategoryImplToJson(
      this,
    );
  }
}

abstract class _LibraryCategory implements LibraryCategory {
  const factory _LibraryCategory(
      {required final String id,
      required final String name,
      final String? parentId,
      final int sortOrder,
      final List<LibraryCategory> children,
      required final DateTime createdAt,
      required final DateTime updatedAt}) = _$LibraryCategoryImpl;

  factory _LibraryCategory.fromJson(Map<String, dynamic> json) =
      _$LibraryCategoryImpl.fromJson;

  /// ID
  @override
  String get id;

  /// 名称
  @override
  String get name;

  /// 父分类ID
  @override
  String? get parentId;

  /// 排序顺序
  @override
  int get sortOrder;

  /// 子分类列表
  @override
  List<LibraryCategory> get children;

  /// 创建时间
  @override
  DateTime get createdAt;

  /// 更新时间
  @override
  DateTime get updatedAt;

  /// Create a copy of LibraryCategory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LibraryCategoryImplCopyWith<_$LibraryCategoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
