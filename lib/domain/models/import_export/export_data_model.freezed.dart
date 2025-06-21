// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'export_data_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ExportDataModel _$ExportDataModelFromJson(Map<String, dynamic> json) {
  return _ExportDataModel.fromJson(json);
}

/// @nodoc
mixin _$ExportDataModel {
  /// 导出元数据
  ExportMetadata get metadata => throw _privateConstructorUsedError;

  /// 作品数据列表
  List<WorkEntity> get works => throw _privateConstructorUsedError;

  /// 作品图片数据列表
  List<WorkImage> get workImages => throw _privateConstructorUsedError;

  /// 集字数据列表
  List<CharacterEntity> get characters => throw _privateConstructorUsedError;

  /// 导出清单
  ExportManifest get manifest => throw _privateConstructorUsedError;

  /// Serializes this ExportDataModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ExportDataModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExportDataModelCopyWith<ExportDataModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExportDataModelCopyWith<$Res> {
  factory $ExportDataModelCopyWith(
          ExportDataModel value, $Res Function(ExportDataModel) then) =
      _$ExportDataModelCopyWithImpl<$Res, ExportDataModel>;
  @useResult
  $Res call(
      {ExportMetadata metadata,
      List<WorkEntity> works,
      List<WorkImage> workImages,
      List<CharacterEntity> characters,
      ExportManifest manifest});

  $ExportMetadataCopyWith<$Res> get metadata;
  $ExportManifestCopyWith<$Res> get manifest;
}

