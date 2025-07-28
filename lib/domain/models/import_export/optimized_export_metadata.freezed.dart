// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'optimized_export_metadata.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

OptimizedExportMetadata _$OptimizedExportMetadataFromJson(
    Map<String, dynamic> json) {
  return _OptimizedExportMetadata.fromJson(json);
}

/// @nodoc
mixin _$OptimizedExportMetadata {
  /// 数据版本（独立于应用版本）
  String get dataVersion => throw _privateConstructorUsedError;

  /// 导出时间
  DateTime get exportTime => throw _privateConstructorUsedError;

  /// 导出平台
  String get platform => throw _privateConstructorUsedError;

  /// 应用版本（用于参考）
  String get appVersion => throw _privateConstructorUsedError;

  /// 导出类型
  OptimizedExportType get exportType => throw _privateConstructorUsedError;

  /// 导出选项
  OptimizedExportOptions get options => throw _privateConstructorUsedError;

  /// 数据统计
  OptimizedExportStatistics get statistics =>
      throw _privateConstructorUsedError;

  /// 文件清单
  List<OptimizedFileInfo> get files => throw _privateConstructorUsedError;

  /// 校验信息
  OptimizedChecksumInfo get checksums => throw _privateConstructorUsedError;

  /// 扩展信息（用于未来扩展）
  Map<String, dynamic> get extensions => throw _privateConstructorUsedError;

  /// Serializes this OptimizedExportMetadata to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OptimizedExportMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OptimizedExportMetadataCopyWith<OptimizedExportMetadata> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OptimizedExportMetadataCopyWith<$Res> {
  factory $OptimizedExportMetadataCopyWith(OptimizedExportMetadata value,
          $Res Function(OptimizedExportMetadata) then) =
      _$OptimizedExportMetadataCopyWithImpl<$Res, OptimizedExportMetadata>;
  @useResult
  $Res call(
      {String dataVersion,
      DateTime exportTime,
      String platform,
      String appVersion,
      OptimizedExportType exportType,
      OptimizedExportOptions options,
      OptimizedExportStatistics statistics,
      List<OptimizedFileInfo> files,
      OptimizedChecksumInfo checksums,
      Map<String, dynamic> extensions});

  $OptimizedExportTypeCopyWith<$Res> get exportType;
  $OptimizedExportOptionsCopyWith<$Res> get options;
  $OptimizedExportStatisticsCopyWith<$Res> get statistics;
  $OptimizedChecksumInfoCopyWith<$Res> get checksums;
}

/// @nodoc
class _$OptimizedExportMetadataCopyWithImpl<$Res,
        $Val extends OptimizedExportMetadata>
    implements $OptimizedExportMetadataCopyWith<$Res> {
  _$OptimizedExportMetadataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OptimizedExportMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dataVersion = null,
    Object? exportTime = null,
    Object? platform = null,
    Object? appVersion = null,
    Object? exportType = null,
    Object? options = null,
    Object? statistics = null,
    Object? files = null,
    Object? checksums = null,
    Object? extensions = null,
  }) {
    return _then(_value.copyWith(
      dataVersion: null == dataVersion
          ? _value.dataVersion
          : dataVersion // ignore: cast_nullable_to_non_nullable
              as String,
      exportTime: null == exportTime
          ? _value.exportTime
          : exportTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      platform: null == platform
          ? _value.platform
          : platform // ignore: cast_nullable_to_non_nullable
              as String,
      appVersion: null == appVersion
          ? _value.appVersion
          : appVersion // ignore: cast_nullable_to_non_nullable
              as String,
      exportType: null == exportType
          ? _value.exportType
          : exportType // ignore: cast_nullable_to_non_nullable
              as OptimizedExportType,
      options: null == options
          ? _value.options
          : options // ignore: cast_nullable_to_non_nullable
              as OptimizedExportOptions,
      statistics: null == statistics
          ? _value.statistics
          : statistics // ignore: cast_nullable_to_non_nullable
              as OptimizedExportStatistics,
      files: null == files
          ? _value.files
          : files // ignore: cast_nullable_to_non_nullable
              as List<OptimizedFileInfo>,
      checksums: null == checksums
          ? _value.checksums
          : checksums // ignore: cast_nullable_to_non_nullable
              as OptimizedChecksumInfo,
      extensions: null == extensions
          ? _value.extensions
          : extensions // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }

  /// Create a copy of OptimizedExportMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $OptimizedExportTypeCopyWith<$Res> get exportType {
    return $OptimizedExportTypeCopyWith<$Res>(_value.exportType, (value) {
      return _then(_value.copyWith(exportType: value) as $Val);
    });
  }

  /// Create a copy of OptimizedExportMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $OptimizedExportOptionsCopyWith<$Res> get options {
    return $OptimizedExportOptionsCopyWith<$Res>(_value.options, (value) {
      return _then(_value.copyWith(options: value) as $Val);
    });
  }

  /// Create a copy of OptimizedExportMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $OptimizedExportStatisticsCopyWith<$Res> get statistics {
    return $OptimizedExportStatisticsCopyWith<$Res>(_value.statistics, (value) {
      return _then(_value.copyWith(statistics: value) as $Val);
    });
  }

  /// Create a copy of OptimizedExportMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $OptimizedChecksumInfoCopyWith<$Res> get checksums {
    return $OptimizedChecksumInfoCopyWith<$Res>(_value.checksums, (value) {
      return _then(_value.copyWith(checksums: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$OptimizedExportMetadataImplCopyWith<$Res>
    implements $OptimizedExportMetadataCopyWith<$Res> {
  factory _$$OptimizedExportMetadataImplCopyWith(
          _$OptimizedExportMetadataImpl value,
          $Res Function(_$OptimizedExportMetadataImpl) then) =
      __$$OptimizedExportMetadataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String dataVersion,
      DateTime exportTime,
      String platform,
      String appVersion,
      OptimizedExportType exportType,
      OptimizedExportOptions options,
      OptimizedExportStatistics statistics,
      List<OptimizedFileInfo> files,
      OptimizedChecksumInfo checksums,
      Map<String, dynamic> extensions});

  @override
  $OptimizedExportTypeCopyWith<$Res> get exportType;
  @override
  $OptimizedExportOptionsCopyWith<$Res> get options;
  @override
  $OptimizedExportStatisticsCopyWith<$Res> get statistics;
  @override
  $OptimizedChecksumInfoCopyWith<$Res> get checksums;
}

/// @nodoc
class __$$OptimizedExportMetadataImplCopyWithImpl<$Res>
    extends _$OptimizedExportMetadataCopyWithImpl<$Res,
        _$OptimizedExportMetadataImpl>
    implements _$$OptimizedExportMetadataImplCopyWith<$Res> {
  __$$OptimizedExportMetadataImplCopyWithImpl(
      _$OptimizedExportMetadataImpl _value,
      $Res Function(_$OptimizedExportMetadataImpl) _then)
      : super(_value, _then);

  /// Create a copy of OptimizedExportMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dataVersion = null,
    Object? exportTime = null,
    Object? platform = null,
    Object? appVersion = null,
    Object? exportType = null,
    Object? options = null,
    Object? statistics = null,
    Object? files = null,
    Object? checksums = null,
    Object? extensions = null,
  }) {
    return _then(_$OptimizedExportMetadataImpl(
      dataVersion: null == dataVersion
          ? _value.dataVersion
          : dataVersion // ignore: cast_nullable_to_non_nullable
              as String,
      exportTime: null == exportTime
          ? _value.exportTime
          : exportTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      platform: null == platform
          ? _value.platform
          : platform // ignore: cast_nullable_to_non_nullable
              as String,
      appVersion: null == appVersion
          ? _value.appVersion
          : appVersion // ignore: cast_nullable_to_non_nullable
              as String,
      exportType: null == exportType
          ? _value.exportType
          : exportType // ignore: cast_nullable_to_non_nullable
              as OptimizedExportType,
      options: null == options
          ? _value.options
          : options // ignore: cast_nullable_to_non_nullable
              as OptimizedExportOptions,
      statistics: null == statistics
          ? _value.statistics
          : statistics // ignore: cast_nullable_to_non_nullable
              as OptimizedExportStatistics,
      files: null == files
          ? _value._files
          : files // ignore: cast_nullable_to_non_nullable
              as List<OptimizedFileInfo>,
      checksums: null == checksums
          ? _value.checksums
          : checksums // ignore: cast_nullable_to_non_nullable
              as OptimizedChecksumInfo,
      extensions: null == extensions
          ? _value._extensions
          : extensions // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OptimizedExportMetadataImpl extends _OptimizedExportMetadata {
  const _$OptimizedExportMetadataImpl(
      {required this.dataVersion,
      required this.exportTime,
      this.platform = 'flutter',
      required this.appVersion,
      required this.exportType,
      required this.options,
      required this.statistics,
      required final List<OptimizedFileInfo> files,
      required this.checksums,
      final Map<String, dynamic> extensions = const {}})
      : _files = files,
        _extensions = extensions,
        super._();

  factory _$OptimizedExportMetadataImpl.fromJson(Map<String, dynamic> json) =>
      _$$OptimizedExportMetadataImplFromJson(json);

  /// 数据版本（独立于应用版本）
  @override
  final String dataVersion;

  /// 导出时间
  @override
  final DateTime exportTime;

  /// 导出平台
  @override
  @JsonKey()
  final String platform;

  /// 应用版本（用于参考）
  @override
  final String appVersion;

  /// 导出类型
  @override
  final OptimizedExportType exportType;

  /// 导出选项
  @override
  final OptimizedExportOptions options;

  /// 数据统计
  @override
  final OptimizedExportStatistics statistics;

  /// 文件清单
  final List<OptimizedFileInfo> _files;

  /// 文件清单
  @override
  List<OptimizedFileInfo> get files {
    if (_files is EqualUnmodifiableListView) return _files;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_files);
  }

  /// 校验信息
  @override
  final OptimizedChecksumInfo checksums;

  /// 扩展信息（用于未来扩展）
  final Map<String, dynamic> _extensions;

  /// 扩展信息（用于未来扩展）
  @override
  @JsonKey()
  Map<String, dynamic> get extensions {
    if (_extensions is EqualUnmodifiableMapView) return _extensions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_extensions);
  }

  @override
  String toString() {
    return 'OptimizedExportMetadata(dataVersion: $dataVersion, exportTime: $exportTime, platform: $platform, appVersion: $appVersion, exportType: $exportType, options: $options, statistics: $statistics, files: $files, checksums: $checksums, extensions: $extensions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OptimizedExportMetadataImpl &&
            (identical(other.dataVersion, dataVersion) ||
                other.dataVersion == dataVersion) &&
            (identical(other.exportTime, exportTime) ||
                other.exportTime == exportTime) &&
            (identical(other.platform, platform) ||
                other.platform == platform) &&
            (identical(other.appVersion, appVersion) ||
                other.appVersion == appVersion) &&
            (identical(other.exportType, exportType) ||
                other.exportType == exportType) &&
            (identical(other.options, options) || other.options == options) &&
            (identical(other.statistics, statistics) ||
                other.statistics == statistics) &&
            const DeepCollectionEquality().equals(other._files, _files) &&
            (identical(other.checksums, checksums) ||
                other.checksums == checksums) &&
            const DeepCollectionEquality()
                .equals(other._extensions, _extensions));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      dataVersion,
      exportTime,
      platform,
      appVersion,
      exportType,
      options,
      statistics,
      const DeepCollectionEquality().hash(_files),
      checksums,
      const DeepCollectionEquality().hash(_extensions));

  /// Create a copy of OptimizedExportMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OptimizedExportMetadataImplCopyWith<_$OptimizedExportMetadataImpl>
      get copyWith => __$$OptimizedExportMetadataImplCopyWithImpl<
          _$OptimizedExportMetadataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OptimizedExportMetadataImplToJson(
      this,
    );
  }
}

