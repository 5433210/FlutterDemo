// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'work_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

WorkEntity _$WorkEntityFromJson(Map<String, dynamic> json) {
  return _WorkEntity.fromJson(json);
}

/// @nodoc
mixin _$WorkEntity {
  /// ID
  String get id => throw _privateConstructorUsedError;

  /// 标题
  String get title => throw _privateConstructorUsedError;

  /// 作者
  String get author => throw _privateConstructorUsedError;

  /// 备注
  String? get remark => throw _privateConstructorUsedError;

  /// 字体
  @JsonKey(fromJson: _workStyleFromJson, toJson: _workStyleToJson)
  WorkStyle get style => throw _privateConstructorUsedError;

  /// 工具
  @JsonKey(fromJson: _workToolFromJson, toJson: _workToolToJson)
  WorkTool get tool => throw _privateConstructorUsedError;

  /// 创作日期
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  DateTime get creationDate => throw _privateConstructorUsedError;

  /// 创建时间
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  DateTime get createTime => throw _privateConstructorUsedError;

  /// 修改时间
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  DateTime get updateTime => throw _privateConstructorUsedError;

  /// 是否收藏
  @JsonKey(fromJson: _isFavoriteFromJson, toJson: _isFavoriteToJson)
  bool get isFavorite => throw _privateConstructorUsedError;

  /// 图片最后更新时间
  @JsonKey(
      fromJson: _dateTimeFromJson,
      toJson: _dateTimeToJson,
      includeIfNull: false)
  DateTime? get lastImageUpdateTime => throw _privateConstructorUsedError;

  /// 状态
  WorkStatus get status => throw _privateConstructorUsedError;

  /// 首图ID
  String? get firstImageId => throw _privateConstructorUsedError;

  /// 图片列表
  List<WorkImage> get images => throw _privateConstructorUsedError;

  /// 关联字符列表
  List<CharacterEntity> get collectedChars =>
      throw _privateConstructorUsedError;

  /// 标签列表
  List<String> get tags => throw _privateConstructorUsedError;

  /// 图片数量
  int? get imageCount => throw _privateConstructorUsedError;

  /// Serializes this WorkEntity to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WorkEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WorkEntityCopyWith<WorkEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkEntityCopyWith<$Res> {
  factory $WorkEntityCopyWith(
          WorkEntity value, $Res Function(WorkEntity) then) =
      _$WorkEntityCopyWithImpl<$Res, WorkEntity>;
  @useResult
  $Res call(
      {String id,
      String title,
      String author,
      String? remark,
      @JsonKey(fromJson: _workStyleFromJson, toJson: _workStyleToJson)
      WorkStyle style,
      @JsonKey(fromJson: _workToolFromJson, toJson: _workToolToJson)
      WorkTool tool,
      @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
      DateTime creationDate,
      @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
      DateTime createTime,
      @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
      DateTime updateTime,
      @JsonKey(fromJson: _isFavoriteFromJson, toJson: _isFavoriteToJson)
      bool isFavorite,
      @JsonKey(
          fromJson: _dateTimeFromJson,
          toJson: _dateTimeToJson,
          includeIfNull: false)
      DateTime? lastImageUpdateTime,
      WorkStatus status,
      String? firstImageId,
      List<WorkImage> images,
      List<CharacterEntity> collectedChars,
      List<String> tags,
      int? imageCount});
}