/// @nodoc
class _$ExportDataModelCopyWithImpl<$Res, $Val extends ExportDataModel>
    implements $ExportDataModelCopyWith<$Res> {
  _$ExportDataModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExportDataModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? metadata = null,
    Object? works = null,
    Object? workImages = null,
    Object? characters = null,
    Object? manifest = null,
  }) {
    return _then(_value.copyWith(
      metadata: null == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as ExportMetadata,
      works: null == works
          ? _value.works
          : works // ignore: cast_nullable_to_non_nullable
              as List<WorkEntity>,
      workImages: null == workImages
          ? _value.workImages
          : workImages // ignore: cast_nullable_to_non_nullable
              as List<WorkImage>,
      characters: null == characters
          ? _value.characters
          : characters // ignore: cast_nullable_to_non_nullable
              as List<CharacterEntity>,
      manifest: null == manifest
          ? _value.manifest
          : manifest // ignore: cast_nullable_to_non_nullable
              as ExportManifest,
    ) as $Val);
  }

  /// Create a copy of ExportDataModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ExportMetadataCopyWith<$Res> get metadata {
    return $ExportMetadataCopyWith<$Res>(_value.metadata, (value) {
      return _then(_value.copyWith(metadata: value) as $Val);
    });
  }

  /// Create a copy of ExportDataModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ExportManifestCopyWith<$Res> get manifest {
    return $ExportManifestCopyWith<$Res>(_value.manifest, (value) {
      return _then(_value.copyWith(manifest: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ExportDataModelImplCopyWith<$Res>
    implements $ExportDataModelCopyWith<$Res> {
  factory _$$ExportDataModelImplCopyWith(_$ExportDataModelImpl value,
          $Res Function(_$ExportDataModelImpl) then) =
      __$$ExportDataModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {ExportMetadata metadata,
      List<WorkEntity> works,
      List<WorkImage> workImages,
      List<CharacterEntity> characters,
      ExportManifest manifest});

  @override
  $ExportMetadataCopyWith<$Res> get metadata;
  @override
  $ExportManifestCopyWith<$Res> get manifest;
}

/// @nodoc
class __$$ExportDataModelImplCopyWithImpl<$Res>
    extends _$ExportDataModelCopyWithImpl<$Res, _$ExportDataModelImpl>
    implements _$$ExportDataModelImplCopyWith<$Res> {
  __$$ExportDataModelImplCopyWithImpl(
      _$ExportDataModelImpl _value, $Res Function(_$ExportDataModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of ExportDataModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? metadata = null,
    Object? works = null,
    Object? workImages = null,
    Object? characters = null,
    Object? manifest = null,
  }) {
    return _then(_$ExportDataModelImpl(
      metadata: null == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as ExportMetadata,
      works: null == works
          ? _value._works
          : works // ignore: cast_nullable_to_non_nullable
              as List<WorkEntity>,
      workImages: null == workImages
          ? _value._workImages
          : workImages // ignore: cast_nullable_to_non_nullable
              as List<WorkImage>,
      characters: null == characters
          ? _value._characters
          : characters // ignore: cast_nullable_to_non_nullable
              as List<CharacterEntity>,
      manifest: null == manifest
          ? _value.manifest
          : manifest // ignore: cast_nullable_to_non_nullable
              as ExportManifest,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExportDataModelImpl implements _ExportDataModel {
  const _$ExportDataModelImpl(
      {required this.metadata,
      final List<WorkEntity> works = const [],
      final List<WorkImage> workImages = const [],
      final List<CharacterEntity> characters = const [],
      required this.manifest})
      : _works = works,
        _workImages = workImages,
        _characters = characters;

  factory _$ExportDataModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExportDataModelImplFromJson(json);

  /// 导出元数据
  @override
  final ExportMetadata metadata;

  /// 作品数据列表
  final List<WorkEntity> _works;

  /// 作品数据列表
  @override
  @JsonKey()
  List<WorkEntity> get works {
    if (_works is EqualUnmodifiableListView) return _works;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_works);
  }

  /// 作品图片数据列表
  final List<WorkImage> _workImages;

  /// 作品图片数据列表
  @override
  @JsonKey()
  List<WorkImage> get workImages {
    if (_workImages is EqualUnmodifiableListView) return _workImages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_workImages);
  }

  /// 集字数据列表
  final List<CharacterEntity> _characters;

  /// 集字数据列表
  @override
  @JsonKey()
  List<CharacterEntity> get characters {
    if (_characters is EqualUnmodifiableListView) return _characters;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_characters);
  }

  /// 导出清单
  @override
  final ExportManifest manifest;

  @override
  String toString() {
    return 'ExportDataModel(metadata: $metadata, works: $works, workImages: $workImages, characters: $characters, manifest: $manifest)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExportDataModelImpl &&
            (identical(other.metadata, metadata) ||
                other.metadata == metadata) &&
            const DeepCollectionEquality().equals(other._works, _works) &&
            const DeepCollectionEquality()
                .equals(other._workImages, _workImages) &&
            const DeepCollectionEquality()
                .equals(other._characters, _characters) &&
            (identical(other.manifest, manifest) ||
                other.manifest == manifest));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      metadata,
      const DeepCollectionEquality().hash(_works),
      const DeepCollectionEquality().hash(_workImages),
      const DeepCollectionEquality().hash(_characters),
      manifest);

  /// Create a copy of ExportDataModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExportDataModelImplCopyWith<_$ExportDataModelImpl> get copyWith =>
      __$$ExportDataModelImplCopyWithImpl<_$ExportDataModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExportDataModelImplToJson(
      this,
    );
  }
}

abstract class _ExportDataModel implements ExportDataModel {
  const factory _ExportDataModel(
      {required final ExportMetadata metadata,
      final List<WorkEntity> works,
      final List<WorkImage> workImages,
      final List<CharacterEntity> characters,
      required final ExportManifest manifest}) = _$ExportDataModelImpl;

  factory _ExportDataModel.fromJson(Map<String, dynamic> json) =
      _$ExportDataModelImpl.fromJson;

  /// 导出元数据
  @override
  ExportMetadata get metadata;

  /// 作品数据列表
  @override
  List<WorkEntity> get works;

  /// 作品图片数据列表
  @override
  List<WorkImage> get workImages;

  /// 集字数据列表
  @override
  List<CharacterEntity> get characters;

  /// 导出清单
  @override
  ExportManifest get manifest;

  /// Create a copy of ExportDataModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExportDataModelImplCopyWith<_$ExportDataModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ExportMetadata _$ExportMetadataFromJson(Map<String, dynamic> json) {
  return _ExportMetadata.fromJson(json);
}

/// @nodoc
mixin _$ExportMetadata {
  /// 导出版本
  String get version => throw _privateConstructorUsedError;

  /// 导出时间
  DateTime get exportTime => throw _privateConstructorUsedError;

  /// 导出类型
  ExportType get exportType => throw _privateConstructorUsedError;

  /// 导出选项
  ExportOptions get options => throw _privateConstructorUsedError;

  /// 应用版本
  String get appVersion => throw _privateConstructorUsedError;

  /// 平台信息
  String get platform => throw _privateConstructorUsedError;

  /// 数据格式版本
  String get dataFormatVersion => throw _privateConstructorUsedError;

  /// 兼容性信息
  CompatibilityInfo get compatibility => throw _privateConstructorUsedError;

  /// Serializes this ExportMetadata to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ExportMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExportMetadataCopyWith<ExportMetadata> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExportMetadataCopyWith<$Res> {
  factory $ExportMetadataCopyWith(
          ExportMetadata value, $Res Function(ExportMetadata) then) =
      _$ExportMetadataCopyWithImpl<$Res, ExportMetadata>;
  @useResult
  $Res call(
      {String version,
      DateTime exportTime,
      ExportType exportType,
      ExportOptions options,
      String appVersion,
      String platform,
      String dataFormatVersion,
      CompatibilityInfo compatibility});

  $ExportOptionsCopyWith<$Res> get options;
  $CompatibilityInfoCopyWith<$Res> get compatibility;
}

/// @nodoc
class _$ExportMetadataCopyWithImpl<$Res, $Val extends ExportMetadata>
    implements $ExportMetadataCopyWith<$Res> {
  _$ExportMetadataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExportMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? version = null,
    Object? exportTime = null,
    Object? exportType = null,
    Object? options = null,
    Object? appVersion = null,
    Object? platform = null,
    Object? dataFormatVersion = null,
    Object? compatibility = null,
  }) {
    return _then(_value.copyWith(
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      exportTime: null == exportTime
          ? _value.exportTime
          : exportTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      exportType: null == exportType
          ? _value.exportType
          : exportType // ignore: cast_nullable_to_non_nullable
              as ExportType,
      options: null == options
          ? _value.options
          : options // ignore: cast_nullable_to_non_nullable
              as ExportOptions,
      appVersion: null == appVersion
          ? _value.appVersion
          : appVersion // ignore: cast_nullable_to_non_nullable
              as String,
      platform: null == platform
          ? _value.platform
          : platform // ignore: cast_nullable_to_non_nullable
              as String,
      dataFormatVersion: null == dataFormatVersion
          ? _value.dataFormatVersion
          : dataFormatVersion // ignore: cast_nullable_to_non_nullable
              as String,
      compatibility: null == compatibility
          ? _value.compatibility
          : compatibility // ignore: cast_nullable_to_non_nullable
              as CompatibilityInfo,
    ) as $Val);
  }

  /// Create a copy of ExportMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ExportOptionsCopyWith<$Res> get options {
    return $ExportOptionsCopyWith<$Res>(_value.options, (value) {
      return _then(_value.copyWith(options: value) as $Val);
    });
  }

  /// Create a copy of ExportMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CompatibilityInfoCopyWith<$Res> get compatibility {
    return $CompatibilityInfoCopyWith<$Res>(_value.compatibility, (value) {
      return _then(_value.copyWith(compatibility: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ExportMetadataImplCopyWith<$Res>
    implements $ExportMetadataCopyWith<$Res> {
  factory _$$ExportMetadataImplCopyWith(_$ExportMetadataImpl value,
          $Res Function(_$ExportMetadataImpl) then) =
      __$$ExportMetadataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String version,
      DateTime exportTime,
      ExportType exportType,
      ExportOptions options,
      String appVersion,
      String platform,
      String dataFormatVersion,
      CompatibilityInfo compatibility});

  @override
  $ExportOptionsCopyWith<$Res> get options;
  @override
  $CompatibilityInfoCopyWith<$Res> get compatibility;
}

/// @nodoc
class __$$ExportMetadataImplCopyWithImpl<$Res>
    extends _$ExportMetadataCopyWithImpl<$Res, _$ExportMetadataImpl>
    implements _$$ExportMetadataImplCopyWith<$Res> {
  __$$ExportMetadataImplCopyWithImpl(
      _$ExportMetadataImpl _value, $Res Function(_$ExportMetadataImpl) _then)
      : super(_value, _then);

  /// Create a copy of ExportMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? version = null,
    Object? exportTime = null,
    Object? exportType = null,
    Object? options = null,
    Object? appVersion = null,
    Object? platform = null,
    Object? dataFormatVersion = null,
    Object? compatibility = null,
  }) {
    return _then(_$ExportMetadataImpl(
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      exportTime: null == exportTime
          ? _value.exportTime
          : exportTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      exportType: null == exportType
          ? _value.exportType
          : exportType // ignore: cast_nullable_to_non_nullable
              as ExportType,
      options: null == options
          ? _value.options
          : options // ignore: cast_nullable_to_non_nullable
              as ExportOptions,
      appVersion: null == appVersion
          ? _value.appVersion
          : appVersion // ignore: cast_nullable_to_non_nullable
              as String,
      platform: null == platform
          ? _value.platform
          : platform // ignore: cast_nullable_to_non_nullable
              as String,
      dataFormatVersion: null == dataFormatVersion
          ? _value.dataFormatVersion
          : dataFormatVersion // ignore: cast_nullable_to_non_nullable
              as String,
      compatibility: null == compatibility
          ? _value.compatibility
          : compatibility // ignore: cast_nullable_to_non_nullable
              as CompatibilityInfo,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExportMetadataImpl implements _ExportMetadata {
  const _$ExportMetadataImpl(
      {this.version = '1.0.0',
      required this.exportTime,
      required this.exportType,
      required this.options,
      required this.appVersion,
      required this.platform,
      this.dataFormatVersion = '1.0.0',
      required this.compatibility});

  factory _$ExportMetadataImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExportMetadataImplFromJson(json);

  /// 导出版本
  @override
  @JsonKey()
  final String version;

  /// 导出时间
  @override
  final DateTime exportTime;

  /// 导出类型
  @override
  final ExportType exportType;

  /// 导出选项
  @override
  final ExportOptions options;

  /// 应用版本
  @override
  final String appVersion;

  /// 平台信息
  @override
  final String platform;

  /// 数据格式版本
  @override
  @JsonKey()
  final String dataFormatVersion;

  /// 兼容性信息
  @override
  final CompatibilityInfo compatibility;

  @override
  String toString() {
    return 'ExportMetadata(version: $version, exportTime: $exportTime, exportType: $exportType, options: $options, appVersion: $appVersion, platform: $platform, dataFormatVersion: $dataFormatVersion, compatibility: $compatibility)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExportMetadataImpl &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.exportTime, exportTime) ||
                other.exportTime == exportTime) &&
            (identical(other.exportType, exportType) ||
                other.exportType == exportType) &&
            (identical(other.options, options) || other.options == options) &&
            (identical(other.appVersion, appVersion) ||
                other.appVersion == appVersion) &&
            (identical(other.platform, platform) ||
                other.platform == platform) &&
            (identical(other.dataFormatVersion, dataFormatVersion) ||
                other.dataFormatVersion == dataFormatVersion) &&
            (identical(other.compatibility, compatibility) ||
                other.compatibility == compatibility));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, version, exportTime, exportType,
      options, appVersion, platform, dataFormatVersion, compatibility);

  /// Create a copy of ExportMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExportMetadataImplCopyWith<_$ExportMetadataImpl> get copyWith =>
      __$$ExportMetadataImplCopyWithImpl<_$ExportMetadataImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExportMetadataImplToJson(
      this,
    );
  }
}

abstract class _ExportMetadata implements ExportMetadata {
  const factory _ExportMetadata(
      {final String version,
      required final DateTime exportTime,
      required final ExportType exportType,
      required final ExportOptions options,
      required final String appVersion,
      required final String platform,
      final String dataFormatVersion,
      required final CompatibilityInfo compatibility}) = _$ExportMetadataImpl;

  factory _ExportMetadata.fromJson(Map<String, dynamic> json) =
      _$ExportMetadataImpl.fromJson;

  /// 导出版本
  @override
  String get version;

  /// 导出时间
  @override
  DateTime get exportTime;

  /// 导出类型
  @override
  ExportType get exportType;

  /// 导出选项
  @override
  ExportOptions get options;

  /// 应用版本
  @override
  String get appVersion;

  /// 平台信息
  @override
  String get platform;

  /// 数据格式版本
  @override
  String get dataFormatVersion;

  /// 兼容性信息
  @override
  CompatibilityInfo get compatibility;

  /// Create a copy of ExportMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExportMetadataImplCopyWith<_$ExportMetadataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ExportManifest _$ExportManifestFromJson(Map<String, dynamic> json) {
  return _ExportManifest.fromJson(json);
}

/// @nodoc
mixin _$ExportManifest {
  /// 汇总信息
  ExportSummary get summary => throw _privateConstructorUsedError;

  /// 文件列表
  List<ExportFileInfo> get files => throw _privateConstructorUsedError;

  /// 数据统计
  ExportStatistics get statistics => throw _privateConstructorUsedError;

  /// 验证信息
  List<ExportValidation> get validations => throw _privateConstructorUsedError;

  /// Serializes this ExportManifest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ExportManifest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExportManifestCopyWith<ExportManifest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExportManifestCopyWith<$Res> {
  factory $ExportManifestCopyWith(
          ExportManifest value, $Res Function(ExportManifest) then) =
      _$ExportManifestCopyWithImpl<$Res, ExportManifest>;
  @useResult
  $Res call(
      {ExportSummary summary,
      List<ExportFileInfo> files,
      ExportStatistics statistics,
      List<ExportValidation> validations});

  $ExportSummaryCopyWith<$Res> get summary;
  $ExportStatisticsCopyWith<$Res> get statistics;
}

/// @nodoc
class _$ExportManifestCopyWithImpl<$Res, $Val extends ExportManifest>
    implements $ExportManifestCopyWith<$Res> {
  _$ExportManifestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExportManifest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? summary = null,
    Object? files = null,
    Object? statistics = null,
    Object? validations = null,
  }) {
    return _then(_value.copyWith(
      summary: null == summary
          ? _value.summary
          : summary // ignore: cast_nullable_to_non_nullable
              as ExportSummary,
      files: null == files
          ? _value.files
          : files // ignore: cast_nullable_to_non_nullable
              as List<ExportFileInfo>,
      statistics: null == statistics
          ? _value.statistics
          : statistics // ignore: cast_nullable_to_non_nullable
              as ExportStatistics,
      validations: null == validations
          ? _value.validations
          : validations // ignore: cast_nullable_to_non_nullable
              as List<ExportValidation>,
    ) as $Val);
  }

  /// Create a copy of ExportManifest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ExportSummaryCopyWith<$Res> get summary {
    return $ExportSummaryCopyWith<$Res>(_value.summary, (value) {
      return _then(_value.copyWith(summary: value) as $Val);
    });
  }

  /// Create a copy of ExportManifest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ExportStatisticsCopyWith<$Res> get statistics {
    return $ExportStatisticsCopyWith<$Res>(_value.statistics, (value) {
      return _then(_value.copyWith(statistics: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ExportManifestImplCopyWith<$Res>
    implements $ExportManifestCopyWith<$Res> {
  factory _$$ExportManifestImplCopyWith(_$ExportManifestImpl value,
          $Res Function(_$ExportManifestImpl) then) =
      __$$ExportManifestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {ExportSummary summary,
      List<ExportFileInfo> files,
      ExportStatistics statistics,
      List<ExportValidation> validations});

  @override
  $ExportSummaryCopyWith<$Res> get summary;
  @override
  $ExportStatisticsCopyWith<$Res> get statistics;
}

/// @nodoc
class __$$ExportManifestImplCopyWithImpl<$Res>
    extends _$ExportManifestCopyWithImpl<$Res, _$ExportManifestImpl>
    implements _$$ExportManifestImplCopyWith<$Res> {
  __$$ExportManifestImplCopyWithImpl(
      _$ExportManifestImpl _value, $Res Function(_$ExportManifestImpl) _then)
      : super(_value, _then);

  /// Create a copy of ExportManifest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? summary = null,
    Object? files = null,
    Object? statistics = null,
    Object? validations = null,
  }) {
    return _then(_$ExportManifestImpl(
      summary: null == summary
          ? _value.summary
          : summary // ignore: cast_nullable_to_non_nullable
              as ExportSummary,
      files: null == files
          ? _value._files
          : files // ignore: cast_nullable_to_non_nullable
              as List<ExportFileInfo>,
      statistics: null == statistics
          ? _value.statistics
          : statistics // ignore: cast_nullable_to_non_nullable
              as ExportStatistics,
      validations: null == validations
          ? _value._validations
          : validations // ignore: cast_nullable_to_non_nullable
              as List<ExportValidation>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExportManifestImpl implements _ExportManifest {
  const _$ExportManifestImpl(
      {required this.summary,
      required final List<ExportFileInfo> files,
      required this.statistics,
      required final List<ExportValidation> validations})
      : _files = files,
        _validations = validations;

  factory _$ExportManifestImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExportManifestImplFromJson(json);

  /// 汇总信息
  @override
  final ExportSummary summary;

  /// 文件列表
  final List<ExportFileInfo> _files;

  /// 文件列表
  @override
  List<ExportFileInfo> get files {
    if (_files is EqualUnmodifiableListView) return _files;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_files);
  }

  /// 数据统计
  @override
  final ExportStatistics statistics;

  /// 验证信息
  final List<ExportValidation> _validations;

  /// 验证信息
  @override
  List<ExportValidation> get validations {
    if (_validations is EqualUnmodifiableListView) return _validations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_validations);
  }

  @override
  String toString() {
    return 'ExportManifest(summary: $summary, files: $files, statistics: $statistics, validations: $validations)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExportManifestImpl &&
            (identical(other.summary, summary) || other.summary == summary) &&
            const DeepCollectionEquality().equals(other._files, _files) &&
            (identical(other.statistics, statistics) ||
                other.statistics == statistics) &&
            const DeepCollectionEquality()
                .equals(other._validations, _validations));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      summary,
      const DeepCollectionEquality().hash(_files),
      statistics,
      const DeepCollectionEquality().hash(_validations));

  /// Create a copy of ExportManifest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExportManifestImplCopyWith<_$ExportManifestImpl> get copyWith =>
      __$$ExportManifestImplCopyWithImpl<_$ExportManifestImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExportManifestImplToJson(
      this,
    );
  }
}

abstract class _ExportManifest implements ExportManifest {
  const factory _ExportManifest(
          {required final ExportSummary summary,
          required final List<ExportFileInfo> files,
          required final ExportStatistics statistics,
          required final List<ExportValidation> validations}) =
      _$ExportManifestImpl;

  factory _ExportManifest.fromJson(Map<String, dynamic> json) =
      _$ExportManifestImpl.fromJson;

  /// 汇总信息
  @override
  ExportSummary get summary;

  /// 文件列表
  @override
  List<ExportFileInfo> get files;

  /// 数据统计
  @override
  ExportStatistics get statistics;

  /// 验证信息
  @override
  List<ExportValidation> get validations;

  /// Create a copy of ExportManifest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExportManifestImplCopyWith<_$ExportManifestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ExportSummary _$ExportSummaryFromJson(Map<String, dynamic> json) {
  return _ExportSummary.fromJson(json);
}

/// @nodoc
mixin _$ExportSummary {
  /// 作品总数
  int get workCount => throw _privateConstructorUsedError;

  /// 集字总数
  int get characterCount => throw _privateConstructorUsedError;

  /// 图片文件总数
  int get imageCount => throw _privateConstructorUsedError;

  /// 数据文件总数
  int get dataFileCount => throw _privateConstructorUsedError;

  /// 压缩包大小（字节）
  int get totalSize => throw _privateConstructorUsedError;

  /// 原始数据大小（字节）
  int get originalSize => throw _privateConstructorUsedError;

  /// 压缩率
  double get compressionRatio => throw _privateConstructorUsedError;

  /// Serializes this ExportSummary to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ExportSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExportSummaryCopyWith<ExportSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExportSummaryCopyWith<$Res> {
  factory $ExportSummaryCopyWith(
          ExportSummary value, $Res Function(ExportSummary) then) =
      _$ExportSummaryCopyWithImpl<$Res, ExportSummary>;
  @useResult
  $Res call(
      {int workCount,
      int characterCount,
      int imageCount,
      int dataFileCount,
      int totalSize,
      int originalSize,
      double compressionRatio});
}

/// @nodoc
class _$ExportSummaryCopyWithImpl<$Res, $Val extends ExportSummary>
    implements $ExportSummaryCopyWith<$Res> {
  _$ExportSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExportSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? workCount = null,
    Object? characterCount = null,
    Object? imageCount = null,
    Object? dataFileCount = null,
    Object? totalSize = null,
    Object? originalSize = null,
    Object? compressionRatio = null,
  }) {
    return _then(_value.copyWith(
      workCount: null == workCount
          ? _value.workCount
          : workCount // ignore: cast_nullable_to_non_nullable
              as int,
      characterCount: null == characterCount
          ? _value.characterCount
          : characterCount // ignore: cast_nullable_to_non_nullable
              as int,
      imageCount: null == imageCount
          ? _value.imageCount
          : imageCount // ignore: cast_nullable_to_non_nullable
              as int,
      dataFileCount: null == dataFileCount
          ? _value.dataFileCount
          : dataFileCount // ignore: cast_nullable_to_non_nullable
              as int,
      totalSize: null == totalSize
          ? _value.totalSize
          : totalSize // ignore: cast_nullable_to_non_nullable
              as int,
      originalSize: null == originalSize
          ? _value.originalSize
          : originalSize // ignore: cast_nullable_to_non_nullable
              as int,
      compressionRatio: null == compressionRatio
          ? _value.compressionRatio
          : compressionRatio // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExportSummaryImplCopyWith<$Res>
    implements $ExportSummaryCopyWith<$Res> {
  factory _$$ExportSummaryImplCopyWith(
          _$ExportSummaryImpl value, $Res Function(_$ExportSummaryImpl) then) =
      __$$ExportSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int workCount,
      int characterCount,
      int imageCount,
      int dataFileCount,
      int totalSize,
      int originalSize,
      double compressionRatio});
}

/// @nodoc
class __$$ExportSummaryImplCopyWithImpl<$Res>
    extends _$ExportSummaryCopyWithImpl<$Res, _$ExportSummaryImpl>
    implements _$$ExportSummaryImplCopyWith<$Res> {
  __$$ExportSummaryImplCopyWithImpl(
      _$ExportSummaryImpl _value, $Res Function(_$ExportSummaryImpl) _then)
      : super(_value, _then);

  /// Create a copy of ExportSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? workCount = null,
    Object? characterCount = null,
    Object? imageCount = null,
    Object? dataFileCount = null,
    Object? totalSize = null,
    Object? originalSize = null,
    Object? compressionRatio = null,
  }) {
    return _then(_$ExportSummaryImpl(
      workCount: null == workCount
          ? _value.workCount
          : workCount // ignore: cast_nullable_to_non_nullable
              as int,
      characterCount: null == characterCount
          ? _value.characterCount
          : characterCount // ignore: cast_nullable_to_non_nullable
              as int,
      imageCount: null == imageCount
          ? _value.imageCount
          : imageCount // ignore: cast_nullable_to_non_nullable
              as int,
      dataFileCount: null == dataFileCount
          ? _value.dataFileCount
          : dataFileCount // ignore: cast_nullable_to_non_nullable
              as int,
      totalSize: null == totalSize
          ? _value.totalSize
          : totalSize // ignore: cast_nullable_to_non_nullable
              as int,
      originalSize: null == originalSize
          ? _value.originalSize
          : originalSize // ignore: cast_nullable_to_non_nullable
              as int,
      compressionRatio: null == compressionRatio
          ? _value.compressionRatio
          : compressionRatio // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExportSummaryImpl implements _ExportSummary {
  const _$ExportSummaryImpl(
      {this.workCount = 0,
      this.characterCount = 0,
      this.imageCount = 0,
      this.dataFileCount = 0,
      this.totalSize = 0,
      this.originalSize = 0,
      this.compressionRatio = 0.0});

  factory _$ExportSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExportSummaryImplFromJson(json);

  /// 作品总数
  @override
  @JsonKey()
  final int workCount;

  /// 集字总数
  @override
  @JsonKey()
  final int characterCount;

  /// 图片文件总数
  @override
  @JsonKey()
  final int imageCount;

  /// 数据文件总数
  @override
  @JsonKey()
  final int dataFileCount;

  /// 压缩包大小（字节）
  @override
  @JsonKey()
  final int totalSize;

  /// 原始数据大小（字节）
  @override
  @JsonKey()
  final int originalSize;

  /// 压缩率
  @override
  @JsonKey()
  final double compressionRatio;

  @override
  String toString() {
    return 'ExportSummary(workCount: $workCount, characterCount: $characterCount, imageCount: $imageCount, dataFileCount: $dataFileCount, totalSize: $totalSize, originalSize: $originalSize, compressionRatio: $compressionRatio)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExportSummaryImpl &&
            (identical(other.workCount, workCount) ||
                other.workCount == workCount) &&
            (identical(other.characterCount, characterCount) ||
                other.characterCount == characterCount) &&
            (identical(other.imageCount, imageCount) ||
                other.imageCount == imageCount) &&
            (identical(other.dataFileCount, dataFileCount) ||
                other.dataFileCount == dataFileCount) &&
            (identical(other.totalSize, totalSize) ||
                other.totalSize == totalSize) &&
            (identical(other.originalSize, originalSize) ||
                other.originalSize == originalSize) &&
            (identical(other.compressionRatio, compressionRatio) ||
                other.compressionRatio == compressionRatio));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, workCount, characterCount,
      imageCount, dataFileCount, totalSize, originalSize, compressionRatio);

  /// Create a copy of ExportSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExportSummaryImplCopyWith<_$ExportSummaryImpl> get copyWith =>
      __$$ExportSummaryImplCopyWithImpl<_$ExportSummaryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExportSummaryImplToJson(
      this,
    );
  }
}