abstract class _OptimizedExportMetadata extends OptimizedExportMetadata {
  const factory _OptimizedExportMetadata(
      {required final String dataVersion,
      required final DateTime exportTime,
      final String platform,
      required final String appVersion,
      required final OptimizedExportType exportType,
      required final OptimizedExportOptions options,
      required final OptimizedExportStatistics statistics,
      required final List<OptimizedFileInfo> files,
      required final OptimizedChecksumInfo checksums,
      final Map<String, dynamic> extensions}) = _$OptimizedExportMetadataImpl;
  const _OptimizedExportMetadata._() : super._();

  factory _OptimizedExportMetadata.fromJson(Map<String, dynamic> json) =
      _$OptimizedExportMetadataImpl.fromJson;

  /// 数据版本（独立于应用版本）
  @override
  String get dataVersion;

  /// 导出时间
  @override
  DateTime get exportTime;

  /// 导出平台
  @override
  String get platform;

  /// 应用版本（用于参考）
  @override
  String get appVersion;

  /// 导出类型
  @override
  OptimizedExportType get exportType;

  /// 导出选项
  @override
  OptimizedExportOptions get options;

  /// 数据统计
  @override
  OptimizedExportStatistics get statistics;

  /// 文件清单
  @override
  List<OptimizedFileInfo> get files;

  /// 校验信息
  @override
  OptimizedChecksumInfo get checksums;

  /// 扩展信息（用于未来扩展）
  @override
  Map<String, dynamic> get extensions;

  /// Create a copy of OptimizedExportMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OptimizedExportMetadataImplCopyWith<_$OptimizedExportMetadataImpl>
      get copyWith => throw _privateConstructorUsedError;
}

OptimizedExportType _$OptimizedExportTypeFromJson(Map<String, dynamic> json) {
  return _OptimizedExportType.fromJson(json);
}

