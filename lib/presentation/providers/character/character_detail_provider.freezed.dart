// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'character_detail_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CharacterFormatInfo _$CharacterFormatInfoFromJson(Map<String, dynamic> json) {
  return _CharacterFormatInfo.fromJson(json);
}

/// @nodoc
mixin _$CharacterFormatInfo {
  CharacterImageType get format => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  Future<String> Function(String)? get pathResolver =>
      throw _privateConstructorUsedError;

  /// Serializes this CharacterFormatInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CharacterFormatInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CharacterFormatInfoCopyWith<CharacterFormatInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CharacterFormatInfoCopyWith<$Res> {
  factory $CharacterFormatInfoCopyWith(
          CharacterFormatInfo value, $Res Function(CharacterFormatInfo) then) =
      _$CharacterFormatInfoCopyWithImpl<$Res, CharacterFormatInfo>;
  @useResult
  $Res call(
      {CharacterImageType format,
      String name,
      String description,
      @JsonKey(ignore: true) Future<String> Function(String)? pathResolver});
}

/// @nodoc
class _$CharacterFormatInfoCopyWithImpl<$Res, $Val extends CharacterFormatInfo>
    implements $CharacterFormatInfoCopyWith<$Res> {
  _$CharacterFormatInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CharacterFormatInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? format = null,
    Object? name = null,
    Object? description = null,
    Object? pathResolver = freezed,
  }) {
    return _then(_value.copyWith(
      format: null == format
          ? _value.format
          : format // ignore: cast_nullable_to_non_nullable
              as CharacterImageType,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      pathResolver: freezed == pathResolver
          ? _value.pathResolver
          : pathResolver // ignore: cast_nullable_to_non_nullable
              as Future<String> Function(String)?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CharacterFormatInfoImplCopyWith<$Res>
    implements $CharacterFormatInfoCopyWith<$Res> {
  factory _$$CharacterFormatInfoImplCopyWith(_$CharacterFormatInfoImpl value,
          $Res Function(_$CharacterFormatInfoImpl) then) =
      __$$CharacterFormatInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {CharacterImageType format,
      String name,
      String description,
      @JsonKey(ignore: true) Future<String> Function(String)? pathResolver});
}

/// @nodoc
class __$$CharacterFormatInfoImplCopyWithImpl<$Res>
    extends _$CharacterFormatInfoCopyWithImpl<$Res, _$CharacterFormatInfoImpl>
    implements _$$CharacterFormatInfoImplCopyWith<$Res> {
  __$$CharacterFormatInfoImplCopyWithImpl(_$CharacterFormatInfoImpl _value,
      $Res Function(_$CharacterFormatInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of CharacterFormatInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? format = null,
    Object? name = null,
    Object? description = null,
    Object? pathResolver = freezed,
  }) {
    return _then(_$CharacterFormatInfoImpl(
      format: null == format
          ? _value.format
          : format // ignore: cast_nullable_to_non_nullable
              as CharacterImageType,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      pathResolver: freezed == pathResolver
          ? _value.pathResolver
          : pathResolver // ignore: cast_nullable_to_non_nullable
              as Future<String> Function(String)?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CharacterFormatInfoImpl extends _CharacterFormatInfo {
  const _$CharacterFormatInfoImpl(
      {required this.format,
      required this.name,
      required this.description,
      @JsonKey(ignore: true) this.pathResolver})
      : super._();

  factory _$CharacterFormatInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$CharacterFormatInfoImplFromJson(json);

  @override
  final CharacterImageType format;
  @override
  final String name;
  @override
  final String description;
  @override
  @JsonKey(ignore: true)
  final Future<String> Function(String)? pathResolver;

  @override
  String toString() {
    return 'CharacterFormatInfo(format: $format, name: $name, description: $description, pathResolver: $pathResolver)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CharacterFormatInfoImpl &&
            (identical(other.format, format) || other.format == format) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.pathResolver, pathResolver) ||
                other.pathResolver == pathResolver));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, format, name, description, pathResolver);

  /// Create a copy of CharacterFormatInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CharacterFormatInfoImplCopyWith<_$CharacterFormatInfoImpl> get copyWith =>
      __$$CharacterFormatInfoImplCopyWithImpl<_$CharacterFormatInfoImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CharacterFormatInfoImplToJson(
      this,
    );
  }
}

abstract class _CharacterFormatInfo extends CharacterFormatInfo {
  const factory _CharacterFormatInfo(
          {required final CharacterImageType format,
          required final String name,
          required final String description,
          @JsonKey(ignore: true)
          final Future<String> Function(String)? pathResolver}) =
      _$CharacterFormatInfoImpl;
  const _CharacterFormatInfo._() : super._();

  factory _CharacterFormatInfo.fromJson(Map<String, dynamic> json) =
      _$CharacterFormatInfoImpl.fromJson;

  @override
  CharacterImageType get format;
  @override
  String get name;
  @override
  String get description;
  @override
  @JsonKey(ignore: true)
  Future<String> Function(String)? get pathResolver;

  /// Create a copy of CharacterFormatInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CharacterFormatInfoImplCopyWith<_$CharacterFormatInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