abstract class _ExportSummary implements ExportSummary {
  const factory _ExportSummary(
      {final int workCount,
      final int characterCount,
      final int imageCount,
      final int dataFileCount,
      final int totalSize,
      final int originalSize,
      final double compressionRatio}) = _$ExportSummaryImpl;

  factory _ExportSummary.fromJson(Map<String, dynamic> json) =
      _$ExportSummaryImpl.fromJson;

  /// 作品总数
  @override
  int get workCount;

  /// 集字总数
  @override
  int get characterCount;

  /// 图片文件总数
  @override
  int get imageCount;

  /// 数据文件总数
  @override
  int get dataFileCount;

  /// 压缩包大小（字节）
  @override
  int get totalSize;

  /// 原始数据大小（字节）
  @override
  int get originalSize;

  /// 压缩率
  @override
  double get compressionRatio;

  /// Create a copy of ExportSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExportSummaryImplCopyWith<_$ExportSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ExportFileInfo _$ExportFileInfoFromJson(Map<String, dynamic> json) {
  return _ExportFileInfo.fromJson(json);
}

/// @nodoc
mixin _$ExportFileInfo {
  /// 文件名
  String get fileName => throw _privateConstructorUsedError;

  /// 文件路径（在压缩包中）
  String get filePath => throw _privateConstructorUsedError;

  /// 文件类型
  ExportFileType get fileType => throw _privateConstructorUsedError;

  /// 文件大小（字节）
  int get fileSize => throw _privateConstructorUsedError;

  /// 文件校验和
  String get checksum => throw _privateConstructorUsedError;

  /// 校验算法
  String get checksumAlgorithm => throw _privateConstructorUsedError;

  /// 是否必需文件
  bool get isRequired => throw _privateConstructorUsedError;

  /// 文件描述
  String? get description => throw _privateConstructorUsedError;

  /// Serializes this ExportFileInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ExportFileInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExportFileInfoCopyWith<ExportFileInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExportFileInfoCopyWith<$Res> {
  factory $ExportFileInfoCopyWith(
          ExportFileInfo value, $Res Function(ExportFileInfo) then) =
      _$ExportFileInfoCopyWithImpl<$Res, ExportFileInfo>;
  @useResult
  $Res call(
      {String fileName,
      String filePath,
      ExportFileType fileType,
      int fileSize,
      String checksum,
      String checksumAlgorithm,
      bool isRequired,
      String? description});
}

