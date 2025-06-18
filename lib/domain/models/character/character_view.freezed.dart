// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'character_view.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CharacterView _$CharacterViewFromJson(Map<String, dynamic> json) {
  return _CharacterView.fromJson(json);
}

/// @nodoc
mixin _$CharacterView {
  /// 唯一标识符
  String get id => throw _privateConstructorUsedError;

  /// 字符内容（简体字）
  String get character => throw _privateConstructorUsedError;

  /// 作品ID
  String get workId => throw _privateConstructorUsedError;

  /// 页面ID
  String get pageId => throw _privateConstructorUsedError;

  /// 作品名称
  String get title => throw _privateConstructorUsedError;

  /// 书写工具 (动态配置)
  String? get tool => throw _privateConstructorUsedError;

  /// 字体风格 (动态配置)
  String? get style => throw _privateConstructorUsedError;

  /// 作者
  String? get author => throw _privateConstructorUsedError;

  /// 字符收集时间
  DateTime get collectionTime => throw _privateConstructorUsedError;

  /// 字符最近更新时间
  DateTime get updateTime => throw _privateConstructorUsedError;

  /// 是否收藏
  bool get isFavorite => throw _privateConstructorUsedError;

  /// 标签列表
  List<String> get tags => throw _privateConstructorUsedError;

  /// 字符区域信息
  CharacterRegion get region => throw _privateConstructorUsedError;

  /// Serializes this CharacterView to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CharacterView
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CharacterViewCopyWith<CharacterView> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CharacterViewCopyWith<$Res> {
  factory $CharacterViewCopyWith(
          CharacterView value, $Res Function(CharacterView) then) =
      _$CharacterViewCopyWithImpl<$Res, CharacterView>;
  @useResult
  $Res call(
      {String id,
      String character,
      String workId,
      String pageId,
      String title,
      String? tool,
      String? style,
      String? author,
      DateTime collectionTime,
      DateTime updateTime,
      bool isFavorite,
      List<String> tags,
      CharacterRegion region});

  $CharacterRegionCopyWith<$Res> get region;
}

/// @nodoc
class _$CharacterViewCopyWithImpl<$Res, $Val extends CharacterView>
    implements $CharacterViewCopyWith<$Res> {
  _$CharacterViewCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CharacterView
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? character = null,
    Object? workId = null,
    Object? pageId = null,
    Object? title = null,
    Object? tool = freezed,
    Object? style = freezed,
    Object? author = freezed,
    Object? collectionTime = null,
    Object? updateTime = null,
    Object? isFavorite = null,
    Object? tags = null,
    Object? region = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      character: null == character
          ? _value.character
          : character // ignore: cast_nullable_to_non_nullable
              as String,
      workId: null == workId
          ? _value.workId
          : workId // ignore: cast_nullable_to_non_nullable
              as String,
      pageId: null == pageId
          ? _value.pageId
          : pageId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      tool: freezed == tool
          ? _value.tool
          : tool // ignore: cast_nullable_to_non_nullable
              as String?,
      style: freezed == style
          ? _value.style
          : style // ignore: cast_nullable_to_non_nullable
              as String?,
      author: freezed == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as String?,
      collectionTime: null == collectionTime
          ? _value.collectionTime
          : collectionTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updateTime: null == updateTime
          ? _value.updateTime
          : updateTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isFavorite: null == isFavorite
          ? _value.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      region: null == region
          ? _value.region
          : region // ignore: cast_nullable_to_non_nullable
              as CharacterRegion,
    ) as $Val);
  }

  /// Create a copy of CharacterView
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CharacterRegionCopyWith<$Res> get region {
    return $CharacterRegionCopyWith<$Res>(_value.region, (value) {
      return _then(_value.copyWith(region: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CharacterViewImplCopyWith<$Res>
    implements $CharacterViewCopyWith<$Res> {
  factory _$$CharacterViewImplCopyWith(
          _$CharacterViewImpl value, $Res Function(_$CharacterViewImpl) then) =
      __$$CharacterViewImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String character,
      String workId,
      String pageId,
      String title,
      String? tool,
      String? style,
      String? author,
      DateTime collectionTime,
      DateTime updateTime,
      bool isFavorite,
      List<String> tags,
      CharacterRegion region});

  @override
  $CharacterRegionCopyWith<$Res> get region;
}

/// @nodoc
class __$$CharacterViewImplCopyWithImpl<$Res>
    extends _$CharacterViewCopyWithImpl<$Res, _$CharacterViewImpl>
    implements _$$CharacterViewImplCopyWith<$Res> {
  __$$CharacterViewImplCopyWithImpl(
      _$CharacterViewImpl _value, $Res Function(_$CharacterViewImpl) _then)
      : super(_value, _then);

  /// Create a copy of CharacterView
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? character = null,
    Object? workId = null,
    Object? pageId = null,
    Object? title = null,
    Object? tool = freezed,
    Object? style = freezed,
    Object? author = freezed,
    Object? collectionTime = null,
    Object? updateTime = null,
    Object? isFavorite = null,
    Object? tags = null,
    Object? region = null,
  }) {
    return _then(_$CharacterViewImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      character: null == character
          ? _value.character
          : character // ignore: cast_nullable_to_non_nullable
              as String,
      workId: null == workId
          ? _value.workId
          : workId // ignore: cast_nullable_to_non_nullable
              as String,
      pageId: null == pageId
          ? _value.pageId
          : pageId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      tool: freezed == tool
          ? _value.tool
          : tool // ignore: cast_nullable_to_non_nullable
              as String?,
      style: freezed == style
          ? _value.style
          : style // ignore: cast_nullable_to_non_nullable
              as String?,
      author: freezed == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as String?,
      collectionTime: null == collectionTime
          ? _value.collectionTime
          : collectionTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updateTime: null == updateTime
          ? _value.updateTime
          : updateTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isFavorite: null == isFavorite
          ? _value.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      region: null == region
          ? _value.region
          : region // ignore: cast_nullable_to_non_nullable
              as CharacterRegion,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CharacterViewImpl extends _CharacterView {
  const _$CharacterViewImpl(
      {required this.id,
      required this.character,
      required this.workId,
      required this.pageId,
      required this.title,
      this.tool,
      this.style,
      this.author,
      required this.collectionTime,
      required this.updateTime,
      this.isFavorite = false,
      final List<String> tags = const [],
      required this.region})
      : _tags = tags,
        super._();

  factory _$CharacterViewImpl.fromJson(Map<String, dynamic> json) =>
      _$$CharacterViewImplFromJson(json);

  /// 唯一标识符
  @override
  final String id;

  /// 字符内容（简体字）
  @override
  final String character;

  /// 作品ID
  @override
  final String workId;

  /// 页面ID
  @override
  final String pageId;

  /// 作品名称
  @override
  final String title;

  /// 书写工具 (动态配置)
  @override
  final String? tool;

  /// 字体风格 (动态配置)
  @override
  final String? style;

  /// 作者
  @override
  final String? author;

  /// 字符收集时间
  @override
  final DateTime collectionTime;

  /// 字符最近更新时间
  @override
  final DateTime updateTime;

  /// 是否收藏
  @override
  @JsonKey()
  final bool isFavorite;

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

  /// 字符区域信息
  @override
  final CharacterRegion region;

  @override
  String toString() {
    return 'CharacterView(id: $id, character: $character, workId: $workId, pageId: $pageId, title: $title, tool: $tool, style: $style, author: $author, collectionTime: $collectionTime, updateTime: $updateTime, isFavorite: $isFavorite, tags: $tags, region: $region)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CharacterViewImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.character, character) ||
                other.character == character) &&
            (identical(other.workId, workId) || other.workId == workId) &&
            (identical(other.pageId, pageId) || other.pageId == pageId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.tool, tool) || other.tool == tool) &&
            (identical(other.style, style) || other.style == style) &&
            (identical(other.author, author) || other.author == author) &&
            (identical(other.collectionTime, collectionTime) ||
                other.collectionTime == collectionTime) &&
            (identical(other.updateTime, updateTime) ||
                other.updateTime == updateTime) &&
            (identical(other.isFavorite, isFavorite) ||
                other.isFavorite == isFavorite) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.region, region) || other.region == region));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      character,
      workId,
      pageId,
      title,
      tool,
      style,
      author,
      collectionTime,
      updateTime,
      isFavorite,
      const DeepCollectionEquality().hash(_tags),
      region);

  /// Create a copy of CharacterView
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CharacterViewImplCopyWith<_$CharacterViewImpl> get copyWith =>
      __$$CharacterViewImplCopyWithImpl<_$CharacterViewImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CharacterViewImplToJson(
      this,
    );
  }
}

