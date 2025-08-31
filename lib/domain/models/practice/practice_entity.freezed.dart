// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'practice_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PracticeEntity _$PracticeEntityFromJson(Map<String, dynamic> json) {
  return _PracticeEntity.fromJson(json);
}

/// @nodoc
mixin _$PracticeEntity {
  /// ID
  String get id => throw _privateConstructorUsedError;

  /// 标题
  String get title => throw _privateConstructorUsedError;

  /// 页面列表 - 存储完整的页面内容
  List<Map<String, dynamic>> get pages => throw _privateConstructorUsedError;

  /// 标签列表
  List<String> get tags => throw _privateConstructorUsedError;

  /// 状态
  String get status => throw _privateConstructorUsedError;

  /// 创建时间
  DateTime get createTime => throw _privateConstructorUsedError;

  /// 更新时间
  DateTime get updateTime => throw _privateConstructorUsedError;

  /// 是否收藏
  bool get isFavorite => throw _privateConstructorUsedError;

  /// 页数 - 数据库存储字段，与pages.length保持同步
  int get pageCount => throw _privateConstructorUsedError;

  /// 元数据 - JSON格式存储的扩展信息
  Map<String, dynamic> get metadata => throw _privateConstructorUsedError;

  /// 缩略图数据 (BLOB)
  @JsonKey(fromJson: _bytesFromJson, toJson: _bytesToJson)
  Uint8List? get thumbnail => throw _privateConstructorUsedError;

  /// Serializes this PracticeEntity to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PracticeEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PracticeEntityCopyWith<PracticeEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PracticeEntityCopyWith<$Res> {
  factory $PracticeEntityCopyWith(
          PracticeEntity value, $Res Function(PracticeEntity) then) =
      _$PracticeEntityCopyWithImpl<$Res, PracticeEntity>;
  @useResult
  $Res call(
      {String id,
      String title,
      List<Map<String, dynamic>> pages,
      List<String> tags,
      String status,
      DateTime createTime,
      DateTime updateTime,
      bool isFavorite,
      int pageCount,
      Map<String, dynamic> metadata,
      @JsonKey(fromJson: _bytesFromJson, toJson: _bytesToJson)
      Uint8List? thumbnail});
}

/// @nodoc
class _$PracticeEntityCopyWithImpl<$Res, $Val extends PracticeEntity>
    implements $PracticeEntityCopyWith<$Res> {
  _$PracticeEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PracticeEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? pages = null,
    Object? tags = null,
    Object? status = null,
    Object? createTime = null,
    Object? updateTime = null,
    Object? isFavorite = null,
    Object? pageCount = null,
    Object? metadata = null,
    Object? thumbnail = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      pages: null == pages
          ? _value.pages
          : pages // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      createTime: null == createTime
          ? _value.createTime
          : createTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updateTime: null == updateTime
          ? _value.updateTime
          : updateTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isFavorite: null == isFavorite
          ? _value.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
      pageCount: null == pageCount
          ? _value.pageCount
          : pageCount // ignore: cast_nullable_to_non_nullable
              as int,
      metadata: null == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      thumbnail: freezed == thumbnail
          ? _value.thumbnail
          : thumbnail // ignore: cast_nullable_to_non_nullable
              as Uint8List?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PracticeEntityImplCopyWith<$Res>
    implements $PracticeEntityCopyWith<$Res> {
  factory _$$PracticeEntityImplCopyWith(_$PracticeEntityImpl value,
          $Res Function(_$PracticeEntityImpl) then) =
      __$$PracticeEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      List<Map<String, dynamic>> pages,
      List<String> tags,
      String status,
      DateTime createTime,
      DateTime updateTime,
      bool isFavorite,
      int pageCount,
      Map<String, dynamic> metadata,
      @JsonKey(fromJson: _bytesFromJson, toJson: _bytesToJson)
      Uint8List? thumbnail});
}