/// @nodoc
class _$ExportFileInfoCopyWithImpl<$Res, $Val extends ExportFileInfo>
    implements $ExportFileInfoCopyWith<$Res> {
  _$ExportFileInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExportFileInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fileName = null,
    Object? filePath = null,
    Object? fileType = null,
    Object? fileSize = null,
    Object? checksum = null,
    Object? checksumAlgorithm = null,
    Object? isRequired = null,
    Object? description = freezed,
  }) {
    return _then(_value.copyWith(
      fileName: null == fileName
          ? _value.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String,
      filePath: null == filePath
          ? _value.filePath
          : filePath // ignore: cast_nullable_to_non_nullable
              as String,
      fileType: null == fileType
          ? _value.fileType
          : fileType // ignore: cast_nullable_to_non_nullable
              as ExportFileType,
      fileSize: null == fileSize
          ? _value.fileSize
          : fileSize // ignore: cast_nullable_to_non_nullable
              as int,
      checksum: null == checksum
          ? _value.checksum
          : checksum // ignore: cast_nullable_to_non_nullable
              as String,
      checksumAlgorithm: null == checksumAlgorithm
          ? _value.checksumAlgorithm
          : checksumAlgorithm // ignore: cast_nullable_to_non_nullable
              as String,
      isRequired: null == isRequired
          ? _value.isRequired
          : isRequired // ignore: cast_nullable_to_non_nullable
              as bool,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExportFileInfoImplCopyWith<$Res>
    implements $ExportFileInfoCopyWith<$Res> {
  factory _$$ExportFileInfoImplCopyWith(_$ExportFileInfoImpl value,
          $Res Function(_$ExportFileInfoImpl) then) =
      __$$ExportFileInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String fileName,
      String filePath,
      ExportFileType fileType,
      int fileSize,
      String checksum,
      String checksumAlgorithm,
      bool isRequired,
      String? description});
}

/// @nodoc
class __$$ExportFileInfoImplCopyWithImpl<$Res>
    extends _$ExportFileInfoCopyWithImpl<$Res, _$ExportFileInfoImpl>
    implements _$$ExportFileInfoImplCopyWith<$Res> {
  __$$ExportFileInfoImplCopyWithImpl(
      _$ExportFileInfoImpl _value, $Res Function(_$ExportFileInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of ExportFileInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fileName = null,
    Object? filePath = null,
    Object? fileType = null,
    Object? fileSize = null,
    Object? checksum = null,
    Object? checksumAlgorithm = null,
    Object? isRequired = null,
    Object? description = freezed,
  }) {
    return _then(_$ExportFileInfoImpl(
      fileName: null == fileName
          ? _value.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String,
      filePath: null == filePath
          ? _value.filePath
          : filePath // ignore: cast_nullable_to_non_nullable
              as String,
      fileType: null == fileType
          ? _value.fileType
          : fileType // ignore: cast_nullable_to_non_nullable
              as ExportFileType,
      fileSize: null == fileSize
          ? _value.fileSize
          : fileSize // ignore: cast_nullable_to_non_nullable
              as int,
      checksum: null == checksum
          ? _value.checksum
          : checksum // ignore: cast_nullable_to_non_nullable
              as String,
      checksumAlgorithm: null == checksumAlgorithm
          ? _value.checksumAlgorithm
          : checksumAlgorithm // ignore: cast_nullable_to_non_nullable
              as String,
      isRequired: null == isRequired
          ? _value.isRequired
          : isRequired // ignore: cast_nullable_to_non_nullable
              as bool,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExportFileInfoImpl implements _ExportFileInfo {
  const _$ExportFileInfoImpl(
      {required this.fileName,
      required this.filePath,
      required this.fileType,
      required this.fileSize,
      required this.checksum,
      this.checksumAlgorithm = 'MD5',
      this.isRequired = true,
      this.description});

  factory _$ExportFileInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExportFileInfoImplFromJson(json);

  /// 文件名
  @override
  final String fileName;

  /// 文件路径（在压缩包中）
  @override
  final String filePath;

  /// 文件类型
  @override
  final ExportFileType fileType;

  /// 文件大小（字节）
  @override
  final int fileSize;

  /// 文件校验和
  @override
  final String checksum;

  /// 校验算法
  @override
  @JsonKey()
  final String checksumAlgorithm;

  /// 是否必需文件
  @override
  @JsonKey()
  final bool isRequired;

  /// 文件描述
  @override
  final String? description;

  @override
  String toString() {
    return 'ExportFileInfo(fileName: $fileName, filePath: $filePath, fileType: $fileType, fileSize: $fileSize, checksum: $checksum, checksumAlgorithm: $checksumAlgorithm, isRequired: $isRequired, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExportFileInfoImpl &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName) &&
            (identical(other.filePath, filePath) ||
                other.filePath == filePath) &&
            (identical(other.fileType, fileType) ||
                other.fileType == fileType) &&
            (identical(other.fileSize, fileSize) ||
                other.fileSize == fileSize) &&
            (identical(other.checksum, checksum) ||
                other.checksum == checksum) &&
            (identical(other.checksumAlgorithm, checksumAlgorithm) ||
                other.checksumAlgorithm == checksumAlgorithm) &&
            (identical(other.isRequired, isRequired) ||
                other.isRequired == isRequired) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, fileName, filePath, fileType,
      fileSize, checksum, checksumAlgorithm, isRequired, description);

  /// Create a copy of ExportFileInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExportFileInfoImplCopyWith<_$ExportFileInfoImpl> get copyWith =>
      __$$ExportFileInfoImplCopyWithImpl<_$ExportFileInfoImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExportFileInfoImplToJson(
      this,
    );
  }
}

abstract class _ExportFileInfo implements ExportFileInfo {
  const factory _ExportFileInfo(
      {required final String fileName,
      required final String filePath,
      required final ExportFileType fileType,
      required final int fileSize,
      required final String checksum,
      final String checksumAlgorithm,
      final bool isRequired,
      final String? description}) = _$ExportFileInfoImpl;

  factory _ExportFileInfo.fromJson(Map<String, dynamic> json) =
      _$ExportFileInfoImpl.fromJson;

  /// 文件名
  @override
  String get fileName;

  /// 文件路径（在压缩包中）
  @override
  String get filePath;

  /// 文件类型
  @override
  ExportFileType get fileType;

  /// 文件大小（字节）
  @override
  int get fileSize;

  /// 文件校验和
  @override
  String get checksum;

  /// 校验算法
  @override
  String get checksumAlgorithm;

  /// 是否必需文件
  @override
  bool get isRequired;

  /// 文件描述
  @override
  String? get description;

  /// Create a copy of ExportFileInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExportFileInfoImplCopyWith<_$ExportFileInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ExportStatistics _$ExportStatisticsFromJson(Map<String, dynamic> json) {
  return _ExportStatistics.fromJson(json);
}

/// @nodoc
mixin _$ExportStatistics {
  /// 按风格分组的作品数量
  Map<String, int> get worksByStyle => throw _privateConstructorUsedError;

  /// 按工具分组的作品数量
  Map<String, int> get worksByTool => throw _privateConstructorUsedError;

  /// 按日期分组的作品数量
  Map<String, int> get worksByDate => throw _privateConstructorUsedError;

  /// 按字符分组的集字数量
  Map<String, int> get charactersByChar => throw _privateConstructorUsedError;

  /// 文件格式统计
  Map<String, int> get filesByFormat => throw _privateConstructorUsedError;

  /// 自定义配置统计
  CustomConfigStatistics get customConfigs =>
      throw _privateConstructorUsedError;

  /// Serializes this ExportStatistics to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ExportStatistics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExportStatisticsCopyWith<ExportStatistics> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExportStatisticsCopyWith<$Res> {
  factory $ExportStatisticsCopyWith(
          ExportStatistics value, $Res Function(ExportStatistics) then) =
      _$ExportStatisticsCopyWithImpl<$Res, ExportStatistics>;
  @useResult
  $Res call(
      {Map<String, int> worksByStyle,
      Map<String, int> worksByTool,
      Map<String, int> worksByDate,
      Map<String, int> charactersByChar,
      Map<String, int> filesByFormat,
      CustomConfigStatistics customConfigs});

  $CustomConfigStatisticsCopyWith<$Res> get customConfigs;
}

/// @nodoc
class _$ExportStatisticsCopyWithImpl<$Res, $Val extends ExportStatistics>
    implements $ExportStatisticsCopyWith<$Res> {
  _$ExportStatisticsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExportStatistics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? worksByStyle = null,
    Object? worksByTool = null,
    Object? worksByDate = null,
    Object? charactersByChar = null,
    Object? filesByFormat = null,
    Object? customConfigs = null,
  }) {
    return _then(_value.copyWith(
      worksByStyle: null == worksByStyle
          ? _value.worksByStyle
          : worksByStyle // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      worksByTool: null == worksByTool
          ? _value.worksByTool
          : worksByTool // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      worksByDate: null == worksByDate
          ? _value.worksByDate
          : worksByDate // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      charactersByChar: null == charactersByChar
          ? _value.charactersByChar
          : charactersByChar // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      filesByFormat: null == filesByFormat
          ? _value.filesByFormat
          : filesByFormat // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      customConfigs: null == customConfigs
          ? _value.customConfigs
          : customConfigs // ignore: cast_nullable_to_non_nullable
              as CustomConfigStatistics,
    ) as $Val);
  }

  /// Create a copy of ExportStatistics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CustomConfigStatisticsCopyWith<$Res> get customConfigs {
    return $CustomConfigStatisticsCopyWith<$Res>(_value.customConfigs, (value) {
      return _then(_value.copyWith(customConfigs: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ExportStatisticsImplCopyWith<$Res>
    implements $ExportStatisticsCopyWith<$Res> {
  factory _$$ExportStatisticsImplCopyWith(_$ExportStatisticsImpl value,
          $Res Function(_$ExportStatisticsImpl) then) =
      __$$ExportStatisticsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {Map<String, int> worksByStyle,
      Map<String, int> worksByTool,
      Map<String, int> worksByDate,
      Map<String, int> charactersByChar,
      Map<String, int> filesByFormat,
      CustomConfigStatistics customConfigs});

  @override
  $CustomConfigStatisticsCopyWith<$Res> get customConfigs;
}

/// @nodoc
class __$$ExportStatisticsImplCopyWithImpl<$Res>
    extends _$ExportStatisticsCopyWithImpl<$Res, _$ExportStatisticsImpl>
    implements _$$ExportStatisticsImplCopyWith<$Res> {
  __$$ExportStatisticsImplCopyWithImpl(_$ExportStatisticsImpl _value,
      $Res Function(_$ExportStatisticsImpl) _then)
      : super(_value, _then);

  /// Create a copy of ExportStatistics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? worksByStyle = null,
    Object? worksByTool = null,
    Object? worksByDate = null,
    Object? charactersByChar = null,
    Object? filesByFormat = null,
    Object? customConfigs = null,
  }) {
    return _then(_$ExportStatisticsImpl(
      worksByStyle: null == worksByStyle
          ? _value._worksByStyle
          : worksByStyle // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      worksByTool: null == worksByTool
          ? _value._worksByTool
          : worksByTool // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      worksByDate: null == worksByDate
          ? _value._worksByDate
          : worksByDate // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      charactersByChar: null == charactersByChar
          ? _value._charactersByChar
          : charactersByChar // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      filesByFormat: null == filesByFormat
          ? _value._filesByFormat
          : filesByFormat // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      customConfigs: null == customConfigs
          ? _value.customConfigs
          : customConfigs // ignore: cast_nullable_to_non_nullable
              as CustomConfigStatistics,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExportStatisticsImpl implements _ExportStatistics {
  const _$ExportStatisticsImpl(
      {final Map<String, int> worksByStyle = const {},
      final Map<String, int> worksByTool = const {},
      final Map<String, int> worksByDate = const {},
      final Map<String, int> charactersByChar = const {},
      final Map<String, int> filesByFormat = const {},
      required this.customConfigs})
      : _worksByStyle = worksByStyle,
        _worksByTool = worksByTool,
        _worksByDate = worksByDate,
        _charactersByChar = charactersByChar,
        _filesByFormat = filesByFormat;

  factory _$ExportStatisticsImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExportStatisticsImplFromJson(json);

  /// 按风格分组的作品数量
  final Map<String, int> _worksByStyle;

  /// 按风格分组的作品数量
  @override
  @JsonKey()
  Map<String, int> get worksByStyle {
    if (_worksByStyle is EqualUnmodifiableMapView) return _worksByStyle;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_worksByStyle);
  }

  /// 按工具分组的作品数量
  final Map<String, int> _worksByTool;

  /// 按工具分组的作品数量
  @override
  @JsonKey()
  Map<String, int> get worksByTool {
    if (_worksByTool is EqualUnmodifiableMapView) return _worksByTool;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_worksByTool);
  }

  /// 按日期分组的作品数量
  final Map<String, int> _worksByDate;

  /// 按日期分组的作品数量
  @override
  @JsonKey()
  Map<String, int> get worksByDate {
    if (_worksByDate is EqualUnmodifiableMapView) return _worksByDate;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_worksByDate);
  }

  /// 按字符分组的集字数量
  final Map<String, int> _charactersByChar;

  /// 按字符分组的集字数量
  @override
  @JsonKey()
  Map<String, int> get charactersByChar {
    if (_charactersByChar is EqualUnmodifiableMapView) return _charactersByChar;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_charactersByChar);
  }

  /// 文件格式统计
  final Map<String, int> _filesByFormat;

  /// 文件格式统计
  @override
  @JsonKey()
  Map<String, int> get filesByFormat {
    if (_filesByFormat is EqualUnmodifiableMapView) return _filesByFormat;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_filesByFormat);
  }

  /// 自定义配置统计
  @override
  final CustomConfigStatistics customConfigs;

  @override
  String toString() {
    return 'ExportStatistics(worksByStyle: $worksByStyle, worksByTool: $worksByTool, worksByDate: $worksByDate, charactersByChar: $charactersByChar, filesByFormat: $filesByFormat, customConfigs: $customConfigs)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExportStatisticsImpl &&
            const DeepCollectionEquality()
                .equals(other._worksByStyle, _worksByStyle) &&
            const DeepCollectionEquality()
                .equals(other._worksByTool, _worksByTool) &&
            const DeepCollectionEquality()
                .equals(other._worksByDate, _worksByDate) &&
            const DeepCollectionEquality()
                .equals(other._charactersByChar, _charactersByChar) &&
            const DeepCollectionEquality()
                .equals(other._filesByFormat, _filesByFormat) &&
            (identical(other.customConfigs, customConfigs) ||
                other.customConfigs == customConfigs));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_worksByStyle),
      const DeepCollectionEquality().hash(_worksByTool),
      const DeepCollectionEquality().hash(_worksByDate),
      const DeepCollectionEquality().hash(_charactersByChar),
      const DeepCollectionEquality().hash(_filesByFormat),
      customConfigs);

  /// Create a copy of ExportStatistics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExportStatisticsImplCopyWith<_$ExportStatisticsImpl> get copyWith =>
      __$$ExportStatisticsImplCopyWithImpl<_$ExportStatisticsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExportStatisticsImplToJson(
      this,
    );
  }
}

