// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'library_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

LibraryItem _$LibraryItemFromJson(Map<String, dynamic> json) {
  return _LibraryItem.fromJson(json);
}

/// @nodoc
mixin _$LibraryItem {
  /// ID
  String get id => throw _privateConstructorUsedError;

  /// 名称
  String get name => throw _privateConstructorUsedError;

  /// 类型
  String get type => throw _privateConstructorUsedError;

  /// 格式
  String get format => throw _privateConstructorUsedError;

  /// 文件路径
  String get path => throw _privateConstructorUsedError;

  /// 宽度
  int get width => throw _privateConstructorUsedError;

  /// 高度
  int get height => throw _privateConstructorUsedError;

  /// 文件大小（字节）
  int get size => throw _privateConstructorUsedError;

  /// 标签列表
  List<String> get tags => throw _privateConstructorUsedError;

  /// 分类列表
  List<String> get categories => throw _privateConstructorUsedError;

  /// 元数据
  Map<String, dynamic> get metadata => throw _privateConstructorUsedError;

  /// 是否收藏
  bool get isFavorite => throw _privateConstructorUsedError;

  /// 备注信息
  String get remarks => throw _privateConstructorUsedError;

  /// 缩略图数据
  @Uint8ListConverter()
  Uint8List? get thumbnail => throw _privateConstructorUsedError;

  /// 创建时间
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// 更新时间
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this LibraryItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LibraryItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LibraryItemCopyWith<LibraryItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LibraryItemCopyWith<$Res> {
  factory $LibraryItemCopyWith(
          LibraryItem value, $Res Function(LibraryItem) then) =
      _$LibraryItemCopyWithImpl<$Res, LibraryItem>;
  @useResult
  $Res call(
      {String id,
      String name,
      String type,
      String format,
      String path,
      int width,
      int height,
      int size,
      List<String> tags,
      List<String> categories,
      Map<String, dynamic> metadata,
      bool isFavorite,
      String remarks,
      @Uint8ListConverter() Uint8List? thumbnail,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class _$LibraryItemCopyWithImpl<$Res, $Val extends LibraryItem>
    implements $LibraryItemCopyWith<$Res> {
  _$LibraryItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LibraryItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? format = null,
    Object? path = null,
    Object? width = null,
    Object? height = null,
    Object? size = null,
    Object? tags = null,
    Object? categories = null,
    Object? metadata = null,
    Object? isFavorite = null,
    Object? remarks = null,
    Object? thumbnail = freezed,
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
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      format: null == format
          ? _value.format
          : format // ignore: cast_nullable_to_non_nullable
              as String,
      path: null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
      size: null == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as int,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      categories: null == categories
          ? _value.categories
          : categories // ignore: cast_nullable_to_non_nullable
              as List<String>,
      metadata: null == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      isFavorite: null == isFavorite
          ? _value.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
      remarks: null == remarks
          ? _value.remarks
          : remarks // ignore: cast_nullable_to_non_nullable
              as String,
      thumbnail: freezed == thumbnail
          ? _value.thumbnail
          : thumbnail // ignore: cast_nullable_to_non_nullable
              as Uint8List?,
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
abstract class _$$LibraryItemImplCopyWith<$Res>
    implements $LibraryItemCopyWith<$Res> {
  factory _$$LibraryItemImplCopyWith(
          _$LibraryItemImpl value, $Res Function(_$LibraryItemImpl) then) =
      __$$LibraryItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String type,
      String format,
      String path,
      int width,
      int height,
      int size,
      List<String> tags,
      List<String> categories,
      Map<String, dynamic> metadata,
      bool isFavorite,
      String remarks,
      @Uint8ListConverter() Uint8List? thumbnail,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class __$$LibraryItemImplCopyWithImpl<$Res>
    extends _$LibraryItemCopyWithImpl<$Res, _$LibraryItemImpl>
    implements _$$LibraryItemImplCopyWith<$Res> {
  __$$LibraryItemImplCopyWithImpl(
      _$LibraryItemImpl _value, $Res Function(_$LibraryItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of LibraryItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? format = null,
    Object? path = null,
    Object? width = null,
    Object? height = null,
    Object? size = null,
    Object? tags = null,
    Object? categories = null,
    Object? metadata = null,
    Object? isFavorite = null,
    Object? remarks = null,
    Object? thumbnail = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$LibraryItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      format: null == format
          ? _value.format
          : format // ignore: cast_nullable_to_non_nullable
              as String,
      path: null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
      size: null == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as int,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      categories: null == categories
          ? _value._categories
          : categories // ignore: cast_nullable_to_non_nullable
              as List<String>,
      metadata: null == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      isFavorite: null == isFavorite
          ? _value.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
      remarks: null == remarks
          ? _value.remarks
          : remarks // ignore: cast_nullable_to_non_nullable
              as String,
      thumbnail: freezed == thumbnail
          ? _value.thumbnail
          : thumbnail // ignore: cast_nullable_to_non_nullable
              as Uint8List?,
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
class _$LibraryItemImpl implements _LibraryItem {
  const _$LibraryItemImpl(
      {required this.id,
      required this.name,
      required this.type,
      required this.format,
      required this.path,
      required this.width,
      required this.height,
      required this.size,
      final List<String> tags = const [],
      final List<String> categories = const [],
      final Map<String, dynamic> metadata = const {},
      this.isFavorite = false,
      this.remarks = '',
      @Uint8ListConverter() this.thumbnail,
      required this.createdAt,
      required this.updatedAt})
      : _tags = tags,
        _categories = categories,
        _metadata = metadata;

  factory _$LibraryItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$LibraryItemImplFromJson(json);

  /// ID
  @override
  final String id;

  /// 名称
  @override
  final String name;

  /// 类型
  @override
  final String type;

  /// 格式
  @override
  final String format;

  /// 文件路径
  @override
  final String path;

  /// 宽度
  @override
  final int width;

  /// 高度
  @override
  final int height;

  /// 文件大小（字节）
  @override
  final int size;

  /// 标签列表
  final List<String> _tags;

  /// 标签列表
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  /// 分类列表
  final List<String> _categories;

  /// 分类列表
  @override
  @JsonKey()
  List<String> get categories {
    if (_categories is EqualUnmodifiableListView) return _categories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_categories);
  }

  /// 元数据
  final Map<String, dynamic> _metadata;

  /// 元数据
  @override
  @JsonKey()
  Map<String, dynamic> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  /// 是否收藏
  @override
  @JsonKey()
  final bool isFavorite;

  /// 备注信息
  @override
  @JsonKey()
  final String remarks;

  /// 缩略图数据
  @override
  @Uint8ListConverter()
  final Uint8List? thumbnail;

  /// 创建时间
  @override
  final DateTime createdAt;

  /// 更新时间
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'LibraryItem(id: $id, name: $name, type: $type, format: $format, path: $path, width: $width, height: $height, size: $size, tags: $tags, categories: $categories, metadata: $metadata, isFavorite: $isFavorite, remarks: $remarks, thumbnail: $thumbnail, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LibraryItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.format, format) || other.format == format) &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.size, size) || other.size == size) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            const DeepCollectionEquality()
                .equals(other._categories, _categories) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata) &&
            (identical(other.isFavorite, isFavorite) ||
                other.isFavorite == isFavorite) &&
            (identical(other.remarks, remarks) || other.remarks == remarks) &&
            const DeepCollectionEquality().equals(other.thumbnail, thumbnail) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      type,
      format,
      path,
      width,
      height,
      size,
      const DeepCollectionEquality().hash(_tags),
      const DeepCollectionEquality().hash(_categories),
      const DeepCollectionEquality().hash(_metadata),
      isFavorite,
      remarks,
      const DeepCollectionEquality().hash(thumbnail),
      createdAt,
      updatedAt);

  /// Create a copy of LibraryItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LibraryItemImplCopyWith<_$LibraryItemImpl> get copyWith =>
      __$$LibraryItemImplCopyWithImpl<_$LibraryItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LibraryItemImplToJson(
      this,
    );
  }
}

abstract class _LibraryItem implements LibraryItem {
  const factory _LibraryItem(
      {required final String id,
      required final String name,
      required final String type,
      required final String format,
      required final String path,
      required final int width,
      required final int height,
      required final int size,
      final List<String> tags,
      final List<String> categories,
      final Map<String, dynamic> metadata,
      final bool isFavorite,
      final String remarks,
      @Uint8ListConverter() final Uint8List? thumbnail,
      required final DateTime createdAt,
      required final DateTime updatedAt}) = _$LibraryItemImpl;

  factory _LibraryItem.fromJson(Map<String, dynamic> json) =
      _$LibraryItemImpl.fromJson;

  /// ID
  @override
  String get id;

  /// 名称
  @override
  String get name;

  /// 类型
  @override
  String get type;

  /// 格式
  @override
  String get format;

  /// 文件路径
  @override
  String get path;

  /// 宽度
  @override
  int get width;

  /// 高度
  @override
  int get height;

  /// 文件大小（字节）
  @override
  int get size;

  /// 标签列表
  @override
  List<String> get tags;

  /// 分类列表
  @override
  List<String> get categories;

  /// 元数据
  @override
  Map<String, dynamic> get metadata;

  /// 是否收藏
  @override
  bool get isFavorite;

  /// 备注信息
  @override
  String get remarks;

  /// 缩略图数据
  @override
  @Uint8ListConverter()
  Uint8List? get thumbnail;

  /// 创建时间
  @override
  DateTime get createdAt;

  /// 更新时间
  @override
  DateTime get updatedAt;

  /// Create a copy of LibraryItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LibraryItemImplCopyWith<_$LibraryItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