abstract class _CharacterView extends CharacterView {
  const factory _CharacterView(
      {required final String id,
      required final String character,
      required final String workId,
      required final String pageId,
      required final String title,
      final String? tool,
      final String? style,
      final String? author,
      required final DateTime collectionTime,
      required final DateTime updateTime,
      final bool isFavorite,
      final List<String> tags,
      required final CharacterRegion region}) = _$CharacterViewImpl;
  const _CharacterView._() : super._();

  factory _CharacterView.fromJson(Map<String, dynamic> json) =
      _$CharacterViewImpl.fromJson;

  /// 唯一标识符
  @override
  String get id;

  /// 字符内容（简体字）
  @override
  String get character;

  /// 作品ID
  @override
  String get workId;

  /// 页面ID
  @override
  String get pageId;

  /// 作品名称
  @override
  String get title;

  /// 书写工具 (动态配置)
  @override
  String? get tool;

  /// 字体风格 (动态配置)
  @override
  String? get style;

  /// 作者
  @override
  String? get author;

  /// 字符收集时间
  @override
  DateTime get collectionTime;

  /// 字符最近更新时间
  @override
  DateTime get updateTime;

  /// 是否收藏
  @override
  bool get isFavorite;

  /// 标签列表
  @override
  List<String> get tags;

  /// 字符区域信息
  @override
  CharacterRegion get region;

  /// Create a copy of CharacterView
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CharacterViewImplCopyWith<_$CharacterViewImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