abstract class _ExportStatistics implements ExportStatistics {
  const factory _ExportStatistics(
          {final Map<String, int> worksByStyle,
          final Map<String, int> worksByTool,
          final Map<String, int> worksByDate,
          final Map<String, int> charactersByChar,
          final Map<String, int> filesByFormat,
          required final CustomConfigStatistics customConfigs}) =
      _$ExportStatisticsImpl;

  factory _ExportStatistics.fromJson(Map<String, dynamic> json) =
      _$ExportStatisticsImpl.fromJson;

  /// 按风格分组的作品数量
  @override
  Map<String, int> get worksByStyle;

  /// 按工具分组的作品数量
  @override
  Map<String, int> get worksByTool;

  /// 按日期分组的作品数量
  @override
  Map<String, int> get worksByDate;

  /// 按字符分组的集字数量
  @override
  Map<String, int> get charactersByChar;

  /// 文件格式统计
  @override
  Map<String, int> get filesByFormat;

  /// 自定义配置统计
  @override
  CustomConfigStatistics get customConfigs;

  /// Create a copy of ExportStatistics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExportStatisticsImplCopyWith<_$ExportStatisticsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CustomConfigStatistics _$CustomConfigStatisticsFromJson(
    Map<String, dynamic> json) {
  return _CustomConfigStatistics.fromJson(json);
}

/// @nodoc
mixin _$CustomConfigStatistics {
  /// 自定义书法风格列表
  List<String> get customStyles => throw _privateConstructorUsedError;

  /// 自定义书写工具列表
  List<String> get customTools => throw _privateConstructorUsedError;

  /// 自定义风格使用次数
  Map<String, int> get customStyleUsage => throw _privateConstructorUsedError;

  /// 自定义工具使用次数
  Map<String, int> get customToolUsage => throw _privateConstructorUsedError;

  /// Serializes this CustomConfigStatistics to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CustomConfigStatistics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CustomConfigStatisticsCopyWith<CustomConfigStatistics> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CustomConfigStatisticsCopyWith<$Res> {
  factory $CustomConfigStatisticsCopyWith(CustomConfigStatistics value,
          $Res Function(CustomConfigStatistics) then) =
      _$CustomConfigStatisticsCopyWithImpl<$Res, CustomConfigStatistics>;
  @useResult
  $Res call(
      {List<String> customStyles,
      List<String> customTools,
      Map<String, int> customStyleUsage,
      Map<String, int> customToolUsage});
}

