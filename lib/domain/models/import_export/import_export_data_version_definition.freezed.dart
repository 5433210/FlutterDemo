// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'import_export_data_version_definition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ImportExportDataVersionInfo _$ImportExportDataVersionInfoFromJson(
    Map<String, dynamic> json) {
  return _ImportExportDataVersionInfo.fromJson(json);
}

/// @nodoc
mixin _$ImportExportDataVersionInfo {
  /// 数据版本标识
  String get version => throw _privateConstructorUsedError;

  /// 版本描述
  String get description => throw _privateConstructorUsedError;

  /// 支持的应用版本列表
  List<String> get supportedAppVersions => throw _privateConstructorUsedError;

  /// 支持的数据库版本范围 [最小版本, 最大版本]
  List<int> get databaseVersionRange => throw _privateConstructorUsedError;

  /// 版本特性列表
  List<String> get features => throw _privateConstructorUsedError;

  /// 版本发布时间
  DateTime? get releaseDate => throw _privateConstructorUsedError;

  /// 是否已弃用
  bool get deprecated => throw _privateConstructorUsedError;

  /// 弃用说明
  String? get deprecationNote => throw _privateConstructorUsedError;

  /// Serializes this ImportExportDataVersionInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ImportExportDataVersionInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ImportExportDataVersionInfoCopyWith<ImportExportDataVersionInfo>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ImportExportDataVersionInfoCopyWith<$Res> {
  factory $ImportExportDataVersionInfoCopyWith(
          ImportExportDataVersionInfo value,
          $Res Function(ImportExportDataVersionInfo) then) =
      _$ImportExportDataVersionInfoCopyWithImpl<$Res,
          ImportExportDataVersionInfo>;
  @useResult
  $Res call(
      {String version,
      String description,
      List<String> supportedAppVersions,
      List<int> databaseVersionRange,
      List<String> features,
      DateTime? releaseDate,
      bool deprecated,
      String? deprecationNote});
}

