// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'character_region.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CharacterRegion _$CharacterRegionFromJson(Map<String, dynamic> json) {
  return _CharacterRegion.fromJson(json);
}

/// @nodoc
mixin _$CharacterRegion {
  String get id => throw _privateConstructorUsedError;
  String get pageId => throw _privateConstructorUsedError;
  @RectConverter()
  Rect get rect => throw _privateConstructorUsedError;
  double get rotation => throw _privateConstructorUsedError;
  String get character => throw _privateConstructorUsedError;
  DateTime get createTime => throw _privateConstructorUsedError;
  DateTime get updateTime => throw _privateConstructorUsedError;
  ProcessingOptions get options => throw _privateConstructorUsedError;
  @OffsetListConverter()
  List<Offset>? get erasePoints => throw _privateConstructorUsedError;

  /// Serializes this CharacterRegion to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CharacterRegion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CharacterRegionCopyWith<CharacterRegion> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CharacterRegionCopyWith<$Res> {
  factory $CharacterRegionCopyWith(
          CharacterRegion value, $Res Function(CharacterRegion) then) =
      _$CharacterRegionCopyWithImpl<$Res, CharacterRegion>;
  @useResult
  $Res call(
      {String id,
      String pageId,
      @RectConverter() Rect rect,
      double rotation,
      String character,
      DateTime createTime,
      DateTime updateTime,
      ProcessingOptions options,
      @OffsetListConverter() List<Offset>? erasePoints});

  $ProcessingOptionsCopyWith<$Res> get options;
}