/// @nodoc
class _$CustomConfigStatisticsCopyWithImpl<$Res,
        $Val extends CustomConfigStatistics>
    implements $CustomConfigStatisticsCopyWith<$Res> {
  _$CustomConfigStatisticsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CustomConfigStatistics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? customStyles = null,
    Object? customTools = null,
    Object? customStyleUsage = null,
    Object? customToolUsage = null,
  }) {
    return _then(_value.copyWith(
      customStyles: null == customStyles
          ? _value.customStyles
          : customStyles // ignore: cast_nullable_to_non_nullable
              as List<String>,
      customTools: null == customTools
          ? _value.customTools
          : customTools // ignore: cast_nullable_to_non_nullable
              as List<String>,
      customStyleUsage: null == customStyleUsage
          ? _value.customStyleUsage
          : customStyleUsage // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      customToolUsage: null == customToolUsage
          ? _value.customToolUsage
          : customToolUsage // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CustomConfigStatisticsImplCopyWith<$Res>
    implements $CustomConfigStatisticsCopyWith<$Res> {
  factory _$$CustomConfigStatisticsImplCopyWith(
          _$CustomConfigStatisticsImpl value,
          $Res Function(_$CustomConfigStatisticsImpl) then) =
      __$$CustomConfigStatisticsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<String> customStyles,
      List<String> customTools,
      Map<String, int> customStyleUsage,
      Map<String, int> customToolUsage});
}

/// @nodoc
class __$$CustomConfigStatisticsImplCopyWithImpl<$Res>
    extends _$CustomConfigStatisticsCopyWithImpl<$Res,
        _$CustomConfigStatisticsImpl>
    implements _$$CustomConfigStatisticsImplCopyWith<$Res> {
  __$$CustomConfigStatisticsImplCopyWithImpl(
      _$CustomConfigStatisticsImpl _value,
      $Res Function(_$CustomConfigStatisticsImpl) _then)
      : super(_value, _then);

  /// Create a copy of CustomConfigStatistics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? customStyles = null,
    Object? customTools = null,
    Object? customStyleUsage = null,
    Object? customToolUsage = null,
  }) {
    return _then(_$CustomConfigStatisticsImpl(
      customStyles: null == customStyles
          ? _value._customStyles
          : customStyles // ignore: cast_nullable_to_non_nullable
              as List<String>,
      customTools: null == customTools
          ? _value._customTools
          : customTools // ignore: cast_nullable_to_non_nullable
              as List<String>,
      customStyleUsage: null == customStyleUsage
          ? _value._customStyleUsage
          : customStyleUsage // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      customToolUsage: null == customToolUsage
          ? _value._customToolUsage
          : customToolUsage // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CustomConfigStatisticsImpl implements _CustomConfigStatistics {
  const _$CustomConfigStatisticsImpl(
      {final List<String> customStyles = const [],
      final List<String> customTools = const [],
      final Map<String, int> customStyleUsage = const {},
      final Map<String, int> customToolUsage = const {}})
      : _customStyles = customStyles,
        _customTools = customTools,
        _customStyleUsage = customStyleUsage,
        _customToolUsage = customToolUsage;

  factory _$CustomConfigStatisticsImpl.fromJson(Map<String, dynamic> json) =>
      _$$CustomConfigStatisticsImplFromJson(json);

  /// 自定义书法风格列表
  final List<String> _customStyles;

  /// 自定义书法风格列表
  @override
  @JsonKey()
  List<String> get customStyles {
    if (_customStyles is EqualUnmodifiableListView) return _customStyles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_customStyles);
  }

  /// 自定义书写工具列表
  final List<String> _customTools;

  /// 自定义书写工具列表
  @override
  @JsonKey()
  List<String> get customTools {
    if (_customTools is EqualUnmodifiableListView) return _customTools;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_customTools);
  }

  /// 自定义风格使用次数
  final Map<String, int> _customStyleUsage;

  /// 自定义风格使用次数
  @override
  @JsonKey()
  Map<String, int> get customStyleUsage {
    if (_customStyleUsage is EqualUnmodifiableMapView) return _customStyleUsage;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_customStyleUsage);
  }

  /// 自定义工具使用次数
  final Map<String, int> _customToolUsage;

  /// 自定义工具使用次数
  @override
  @JsonKey()
  Map<String, int> get customToolUsage {
    if (_customToolUsage is EqualUnmodifiableMapView) return _customToolUsage;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_customToolUsage);
  }

  @override
  String toString() {
    return 'CustomConfigStatistics(customStyles: $customStyles, customTools: $customTools, customStyleUsage: $customStyleUsage, customToolUsage: $customToolUsage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CustomConfigStatisticsImpl &&
            const DeepCollectionEquality()
                .equals(other._customStyles, _customStyles) &&
            const DeepCollectionEquality()
                .equals(other._customTools, _customTools) &&
            const DeepCollectionEquality()
                .equals(other._customStyleUsage, _customStyleUsage) &&
            const DeepCollectionEquality()
                .equals(other._customToolUsage, _customToolUsage));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_customStyles),
      const DeepCollectionEquality().hash(_customTools),
      const DeepCollectionEquality().hash(_customStyleUsage),
      const DeepCollectionEquality().hash(_customToolUsage));

  /// Create a copy of CustomConfigStatistics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CustomConfigStatisticsImplCopyWith<_$CustomConfigStatisticsImpl>
      get copyWith => __$$CustomConfigStatisticsImplCopyWithImpl<
          _$CustomConfigStatisticsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CustomConfigStatisticsImplToJson(
      this,
    );
  }
}

abstract class _CustomConfigStatistics implements CustomConfigStatistics {
  const factory _CustomConfigStatistics(
      {final List<String> customStyles,
      final List<String> customTools,
      final Map<String, int> customStyleUsage,
      final Map<String, int> customToolUsage}) = _$CustomConfigStatisticsImpl;

  factory _CustomConfigStatistics.fromJson(Map<String, dynamic> json) =
      _$CustomConfigStatisticsImpl.fromJson;

  /// 自定义书法风格列表
  @override
  List<String> get customStyles;

  /// 自定义书写工具列表
  @override
  List<String> get customTools;

  /// 自定义风格使用次数
  @override
  Map<String, int> get customStyleUsage;

  /// 自定义工具使用次数
  @override
  Map<String, int> get customToolUsage;

  /// Create a copy of CustomConfigStatistics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CustomConfigStatisticsImplCopyWith<_$CustomConfigStatisticsImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ExportValidation _$ExportValidationFromJson(Map<String, dynamic> json) {
  return _ExportValidation.fromJson(json);
}

/// @nodoc
mixin _$ExportValidation {
  /// 验证类型
  ExportValidationType get type => throw _privateConstructorUsedError;

  /// 验证状态
  ValidationStatus get status => throw _privateConstructorUsedError;

  /// 验证消息
  String get message => throw _privateConstructorUsedError;

  /// 验证详情
  Map<String, dynamic>? get details => throw _privateConstructorUsedError;

  /// 验证时间
  DateTime get timestamp => throw _privateConstructorUsedError;

  /// Serializes this ExportValidation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ExportValidation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExportValidationCopyWith<ExportValidation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExportValidationCopyWith<$Res> {
  factory $ExportValidationCopyWith(
          ExportValidation value, $Res Function(ExportValidation) then) =
      _$ExportValidationCopyWithImpl<$Res, ExportValidation>;
  @useResult
  $Res call(
      {ExportValidationType type,
      ValidationStatus status,
      String message,
      Map<String, dynamic>? details,
      DateTime timestamp});
}