/// @nodoc
class _$WorkEntityCopyWithImpl<$Res, $Val extends WorkEntity>
    implements $WorkEntityCopyWith<$Res> {
  _$WorkEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WorkEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? author = null,
    Object? remark = freezed,
    Object? style = null,
    Object? tool = null,
    Object? creationDate = null,
    Object? createTime = null,
    Object? updateTime = null,
    Object? isFavorite = null,
    Object? lastImageUpdateTime = freezed,
    Object? status = null,
    Object? firstImageId = freezed,
    Object? images = null,
    Object? collectedChars = null,
    Object? tags = null,
    Object? imageCount = freezed,
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
      author: null == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as String,
      remark: freezed == remark
          ? _value.remark
          : remark // ignore: cast_nullable_to_non_nullable
              as String?,
      style: null == style
          ? _value.style
          : style // ignore: cast_nullable_to_non_nullable
              as WorkStyle,
      tool: null == tool
          ? _value.tool
          : tool // ignore: cast_nullable_to_non_nullable
              as WorkTool,
      creationDate: null == creationDate
          ? _value.creationDate
          : creationDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
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
      lastImageUpdateTime: freezed == lastImageUpdateTime
          ? _value.lastImageUpdateTime
          : lastImageUpdateTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as WorkStatus,
      firstImageId: freezed == firstImageId
          ? _value.firstImageId
          : firstImageId // ignore: cast_nullable_to_non_nullable
              as String?,
      images: null == images
          ? _value.images
          : images // ignore: cast_nullable_to_non_nullable
              as List<WorkImage>,
      collectedChars: null == collectedChars
          ? _value.collectedChars
          : collectedChars // ignore: cast_nullable_to_non_nullable
              as List<CharacterEntity>,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      imageCount: freezed == imageCount
          ? _value.imageCount
          : imageCount // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WorkEntityImplCopyWith<$Res>
    implements $WorkEntityCopyWith<$Res> {
  factory _$$WorkEntityImplCopyWith(
          _$WorkEntityImpl value, $Res Function(_$WorkEntityImpl) then) =
      __$$WorkEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String author,
      String? remark,
      @JsonKey(fromJson: _workStyleFromJson, toJson: _workStyleToJson)
      WorkStyle style,
      @JsonKey(fromJson: _workToolFromJson, toJson: _workToolToJson)
      WorkTool tool,
      @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
      DateTime creationDate,
      @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
      DateTime createTime,
      @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
      DateTime updateTime,
      @JsonKey(fromJson: _isFavoriteFromJson, toJson: _isFavoriteToJson)
      bool isFavorite,
      @JsonKey(
          fromJson: _dateTimeFromJson,
          toJson: _dateTimeToJson,
          includeIfNull: false)
      DateTime? lastImageUpdateTime,
      WorkStatus status,
      String? firstImageId,
      List<WorkImage> images,
      List<CharacterEntity> collectedChars,
      List<String> tags,
      int? imageCount});
}