/// @nodoc
class _$ImportExportDataVersionInfoCopyWithImpl<$Res,
        $Val extends ImportExportDataVersionInfo>
    implements $ImportExportDataVersionInfoCopyWith<$Res> {
  _$ImportExportDataVersionInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ImportExportDataVersionInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? version = null,
    Object? description = null,
    Object? supportedAppVersions = null,
    Object? databaseVersionRange = null,
    Object? features = null,
    Object? releaseDate = freezed,
    Object? deprecated = null,
    Object? deprecationNote = freezed,
  }) {
    return _then(_value.copyWith(
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      supportedAppVersions: null == supportedAppVersions
          ? _value.supportedAppVersions
          : supportedAppVersions // ignore: cast_nullable_to_non_nullable
              as List<String>,
      databaseVersionRange: null == databaseVersionRange
          ? _value.databaseVersionRange
          : databaseVersionRange // ignore: cast_nullable_to_non_nullable
              as List<int>,
      features: null == features
          ? _value.features
          : features // ignore: cast_nullable_to_non_nullable
              as List<String>,
      releaseDate: freezed == releaseDate
          ? _value.releaseDate
          : releaseDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      deprecated: null == deprecated
          ? _value.deprecated
          : deprecated // ignore: cast_nullable_to_non_nullable
              as bool,
      deprecationNote: freezed == deprecationNote
          ? _value.deprecationNote
          : deprecationNote // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ImportExportDataVersionInfoImplCopyWith<$Res>
    implements $ImportExportDataVersionInfoCopyWith<$Res> {
  factory _$$ImportExportDataVersionInfoImplCopyWith(
          _$ImportExportDataVersionInfoImpl value,
          $Res Function(_$ImportExportDataVersionInfoImpl) then) =
      __$$ImportExportDataVersionInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String version,
      String description,
      List<String> supportedAppVersions,
      List<int> databaseVersionRange,
      List<String> features,
      DateTime? releaseDate,
      bool deprecated,
      String? deprecationNote});
}

/// @nodoc
class __$$ImportExportDataVersionInfoImplCopyWithImpl<$Res>
    extends _$ImportExportDataVersionInfoCopyWithImpl<$Res,
        _$ImportExportDataVersionInfoImpl>
    implements _$$ImportExportDataVersionInfoImplCopyWith<$Res> {
  __$$ImportExportDataVersionInfoImplCopyWithImpl(
      _$ImportExportDataVersionInfoImpl _value,
      $Res Function(_$ImportExportDataVersionInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of ImportExportDataVersionInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? version = null,
    Object? description = null,
    Object? supportedAppVersions = null,
    Object? databaseVersionRange = null,
    Object? features = null,
    Object? releaseDate = freezed,
    Object? deprecated = null,
    Object? deprecationNote = freezed,
  }) {
    return _then(_$ImportExportDataVersionInfoImpl(
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      supportedAppVersions: null == supportedAppVersions
          ? _value._supportedAppVersions
          : supportedAppVersions // ignore: cast_nullable_to_non_nullable
              as List<String>,
      databaseVersionRange: null == databaseVersionRange
          ? _value._databaseVersionRange
          : databaseVersionRange // ignore: cast_nullable_to_non_nullable
              as List<int>,
      features: null == features
          ? _value._features
          : features // ignore: cast_nullable_to_non_nullable
              as List<String>,
      releaseDate: freezed == releaseDate
          ? _value.releaseDate
          : releaseDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      deprecated: null == deprecated
          ? _value.deprecated
          : deprecated // ignore: cast_nullable_to_non_nullable
              as bool,
      deprecationNote: freezed == deprecationNote
          ? _value.deprecationNote
          : deprecationNote // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ImportExportDataVersionInfoImpl
    implements _ImportExportDataVersionInfo {
  const _$ImportExportDataVersionInfoImpl(
      {required this.version,
      required this.description,
      required final List<String> supportedAppVersions,
      required final List<int> databaseVersionRange,
      required final List<String> features,
      this.releaseDate,
      this.deprecated = false,
      this.deprecationNote})
      : _supportedAppVersions = supportedAppVersions,
        _databaseVersionRange = databaseVersionRange,
        _features = features;

  factory _$ImportExportDataVersionInfoImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$ImportExportDataVersionInfoImplFromJson(json);

  /// 数据版本标识
  @override
  final String version;

  /// 版本描述
  @override
  final String description;

  /// 支持的应用版本列表
  final List<String> _supportedAppVersions;

  /// 支持的应用版本列表
  @override
  List<String> get supportedAppVersions {
    if (_supportedAppVersions is EqualUnmodifiableListView)
      return _supportedAppVersions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_supportedAppVersions);
  }

  /// 支持的数据库版本范围 [最小版本, 最大版本]
  final List<int> _databaseVersionRange;

  /// 支持的数据库版本范围 [最小版本, 最大版本]
  @override
  List<int> get databaseVersionRange {
    if (_databaseVersionRange is EqualUnmodifiableListView)
      return _databaseVersionRange;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_databaseVersionRange);
  }

  /// 版本特性列表
  final List<String> _features;

  /// 版本特性列表
  @override
  List<String> get features {
    if (_features is EqualUnmodifiableListView) return _features;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_features);
  }

  /// 版本发布时间
  @override
  final DateTime? releaseDate;

  /// 是否已弃用
  @override
  @JsonKey()
  final bool deprecated;

  /// 弃用说明
  @override
  final String? deprecationNote;

  @override
  String toString() {
    return 'ImportExportDataVersionInfo(version: $version, description: $description, supportedAppVersions: $supportedAppVersions, databaseVersionRange: $databaseVersionRange, features: $features, releaseDate: $releaseDate, deprecated: $deprecated, deprecationNote: $deprecationNote)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ImportExportDataVersionInfoImpl &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality()
                .equals(other._supportedAppVersions, _supportedAppVersions) &&
            const DeepCollectionEquality()
                .equals(other._databaseVersionRange, _databaseVersionRange) &&
            const DeepCollectionEquality().equals(other._features, _features) &&
            (identical(other.releaseDate, releaseDate) ||
                other.releaseDate == releaseDate) &&
            (identical(other.deprecated, deprecated) ||
                other.deprecated == deprecated) &&
            (identical(other.deprecationNote, deprecationNote) ||
                other.deprecationNote == deprecationNote));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      version,
      description,
      const DeepCollectionEquality().hash(_supportedAppVersions),
      const DeepCollectionEquality().hash(_databaseVersionRange),
      const DeepCollectionEquality().hash(_features),
      releaseDate,
      deprecated,
      deprecationNote);

  /// Create a copy of ImportExportDataVersionInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ImportExportDataVersionInfoImplCopyWith<_$ImportExportDataVersionInfoImpl>
      get copyWith => __$$ImportExportDataVersionInfoImplCopyWithImpl<
          _$ImportExportDataVersionInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ImportExportDataVersionInfoImplToJson(
      this,
    );
  }
}

abstract class _ImportExportDataVersionInfo
    implements ImportExportDataVersionInfo {
  const factory _ImportExportDataVersionInfo(
      {required final String version,
      required final String description,
      required final List<String> supportedAppVersions,
      required final List<int> databaseVersionRange,
      required final List<String> features,
      final DateTime? releaseDate,
      final bool deprecated,
      final String? deprecationNote}) = _$ImportExportDataVersionInfoImpl;

  factory _ImportExportDataVersionInfo.fromJson(Map<String, dynamic> json) =
      _$ImportExportDataVersionInfoImpl.fromJson;

  /// 数据版本标识
  @override
  String get version;

  /// 版本描述
  @override
  String get description;

  /// 支持的应用版本列表
  @override
  List<String> get supportedAppVersions;

  /// 支持的数据库版本范围 [最小版本, 最大版本]
  @override
  List<int> get databaseVersionRange;

  /// 版本特性列表
  @override
  List<String> get features;

  /// 版本发布时间
  @override
  DateTime? get releaseDate;

  /// 是否已弃用
  @override
  bool get deprecated;

  /// 弃用说明
  @override
  String? get deprecationNote;

  /// Create a copy of ImportExportDataVersionInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ImportExportDataVersionInfoImplCopyWith<_$ImportExportDataVersionInfoImpl>
      get copyWith => throw _privateConstructorUsedError;
}