/// @nodoc
mixin _$OptimizedExportType {
  /// 主要类型
  String get primary => throw _privateConstructorUsedError;

  /// 子类型
  String? get secondary => throw _privateConstructorUsedError;

  /// 包含的数据类型
  List<String> get includedDataTypes => throw _privateConstructorUsedError;

  /// 是否包含关联数据
  bool get includeRelatedData => throw _privateConstructorUsedError;

  /// Serializes this OptimizedExportType to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OptimizedExportType
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OptimizedExportTypeCopyWith<OptimizedExportType> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OptimizedExportTypeCopyWith<$Res> {
  factory $OptimizedExportTypeCopyWith(
          OptimizedExportType value, $Res Function(OptimizedExportType) then) =
      _$OptimizedExportTypeCopyWithImpl<$Res, OptimizedExportType>;
  @useResult
  $Res call(
      {String primary,
      String? secondary,
      List<String> includedDataTypes,
      bool includeRelatedData});
}

/// @nodoc
class _$OptimizedExportTypeCopyWithImpl<$Res, $Val extends OptimizedExportType>
    implements $OptimizedExportTypeCopyWith<$Res> {
  _$OptimizedExportTypeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OptimizedExportType
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? primary = null,
    Object? secondary = freezed,
    Object? includedDataTypes = null,
    Object? includeRelatedData = null,
  }) {
    return _then(_value.copyWith(
      primary: null == primary
          ? _value.primary
          : primary // ignore: cast_nullable_to_non_nullable
              as String,
      secondary: freezed == secondary
          ? _value.secondary
          : secondary // ignore: cast_nullable_to_non_nullable
              as String?,
      includedDataTypes: null == includedDataTypes
          ? _value.includedDataTypes
          : includedDataTypes // ignore: cast_nullable_to_non_nullable
              as List<String>,
      includeRelatedData: null == includeRelatedData
          ? _value.includeRelatedData
          : includeRelatedData // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OptimizedExportTypeImplCopyWith<$Res>
    implements $OptimizedExportTypeCopyWith<$Res> {
  factory _$$OptimizedExportTypeImplCopyWith(_$OptimizedExportTypeImpl value,
          $Res Function(_$OptimizedExportTypeImpl) then) =
      __$$OptimizedExportTypeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String primary,
      String? secondary,
      List<String> includedDataTypes,
      bool includeRelatedData});
}

/// @nodoc
class __$$OptimizedExportTypeImplCopyWithImpl<$Res>
    extends _$OptimizedExportTypeCopyWithImpl<$Res, _$OptimizedExportTypeImpl>
    implements _$$OptimizedExportTypeImplCopyWith<$Res> {
  __$$OptimizedExportTypeImplCopyWithImpl(_$OptimizedExportTypeImpl _value,
      $Res Function(_$OptimizedExportTypeImpl) _then)
      : super(_value, _then);

  /// Create a copy of OptimizedExportType
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? primary = null,
    Object? secondary = freezed,
    Object? includedDataTypes = null,
    Object? includeRelatedData = null,
  }) {
    return _then(_$OptimizedExportTypeImpl(
      primary: null == primary
          ? _value.primary
          : primary // ignore: cast_nullable_to_non_nullable
              as String,
      secondary: freezed == secondary
          ? _value.secondary
          : secondary // ignore: cast_nullable_to_non_nullable
              as String?,
      includedDataTypes: null == includedDataTypes
          ? _value._includedDataTypes
          : includedDataTypes // ignore: cast_nullable_to_non_nullable
              as List<String>,
      includeRelatedData: null == includeRelatedData
          ? _value.includeRelatedData
          : includeRelatedData // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OptimizedExportTypeImpl implements _OptimizedExportType {
  const _$OptimizedExportTypeImpl(
      {required this.primary,
      this.secondary,
      required final List<String> includedDataTypes,
      this.includeRelatedData = false})
      : _includedDataTypes = includedDataTypes;

  factory _$OptimizedExportTypeImpl.fromJson(Map<String, dynamic> json) =>
      _$$OptimizedExportTypeImplFromJson(json);

  /// 主要类型
  @override
  final String primary;

  /// 子类型
  @override
  final String? secondary;

  /// 包含的数据类型
  final List<String> _includedDataTypes;

  /// 包含的数据类型
  @override
  List<String> get includedDataTypes {
    if (_includedDataTypes is EqualUnmodifiableListView)
      return _includedDataTypes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_includedDataTypes);
  }

  /// 是否包含关联数据
  @override
  @JsonKey()
  final bool includeRelatedData;

  @override
  String toString() {
    return 'OptimizedExportType(primary: $primary, secondary: $secondary, includedDataTypes: $includedDataTypes, includeRelatedData: $includeRelatedData)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OptimizedExportTypeImpl &&
            (identical(other.primary, primary) || other.primary == primary) &&
            (identical(other.secondary, secondary) ||
                other.secondary == secondary) &&
            const DeepCollectionEquality()
                .equals(other._includedDataTypes, _includedDataTypes) &&
            (identical(other.includeRelatedData, includeRelatedData) ||
                other.includeRelatedData == includeRelatedData));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      primary,
      secondary,
      const DeepCollectionEquality().hash(_includedDataTypes),
      includeRelatedData);

  /// Create a copy of OptimizedExportType
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OptimizedExportTypeImplCopyWith<_$OptimizedExportTypeImpl> get copyWith =>
      __$$OptimizedExportTypeImplCopyWithImpl<_$OptimizedExportTypeImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OptimizedExportTypeImplToJson(
      this,
    );
  }
}

abstract class _OptimizedExportType implements OptimizedExportType {
  const factory _OptimizedExportType(
      {required final String primary,
      final String? secondary,
      required final List<String> includedDataTypes,
      final bool includeRelatedData}) = _$OptimizedExportTypeImpl;

  factory _OptimizedExportType.fromJson(Map<String, dynamic> json) =
      _$OptimizedExportTypeImpl.fromJson;

  /// 主要类型
  @override
  String get primary;

  /// 子类型
  @override
  String? get secondary;

  /// 包含的数据类型
  @override
  List<String> get includedDataTypes;

  /// 是否包含关联数据
  @override
  bool get includeRelatedData;