/// @nodoc
class _$ExportValidationCopyWithImpl<$Res, $Val extends ExportValidation>
    implements $ExportValidationCopyWith<$Res> {
  _$ExportValidationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExportValidation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? status = null,
    Object? message = null,
    Object? details = freezed,
    Object? timestamp = null,
  }) {
    return _then(_value.copyWith(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as ExportValidationType,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as ValidationStatus,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      details: freezed == details
          ? _value.details
          : details // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExportValidationImplCopyWith<$Res>
    implements $ExportValidationCopyWith<$Res> {
  factory _$$ExportValidationImplCopyWith(_$ExportValidationImpl value,
          $Res Function(_$ExportValidationImpl) then) =
      __$$ExportValidationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {ExportValidationType type,
      ValidationStatus status,
      String message,
      Map<String, dynamic>? details,
      DateTime timestamp});
}

/// @nodoc
class __$$ExportValidationImplCopyWithImpl<$Res>
    extends _$ExportValidationCopyWithImpl<$Res, _$ExportValidationImpl>
    implements _$$ExportValidationImplCopyWith<$Res> {
  __$$ExportValidationImplCopyWithImpl(_$ExportValidationImpl _value,
      $Res Function(_$ExportValidationImpl) _then)
      : super(_value, _then);

  /// Create a copy of ExportValidation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? status = null,
    Object? message = null,
    Object? details = freezed,
    Object? timestamp = null,
  }) {
    return _then(_$ExportValidationImpl(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as ExportValidationType,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as ValidationStatus,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      details: freezed == details
          ? _value._details
          : details // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExportValidationImpl implements _ExportValidation {
  const _$ExportValidationImpl(
      {required this.type,
      required this.status,
      required this.message,
      final Map<String, dynamic>? details,
      required this.timestamp})
      : _details = details;

  factory _$ExportValidationImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExportValidationImplFromJson(json);

  /// 验证类型
  @override
  final ExportValidationType type;

  /// 验证状态
  @override
  final ValidationStatus status;

  /// 验证消息
  @override
  final String message;

  /// 验证详情
  final Map<String, dynamic>? _details;

  /// 验证详情
  @override
  Map<String, dynamic>? get details {
    final value = _details;
    if (value == null) return null;
    if (_details is EqualUnmodifiableMapView) return _details;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  /// 验证时间
  @override
  final DateTime timestamp;

  @override
  String toString() {
    return 'ExportValidation(type: $type, status: $status, message: $message, details: $details, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExportValidationImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.message, message) || other.message == message) &&
            const DeepCollectionEquality().equals(other._details, _details) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, type, status, message,
      const DeepCollectionEquality().hash(_details), timestamp);

  /// Create a copy of ExportValidation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExportValidationImplCopyWith<_$ExportValidationImpl> get copyWith =>
      __$$ExportValidationImplCopyWithImpl<_$ExportValidationImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExportValidationImplToJson(
      this,
    );
  }
}

abstract class _ExportValidation implements ExportValidation {
  const factory _ExportValidation(
      {required final ExportValidationType type,
      required final ValidationStatus status,
      required final String message,
      final Map<String, dynamic>? details,
      required final DateTime timestamp}) = _$ExportValidationImpl;

  factory _ExportValidation.fromJson(Map<String, dynamic> json) =
      _$ExportValidationImpl.fromJson;

  /// 验证类型
  @override
  ExportValidationType get type;

  /// 验证状态
  @override
  ValidationStatus get status;

  /// 验证消息
  @override
  String get message;

  /// 验证详情
  @override
  Map<String, dynamic>? get details;

  /// 验证时间
  @override
  DateTime get timestamp;

  /// Create a copy of ExportValidation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExportValidationImplCopyWith<_$ExportValidationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CompatibilityInfo _$CompatibilityInfoFromJson(Map<String, dynamic> json) {
  return _CompatibilityInfo.fromJson(json);
}

/// @nodoc
mixin _$CompatibilityInfo {
  /// 最低支持版本
  String get minSupportedVersion => throw _privateConstructorUsedError;

  /// 推荐版本
  String get recommendedVersion => throw _privateConstructorUsedError;

  /// 兼容性标记
  List<String> get compatibilityFlags => throw _privateConstructorUsedError;

  /// 向下兼容性
  bool get backwardCompatible => throw _privateConstructorUsedError;

  /// 向前兼容性
  bool get forwardCompatible => throw _privateConstructorUsedError;

  /// Serializes this CompatibilityInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CompatibilityInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CompatibilityInfoCopyWith<CompatibilityInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CompatibilityInfoCopyWith<$Res> {
  factory $CompatibilityInfoCopyWith(
          CompatibilityInfo value, $Res Function(CompatibilityInfo) then) =
      _$CompatibilityInfoCopyWithImpl<$Res, CompatibilityInfo>;
  @useResult
  $Res call(
      {String minSupportedVersion,
      String recommendedVersion,
      List<String> compatibilityFlags,
      bool backwardCompatible,
      bool forwardCompatible});
}

/// @nodoc
class _$CompatibilityInfoCopyWithImpl<$Res, $Val extends CompatibilityInfo>
    implements $CompatibilityInfoCopyWith<$Res> {
  _$CompatibilityInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CompatibilityInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? minSupportedVersion = null,
    Object? recommendedVersion = null,
    Object? compatibilityFlags = null,
    Object? backwardCompatible = null,
    Object? forwardCompatible = null,
  }) {
    return _then(_value.copyWith(
      minSupportedVersion: null == minSupportedVersion
          ? _value.minSupportedVersion
          : minSupportedVersion // ignore: cast_nullable_to_non_nullable
              as String,
      recommendedVersion: null == recommendedVersion
          ? _value.recommendedVersion
          : recommendedVersion // ignore: cast_nullable_to_non_nullable
              as String,
      compatibilityFlags: null == compatibilityFlags
          ? _value.compatibilityFlags
          : compatibilityFlags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      backwardCompatible: null == backwardCompatible
          ? _value.backwardCompatible
          : backwardCompatible // ignore: cast_nullable_to_non_nullable
              as bool,
      forwardCompatible: null == forwardCompatible
          ? _value.forwardCompatible
          : forwardCompatible // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CompatibilityInfoImplCopyWith<$Res>
    implements $CompatibilityInfoCopyWith<$Res> {
  factory _$$CompatibilityInfoImplCopyWith(_$CompatibilityInfoImpl value,
          $Res Function(_$CompatibilityInfoImpl) then) =
      __$$CompatibilityInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String minSupportedVersion,
      String recommendedVersion,
      List<String> compatibilityFlags,
      bool backwardCompatible,
      bool forwardCompatible});
}

/// @nodoc
class __$$CompatibilityInfoImplCopyWithImpl<$Res>
    extends _$CompatibilityInfoCopyWithImpl<$Res, _$CompatibilityInfoImpl>
    implements _$$CompatibilityInfoImplCopyWith<$Res> {
  __$$CompatibilityInfoImplCopyWithImpl(_$CompatibilityInfoImpl _value,
      $Res Function(_$CompatibilityInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of CompatibilityInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? minSupportedVersion = null,
    Object? recommendedVersion = null,
    Object? compatibilityFlags = null,
    Object? backwardCompatible = null,
    Object? forwardCompatible = null,
  }) {
    return _then(_$CompatibilityInfoImpl(
      minSupportedVersion: null == minSupportedVersion
          ? _value.minSupportedVersion
          : minSupportedVersion // ignore: cast_nullable_to_non_nullable
              as String,
      recommendedVersion: null == recommendedVersion
          ? _value.recommendedVersion
          : recommendedVersion // ignore: cast_nullable_to_non_nullable
              as String,
      compatibilityFlags: null == compatibilityFlags
          ? _value._compatibilityFlags
          : compatibilityFlags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      backwardCompatible: null == backwardCompatible
          ? _value.backwardCompatible
          : backwardCompatible // ignore: cast_nullable_to_non_nullable
              as bool,
      forwardCompatible: null == forwardCompatible
          ? _value.forwardCompatible
          : forwardCompatible // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CompatibilityInfoImpl implements _CompatibilityInfo {
  const _$CompatibilityInfoImpl(
      {required this.minSupportedVersion,
      required this.recommendedVersion,
      final List<String> compatibilityFlags = const [],
      this.backwardCompatible = true,
      this.forwardCompatible = false})
      : _compatibilityFlags = compatibilityFlags;

  factory _$CompatibilityInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$CompatibilityInfoImplFromJson(json);

  /// 最低支持版本
  @override
  final String minSupportedVersion;

  /// 推荐版本
  @override
  final String recommendedVersion;

  /// 兼容性标记
  final List<String> _compatibilityFlags;

  /// 兼容性标记
  @override
  @JsonKey()
  List<String> get compatibilityFlags {
    if (_compatibilityFlags is EqualUnmodifiableListView)
      return _compatibilityFlags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_compatibilityFlags);
  }

  /// 向下兼容性
  @override
  @JsonKey()
  final bool backwardCompatible;

  /// 向前兼容性
  @override
  @JsonKey()
  final bool forwardCompatible;

  @override
  String toString() {
    return 'CompatibilityInfo(minSupportedVersion: $minSupportedVersion, recommendedVersion: $recommendedVersion, compatibilityFlags: $compatibilityFlags, backwardCompatible: $backwardCompatible, forwardCompatible: $forwardCompatible)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompatibilityInfoImpl &&
            (identical(other.minSupportedVersion, minSupportedVersion) ||
                other.minSupportedVersion == minSupportedVersion) &&
            (identical(other.recommendedVersion, recommendedVersion) ||
                other.recommendedVersion == recommendedVersion) &&
            const DeepCollectionEquality()
                .equals(other._compatibilityFlags, _compatibilityFlags) &&
            (identical(other.backwardCompatible, backwardCompatible) ||
                other.backwardCompatible == backwardCompatible) &&
            (identical(other.forwardCompatible, forwardCompatible) ||
                other.forwardCompatible == forwardCompatible));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      minSupportedVersion,
      recommendedVersion,
      const DeepCollectionEquality().hash(_compatibilityFlags),
      backwardCompatible,
      forwardCompatible);

  /// Create a copy of CompatibilityInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CompatibilityInfoImplCopyWith<_$CompatibilityInfoImpl> get copyWith =>
      __$$CompatibilityInfoImplCopyWithImpl<_$CompatibilityInfoImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CompatibilityInfoImplToJson(
      this,
    );
  }
}

abstract class _CompatibilityInfo implements CompatibilityInfo {
  const factory _CompatibilityInfo(
      {required final String minSupportedVersion,
      required final String recommendedVersion,
      final List<String> compatibilityFlags,
      final bool backwardCompatible,
      final bool forwardCompatible}) = _$CompatibilityInfoImpl;

  factory _CompatibilityInfo.fromJson(Map<String, dynamic> json) =
      _$CompatibilityInfoImpl.fromJson;

  /// 最低支持版本
  @override
  String get minSupportedVersion;

  /// 推荐版本
  @override
  String get recommendedVersion;

  /// 兼容性标记
  @override
  List<String> get compatibilityFlags;

  /// 向下兼容性
  @override
  bool get backwardCompatible;

  /// 向前兼容性
  @override
  bool get forwardCompatible;

  /// Create a copy of CompatibilityInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CompatibilityInfoImplCopyWith<_$CompatibilityInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ExportOptions _$ExportOptionsFromJson(Map<String, dynamic> json) {
  return _ExportOptions.fromJson(json);
}

/// @nodoc
mixin _$ExportOptions {
  /// 导出类型
  ExportType get type => throw _privateConstructorUsedError;

  /// 导出格式
  ExportFormat get format => throw _privateConstructorUsedError;

  /// 是否包含图片文件
  bool get includeImages => throw _privateConstructorUsedError;

  /// 是否包含元数据
  bool get includeMetadata => throw _privateConstructorUsedError;

  /// 是否压缩数据
  bool get compressData => throw _privateConstructorUsedError;

  /// 版本信息
  String get version => throw _privateConstructorUsedError;

  /// 是否包含关联数据
  bool get includeRelatedData => throw _privateConstructorUsedError;

  /// 压缩级别 (0-9)
  int get compressionLevel => throw _privateConstructorUsedError;

  /// 是否生成缩略图
  bool get generateThumbnails => throw _privateConstructorUsedError;

  /// 文件名前缀
  String? get fileNamePrefix => throw _privateConstructorUsedError;

  /// 自定义选项
  Map<String, dynamic> get customOptions => throw _privateConstructorUsedError;

  /// Serializes this ExportOptions to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ExportOptions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExportOptionsCopyWith<ExportOptions> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExportOptionsCopyWith<$Res> {
  factory $ExportOptionsCopyWith(
          ExportOptions value, $Res Function(ExportOptions) then) =
      _$ExportOptionsCopyWithImpl<$Res, ExportOptions>;
  @useResult
  $Res call(
      {ExportType type,
      ExportFormat format,
      bool includeImages,
      bool includeMetadata,
      bool compressData,
      String version,
      bool includeRelatedData,
      int compressionLevel,
      bool generateThumbnails,
      String? fileNamePrefix,
      Map<String, dynamic> customOptions});
}

/// @nodoc
class _$ExportOptionsCopyWithImpl<$Res, $Val extends ExportOptions>
    implements $ExportOptionsCopyWith<$Res> {
  _$ExportOptionsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExportOptions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? format = null,
    Object? includeImages = null,
    Object? includeMetadata = null,
    Object? compressData = null,
    Object? version = null,
    Object? includeRelatedData = null,
    Object? compressionLevel = null,
    Object? generateThumbnails = null,
    Object? fileNamePrefix = freezed,
    Object? customOptions = null,
  }) {
    return _then(_value.copyWith(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as ExportType,
      format: null == format
          ? _value.format
          : format // ignore: cast_nullable_to_non_nullable
              as ExportFormat,
      includeImages: null == includeImages
          ? _value.includeImages
          : includeImages // ignore: cast_nullable_to_non_nullable
              as bool,
      includeMetadata: null == includeMetadata
          ? _value.includeMetadata
          : includeMetadata // ignore: cast_nullable_to_non_nullable
              as bool,
      compressData: null == compressData
          ? _value.compressData
          : compressData // ignore: cast_nullable_to_non_nullable
              as bool,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      includeRelatedData: null == includeRelatedData
          ? _value.includeRelatedData
          : includeRelatedData // ignore: cast_nullable_to_non_nullable
              as bool,
      compressionLevel: null == compressionLevel
          ? _value.compressionLevel
          : compressionLevel // ignore: cast_nullable_to_non_nullable
              as int,
      generateThumbnails: null == generateThumbnails
          ? _value.generateThumbnails
          : generateThumbnails // ignore: cast_nullable_to_non_nullable
              as bool,
      fileNamePrefix: freezed == fileNamePrefix
          ? _value.fileNamePrefix
          : fileNamePrefix // ignore: cast_nullable_to_non_nullable
              as String?,
      customOptions: null == customOptions
          ? _value.customOptions
          : customOptions // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExportOptionsImplCopyWith<$Res>
    implements $ExportOptionsCopyWith<$Res> {
  factory _$$ExportOptionsImplCopyWith(
          _$ExportOptionsImpl value, $Res Function(_$ExportOptionsImpl) then) =
      __$$ExportOptionsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {ExportType type,
      ExportFormat format,
      bool includeImages,
      bool includeMetadata,
      bool compressData,
      String version,
      bool includeRelatedData,
      int compressionLevel,
      bool generateThumbnails,
      String? fileNamePrefix,
      Map<String, dynamic> customOptions});
}

/// @nodoc
class __$$ExportOptionsImplCopyWithImpl<$Res>
    extends _$ExportOptionsCopyWithImpl<$Res, _$ExportOptionsImpl>
    implements _$$ExportOptionsImplCopyWith<$Res> {
  __$$ExportOptionsImplCopyWithImpl(
      _$ExportOptionsImpl _value, $Res Function(_$ExportOptionsImpl) _then)
      : super(_value, _then);

  /// Create a copy of ExportOptions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? format = null,
    Object? includeImages = null,
    Object? includeMetadata = null,
    Object? compressData = null,
    Object? version = null,
    Object? includeRelatedData = null,
    Object? compressionLevel = null,
    Object? generateThumbnails = null,
    Object? fileNamePrefix = freezed,
    Object? customOptions = null,
  }) {
    return _then(_$ExportOptionsImpl(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as ExportType,
      format: null == format
          ? _value.format
          : format // ignore: cast_nullable_to_non_nullable
              as ExportFormat,
      includeImages: null == includeImages
          ? _value.includeImages
          : includeImages // ignore: cast_nullable_to_non_nullable
              as bool,
      includeMetadata: null == includeMetadata
          ? _value.includeMetadata
          : includeMetadata // ignore: cast_nullable_to_non_nullable
              as bool,
      compressData: null == compressData
          ? _value.compressData
          : compressData // ignore: cast_nullable_to_non_nullable
              as bool,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
      includeRelatedData: null == includeRelatedData
          ? _value.includeRelatedData
          : includeRelatedData // ignore: cast_nullable_to_non_nullable
              as bool,
      compressionLevel: null == compressionLevel
          ? _value.compressionLevel
          : compressionLevel // ignore: cast_nullable_to_non_nullable
              as int,
      generateThumbnails: null == generateThumbnails
          ? _value.generateThumbnails
          : generateThumbnails // ignore: cast_nullable_to_non_nullable
              as bool,
      fileNamePrefix: freezed == fileNamePrefix
          ? _value.fileNamePrefix
          : fileNamePrefix // ignore: cast_nullable_to_non_nullable
              as String?,
      customOptions: null == customOptions
          ? _value._customOptions
          : customOptions // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExportOptionsImpl implements _ExportOptions {
  const _$ExportOptionsImpl(
      {required this.type,
      required this.format,
      this.includeImages = true,
      this.includeMetadata = true,
      this.compressData = true,
      this.version = '1.0',
      this.includeRelatedData = true,
      this.compressionLevel = 6,
      this.generateThumbnails = true,
      this.fileNamePrefix,
      final Map<String, dynamic> customOptions = const {}})
      : _customOptions = customOptions;

  factory _$ExportOptionsImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExportOptionsImplFromJson(json);

  /// 导出类型
  @override
  final ExportType type;

  /// 导出格式
  @override
  final ExportFormat format;

  /// 是否包含图片文件
  @override
  @JsonKey()
  final bool includeImages;

  /// 是否包含元数据
  @override
  @JsonKey()
  final bool includeMetadata;

  /// 是否压缩数据
  @override
  @JsonKey()
  final bool compressData;

  /// 版本信息
  @override
  @JsonKey()
  final String version;

  /// 是否包含关联数据
  @override
  @JsonKey()
  final bool includeRelatedData;

  /// 压缩级别 (0-9)
  @override
  @JsonKey()
  final int compressionLevel;

  /// 是否生成缩略图
  @override
  @JsonKey()
  final bool generateThumbnails;

  /// 文件名前缀
  @override
  final String? fileNamePrefix;

  /// 自定义选项
  final Map<String, dynamic> _customOptions;

  /// 自定义选项
  @override
  @JsonKey()
  Map<String, dynamic> get customOptions {
    if (_customOptions is EqualUnmodifiableMapView) return _customOptions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_customOptions);
  }

  @override
  String toString() {
    return 'ExportOptions(type: $type, format: $format, includeImages: $includeImages, includeMetadata: $includeMetadata, compressData: $compressData, version: $version, includeRelatedData: $includeRelatedData, compressionLevel: $compressionLevel, generateThumbnails: $generateThumbnails, fileNamePrefix: $fileNamePrefix, customOptions: $customOptions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExportOptionsImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.format, format) || other.format == format) &&
            (identical(other.includeImages, includeImages) ||
                other.includeImages == includeImages) &&
            (identical(other.includeMetadata, includeMetadata) ||
                other.includeMetadata == includeMetadata) &&
            (identical(other.compressData, compressData) ||
                other.compressData == compressData) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.includeRelatedData, includeRelatedData) ||
                other.includeRelatedData == includeRelatedData) &&
            (identical(other.compressionLevel, compressionLevel) ||
                other.compressionLevel == compressionLevel) &&
            (identical(other.generateThumbnails, generateThumbnails) ||
                other.generateThumbnails == generateThumbnails) &&
            (identical(other.fileNamePrefix, fileNamePrefix) ||
                other.fileNamePrefix == fileNamePrefix) &&
            const DeepCollectionEquality()
                .equals(other._customOptions, _customOptions));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      type,
      format,
      includeImages,
      includeMetadata,
      compressData,
      version,
      includeRelatedData,
      compressionLevel,
      generateThumbnails,
      fileNamePrefix,
      const DeepCollectionEquality().hash(_customOptions));

  /// Create a copy of ExportOptions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExportOptionsImplCopyWith<_$ExportOptionsImpl> get copyWith =>
      __$$ExportOptionsImplCopyWithImpl<_$ExportOptionsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExportOptionsImplToJson(
      this,
    );
  }
}