/// @nodoc
class __$$WorkEntityImplCopyWithImpl<$Res>
    extends _$WorkEntityCopyWithImpl<$Res, _$WorkEntityImpl>
    implements _$$WorkEntityImplCopyWith<$Res> {
  __$$WorkEntityImplCopyWithImpl(
      _$WorkEntityImpl _value, $Res Function(_$WorkEntityImpl) _then)
      : super(_value, _then);

  /// Create a copy of WorkEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? author = null,
    Object? remark = freezed,
    Object? style = null,
    Object? tool = null,
    Object? creationDate = null,
    Object? createTime = null,
    Object? updateTime = null,
    Object? isFavorite = null,
    Object? lastImageUpdateTime = freezed,
    Object? status = null,
    Object? firstImageId = freezed,
    Object? images = null,
    Object? collectedChars = null,
    Object? tags = null,
    Object? imageCount = freezed,
  }) {
    return _then(_$WorkEntityImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      author: null == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as String,
      remark: freezed == remark
          ? _value.remark
          : remark // ignore: cast_nullable_to_non_nullable
              as String?,
      style: null == style
          ? _value.style
          : style // ignore: cast_nullable_to_non_nullable
              as WorkStyle,
      tool: null == tool
          ? _value.tool
          : tool // ignore: cast_nullable_to_non_nullable
              as WorkTool,
      creationDate: null == creationDate
          ? _value.creationDate
          : creationDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
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
      lastImageUpdateTime: freezed == lastImageUpdateTime
          ? _value.lastImageUpdateTime
          : lastImageUpdateTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as WorkStatus,
      firstImageId: freezed == firstImageId
          ? _value.firstImageId
          : firstImageId // ignore: cast_nullable_to_non_nullable
              as String?,
      images: null == images
          ? _value._images
          : images // ignore: cast_nullable_to_non_nullable
              as List<WorkImage>,
      collectedChars: null == collectedChars
          ? _value._collectedChars
          : collectedChars // ignore: cast_nullable_to_non_nullable
              as List<CharacterEntity>,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      imageCount: freezed == imageCount
          ? _value.imageCount
          : imageCount // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkEntityImpl extends _WorkEntity {
  const _$WorkEntityImpl(
      {required this.id,
      required this.title,
      required this.author,
      this.remark,
      @JsonKey(fromJson: _workStyleFromJson, toJson: _workStyleToJson)
      required this.style,
      @JsonKey(fromJson: _workToolFromJson, toJson: _workToolToJson)
      required this.tool,
      @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
      required this.creationDate,
      @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
      required this.createTime,
      @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
      required this.updateTime,
      @JsonKey(fromJson: _isFavoriteFromJson, toJson: _isFavoriteToJson)
      this.isFavorite = false,
      @JsonKey(
          fromJson: _dateTimeFromJson,
          toJson: _dateTimeToJson,
          includeIfNull: false)
      this.lastImageUpdateTime,
      this.status = WorkStatus.draft,
      this.firstImageId,
      final List<WorkImage> images = const [],
      final List<CharacterEntity> collectedChars = const [],
      final List<String> tags = const [],
      this.imageCount})
      : _images = images,
        _collectedChars = collectedChars,
        _tags = tags,
        super._();

  factory _$WorkEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkEntityImplFromJson(json);

  /// ID
  @override
  final String id;

  /// 标题
  @override
  final String title;

  /// 作者
  @override
  final String author;

  /// 备注
  @override
  final String? remark;

  /// 字体
  @override
  @JsonKey(fromJson: _workStyleFromJson, toJson: _workStyleToJson)
  final WorkStyle style;

  /// 工具
  @override
  @JsonKey(fromJson: _workToolFromJson, toJson: _workToolToJson)
  final WorkTool tool;

  /// 创作日期
  @override
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime creationDate;

  /// 创建时间
  @override
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime createTime;

  /// 修改时间
  @override
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime updateTime;

  /// 是否收藏
  @override
  @JsonKey(fromJson: _isFavoriteFromJson, toJson: _isFavoriteToJson)
  final bool isFavorite;

  /// 图片最后更新时间
  @override
  @JsonKey(
      fromJson: _dateTimeFromJson,
      toJson: _dateTimeToJson,
      includeIfNull: false)
  final DateTime? lastImageUpdateTime;

  /// 状态
  @override
  @JsonKey()
  final WorkStatus status;

  /// 首图ID
  @override
  final String? firstImageId;

  /// 图片列表
  final List<WorkImage> _images;

  /// 图片列表
  @override
  @JsonKey()
  List<WorkImage> get images {
    if (_images is EqualUnmodifiableListView) return _images;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_images);
  }

  /// 关联字符列表
  final List<CharacterEntity> _collectedChars;

  /// 关联字符列表
  @override
  @JsonKey()
  List<CharacterEntity> get collectedChars {
    if (_collectedChars is EqualUnmodifiableListView) return _collectedChars;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_collectedChars);
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

  /// 图片数量
  @override
  final int? imageCount;

  @override
  String toString() {
    return 'WorkEntity(id: $id, title: $title, author: $author, remark: $remark, style: $style, tool: $tool, creationDate: $creationDate, createTime: $createTime, updateTime: $updateTime, isFavorite: $isFavorite, lastImageUpdateTime: $lastImageUpdateTime, status: $status, firstImageId: $firstImageId, images: $images, collectedChars: $collectedChars, tags: $tags, imageCount: $imageCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.author, author) || other.author == author) &&
            (identical(other.remark, remark) || other.remark == remark) &&
            (identical(other.style, style) || other.style == style) &&
            (identical(other.tool, tool) || other.tool == tool) &&
            (identical(other.creationDate, creationDate) ||
                other.creationDate == creationDate) &&
            (identical(other.createTime, createTime) ||
                other.createTime == createTime) &&
            (identical(other.updateTime, updateTime) ||
                other.updateTime == updateTime) &&
            (identical(other.isFavorite, isFavorite) ||
                other.isFavorite == isFavorite) &&
            (identical(other.lastImageUpdateTime, lastImageUpdateTime) ||
                other.lastImageUpdateTime == lastImageUpdateTime) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.firstImageId, firstImageId) ||
                other.firstImageId == firstImageId) &&
            const DeepCollectionEquality().equals(other._images, _images) &&
            const DeepCollectionEquality()
                .equals(other._collectedChars, _collectedChars) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.imageCount, imageCount) ||
                other.imageCount == imageCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      author,
      remark,
      style,
      tool,
      creationDate,
      createTime,
      updateTime,
      isFavorite,
      lastImageUpdateTime,
      status,
      firstImageId,
      const DeepCollectionEquality().hash(_images),
      const DeepCollectionEquality().hash(_collectedChars),
      const DeepCollectionEquality().hash(_tags),
      imageCount);

  /// Create a copy of WorkEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkEntityImplCopyWith<_$WorkEntityImpl> get copyWith =>
      __$$WorkEntityImplCopyWithImpl<_$WorkEntityImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkEntityImplToJson(
      this,
    );
  }
}