  /// Create a copy of OptimizedExportType
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OptimizedExportTypeImplCopyWith<_$OptimizedExportTypeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

OptimizedExportOptions _$OptimizedExportOptionsFromJson(
    Map<String, dynamic> json) {
  return _OptimizedExportOptions.fromJson(json);
}

/// @nodoc
mixin _$OptimizedExportOptions {
  /// 压缩级别 (0-9)
  int get compressionLevel => throw _privateConstructorUsedError;

  /// 是否包含图片
  bool get includeImages => throw _privateConstructorUsedError;

  /// 是否包含元数据
  bool get includeMetadata => throw _privateConstructorUsedError;

  /// 是否生成缩略图
  bool get generateThumbnails => throw _privateConstructorUsedError;

  /// 图片质量 (0-100)
  int get imageQuality => throw _privateConstructorUsedError;

  /// 最大图片尺寸
  int? get maxImageSize => throw _privateConstructorUsedError;

  /// 自定义选项
  Map<String, dynamic> get customOptions => throw _privateConstructorUsedError;

  /// Serializes this OptimizedExportOptions to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OptimizedExportOptions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OptimizedExportOptionsCopyWith<OptimizedExportOptions> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OptimizedExportOptionsCopyWith<$Res> {
  factory $OptimizedExportOptionsCopyWith(OptimizedExportOptions value,
          $Res Function(OptimizedExportOptions) then) =
      _$OptimizedExportOptionsCopyWithImpl<$Res, OptimizedExportOptions>;
  @useResult
  $Res call(
      {int compressionLevel,
      bool includeImages,
      bool includeMetadata,
      bool generateThumbnails,
      int imageQuality,
      int? maxImageSize,
      Map<String, dynamic> customOptions});
}

/// @nodoc
class _$OptimizedExportOptionsCopyWithImpl<$Res,
        $Val extends OptimizedExportOptions>
    implements $OptimizedExportOptionsCopyWith<$Res> {
  _$OptimizedExportOptionsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OptimizedExportOptions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? compressionLevel = null,
    Object? includeImages = null,
    Object? includeMetadata = null,
    Object? generateThumbnails = null,
    Object? imageQuality = null,
    Object? maxImageSize = freezed,
    Object? customOptions = null,
  }) {
    return _then(_value.copyWith(
      compressionLevel: null == compressionLevel
          ? _value.compressionLevel
          : compressionLevel // ignore: cast_nullable_to_non_nullable
              as int,
      includeImages: null == includeImages
          ? _value.includeImages
          : includeImages // ignore: cast_nullable_to_non_nullable
              as bool,
      includeMetadata: null == includeMetadata
          ? _value.includeMetadata
          : includeMetadata // ignore: cast_nullable_to_non_nullable
              as bool,
      generateThumbnails: null == generateThumbnails
          ? _value.generateThumbnails
          : generateThumbnails // ignore: cast_nullable_to_non_nullable
              as bool,
      imageQuality: null == imageQuality
          ? _value.imageQuality
          : imageQuality // ignore: cast_nullable_to_non_nullable
              as int,
      maxImageSize: freezed == maxImageSize
          ? _value.maxImageSize
          : maxImageSize // ignore: cast_nullable_to_non_nullable
              as int?,
      customOptions: null == customOptions
          ? _value.customOptions
          : customOptions // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OptimizedExportOptionsImplCopyWith<$Res>
    implements $OptimizedExportOptionsCopyWith<$Res> {
  factory _$$OptimizedExportOptionsImplCopyWith(
          _$OptimizedExportOptionsImpl value,
          $Res Function(_$OptimizedExportOptionsImpl) then) =
      __$$OptimizedExportOptionsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int compressionLevel,
      bool includeImages,
      bool includeMetadata,
      bool generateThumbnails,
      int imageQuality,
      int? maxImageSize,
      Map<String, dynamic> customOptions});
}

/// @nodoc
class __$$OptimizedExportOptionsImplCopyWithImpl<$Res>
    extends _$OptimizedExportOptionsCopyWithImpl<$Res,
        _$OptimizedExportOptionsImpl>
    implements _$$OptimizedExportOptionsImplCopyWith<$Res> {
  __$$OptimizedExportOptionsImplCopyWithImpl(
      _$OptimizedExportOptionsImpl _value,
      $Res Function(_$OptimizedExportOptionsImpl) _then)
      : super(_value, _then);

  /// Create a copy of OptimizedExportOptions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? compressionLevel = null,
    Object? includeImages = null,
    Object? includeMetadata = null,
    Object? generateThumbnails = null,
    Object? imageQuality = null,
    Object? maxImageSize = freezed,
    Object? customOptions = null,
  }) {
    return _then(_$OptimizedExportOptionsImpl(
      compressionLevel: null == compressionLevel
          ? _value.compressionLevel
          : compressionLevel // ignore: cast_nullable_to_non_nullable
              as int,
      includeImages: null == includeImages
          ? _value.includeImages
          : includeImages // ignore: cast_nullable_to_non_nullable
              as bool,
      includeMetadata: null == includeMetadata
          ? _value.includeMetadata
          : includeMetadata // ignore: cast_nullable_to_non_nullable
              as bool,
      generateThumbnails: null == generateThumbnails
          ? _value.generateThumbnails
          : generateThumbnails // ignore: cast_nullable_to_non_nullable
              as bool,
      imageQuality: null == imageQuality
          ? _value.imageQuality
          : imageQuality // ignore: cast_nullable_to_non_nullable
              as int,
      maxImageSize: freezed == maxImageSize
          ? _value.maxImageSize
          : maxImageSize // ignore: cast_nullable_to_non_nullable
              as int?,
      customOptions: null == customOptions
          ? _value._customOptions
          : customOptions // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OptimizedExportOptionsImpl implements _OptimizedExportOptions {
  const _$OptimizedExportOptionsImpl(
      {this.compressionLevel = 6,
      this.includeImages = true,
      this.includeMetadata = true,
      this.generateThumbnails = false,
      this.imageQuality = 85,
      this.maxImageSize,
      final Map<String, dynamic> customOptions = const {}})
      : _customOptions = customOptions;

  factory _$OptimizedExportOptionsImpl.fromJson(Map<String, dynamic> json) =>
      _$$OptimizedExportOptionsImplFromJson(json);

  /// 压缩级别 (0-9)
  @override
  @JsonKey()
  final int compressionLevel;

  /// 是否包含图片
  @override
  @JsonKey()
  final bool includeImages;

  /// 是否包含元数据
  @override
  @JsonKey()
  final bool includeMetadata;

  /// 是否生成缩略图
  @override
  @JsonKey()
  final bool generateThumbnails;

  /// 图片质量 (0-100)
  @override
  @JsonKey()
  final int imageQuality;

  /// 最大图片尺寸
  @override
  final int? maxImageSize;

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
    return 'OptimizedExportOptions(compressionLevel: $compressionLevel, includeImages: $includeImages, includeMetadata: $includeMetadata, generateThumbnails: $generateThumbnails, imageQuality: $imageQuality, maxImageSize: $maxImageSize, customOptions: $customOptions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OptimizedExportOptionsImpl &&
            (identical(other.compressionLevel, compressionLevel) ||
                other.compressionLevel == compressionLevel) &&
            (identical(other.includeImages, includeImages) ||
                other.includeImages == includeImages) &&
            (identical(other.includeMetadata, includeMetadata) ||
                other.includeMetadata == includeMetadata) &&
            (identical(other.generateThumbnails, generateThumbnails) ||
                other.generateThumbnails == generateThumbnails) &&
            (identical(other.imageQuality, imageQuality) ||
                other.imageQuality == imageQuality) &&
            (identical(other.maxImageSize, maxImageSize) ||
                other.maxImageSize == maxImageSize) &&
            const DeepCollectionEquality()
                .equals(other._customOptions, _customOptions));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      compressionLevel,
      includeImages,
      includeMetadata,
      generateThumbnails,
      imageQuality,
      maxImageSize,
      const DeepCollectionEquality().hash(_customOptions));

  /// Create a copy of OptimizedExportOptions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OptimizedExportOptionsImplCopyWith<_$OptimizedExportOptionsImpl>
      get copyWith => __$$OptimizedExportOptionsImplCopyWithImpl<
          _$OptimizedExportOptionsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OptimizedExportOptionsImplToJson(
      this,
    );
  }
}

abstract class _OptimizedExportOptions implements OptimizedExportOptions {
  const factory _OptimizedExportOptions(
      {final int compressionLevel,
      final bool includeImages,
      final bool includeMetadata,
      final bool generateThumbnails,
      final int imageQuality,
      final int? maxImageSize,
      final Map<String, dynamic> customOptions}) = _$OptimizedExportOptionsImpl;

  factory _OptimizedExportOptions.fromJson(Map<String, dynamic> json) =
      _$OptimizedExportOptionsImpl.fromJson;

  /// 压缩级别 (0-9)
  @override
  int get compressionLevel;

  /// 是否包含图片
  @override
  bool get includeImages;

  /// 是否包含元数据
  @override
  bool get includeMetadata;

  /// 是否生成缩略图
  @override
  bool get generateThumbnails;

  /// 图片质量 (0-100)
  @override
  int get imageQuality;

  /// 最大图片尺寸
  @override
  int? get maxImageSize;

  /// 自定义选项
  @override
  Map<String, dynamic> get customOptions;

  /// Create a copy of OptimizedExportOptions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OptimizedExportOptionsImplCopyWith<_$OptimizedExportOptionsImpl>
      get copyWith => throw _privateConstructorUsedError;
}

OptimizedExportStatistics _$OptimizedExportStatisticsFromJson(
    Map<String, dynamic> json) {
  return _OptimizedExportStatistics.fromJson(json);
}

/// @nodoc
mixin _$OptimizedExportStatistics {
  /// 作品数量
  int get workCount => throw _privateConstructorUsedError;

  /// 集字数量
  int get characterCount => throw _privateConstructorUsedError;

  /// 图片数量
  int get imageCount => throw _privateConstructorUsedError;

  /// 文件数量
  int get fileCount => throw _privateConstructorUsedError;

  /// 原始大小（字节）
  int get originalSize => throw _privateConstructorUsedError;

  /// 压缩后大小（字节）
  int get compressedSize => throw _privateConstructorUsedError;

  /// 处理时间（毫秒）
  int get processingTimeMs => throw _privateConstructorUsedError;

  /// 扩展统计
  Map<String, int> get extendedStats => throw _privateConstructorUsedError;

  /// Serializes this OptimizedExportStatistics to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OptimizedExportStatistics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OptimizedExportStatisticsCopyWith<OptimizedExportStatistics> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OptimizedExportStatisticsCopyWith<$Res> {
  factory $OptimizedExportStatisticsCopyWith(OptimizedExportStatistics value,
          $Res Function(OptimizedExportStatistics) then) =
      _$OptimizedExportStatisticsCopyWithImpl<$Res, OptimizedExportStatistics>;
  @useResult
  $Res call(
      {int workCount,
      int characterCount,
      int imageCount,
      int fileCount,
      int originalSize,
      int compressedSize,
      int processingTimeMs,
      Map<String, int> extendedStats});
}