abstract class _ExportOptions implements ExportOptions {
  const factory _ExportOptions(
      {required final ExportType type,
      required final ExportFormat format,
      final bool includeImages,
      final bool includeMetadata,
      final bool compressData,
      final String version,
      final bool includeRelatedData,
      final int compressionLevel,
      final bool generateThumbnails,
      final String? fileNamePrefix,
      final Map<String, dynamic> customOptions}) = _$ExportOptionsImpl;

  factory _ExportOptions.fromJson(Map<String, dynamic> json) =
      _$ExportOptionsImpl.fromJson;

  /// 导出类型
  @override
  ExportType get type;

  /// 导出格式
  @override
  ExportFormat get format;

  /// 是否包含图片文件
  @override
  bool get includeImages;

  /// 是否包含元数据
  @override
  bool get includeMetadata;

  /// 是否压缩数据
  @override
  bool get compressData;

  /// 版本信息
  @override
  String get version;

  /// 是否包含关联数据
  @override
  bool get includeRelatedData;

  /// 压缩级别 (0-9)
  @override
  int get compressionLevel;

  /// 是否生成缩略图
  @override
  bool get generateThumbnails;

  /// 文件名前缀
  @override
  String? get fileNamePrefix;

  /// 自定义选项
  @override
  Map<String, dynamic> get customOptions;

  /// Create a copy of ExportOptions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExportOptionsImplCopyWith<_$ExportOptionsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