/// @nodoc
class _$CharacterRegionCopyWithImpl<$Res, $Val extends CharacterRegion>
    implements $CharacterRegionCopyWith<$Res> {
  _$CharacterRegionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CharacterRegion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? pageId = null,
    Object? rect = null,
    Object? rotation = null,
    Object? character = null,
    Object? createTime = null,
    Object? updateTime = null,
    Object? options = null,
    Object? erasePoints = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      pageId: null == pageId
          ? _value.pageId
          : pageId // ignore: cast_nullable_to_non_nullable
              as String,
      rect: null == rect
          ? _value.rect
          : rect // ignore: cast_nullable_to_non_nullable
              as Rect,
      rotation: null == rotation
          ? _value.rotation
          : rotation // ignore: cast_nullable_to_non_nullable
              as double,
      character: null == character
          ? _value.character
          : character // ignore: cast_nullable_to_non_nullable
              as String,
      createTime: null == createTime
          ? _value.createTime
          : createTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updateTime: null == updateTime
          ? _value.updateTime
          : updateTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      options: null == options
          ? _value.options
          : options // ignore: cast_nullable_to_non_nullable
              as ProcessingOptions,
      erasePoints: freezed == erasePoints
          ? _value.erasePoints
          : erasePoints // ignore: cast_nullable_to_non_nullable
              as List<Offset>?,
    ) as $Val);
  }

  /// Create a copy of CharacterRegion
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ProcessingOptionsCopyWith<$Res> get options {
    return $ProcessingOptionsCopyWith<$Res>(_value.options, (value) {
      return _then(_value.copyWith(options: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CharacterRegionImplCopyWith<$Res>
    implements $CharacterRegionCopyWith<$Res> {
  factory _$$CharacterRegionImplCopyWith(_$CharacterRegionImpl value,
          $Res Function(_$CharacterRegionImpl) then) =
      __$$CharacterRegionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String pageId,
      @RectConverter() Rect rect,
      double rotation,
      String character,
      DateTime createTime,
      DateTime updateTime,
      ProcessingOptions options,
      @OffsetListConverter() List<Offset>? erasePoints});

  @override
  $ProcessingOptionsCopyWith<$Res> get options;
}

/// @nodoc
class __$$CharacterRegionImplCopyWithImpl<$Res>
    extends _$CharacterRegionCopyWithImpl<$Res, _$CharacterRegionImpl>
    implements _$$CharacterRegionImplCopyWith<$Res> {
  __$$CharacterRegionImplCopyWithImpl(
      _$CharacterRegionImpl _value, $Res Function(_$CharacterRegionImpl) _then)
      : super(_value, _then);

  /// Create a copy of CharacterRegion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? pageId = null,
    Object? rect = null,
    Object? rotation = null,
    Object? character = null,
    Object? createTime = null,
    Object? updateTime = null,
    Object? options = null,
    Object? erasePoints = freezed,
  }) {
    return _then(_$CharacterRegionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      pageId: null == pageId
          ? _value.pageId
          : pageId // ignore: cast_nullable_to_non_nullable
              as String,
      rect: null == rect
          ? _value.rect
          : rect // ignore: cast_nullable_to_non_nullable
              as Rect,
      rotation: null == rotation
          ? _value.rotation
          : rotation // ignore: cast_nullable_to_non_nullable
              as double,
      character: null == character
          ? _value.character
          : character // ignore: cast_nullable_to_non_nullable
              as String,
      createTime: null == createTime
          ? _value.createTime
          : createTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updateTime: null == updateTime
          ? _value.updateTime
          : updateTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      options: null == options
          ? _value.options
          : options // ignore: cast_nullable_to_non_nullable
              as ProcessingOptions,
      erasePoints: freezed == erasePoints
          ? _value._erasePoints
          : erasePoints // ignore: cast_nullable_to_non_nullable
              as List<Offset>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CharacterRegionImpl implements _CharacterRegion {
  const _$CharacterRegionImpl(
      {required this.id,
      required this.pageId,
      @RectConverter() required this.rect,
      this.rotation = 0.0,
      required this.character,
      required this.createTime,
      required this.updateTime,
      required this.options,
      @OffsetListConverter() final List<Offset>? erasePoints})
      : _erasePoints = erasePoints;

  factory _$CharacterRegionImpl.fromJson(Map<String, dynamic> json) =>
      _$$CharacterRegionImplFromJson(json);

  @override
  final String id;
  @override
  final String pageId;
  @override
  @RectConverter()
  final Rect rect;
  @override
  @JsonKey()
  final double rotation;
  @override
  final String character;
  @override
  final DateTime createTime;
  @override
  final DateTime updateTime;
  @override
  final ProcessingOptions options;
  final List<Offset>? _erasePoints;
  @override
  @OffsetListConverter()
  List<Offset>? get erasePoints {
    final value = _erasePoints;
    if (value == null) return null;
    if (_erasePoints is EqualUnmodifiableListView) return _erasePoints;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'CharacterRegion(id: $id, pageId: $pageId, rect: $rect, rotation: $rotation, character: $character, createTime: $createTime, updateTime: $updateTime, options: $options, erasePoints: $erasePoints)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CharacterRegionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.pageId, pageId) || other.pageId == pageId) &&
            (identical(other.rect, rect) || other.rect == rect) &&
            (identical(other.rotation, rotation) ||
                other.rotation == rotation) &&
            (identical(other.character, character) ||
                other.character == character) &&
            (identical(other.createTime, createTime) ||
                other.createTime == createTime) &&
            (identical(other.updateTime, updateTime) ||
                other.updateTime == updateTime) &&
            (identical(other.options, options) || other.options == options) &&
            const DeepCollectionEquality()
                .equals(other._erasePoints, _erasePoints));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      pageId,
      rect,
      rotation,
      character,
      createTime,
      updateTime,
      options,
      const DeepCollectionEquality().hash(_erasePoints));

  /// Create a copy of CharacterRegion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CharacterRegionImplCopyWith<_$CharacterRegionImpl> get copyWith =>
      __$$CharacterRegionImplCopyWithImpl<_$CharacterRegionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CharacterRegionImplToJson(
      this,
    );
  }
}

abstract class _CharacterRegion implements CharacterRegion {
  const factory _CharacterRegion(
          {required final String id,
          required final String pageId,
          @RectConverter() required final Rect rect,
          final double rotation,
          required final String character,
          required final DateTime createTime,
          required final DateTime updateTime,
          required final ProcessingOptions options,
          @OffsetListConverter() final List<Offset>? erasePoints}) =
      _$CharacterRegionImpl;

  factory _CharacterRegion.fromJson(Map<String, dynamic> json) =
      _$CharacterRegionImpl.fromJson;

  @override
  String get id;
  @override
  String get pageId;
  @override
  @RectConverter()
  Rect get rect;
  @override
  double get rotation;
  @override
  String get character;
  @override
  DateTime get createTime;
  @override
  DateTime get updateTime;
  @override
  ProcessingOptions get options;
  @override
  @OffsetListConverter()
  List<Offset>? get erasePoints;

  /// Create a copy of CharacterRegion
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CharacterRegionImplCopyWith<_$CharacterRegionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