/// @nodoc
class _$OptimizedExportStatisticsCopyWithImpl<$Res,
        $Val extends OptimizedExportStatistics>
    implements $OptimizedExportStatisticsCopyWith<$Res> {
  _$OptimizedExportStatisticsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OptimizedExportStatistics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? workCount = null,
    Object? characterCount = null,
    Object? imageCount = null,
    Object? fileCount = null,
    Object? originalSize = null,
    Object? compressedSize = null,
    Object? processingTimeMs = null,
    Object? extendedStats = null,
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
      fileCount: null == fileCount
          ? _value.fileCount
          : fileCount // ignore: cast_nullable_to_non_nullable
              as int,
      originalSize: null == originalSize
          ? _value.originalSize
          : originalSize // ignore: cast_nullable_to_non_nullable
              as int,
      compressedSize: null == compressedSize
          ? _value.compressedSize
          : compressedSize // ignore: cast_nullable_to_non_nullable
              as int,
      processingTimeMs: null == processingTimeMs
          ? _value.processingTimeMs
          : processingTimeMs // ignore: cast_nullable_to_non_nullable
              as int,
      extendedStats: null == extendedStats
          ? _value.extendedStats
          : extendedStats // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OptimizedExportStatisticsImplCopyWith<$Res>
    implements $OptimizedExportStatisticsCopyWith<$Res> {
  factory _$$OptimizedExportStatisticsImplCopyWith(
          _$OptimizedExportStatisticsImpl value,
          $Res Function(_$OptimizedExportStatisticsImpl) then) =
      __$$OptimizedExportStatisticsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int workCount,
      int characterCount,
      int imageCount,
      int fileCount,
      int originalSize,
      int compressedSize,
      int processingTimeMs,
      Map<String, int> extendedStats});
}

/// @nodoc
class __$$OptimizedExportStatisticsImplCopyWithImpl<$Res>
    extends _$OptimizedExportStatisticsCopyWithImpl<$Res,
        _$OptimizedExportStatisticsImpl>
    implements _$$OptimizedExportStatisticsImplCopyWith<$Res> {
  __$$OptimizedExportStatisticsImplCopyWithImpl(
      _$OptimizedExportStatisticsImpl _value,
      $Res Function(_$OptimizedExportStatisticsImpl) _then)
      : super(_value, _then);

  /// Create a copy of OptimizedExportStatistics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? workCount = null,
    Object? characterCount = null,
    Object? imageCount = null,
    Object? fileCount = null,
    Object? originalSize = null,
    Object? compressedSize = null,
    Object? processingTimeMs = null,
    Object? extendedStats = null,
  }) {
    return _then(_$OptimizedExportStatisticsImpl(
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
      fileCount: null == fileCount
          ? _value.fileCount
          : fileCount // ignore: cast_nullable_to_non_nullable
              as int,
      originalSize: null == originalSize
          ? _value.originalSize
          : originalSize // ignore: cast_nullable_to_non_nullable
              as int,
      compressedSize: null == compressedSize
          ? _value.compressedSize
          : compressedSize // ignore: cast_nullable_to_non_nullable
              as int,
      processingTimeMs: null == processingTimeMs
          ? _value.processingTimeMs
          : processingTimeMs // ignore: cast_nullable_to_non_nullable
              as int,
      extendedStats: null == extendedStats
          ? _value._extendedStats
          : extendedStats // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OptimizedExportStatisticsImpl extends _OptimizedExportStatistics {
  const _$OptimizedExportStatisticsImpl(
      {this.workCount = 0,
      this.characterCount = 0,
      this.imageCount = 0,
      this.fileCount = 0,
      this.originalSize = 0,
      this.compressedSize = 0,
      this.processingTimeMs = 0,
      final Map<String, int> extendedStats = const {}})
      : _extendedStats = extendedStats,
        super._();

  factory _$OptimizedExportStatisticsImpl.fromJson(Map<String, dynamic> json) =>
      _$$OptimizedExportStatisticsImplFromJson(json);

  /// 作品数量
  @override
  @JsonKey()
  final int workCount;

  /// 集字数量
  @override
  @JsonKey()
  final int characterCount;

  /// 图片数量
  @override
  @JsonKey()
  final int imageCount;

  /// 文件数量
  @override
  @JsonKey()
  final int fileCount;

  /// 原始大小（字节）
  @override
  @JsonKey()
  final int originalSize;

  /// 压缩后大小（字节）
  @override
  @JsonKey()
  final int compressedSize;

  /// 处理时间（毫秒）
  @override
  @JsonKey()
  final int processingTimeMs;

  /// 扩展统计
  final Map<String, int> _extendedStats;

  /// 扩展统计
  @override
  @JsonKey()
  Map<String, int> get extendedStats {
    if (_extendedStats is EqualUnmodifiableMapView) return _extendedStats;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_extendedStats);
  }

  @override
  String toString() {
    return 'OptimizedExportStatistics(workCount: $workCount, characterCount: $characterCount, imageCount: $imageCount, fileCount: $fileCount, originalSize: $originalSize, compressedSize: $compressedSize, processingTimeMs: $processingTimeMs, extendedStats: $extendedStats)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OptimizedExportStatisticsImpl &&
            (identical(other.workCount, workCount) ||
                other.workCount == workCount) &&
            (identical(other.characterCount, characterCount) ||
                other.characterCount == characterCount) &&
            (identical(other.imageCount, imageCount) ||
                other.imageCount == imageCount) &&
            (identical(other.fileCount, fileCount) ||
                other.fileCount == fileCount) &&
            (identical(other.originalSize, originalSize) ||
                other.originalSize == originalSize) &&
            (identical(other.compressedSize, compressedSize) ||
                other.compressedSize == compressedSize) &&
            (identical(other.processingTimeMs, processingTimeMs) ||
                other.processingTimeMs == processingTimeMs) &&
            const DeepCollectionEquality()
                .equals(other._extendedStats, _extendedStats));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      workCount,
      characterCount,
      imageCount,
      fileCount,
      originalSize,
      compressedSize,
      processingTimeMs,
      const DeepCollectionEquality().hash(_extendedStats));

  /// Create a copy of OptimizedExportStatistics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OptimizedExportStatisticsImplCopyWith<_$OptimizedExportStatisticsImpl>
      get copyWith => __$$OptimizedExportStatisticsImplCopyWithImpl<
          _$OptimizedExportStatisticsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OptimizedExportStatisticsImplToJson(
      this,
    );
  }
}

abstract class _OptimizedExportStatistics extends OptimizedExportStatistics {
  const factory _OptimizedExportStatistics(
      {final int workCount,
      final int characterCount,
      final int imageCount,
      final int fileCount,
      final int originalSize,
      final int compressedSize,
      final int processingTimeMs,
      final Map<String, int> extendedStats}) = _$OptimizedExportStatisticsImpl;
  const _OptimizedExportStatistics._() : super._();

  factory _OptimizedExportStatistics.fromJson(Map<String, dynamic> json) =
      _$OptimizedExportStatisticsImpl.fromJson;

  /// 作品数量
  @override
  int get workCount;

  /// 集字数量
  @override
  int get characterCount;

  /// 图片数量
  @override
  int get imageCount;

  /// 文件数量
  @override
  int get fileCount;

  /// 原始大小（字节）
  @override
  int get originalSize;

  /// 压缩后大小（字节）
  @override
  int get compressedSize;

  /// 处理时间（毫秒）
  @override
  int get processingTimeMs;

  /// 扩展统计
  @override
  Map<String, int> get extendedStats;

  /// Create a copy of OptimizedExportStatistics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OptimizedExportStatisticsImplCopyWith<_$OptimizedExportStatisticsImpl>
      get copyWith => throw _privateConstructorUsedError;
}

OptimizedFileInfo _$OptimizedFileInfoFromJson(Map<String, dynamic> json) {
  return _OptimizedFileInfo.fromJson(json);
}