/// @nodoc
class __$$PracticeEntityImplCopyWithImpl<$Res>
    extends _$PracticeEntityCopyWithImpl<$Res, _$PracticeEntityImpl>
    implements _$$PracticeEntityImplCopyWith<$Res> {
  __$$PracticeEntityImplCopyWithImpl(
      _$PracticeEntityImpl _value, $Res Function(_$PracticeEntityImpl) _then)
      : super(_value, _then);

  /// Create a copy of PracticeEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? pages = null,
    Object? tags = null,
    Object? status = null,
    Object? createTime = null,
    Object? updateTime = null,
    Object? isFavorite = null,
    Object? pageCount = null,
    Object? metadata = null,
    Object? thumbnail = freezed,
  }) {
    return _then(_$PracticeEntityImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      pages: null == pages
          ? _value._pages
          : pages // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      createTime: null == createTime
          ? _value.createTime
          : createTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updateTime: null == updateTime
          ? _value.updateTime
          : updateTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isFavorite: null == isFavorite
          ? _value.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
      pageCount: null == pageCount
          ? _value.pageCount
          : pageCount // ignore: cast_nullable_to_non_nullable
              as int,
      metadata: null == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      thumbnail: freezed == thumbnail
          ? _value.thumbnail
          : thumbnail // ignore: cast_nullable_to_non_nullable
              as Uint8List?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PracticeEntityImpl extends _PracticeEntity {
  const _$PracticeEntityImpl(
      {required this.id,
      required this.title,
      final List<Map<String, dynamic>> pages = const [],
      final List<String> tags = const [],
      this.status = 'active',
      required this.createTime,
      required this.updateTime,
      this.isFavorite = false,
      this.pageCount = 0,
      final Map<String, dynamic> metadata = const {},
      @JsonKey(fromJson: _bytesFromJson, toJson: _bytesToJson) this.thumbnail})
      : _pages = pages,
        _tags = tags,
        _metadata = metadata,
        super._();

  factory _$PracticeEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$PracticeEntityImplFromJson(json);

  /// ID
  @override
  final String id;

  /// 标题
  @override
  final String title;

  /// 页面列表 - 存储完整的页面内容
  final List<Map<String, dynamic>> _pages;

  /// 页面列表 - 存储完整的页面内容
  @override
  @JsonKey()
  List<Map<String, dynamic>> get pages {
    if (_pages is EqualUnmodifiableListView) return _pages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_pages);
  }

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

  /// 状态
  @override
  @JsonKey()
  final String status;

  /// 创建时间
  @override
  final DateTime createTime;

  /// 更新时间
  @override
  final DateTime updateTime;

  /// 是否收藏
  @override
  @JsonKey()
  final bool isFavorite;

  /// 页数 - 数据库存储字段，与pages.length保持同步
  @override
  @JsonKey()
  final int pageCount;

  /// 元数据 - JSON格式存储的扩展信息
  final Map<String, dynamic> _metadata;

  /// 元数据 - JSON格式存储的扩展信息
  @override
  @JsonKey()
  Map<String, dynamic> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  /// 缩略图数据 (BLOB)
  @override
  @JsonKey(fromJson: _bytesFromJson, toJson: _bytesToJson)
  final Uint8List? thumbnail;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PracticeEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            const DeepCollectionEquality().equals(other._pages, _pages) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createTime, createTime) ||
                other.createTime == createTime) &&
            (identical(other.updateTime, updateTime) ||
                other.updateTime == updateTime) &&
            (identical(other.isFavorite, isFavorite) ||
                other.isFavorite == isFavorite) &&
            (identical(other.pageCount, pageCount) ||
                other.pageCount == pageCount) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata) &&
            const DeepCollectionEquality().equals(other.thumbnail, thumbnail));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      const DeepCollectionEquality().hash(_pages),
      const DeepCollectionEquality().hash(_tags),
      status,
      createTime,
      updateTime,
      isFavorite,
      pageCount,
      const DeepCollectionEquality().hash(_metadata),
      const DeepCollectionEquality().hash(thumbnail));

  /// Create a copy of PracticeEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PracticeEntityImplCopyWith<_$PracticeEntityImpl> get copyWith =>
      __$$PracticeEntityImplCopyWithImpl<_$PracticeEntityImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PracticeEntityImplToJson(
      this,
    );
  }
}

abstract class _PracticeEntity extends PracticeEntity {
  const factory _PracticeEntity(
      {required final String id,
      required final String title,
      final List<Map<String, dynamic>> pages,
      final List<String> tags,
      final String status,
      required final DateTime createTime,
      required final DateTime updateTime,
      final bool isFavorite,
      final int pageCount,
      final Map<String, dynamic> metadata,
      @JsonKey(fromJson: _bytesFromJson, toJson: _bytesToJson)
      final Uint8List? thumbnail}) = _$PracticeEntityImpl;
  const _PracticeEntity._() : super._();

  factory _PracticeEntity.fromJson(Map<String, dynamic> json) =
      _$PracticeEntityImpl.fromJson;

  /// ID
  @override
  String get id;

  /// 标题
  @override
  String get title;

  /// 页面列表 - 存储完整的页面内容
  @override
  List<Map<String, dynamic>> get pages;

  /// 标签列表
  @override
  List<String> get tags;

  /// 状态
  @override
  String get status;

  /// 创建时间
  @override
  DateTime get createTime;

  /// 更新时间
  @override
  DateTime get updateTime;

  /// 是否收藏
  @override
  bool get isFavorite;

  /// 页数 - 数据库存储字段，与pages.length保持同步
  @override
  int get pageCount;

  /// 元数据 - JSON格式存储的扩展信息
  @override
  Map<String, dynamic> get metadata;

  /// 缩略图数据 (BLOB)
  @override
  @JsonKey(fromJson: _bytesFromJson, toJson: _bytesToJson)
  Uint8List? get thumbnail;

  /// Create a copy of PracticeEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PracticeEntityImplCopyWith<_$PracticeEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