abstract class _WorkEntity extends WorkEntity {
  const factory _WorkEntity(
      {required final String id,
      required final String title,
      required final String author,
      final String? remark,
      @JsonKey(fromJson: _workStyleFromJson, toJson: _workStyleToJson)
      required final WorkStyle style,
      @JsonKey(fromJson: _workToolFromJson, toJson: _workToolToJson)
      required final WorkTool tool,
      @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
      required final DateTime creationDate,
      @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
      required final DateTime createTime,
      @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
      required final DateTime updateTime,
      @JsonKey(fromJson: _isFavoriteFromJson, toJson: _isFavoriteToJson)
      final bool isFavorite,
      @JsonKey(
          fromJson: _dateTimeFromJson,
          toJson: _dateTimeToJson,
          includeIfNull: false)
      final DateTime? lastImageUpdateTime,
      final WorkStatus status,
      final String? firstImageId,
      final List<WorkImage> images,
      final List<CharacterEntity> collectedChars,
      final List<String> tags,
      final int? imageCount}) = _$WorkEntityImpl;
  const _WorkEntity._() : super._();

  factory _WorkEntity.fromJson(Map<String, dynamic> json) =
      _$WorkEntityImpl.fromJson;

  /// ID
  @override
  String get id;

  /// 标题
  @override
  String get title;

  /// 作者
  @override
  String get author;

  /// 备注
  @override
  String? get remark;

  /// 字体
  @override
  @JsonKey(fromJson: _workStyleFromJson, toJson: _workStyleToJson)
  WorkStyle get style;

  /// 工具
  @override
  @JsonKey(fromJson: _workToolFromJson, toJson: _workToolToJson)
  WorkTool get tool;

  /// 创作日期
  @override
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  DateTime get creationDate;

  /// 创建时间
  @override
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  DateTime get createTime;

  /// 修改时间
  @override
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  DateTime get updateTime;

  /// 是否收藏
  @override
  @JsonKey(fromJson: _isFavoriteFromJson, toJson: _isFavoriteToJson)
  bool get isFavorite;

  /// 图片最后更新时间
  @override
  @JsonKey(
      fromJson: _dateTimeFromJson,
      toJson: _dateTimeToJson,
      includeIfNull: false)
  DateTime? get lastImageUpdateTime;

  /// 状态
  @override
  WorkStatus get status;

  /// 首图ID
  @override
  String? get firstImageId;

  /// 图片列表
  @override
  List<WorkImage> get images;

  /// 关联字符列表
  @override
  List<CharacterEntity> get collectedChars;

  /// 标签列表
  @override
  List<String> get tags;

  /// 图片数量
  @override
  int? get imageCount;

  /// Create a copy of WorkEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WorkEntityImplCopyWith<_$WorkEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