/// @nodoc
mixin _$OptimizedFileInfo {
  /// 文件名
  String get fileName => throw _privateConstructorUsedError;

  /// 文件路径（在压缩包内）
  String get filePath => throw _privateConstructorUsedError;

  /// 文件类型
  String get fileType => throw _privateConstructorUsedError;

  /// 文件大小（字节）
  int get fileSize => throw _privateConstructorUsedError;

  /// 文件校验和
  String get checksum => throw _privateConstructorUsedError;

  /// MIME类型
  String? get mimeType => throw _privateConstructorUsedError;

  /// 创建时间
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// 修改时间
  DateTime? get modifiedAt => throw _privateConstructorUsedError;

  /// 扩展属性
  Map<String, dynamic> get attributes => throw _privateConstructorUsedError;

  /// Serializes this OptimizedFileInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OptimizedFileInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OptimizedFileInfoCopyWith<OptimizedFileInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OptimizedFileInfoCopyWith<$Res> {
  factory $OptimizedFileInfoCopyWith(
          OptimizedFileInfo value, $Res Function(OptimizedFileInfo) then) =
      _$OptimizedFileInfoCopyWithImpl<$Res, OptimizedFileInfo>;
  @useResult
  $Res call(
      {String fileName,
      String filePath,
      String fileType,
      int fileSize,
      String checksum,
      String? mimeType,
      DateTime? createdAt,
      DateTime? modifiedAt,
      Map<String, dynamic> attributes});
}

/// @nodoc
class _$OptimizedFileInfoCopyWithImpl<$Res, $Val extends OptimizedFileInfo>
    implements $OptimizedFileInfoCopyWith<$Res> {
  _$OptimizedFileInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OptimizedFileInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fileName = null,
    Object? filePath = null,
    Object? fileType = null,
    Object? fileSize = null,
    Object? checksum = null,
    Object? mimeType = freezed,
    Object? createdAt = freezed,
    Object? modifiedAt = freezed,
    Object? attributes = null,
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
              as String,
      fileSize: null == fileSize
          ? _value.fileSize
          : fileSize // ignore: cast_nullable_to_non_nullable
              as int,
      checksum: null == checksum
          ? _value.checksum
          : checksum // ignore: cast_nullable_to_non_nullable
              as String,
      mimeType: freezed == mimeType
          ? _value.mimeType
          : mimeType // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      modifiedAt: freezed == modifiedAt
          ? _value.modifiedAt
          : modifiedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      attributes: null == attributes
          ? _value.attributes
          : attributes // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OptimizedFileInfoImplCopyWith<$Res>
    implements $OptimizedFileInfoCopyWith<$Res> {
  factory _$$OptimizedFileInfoImplCopyWith(_$OptimizedFileInfoImpl value,
          $Res Function(_$OptimizedFileInfoImpl) then) =
      __$$OptimizedFileInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String fileName,
      String filePath,
      String fileType,
      int fileSize,
      String checksum,
      String? mimeType,
      DateTime? createdAt,
      DateTime? modifiedAt,
      Map<String, dynamic> attributes});
}

/// @nodoc
class __$$OptimizedFileInfoImplCopyWithImpl<$Res>
    extends _$OptimizedFileInfoCopyWithImpl<$Res, _$OptimizedFileInfoImpl>
    implements _$$OptimizedFileInfoImplCopyWith<$Res> {
  __$$OptimizedFileInfoImplCopyWithImpl(_$OptimizedFileInfoImpl _value,
      $Res Function(_$OptimizedFileInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of OptimizedFileInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fileName = null,
    Object? filePath = null,
    Object? fileType = null,
    Object? fileSize = null,
    Object? checksum = null,
    Object? mimeType = freezed,
    Object? createdAt = freezed,
    Object? modifiedAt = freezed,
    Object? attributes = null,
  }) {
    return _then(_$OptimizedFileInfoImpl(
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
              as String,
      fileSize: null == fileSize
          ? _value.fileSize
          : fileSize // ignore: cast_nullable_to_non_nullable
              as int,
      checksum: null == checksum
          ? _value.checksum
          : checksum // ignore: cast_nullable_to_non_nullable
              as String,
      mimeType: freezed == mimeType
          ? _value.mimeType
          : mimeType // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      modifiedAt: freezed == modifiedAt
          ? _value.modifiedAt
          : modifiedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      attributes: null == attributes
          ? _value._attributes
          : attributes // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OptimizedFileInfoImpl implements _OptimizedFileInfo {
  const _$OptimizedFileInfoImpl(
      {required this.fileName,
      required this.filePath,
      required this.fileType,
      required this.fileSize,
      required this.checksum,
      this.mimeType,
      this.createdAt,
      this.modifiedAt,
      final Map<String, dynamic> attributes = const {}})
      : _attributes = attributes;

  factory _$OptimizedFileInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$OptimizedFileInfoImplFromJson(json);

  /// 文件名
  @override
  final String fileName;

  /// 文件路径（在压缩包内）
  @override
  final String filePath;

  /// 文件类型
  @override
  final String fileType;

  /// 文件大小（字节）
  @override
  final int fileSize;

  /// 文件校验和
  @override
  final String checksum;

  /// MIME类型
  @override
  final String? mimeType;

  /// 创建时间
  @override
  final DateTime? createdAt;

  /// 修改时间
  @override
  final DateTime? modifiedAt;

  /// 扩展属性
  final Map<String, dynamic> _attributes;

  /// 扩展属性
  @override
  @JsonKey()
  Map<String, dynamic> get attributes {
    if (_attributes is EqualUnmodifiableMapView) return _attributes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_attributes);
  }

  @override
  String toString() {
    return 'OptimizedFileInfo(fileName: $fileName, filePath: $filePath, fileType: $fileType, fileSize: $fileSize, checksum: $checksum, mimeType: $mimeType, createdAt: $createdAt, modifiedAt: $modifiedAt, attributes: $attributes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OptimizedFileInfoImpl &&
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
            (identical(other.mimeType, mimeType) ||
                other.mimeType == mimeType) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.modifiedAt, modifiedAt) ||
                other.modifiedAt == modifiedAt) &&
            const DeepCollectionEquality()
                .equals(other._attributes, _attributes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      fileName,
      filePath,
      fileType,
      fileSize,
      checksum,
      mimeType,
      createdAt,
      modifiedAt,
      const DeepCollectionEquality().hash(_attributes));

  /// Create a copy of OptimizedFileInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OptimizedFileInfoImplCopyWith<_$OptimizedFileInfoImpl> get copyWith =>
      __$$OptimizedFileInfoImplCopyWithImpl<_$OptimizedFileInfoImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OptimizedFileInfoImplToJson(
      this,
    );
  }
}

abstract class _OptimizedFileInfo implements OptimizedFileInfo {
  const factory _OptimizedFileInfo(
      {required final String fileName,
      required final String filePath,
      required final String fileType,
      required final int fileSize,
      required final String checksum,
      final String? mimeType,
      final DateTime? createdAt,
      final DateTime? modifiedAt,
      final Map<String, dynamic> attributes}) = _$OptimizedFileInfoImpl;

  factory _OptimizedFileInfo.fromJson(Map<String, dynamic> json) =
      _$OptimizedFileInfoImpl.fromJson;

  /// 文件名
  @override
  String get fileName;

  /// 文件路径（在压缩包内）
  @override
  String get filePath;

  /// 文件类型
  @override
  String get fileType;

  /// 文件大小（字节）
  @override
  int get fileSize;

  /// 文件校验和
  @override
  String get checksum;

  /// MIME类型
  @override
  String? get mimeType;

  /// 创建时间
  @override
  DateTime? get createdAt;

  /// 修改时间
  @override
  DateTime? get modifiedAt;

  /// 扩展属性
  @override
  Map<String, dynamic> get attributes;

