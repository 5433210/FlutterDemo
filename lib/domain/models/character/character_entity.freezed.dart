// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'character_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CharacterEntity _$CharacterEntityFromJson(Map<String, dynamic> json) {
  return _CharacterEntity.fromJson(json);
}

/// @nodoc
mixin _$CharacterEntity {
  /// ID
  String? get id => throw _privateConstructorUsedError;

  /// 汉字
  String get char => throw _privateConstructorUsedError;

  /// 所属作品ID
  String? get workId => throw _privateConstructorUsedError;

  /// 字形区域
  CharacterRegion? get region => throw _privateConstructorUsedError;

  /// 标签列表
  List<String> get tags => throw _privateConstructorUsedError;

  /// 创建时间
  DateTime? get createTime => throw _privateConstructorUsedError;

  /// 更新时间
  DateTime? get updateTime => throw _privateConstructorUsedError;

  /// Serializes this CharacterEntity to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CharacterEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CharacterEntityCopyWith<CharacterEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CharacterEntityCopyWith<$Res> {
  factory $CharacterEntityCopyWith(
          CharacterEntity value, $Res Function(CharacterEntity) then) =
      _$CharacterEntityCopyWithImpl<$Res, CharacterEntity>;
  @useResult
  $Res call(
      {String? id,
      String char,
      String? workId,
      CharacterRegion? region,
      List<String> tags,
      DateTime? createTime,
      DateTime? updateTime});

  $CharacterRegionCopyWith<$Res>? get region;
}

/// @nodoc
class _$CharacterEntityCopyWithImpl<$Res, $Val extends CharacterEntity>
    implements $CharacterEntityCopyWith<$Res> {
  _$CharacterEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CharacterEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? char = null,
    Object? workId = freezed,
    Object? region = freezed,
    Object? tags = null,
    Object? createTime = freezed,
    Object? updateTime = freezed,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      char: null == char
          ? _value.char
          : char // ignore: cast_nullable_to_non_nullable
              as String,
      workId: freezed == workId
          ? _value.workId
          : workId // ignore: cast_nullable_to_non_nullable
              as String?,
      region: freezed == region
          ? _value.region
          : region // ignore: cast_nullable_to_non_nullable
              as CharacterRegion?,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
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

  /// Create a copy of CharacterEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CharacterRegionCopyWith<$Res>? get region {
    if (_value.region == null) {
      return null;
    }

    return $CharacterRegionCopyWith<$Res>(_value.region!, (value) {
      return _then(_value.copyWith(region: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CharacterEntityImplCopyWith<$Res>
    implements $CharacterEntityCopyWith<$Res> {
  factory _$$CharacterEntityImplCopyWith(_$CharacterEntityImpl value,
          $Res Function(_$CharacterEntityImpl) then) =
      __$$CharacterEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? id,
      String char,
      String? workId,
      CharacterRegion? region,
      List<String> tags,
      DateTime? createTime,
      DateTime? updateTime});

  @override
  $CharacterRegionCopyWith<$Res>? get region;
}

/// @nodoc
class __$$CharacterEntityImplCopyWithImpl<$Res>
    extends _$CharacterEntityCopyWithImpl<$Res, _$CharacterEntityImpl>
    implements _$$CharacterEntityImplCopyWith<$Res> {
  __$$CharacterEntityImplCopyWithImpl(
      _$CharacterEntityImpl _value, $Res Function(_$CharacterEntityImpl) _then)
      : super(_value, _then);

  /// Create a copy of CharacterEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? char = null,
    Object? workId = freezed,
    Object? region = freezed,
    Object? tags = null,
    Object? createTime = freezed,
    Object? updateTime = freezed,
  }) {
    return _then(_$CharacterEntityImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      char: null == char
          ? _value.char
          : char // ignore: cast_nullable_to_non_nullable
              as String,
      workId: freezed == workId
          ? _value.workId
          : workId // ignore: cast_nullable_to_non_nullable
              as String?,
      region: freezed == region
          ? _value.region
          : region // ignore: cast_nullable_to_non_nullable
              as CharacterRegion?,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
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
class _$CharacterEntityImpl extends _CharacterEntity {
  const _$CharacterEntityImpl(
      {this.id,
      required this.char,
      this.workId,
      this.region,
      final List<String> tags = const [],
      this.createTime,
      this.updateTime})
      : _tags = tags,
        super._();

  factory _$CharacterEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$CharacterEntityImplFromJson(json);

  /// ID
  @override
  final String? id;

  /// 汉字
  @override
  final String char;

  /// 所属作品ID
  @override
  final String? workId;

  /// 字形区域
  @override
  final CharacterRegion? region;

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

  /// 创建时间
  @override
  final DateTime? createTime;

  /// 更新时间
  @override
  final DateTime? updateTime;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CharacterEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.char, char) || other.char == char) &&
            (identical(other.workId, workId) || other.workId == workId) &&
            (identical(other.region, region) || other.region == region) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.createTime, createTime) ||
                other.createTime == createTime) &&
            (identical(other.updateTime, updateTime) ||
                other.updateTime == updateTime));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, char, workId, region,
      const DeepCollectionEquality().hash(_tags), createTime, updateTime);

  /// Create a copy of CharacterEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CharacterEntityImplCopyWith<_$CharacterEntityImpl> get copyWith =>
      __$$CharacterEntityImplCopyWithImpl<_$CharacterEntityImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CharacterEntityImplToJson(
      this,
    );
  }
}

abstract class _CharacterEntity extends CharacterEntity {
  const factory _CharacterEntity(
      {final String? id,
      required final String char,
      final String? workId,
      final CharacterRegion? region,
      final List<String> tags,
      final DateTime? createTime,
      final DateTime? updateTime}) = _$CharacterEntityImpl;
  const _CharacterEntity._() : super._();

  factory _CharacterEntity.fromJson(Map<String, dynamic> json) =
      _$CharacterEntityImpl.fromJson;

  /// ID
  @override
  String? get id;

  /// 汉字
  @override
  String get char;

  /// 所属作品ID
  @override
  String? get workId;

  /// 字形区域
  @override
  CharacterRegion? get region;

  /// 标签列表
  @override
  List<String> get tags;

  /// 创建时间
  @override
  DateTime? get createTime;

  /// 更新时间
  @override
  DateTime? get updateTime;

  /// Create a copy of CharacterEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CharacterEntityImplCopyWith<_$CharacterEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