  /// Create a copy of OptimizedFileInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OptimizedFileInfoImplCopyWith<_$OptimizedFileInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

OptimizedChecksumInfo _$OptimizedChecksumInfoFromJson(
    Map<String, dynamic> json) {
  return _OptimizedChecksumInfo.fromJson(json);
}

/// @nodoc
mixin _$OptimizedChecksumInfo {
  /// 整体校验和
  String get overall => throw _privateConstructorUsedError;

  /// 数据校验和
  String get dataChecksum => throw _privateConstructorUsedError;

  /// 文件校验和
  String get filesChecksum => throw _privateConstructorUsedError;

  /// 校验算法
  String get algorithm => throw _privateConstructorUsedError;

  /// 校验时间
  DateTime get checksumTime => throw _privateConstructorUsedError;

  /// Serializes this OptimizedChecksumInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OptimizedChecksumInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OptimizedChecksumInfoCopyWith<OptimizedChecksumInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OptimizedChecksumInfoCopyWith<$Res> {
  factory $OptimizedChecksumInfoCopyWith(OptimizedChecksumInfo value,
          $Res Function(OptimizedChecksumInfo) then) =
      _$OptimizedChecksumInfoCopyWithImpl<$Res, OptimizedChecksumInfo>;
  @useResult
  $Res call(
      {String overall,
      String dataChecksum,
      String filesChecksum,
      String algorithm,
      DateTime checksumTime});
}

/// @nodoc
class _$OptimizedChecksumInfoCopyWithImpl<$Res,
        $Val extends OptimizedChecksumInfo>
    implements $OptimizedChecksumInfoCopyWith<$Res> {
  _$OptimizedChecksumInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OptimizedChecksumInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? overall = null,
    Object? dataChecksum = null,
    Object? filesChecksum = null,
    Object? algorithm = null,
    Object? checksumTime = null,
  }) {
    return _then(_value.copyWith(
      overall: null == overall
          ? _value.overall
          : overall // ignore: cast_nullable_to_non_nullable
              as String,
      dataChecksum: null == dataChecksum
          ? _value.dataChecksum
          : dataChecksum // ignore: cast_nullable_to_non_nullable
              as String,
      filesChecksum: null == filesChecksum
          ? _value.filesChecksum
          : filesChecksum // ignore: cast_nullable_to_non_nullable
              as String,
      algorithm: null == algorithm
          ? _value.algorithm
          : algorithm // ignore: cast_nullable_to_non_nullable
              as String,
      checksumTime: null == checksumTime
          ? _value.checksumTime
          : checksumTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OptimizedChecksumInfoImplCopyWith<$Res>
    implements $OptimizedChecksumInfoCopyWith<$Res> {
  factory _$$OptimizedChecksumInfoImplCopyWith(
          _$OptimizedChecksumInfoImpl value,
          $Res Function(_$OptimizedChecksumInfoImpl) then) =
      __$$OptimizedChecksumInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String overall,
      String dataChecksum,
      String filesChecksum,
      String algorithm,
      DateTime checksumTime});
}

/// @nodoc
class __$$OptimizedChecksumInfoImplCopyWithImpl<$Res>
    extends _$OptimizedChecksumInfoCopyWithImpl<$Res,
        _$OptimizedChecksumInfoImpl>
    implements _$$OptimizedChecksumInfoImplCopyWith<$Res> {
  __$$OptimizedChecksumInfoImplCopyWithImpl(_$OptimizedChecksumInfoImpl _value,
      $Res Function(_$OptimizedChecksumInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of OptimizedChecksumInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? overall = null,
    Object? dataChecksum = null,
    Object? filesChecksum = null,
    Object? algorithm = null,
    Object? checksumTime = null,
  }) {
    return _then(_$OptimizedChecksumInfoImpl(
      overall: null == overall
          ? _value.overall
          : overall // ignore: cast_nullable_to_non_nullable
              as String,
      dataChecksum: null == dataChecksum
          ? _value.dataChecksum
          : dataChecksum // ignore: cast_nullable_to_non_nullable
              as String,
      filesChecksum: null == filesChecksum
          ? _value.filesChecksum
          : filesChecksum // ignore: cast_nullable_to_non_nullable
              as String,
      algorithm: null == algorithm
          ? _value.algorithm
          : algorithm // ignore: cast_nullable_to_non_nullable
              as String,
      checksumTime: null == checksumTime
          ? _value.checksumTime
          : checksumTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OptimizedChecksumInfoImpl extends _OptimizedChecksumInfo {
  const _$OptimizedChecksumInfoImpl(
      {required this.overall,
      required this.dataChecksum,
      required this.filesChecksum,
      this.algorithm = 'sha256',
      required this.checksumTime})
      : super._();

  factory _$OptimizedChecksumInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$OptimizedChecksumInfoImplFromJson(json);

  /// 整体校验和
  @override
  final String overall;

  /// 数据校验和
  @override
  final String dataChecksum;

  /// 文件校验和
  @override
  final String filesChecksum;

  /// 校验算法
  @override
  @JsonKey()
  final String algorithm;

  /// 校验时间
  @override
  final DateTime checksumTime;

  @override
  String toString() {
    return 'OptimizedChecksumInfo(overall: $overall, dataChecksum: $dataChecksum, filesChecksum: $filesChecksum, algorithm: $algorithm, checksumTime: $checksumTime)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OptimizedChecksumInfoImpl &&
            (identical(other.overall, overall) || other.overall == overall) &&
            (identical(other.dataChecksum, dataChecksum) ||
                other.dataChecksum == dataChecksum) &&
            (identical(other.filesChecksum, filesChecksum) ||
                other.filesChecksum == filesChecksum) &&
            (identical(other.algorithm, algorithm) ||
                other.algorithm == algorithm) &&
            (identical(other.checksumTime, checksumTime) ||
                other.checksumTime == checksumTime));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, overall, dataChecksum,
      filesChecksum, algorithm, checksumTime);

  /// Create a copy of OptimizedChecksumInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OptimizedChecksumInfoImplCopyWith<_$OptimizedChecksumInfoImpl>
      get copyWith => __$$OptimizedChecksumInfoImplCopyWithImpl<
          _$OptimizedChecksumInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OptimizedChecksumInfoImplToJson(
      this,
    );
  }
}

abstract class _OptimizedChecksumInfo extends OptimizedChecksumInfo {
  const factory _OptimizedChecksumInfo(
      {required final String overall,
      required final String dataChecksum,
      required final String filesChecksum,
      final String algorithm,
      required final DateTime checksumTime}) = _$OptimizedChecksumInfoImpl;
  const _OptimizedChecksumInfo._() : super._();

  factory _OptimizedChecksumInfo.fromJson(Map<String, dynamic> json) =
      _$OptimizedChecksumInfoImpl.fromJson;

  /// 整体校验和
  @override
  String get overall;

  /// 数据校验和
  @override
  String get dataChecksum;

  /// 文件校验和
  @override
  String get filesChecksum;

  /// 校验算法
  @override
  String get algorithm;

  /// 校验时间
  @override
  DateTime get checksumTime;

  /// Create a copy of OptimizedChecksumInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OptimizedChecksumInfoImplCopyWith<_$OptimizedChecksumInfoImpl>
      get copyWith => throw _privateConstructorUsedError;
}

OptimizedCompatibilityInfo _$OptimizedCompatibilityInfoFromJson(
    Map<String, dynamic> json) {
  return _OptimizedCompatibilityInfo.fromJson(json);
}

/// @nodoc
mixin _$OptimizedCompatibilityInfo {
  /// 数据版本
  String get dataVersion => throw _privateConstructorUsedError;

  /// 最低要求应用版本
  String get minRequiredAppVersion => throw _privateConstructorUsedError;

  /// 推荐应用版本
  String get recommendedAppVersion => throw _privateConstructorUsedError;

  /// 是否向后兼容
  bool get isBackwardCompatible => throw _privateConstructorUsedError;

  /// 兼容性说明
  String? get compatibilityNotes => throw _privateConstructorUsedError;

  /// Serializes this OptimizedCompatibilityInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OptimizedCompatibilityInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OptimizedCompatibilityInfoCopyWith<OptimizedCompatibilityInfo>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OptimizedCompatibilityInfoCopyWith<$Res> {
  factory $OptimizedCompatibilityInfoCopyWith(OptimizedCompatibilityInfo value,
          $Res Function(OptimizedCompatibilityInfo) then) =
      _$OptimizedCompatibilityInfoCopyWithImpl<$Res,
          OptimizedCompatibilityInfo>;
  @useResult
  $Res call(
      {String dataVersion,
      String minRequiredAppVersion,
      String recommendedAppVersion,
      bool isBackwardCompatible,
      String? compatibilityNotes});
}

/// @nodoc
class _$OptimizedCompatibilityInfoCopyWithImpl<$Res,
        $Val extends OptimizedCompatibilityInfo>
    implements $OptimizedCompatibilityInfoCopyWith<$Res> {
  _$OptimizedCompatibilityInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OptimizedCompatibilityInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dataVersion = null,
    Object? minRequiredAppVersion = null,
    Object? recommendedAppVersion = null,
    Object? isBackwardCompatible = null,
    Object? compatibilityNotes = freezed,
  }) {
    return _then(_value.copyWith(
      dataVersion: null == dataVersion
          ? _value.dataVersion
          : dataVersion // ignore: cast_nullable_to_non_nullable
              as String,
      minRequiredAppVersion: null == minRequiredAppVersion
          ? _value.minRequiredAppVersion
          : minRequiredAppVersion // ignore: cast_nullable_to_non_nullable
              as String,
      recommendedAppVersion: null == recommendedAppVersion
          ? _value.recommendedAppVersion
          : recommendedAppVersion // ignore: cast_nullable_to_non_nullable
              as String,
      isBackwardCompatible: null == isBackwardCompatible
          ? _value.isBackwardCompatible
          : isBackwardCompatible // ignore: cast_nullable_to_non_nullable
              as bool,
      compatibilityNotes: freezed == compatibilityNotes
          ? _value.compatibilityNotes
          : compatibilityNotes // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OptimizedCompatibilityInfoImplCopyWith<$Res>
    implements $OptimizedCompatibilityInfoCopyWith<$Res> {
  factory _$$OptimizedCompatibilityInfoImplCopyWith(
          _$OptimizedCompatibilityInfoImpl value,
          $Res Function(_$OptimizedCompatibilityInfoImpl) then) =
      __$$OptimizedCompatibilityInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String dataVersion,
      String minRequiredAppVersion,
      String recommendedAppVersion,
      bool isBackwardCompatible,
      String? compatibilityNotes});
}

/// @nodoc
class __$$OptimizedCompatibilityInfoImplCopyWithImpl<$Res>
    extends _$OptimizedCompatibilityInfoCopyWithImpl<$Res,
        _$OptimizedCompatibilityInfoImpl>
    implements _$$OptimizedCompatibilityInfoImplCopyWith<$Res> {
  __$$OptimizedCompatibilityInfoImplCopyWithImpl(
      _$OptimizedCompatibilityInfoImpl _value,
      $Res Function(_$OptimizedCompatibilityInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of OptimizedCompatibilityInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dataVersion = null,
    Object? minRequiredAppVersion = null,
    Object? recommendedAppVersion = null,
    Object? isBackwardCompatible = null,
    Object? compatibilityNotes = freezed,
  }) {
    return _then(_$OptimizedCompatibilityInfoImpl(
      dataVersion: null == dataVersion
          ? _value.dataVersion
          : dataVersion // ignore: cast_nullable_to_non_nullable
              as String,
      minRequiredAppVersion: null == minRequiredAppVersion
          ? _value.minRequiredAppVersion
          : minRequiredAppVersion // ignore: cast_nullable_to_non_nullable
              as String,
      recommendedAppVersion: null == recommendedAppVersion
          ? _value.recommendedAppVersion
          : recommendedAppVersion // ignore: cast_nullable_to_non_nullable
              as String,
      isBackwardCompatible: null == isBackwardCompatible
          ? _value.isBackwardCompatible
          : isBackwardCompatible // ignore: cast_nullable_to_non_nullable
              as bool,
      compatibilityNotes: freezed == compatibilityNotes
          ? _value.compatibilityNotes
          : compatibilityNotes // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OptimizedCompatibilityInfoImpl implements _OptimizedCompatibilityInfo {
  const _$OptimizedCompatibilityInfoImpl(
      {required this.dataVersion,
      required this.minRequiredAppVersion,
      required this.recommendedAppVersion,
      required this.isBackwardCompatible,
      this.compatibilityNotes});

  factory _$OptimizedCompatibilityInfoImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$OptimizedCompatibilityInfoImplFromJson(json);

  /// 数据版本
  @override
  final String dataVersion;

  /// 最低要求应用版本
  @override
  final String minRequiredAppVersion;

  /// 推荐应用版本
  @override
  final String recommendedAppVersion;

  /// 是否向后兼容
  @override
  final bool isBackwardCompatible;

  /// 兼容性说明
  @override
  final String? compatibilityNotes;

  @override
  String toString() {
    return 'OptimizedCompatibilityInfo(dataVersion: $dataVersion, minRequiredAppVersion: $minRequiredAppVersion, recommendedAppVersion: $recommendedAppVersion, isBackwardCompatible: $isBackwardCompatible, compatibilityNotes: $compatibilityNotes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OptimizedCompatibilityInfoImpl &&
            (identical(other.dataVersion, dataVersion) ||
                other.dataVersion == dataVersion) &&
            (identical(other.minRequiredAppVersion, minRequiredAppVersion) ||
                other.minRequiredAppVersion == minRequiredAppVersion) &&
            (identical(other.recommendedAppVersion, recommendedAppVersion) ||
                other.recommendedAppVersion == recommendedAppVersion) &&
            (identical(other.isBackwardCompatible, isBackwardCompatible) ||
                other.isBackwardCompatible == isBackwardCompatible) &&
            (identical(other.compatibilityNotes, compatibilityNotes) ||
                other.compatibilityNotes == compatibilityNotes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      dataVersion,
      minRequiredAppVersion,
      recommendedAppVersion,
      isBackwardCompatible,
      compatibilityNotes);

  /// Create a copy of OptimizedCompatibilityInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OptimizedCompatibilityInfoImplCopyWith<_$OptimizedCompatibilityInfoImpl>
      get copyWith => __$$OptimizedCompatibilityInfoImplCopyWithImpl<
          _$OptimizedCompatibilityInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OptimizedCompatibilityInfoImplToJson(
      this,
    );
  }
}

abstract class _OptimizedCompatibilityInfo
    implements OptimizedCompatibilityInfo {
  const factory _OptimizedCompatibilityInfo(
      {required final String dataVersion,
      required final String minRequiredAppVersion,
      required final String recommendedAppVersion,
      required final bool isBackwardCompatible,
      final String? compatibilityNotes}) = _$OptimizedCompatibilityInfoImpl;

  factory _OptimizedCompatibilityInfo.fromJson(Map<String, dynamic> json) =
      _$OptimizedCompatibilityInfoImpl.fromJson;

  /// 数据版本
  @override
  String get dataVersion;

  /// 最低要求应用版本
  @override
  String get minRequiredAppVersion;

  /// 推荐应用版本
  @override
  String get recommendedAppVersion;

  /// 是否向后兼容
  @override
  bool get isBackwardCompatible;

  /// 兼容性说明
  @override
  String? get compatibilityNotes;

  /// Create a copy of OptimizedCompatibilityInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OptimizedCompatibilityInfoImplCopyWith<_$OptimizedCompatibilityInfoImpl>
      get copyWith => throw _privateConstructorUsedError;
}
