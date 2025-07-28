// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'import_export_data_adapter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ImportExportAdapterResult _$ImportExportAdapterResultFromJson(
    Map<String, dynamic> json) {
  return _ImportExportAdapterResult.fromJson(json);
}

/// @nodoc
mixin _$ImportExportAdapterResult {
  /// 操作是否成功
  bool get success => throw _privateConstructorUsedError;

  /// 结果消息
  String get message => throw _privateConstructorUsedError;

  /// 输出文件路径（成功时）
  String? get outputPath => throw _privateConstructorUsedError;

  /// 错误代码（失败时）
  String? get errorCode => throw _privateConstructorUsedError;

  /// 错误详情（失败时）
  Map<String, dynamic>? get errorDetails => throw _privateConstructorUsedError;

  /// 处理统计信息
  ImportExportAdapterStatistics? get statistics =>
      throw _privateConstructorUsedError;

  /// 处理时间戳
  DateTime? get timestamp => throw _privateConstructorUsedError;

  /// 额外数据
  Map<String, dynamic> get metadata => throw _privateConstructorUsedError;

  /// Serializes this ImportExportAdapterResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ImportExportAdapterResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ImportExportAdapterResultCopyWith<ImportExportAdapterResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ImportExportAdapterResultCopyWith<$Res> {
  factory $ImportExportAdapterResultCopyWith(ImportExportAdapterResult value,
          $Res Function(ImportExportAdapterResult) then) =
      _$ImportExportAdapterResultCopyWithImpl<$Res, ImportExportAdapterResult>;
  @useResult
  $Res call(
      {bool success,
      String message,
      String? outputPath,
      String? errorCode,
      Map<String, dynamic>? errorDetails,
      ImportExportAdapterStatistics? statistics,
      DateTime? timestamp,
      Map<String, dynamic> metadata});

  $ImportExportAdapterStatisticsCopyWith<$Res>? get statistics;
}

/// @nodoc
class _$ImportExportAdapterResultCopyWithImpl<$Res,
        $Val extends ImportExportAdapterResult>
    implements $ImportExportAdapterResultCopyWith<$Res> {
  _$ImportExportAdapterResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ImportExportAdapterResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? success = null,
    Object? message = null,
    Object? outputPath = freezed,
    Object? errorCode = freezed,
    Object? errorDetails = freezed,
    Object? statistics = freezed,
    Object? timestamp = freezed,
    Object? metadata = null,
  }) {
    return _then(_value.copyWith(
      success: null == success
          ? _value.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      outputPath: freezed == outputPath
          ? _value.outputPath
          : outputPath // ignore: cast_nullable_to_non_nullable
              as String?,
      errorCode: freezed == errorCode
          ? _value.errorCode
          : errorCode // ignore: cast_nullable_to_non_nullable
              as String?,
      errorDetails: freezed == errorDetails
          ? _value.errorDetails
          : errorDetails // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      statistics: freezed == statistics
          ? _value.statistics
          : statistics // ignore: cast_nullable_to_non_nullable
              as ImportExportAdapterStatistics?,
      timestamp: freezed == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      metadata: null == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }

  /// Create a copy of ImportExportAdapterResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ImportExportAdapterStatisticsCopyWith<$Res>? get statistics {
    if (_value.statistics == null) {
      return null;
    }

    return $ImportExportAdapterStatisticsCopyWith<$Res>(_value.statistics!,
        (value) {
      return _then(_value.copyWith(statistics: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ImportExportAdapterResultImplCopyWith<$Res>
    implements $ImportExportAdapterResultCopyWith<$Res> {
  factory _$$ImportExportAdapterResultImplCopyWith(
          _$ImportExportAdapterResultImpl value,
          $Res Function(_$ImportExportAdapterResultImpl) then) =
      __$$ImportExportAdapterResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool success,
      String message,
      String? outputPath,
      String? errorCode,
      Map<String, dynamic>? errorDetails,
      ImportExportAdapterStatistics? statistics,
      DateTime? timestamp,
      Map<String, dynamic> metadata});

  @override
  $ImportExportAdapterStatisticsCopyWith<$Res>? get statistics;
}

/// @nodoc
class __$$ImportExportAdapterResultImplCopyWithImpl<$Res>
    extends _$ImportExportAdapterResultCopyWithImpl<$Res,
        _$ImportExportAdapterResultImpl>
    implements _$$ImportExportAdapterResultImplCopyWith<$Res> {
  __$$ImportExportAdapterResultImplCopyWithImpl(
      _$ImportExportAdapterResultImpl _value,
      $Res Function(_$ImportExportAdapterResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of ImportExportAdapterResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? success = null,
    Object? message = null,
    Object? outputPath = freezed,
    Object? errorCode = freezed,
    Object? errorDetails = freezed,
    Object? statistics = freezed,
    Object? timestamp = freezed,
    Object? metadata = null,
  }) {
    return _then(_$ImportExportAdapterResultImpl(
      success: null == success
          ? _value.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      outputPath: freezed == outputPath
          ? _value.outputPath
          : outputPath // ignore: cast_nullable_to_non_nullable
              as String?,
      errorCode: freezed == errorCode
          ? _value.errorCode
          : errorCode // ignore: cast_nullable_to_non_nullable
              as String?,
      errorDetails: freezed == errorDetails
          ? _value._errorDetails
          : errorDetails // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      statistics: freezed == statistics
          ? _value.statistics
          : statistics // ignore: cast_nullable_to_non_nullable
              as ImportExportAdapterStatistics?,
      timestamp: freezed == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      metadata: null == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ImportExportAdapterResultImpl implements _ImportExportAdapterResult {
  const _$ImportExportAdapterResultImpl(
      {required this.success,
      required this.message,
      this.outputPath,
      this.errorCode,
      final Map<String, dynamic>? errorDetails,
      this.statistics,
      this.timestamp = null,
      final Map<String, dynamic> metadata = const {}})
      : _errorDetails = errorDetails,
        _metadata = metadata;

  factory _$ImportExportAdapterResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$ImportExportAdapterResultImplFromJson(json);

  /// 操作是否成功
  @override
  final bool success;

  /// 结果消息
  @override
  final String message;

  /// 输出文件路径（成功时）
  @override
  final String? outputPath;

  /// 错误代码（失败时）
  @override
  final String? errorCode;

  /// 错误详情（失败时）
  final Map<String, dynamic>? _errorDetails;

  /// 错误详情（失败时）
  @override
  Map<String, dynamic>? get errorDetails {
    final value = _errorDetails;
    if (value == null) return null;
    if (_errorDetails is EqualUnmodifiableMapView) return _errorDetails;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  /// 处理统计信息
  @override
  final ImportExportAdapterStatistics? statistics;

  /// 处理时间戳
  @override
  @JsonKey()
  final DateTime? timestamp;

  /// 额外数据
  final Map<String, dynamic> _metadata;

  /// 额外数据
  @override
  @JsonKey()
  Map<String, dynamic> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  @override
  String toString() {
    return 'ImportExportAdapterResult(success: $success, message: $message, outputPath: $outputPath, errorCode: $errorCode, errorDetails: $errorDetails, statistics: $statistics, timestamp: $timestamp, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ImportExportAdapterResultImpl &&
            (identical(other.success, success) || other.success == success) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.outputPath, outputPath) ||
                other.outputPath == outputPath) &&
            (identical(other.errorCode, errorCode) ||
                other.errorCode == errorCode) &&
            const DeepCollectionEquality()
                .equals(other._errorDetails, _errorDetails) &&
            (identical(other.statistics, statistics) ||
                other.statistics == statistics) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      success,
      message,
      outputPath,
      errorCode,
      const DeepCollectionEquality().hash(_errorDetails),
      statistics,
      timestamp,
      const DeepCollectionEquality().hash(_metadata));

  /// Create a copy of ImportExportAdapterResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ImportExportAdapterResultImplCopyWith<_$ImportExportAdapterResultImpl>
      get copyWith => __$$ImportExportAdapterResultImplCopyWithImpl<
          _$ImportExportAdapterResultImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ImportExportAdapterResultImplToJson(
      this,
    );
  }
}

abstract class _ImportExportAdapterResult implements ImportExportAdapterResult {
  const factory _ImportExportAdapterResult(
      {required final bool success,
      required final String message,
      final String? outputPath,
      final String? errorCode,
      final Map<String, dynamic>? errorDetails,
      final ImportExportAdapterStatistics? statistics,
      final DateTime? timestamp,
      final Map<String, dynamic> metadata}) = _$ImportExportAdapterResultImpl;

  factory _ImportExportAdapterResult.fromJson(Map<String, dynamic> json) =
      _$ImportExportAdapterResultImpl.fromJson;

  /// 操作是否成功
  @override
  bool get success;

  /// 结果消息
  @override
  String get message;

  /// 输出文件路径（成功时）
  @override
  String? get outputPath;

  /// 错误代码（失败时）
  @override
  String? get errorCode;

  /// 错误详情（失败时）
  @override
  Map<String, dynamic>? get errorDetails;

  /// 处理统计信息
  @override
  ImportExportAdapterStatistics? get statistics;

  /// 处理时间戳
  @override
  DateTime? get timestamp;

  /// 额外数据
  @override
  Map<String, dynamic> get metadata;

  /// Create a copy of ImportExportAdapterResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ImportExportAdapterResultImplCopyWith<_$ImportExportAdapterResultImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ImportExportAdapterStatistics _$ImportExportAdapterStatisticsFromJson(
    Map<String, dynamic> json) {
  return _ImportExportAdapterStatistics.fromJson(json);
}

/// @nodoc
mixin _$ImportExportAdapterStatistics {
  /// 处理开始时间
  DateTime get startTime => throw _privateConstructorUsedError;

  /// 处理结束时间
  DateTime get endTime => throw _privateConstructorUsedError;

  /// 处理耗时（毫秒）
  int get durationMs => throw _privateConstructorUsedError;

  /// 处理的文件数量
  int get processedFiles => throw _privateConstructorUsedError;

  /// 转换的数据记录数量
  int get convertedRecords => throw _privateConstructorUsedError;

  /// 原始数据大小（字节）
  int get originalSizeBytes => throw _privateConstructorUsedError;

  /// 转换后数据大小（字节）
  int get convertedSizeBytes => throw _privateConstructorUsedError;

  /// 跳过的记录数量
  int get skippedRecords => throw _privateConstructorUsedError;

  /// 错误记录数量
  int get errorRecords => throw _privateConstructorUsedError;

  /// 详细统计信息
  Map<String, dynamic> get details => throw _privateConstructorUsedError;

  /// Serializes this ImportExportAdapterStatistics to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ImportExportAdapterStatistics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ImportExportAdapterStatisticsCopyWith<ImportExportAdapterStatistics>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ImportExportAdapterStatisticsCopyWith<$Res> {
  factory $ImportExportAdapterStatisticsCopyWith(
          ImportExportAdapterStatistics value,
          $Res Function(ImportExportAdapterStatistics) then) =
      _$ImportExportAdapterStatisticsCopyWithImpl<$Res,
          ImportExportAdapterStatistics>;
  @useResult
  $Res call(
      {DateTime startTime,
      DateTime endTime,
      int durationMs,
      int processedFiles,
      int convertedRecords,
      int originalSizeBytes,
      int convertedSizeBytes,
      int skippedRecords,
      int errorRecords,
      Map<String, dynamic> details});
}

/// @nodoc
class _$ImportExportAdapterStatisticsCopyWithImpl<$Res,
        $Val extends ImportExportAdapterStatistics>
    implements $ImportExportAdapterStatisticsCopyWith<$Res> {
  _$ImportExportAdapterStatisticsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ImportExportAdapterStatistics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? startTime = null,
    Object? endTime = null,
    Object? durationMs = null,
    Object? processedFiles = null,
    Object? convertedRecords = null,
    Object? originalSizeBytes = null,
    Object? convertedSizeBytes = null,
    Object? skippedRecords = null,
    Object? errorRecords = null,
    Object? details = null,
  }) {
    return _then(_value.copyWith(
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endTime: null == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      durationMs: null == durationMs
          ? _value.durationMs
          : durationMs // ignore: cast_nullable_to_non_nullable
              as int,
      processedFiles: null == processedFiles
          ? _value.processedFiles
          : processedFiles // ignore: cast_nullable_to_non_nullable
              as int,
      convertedRecords: null == convertedRecords
          ? _value.convertedRecords
          : convertedRecords // ignore: cast_nullable_to_non_nullable
              as int,
      originalSizeBytes: null == originalSizeBytes
          ? _value.originalSizeBytes
          : originalSizeBytes // ignore: cast_nullable_to_non_nullable
              as int,
      convertedSizeBytes: null == convertedSizeBytes
          ? _value.convertedSizeBytes
          : convertedSizeBytes // ignore: cast_nullable_to_non_nullable
              as int,
      skippedRecords: null == skippedRecords
          ? _value.skippedRecords
          : skippedRecords // ignore: cast_nullable_to_non_nullable
              as int,
      errorRecords: null == errorRecords
          ? _value.errorRecords
          : errorRecords // ignore: cast_nullable_to_non_nullable
              as int,
      details: null == details
          ? _value.details
          : details // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ImportExportAdapterStatisticsImplCopyWith<$Res>
    implements $ImportExportAdapterStatisticsCopyWith<$Res> {
  factory _$$ImportExportAdapterStatisticsImplCopyWith(
          _$ImportExportAdapterStatisticsImpl value,
          $Res Function(_$ImportExportAdapterStatisticsImpl) then) =
      __$$ImportExportAdapterStatisticsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {DateTime startTime,
      DateTime endTime,
      int durationMs,
      int processedFiles,
      int convertedRecords,
      int originalSizeBytes,
      int convertedSizeBytes,
      int skippedRecords,
      int errorRecords,
      Map<String, dynamic> details});
}

/// @nodoc
class __$$ImportExportAdapterStatisticsImplCopyWithImpl<$Res>
    extends _$ImportExportAdapterStatisticsCopyWithImpl<$Res,
        _$ImportExportAdapterStatisticsImpl>
    implements _$$ImportExportAdapterStatisticsImplCopyWith<$Res> {
  __$$ImportExportAdapterStatisticsImplCopyWithImpl(
      _$ImportExportAdapterStatisticsImpl _value,
      $Res Function(_$ImportExportAdapterStatisticsImpl) _then)
      : super(_value, _then);

  /// Create a copy of ImportExportAdapterStatistics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? startTime = null,
    Object? endTime = null,
    Object? durationMs = null,
    Object? processedFiles = null,
    Object? convertedRecords = null,
    Object? originalSizeBytes = null,
    Object? convertedSizeBytes = null,
    Object? skippedRecords = null,
    Object? errorRecords = null,
    Object? details = null,
  }) {
    return _then(_$ImportExportAdapterStatisticsImpl(
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endTime: null == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      durationMs: null == durationMs
          ? _value.durationMs
          : durationMs // ignore: cast_nullable_to_non_nullable
              as int,
      processedFiles: null == processedFiles
          ? _value.processedFiles
          : processedFiles // ignore: cast_nullable_to_non_nullable
              as int,
      convertedRecords: null == convertedRecords
          ? _value.convertedRecords
          : convertedRecords // ignore: cast_nullable_to_non_nullable
              as int,
      originalSizeBytes: null == originalSizeBytes
          ? _value.originalSizeBytes
          : originalSizeBytes // ignore: cast_nullable_to_non_nullable
              as int,
      convertedSizeBytes: null == convertedSizeBytes
          ? _value.convertedSizeBytes
          : convertedSizeBytes // ignore: cast_nullable_to_non_nullable
              as int,
      skippedRecords: null == skippedRecords
          ? _value.skippedRecords
          : skippedRecords // ignore: cast_nullable_to_non_nullable
              as int,
      errorRecords: null == errorRecords
          ? _value.errorRecords
          : errorRecords // ignore: cast_nullable_to_non_nullable
              as int,
      details: null == details
          ? _value._details
          : details // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ImportExportAdapterStatisticsImpl
    extends _ImportExportAdapterStatistics {
  const _$ImportExportAdapterStatisticsImpl(
      {required this.startTime,
      required this.endTime,
      required this.durationMs,
      this.processedFiles = 0,
      this.convertedRecords = 0,
      this.originalSizeBytes = 0,
      this.convertedSizeBytes = 0,
      this.skippedRecords = 0,
      this.errorRecords = 0,
      final Map<String, dynamic> details = const {}})
      : _details = details,
        super._();

  factory _$ImportExportAdapterStatisticsImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$ImportExportAdapterStatisticsImplFromJson(json);

  /// 处理开始时间
  @override
  final DateTime startTime;

  /// 处理结束时间
  @override
  final DateTime endTime;

  /// 处理耗时（毫秒）
  @override
  final int durationMs;

  /// 处理的文件数量
  @override
  @JsonKey()
  final int processedFiles;

  /// 转换的数据记录数量
  @override
  @JsonKey()
  final int convertedRecords;

  /// 原始数据大小（字节）
  @override
  @JsonKey()
  final int originalSizeBytes;

  /// 转换后数据大小（字节）
  @override
  @JsonKey()
  final int convertedSizeBytes;

  /// 跳过的记录数量
  @override
  @JsonKey()
  final int skippedRecords;

  /// 错误记录数量
  @override
  @JsonKey()
  final int errorRecords;

  /// 详细统计信息
  final Map<String, dynamic> _details;

  /// 详细统计信息
  @override
  @JsonKey()
  Map<String, dynamic> get details {
    if (_details is EqualUnmodifiableMapView) return _details;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_details);
  }

  @override
  String toString() {
    return 'ImportExportAdapterStatistics(startTime: $startTime, endTime: $endTime, durationMs: $durationMs, processedFiles: $processedFiles, convertedRecords: $convertedRecords, originalSizeBytes: $originalSizeBytes, convertedSizeBytes: $convertedSizeBytes, skippedRecords: $skippedRecords, errorRecords: $errorRecords, details: $details)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ImportExportAdapterStatisticsImpl &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.durationMs, durationMs) ||
                other.durationMs == durationMs) &&
            (identical(other.processedFiles, processedFiles) ||
                other.processedFiles == processedFiles) &&
            (identical(other.convertedRecords, convertedRecords) ||
                other.convertedRecords == convertedRecords) &&
            (identical(other.originalSizeBytes, originalSizeBytes) ||
                other.originalSizeBytes == originalSizeBytes) &&
            (identical(other.convertedSizeBytes, convertedSizeBytes) ||
                other.convertedSizeBytes == convertedSizeBytes) &&
            (identical(other.skippedRecords, skippedRecords) ||
                other.skippedRecords == skippedRecords) &&
            (identical(other.errorRecords, errorRecords) ||
                other.errorRecords == errorRecords) &&
            const DeepCollectionEquality().equals(other._details, _details));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      startTime,
      endTime,
      durationMs,
      processedFiles,
      convertedRecords,
      originalSizeBytes,
      convertedSizeBytes,
      skippedRecords,
      errorRecords,
      const DeepCollectionEquality().hash(_details));

  /// Create a copy of ImportExportAdapterStatistics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ImportExportAdapterStatisticsImplCopyWith<
          _$ImportExportAdapterStatisticsImpl>
      get copyWith => __$$ImportExportAdapterStatisticsImplCopyWithImpl<
          _$ImportExportAdapterStatisticsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ImportExportAdapterStatisticsImplToJson(
      this,
    );
  }
}

abstract class _ImportExportAdapterStatistics
    extends ImportExportAdapterStatistics {
  const factory _ImportExportAdapterStatistics(
          {required final DateTime startTime,
          required final DateTime endTime,
          required final int durationMs,
          final int processedFiles,
          final int convertedRecords,
          final int originalSizeBytes,
          final int convertedSizeBytes,
          final int skippedRecords,
          final int errorRecords,
          final Map<String, dynamic> details}) =
      _$ImportExportAdapterStatisticsImpl;
  const _ImportExportAdapterStatistics._() : super._();

  factory _ImportExportAdapterStatistics.fromJson(Map<String, dynamic> json) =
      _$ImportExportAdapterStatisticsImpl.fromJson;

  /// 处理开始时间
  @override
  DateTime get startTime;

  /// 处理结束时间
  @override
  DateTime get endTime;

  /// 处理耗时（毫秒）
  @override
  int get durationMs;

  /// 处理的文件数量
  @override
  int get processedFiles;

  /// 转换的数据记录数量
  @override
  int get convertedRecords;

  /// 原始数据大小（字节）
  @override
  int get originalSizeBytes;

  /// 转换后数据大小（字节）
  @override
  int get convertedSizeBytes;

  /// 跳过的记录数量
  @override
  int get skippedRecords;

  /// 错误记录数量
  @override
  int get errorRecords;

  /// 详细统计信息
  @override
  Map<String, dynamic> get details;

  /// Create a copy of ImportExportAdapterStatistics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ImportExportAdapterStatisticsImplCopyWith<
          _$ImportExportAdapterStatisticsImpl>
      get copyWith => throw _privateConstructorUsedError;
}

UpgradeChainResult _$UpgradeChainResultFromJson(Map<String, dynamic> json) {
  return _UpgradeChainResult.fromJson(json);
}

/// @nodoc
mixin _$UpgradeChainResult {
  /// 升级是否成功
  bool get success => throw _privateConstructorUsedError;

  /// 结果消息
  String get message => throw _privateConstructorUsedError;

  /// 最终输出路径
  String? get finalOutputPath => throw _privateConstructorUsedError;

  /// 各个适配器的结果
  List<ImportExportAdapterResult> get adapterResults =>
      throw _privateConstructorUsedError;

  /// 总体统计信息
  UpgradeChainStatistics? get statistics => throw _privateConstructorUsedError;

  /// 错误信息（失败时）
  String? get errorMessage => throw _privateConstructorUsedError;

  /// 失败的适配器索引（失败时）
  int? get failedAdapterIndex => throw _privateConstructorUsedError;

  /// Serializes this UpgradeChainResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UpgradeChainResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UpgradeChainResultCopyWith<UpgradeChainResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UpgradeChainResultCopyWith<$Res> {
  factory $UpgradeChainResultCopyWith(
          UpgradeChainResult value, $Res Function(UpgradeChainResult) then) =
      _$UpgradeChainResultCopyWithImpl<$Res, UpgradeChainResult>;
  @useResult
  $Res call(
      {bool success,
      String message,
      String? finalOutputPath,
      List<ImportExportAdapterResult> adapterResults,
      UpgradeChainStatistics? statistics,
      String? errorMessage,
      int? failedAdapterIndex});

  $UpgradeChainStatisticsCopyWith<$Res>? get statistics;
}

/// @nodoc
class _$UpgradeChainResultCopyWithImpl<$Res, $Val extends UpgradeChainResult>
    implements $UpgradeChainResultCopyWith<$Res> {
  _$UpgradeChainResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UpgradeChainResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? success = null,
    Object? message = null,
    Object? finalOutputPath = freezed,
    Object? adapterResults = null,
    Object? statistics = freezed,
    Object? errorMessage = freezed,
    Object? failedAdapterIndex = freezed,
  }) {
    return _then(_value.copyWith(
      success: null == success
          ? _value.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      finalOutputPath: freezed == finalOutputPath
          ? _value.finalOutputPath
          : finalOutputPath // ignore: cast_nullable_to_non_nullable
              as String?,
      adapterResults: null == adapterResults
          ? _value.adapterResults
          : adapterResults // ignore: cast_nullable_to_non_nullable
              as List<ImportExportAdapterResult>,
      statistics: freezed == statistics
          ? _value.statistics
          : statistics // ignore: cast_nullable_to_non_nullable
              as UpgradeChainStatistics?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      failedAdapterIndex: freezed == failedAdapterIndex
          ? _value.failedAdapterIndex
          : failedAdapterIndex // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }

  /// Create a copy of UpgradeChainResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UpgradeChainStatisticsCopyWith<$Res>? get statistics {
    if (_value.statistics == null) {
      return null;
    }

    return $UpgradeChainStatisticsCopyWith<$Res>(_value.statistics!, (value) {
      return _then(_value.copyWith(statistics: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$UpgradeChainResultImplCopyWith<$Res>
    implements $UpgradeChainResultCopyWith<$Res> {
  factory _$$UpgradeChainResultImplCopyWith(_$UpgradeChainResultImpl value,
          $Res Function(_$UpgradeChainResultImpl) then) =
      __$$UpgradeChainResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool success,
      String message,
      String? finalOutputPath,
      List<ImportExportAdapterResult> adapterResults,
      UpgradeChainStatistics? statistics,
      String? errorMessage,
      int? failedAdapterIndex});

  @override
  $UpgradeChainStatisticsCopyWith<$Res>? get statistics;
}

/// @nodoc
class __$$UpgradeChainResultImplCopyWithImpl<$Res>
    extends _$UpgradeChainResultCopyWithImpl<$Res, _$UpgradeChainResultImpl>
    implements _$$UpgradeChainResultImplCopyWith<$Res> {
  __$$UpgradeChainResultImplCopyWithImpl(_$UpgradeChainResultImpl _value,
      $Res Function(_$UpgradeChainResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of UpgradeChainResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? success = null,
    Object? message = null,
    Object? finalOutputPath = freezed,
    Object? adapterResults = null,
    Object? statistics = freezed,
    Object? errorMessage = freezed,
    Object? failedAdapterIndex = freezed,
  }) {
    return _then(_$UpgradeChainResultImpl(
      success: null == success
          ? _value.success
          : success // ignore: cast_nullable_to_non_nullable
              as bool,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      finalOutputPath: freezed == finalOutputPath
          ? _value.finalOutputPath
          : finalOutputPath // ignore: cast_nullable_to_non_nullable
              as String?,
      adapterResults: null == adapterResults
          ? _value._adapterResults
          : adapterResults // ignore: cast_nullable_to_non_nullable
              as List<ImportExportAdapterResult>,
      statistics: freezed == statistics
          ? _value.statistics
          : statistics // ignore: cast_nullable_to_non_nullable
              as UpgradeChainStatistics?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      failedAdapterIndex: freezed == failedAdapterIndex
          ? _value.failedAdapterIndex
          : failedAdapterIndex // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UpgradeChainResultImpl extends _UpgradeChainResult {
  const _$UpgradeChainResultImpl(
      {required this.success,
      required this.message,
      this.finalOutputPath,
      required final List<ImportExportAdapterResult> adapterResults,
      this.statistics,
      this.errorMessage,
      this.failedAdapterIndex})
      : _adapterResults = adapterResults,
        super._();

  factory _$UpgradeChainResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$UpgradeChainResultImplFromJson(json);

  /// 升级是否成功
  @override
  final bool success;

  /// 结果消息
  @override
  final String message;

  /// 最终输出路径
  @override
  final String? finalOutputPath;

  /// 各个适配器的结果
  final List<ImportExportAdapterResult> _adapterResults;

  /// 各个适配器的结果
  @override
  List<ImportExportAdapterResult> get adapterResults {
    if (_adapterResults is EqualUnmodifiableListView) return _adapterResults;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_adapterResults);
  }

  /// 总体统计信息
  @override
  final UpgradeChainStatistics? statistics;

  /// 错误信息（失败时）
  @override
  final String? errorMessage;

  /// 失败的适配器索引（失败时）
  @override
  final int? failedAdapterIndex;

  @override
  String toString() {
    return 'UpgradeChainResult(success: $success, message: $message, finalOutputPath: $finalOutputPath, adapterResults: $adapterResults, statistics: $statistics, errorMessage: $errorMessage, failedAdapterIndex: $failedAdapterIndex)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UpgradeChainResultImpl &&
            (identical(other.success, success) || other.success == success) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.finalOutputPath, finalOutputPath) ||
                other.finalOutputPath == finalOutputPath) &&
            const DeepCollectionEquality()
                .equals(other._adapterResults, _adapterResults) &&
            (identical(other.statistics, statistics) ||
                other.statistics == statistics) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.failedAdapterIndex, failedAdapterIndex) ||
                other.failedAdapterIndex == failedAdapterIndex));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      success,
      message,
      finalOutputPath,
      const DeepCollectionEquality().hash(_adapterResults),
      statistics,
      errorMessage,
      failedAdapterIndex);

  /// Create a copy of UpgradeChainResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UpgradeChainResultImplCopyWith<_$UpgradeChainResultImpl> get copyWith =>
      __$$UpgradeChainResultImplCopyWithImpl<_$UpgradeChainResultImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UpgradeChainResultImplToJson(
      this,
    );
  }
}

abstract class _UpgradeChainResult extends UpgradeChainResult {
  const factory _UpgradeChainResult(
      {required final bool success,
      required final String message,
      final String? finalOutputPath,
      required final List<ImportExportAdapterResult> adapterResults,
      final UpgradeChainStatistics? statistics,
      final String? errorMessage,
      final int? failedAdapterIndex}) = _$UpgradeChainResultImpl;
  const _UpgradeChainResult._() : super._();

  factory _UpgradeChainResult.fromJson(Map<String, dynamic> json) =
      _$UpgradeChainResultImpl.fromJson;

  /// 升级是否成功
  @override
  bool get success;

  /// 结果消息
  @override
  String get message;

  /// 最终输出路径
  @override
  String? get finalOutputPath;

  /// 各个适配器的结果
  @override
  List<ImportExportAdapterResult> get adapterResults;

  /// 总体统计信息
  @override
  UpgradeChainStatistics? get statistics;

  /// 错误信息（失败时）
  @override
  String? get errorMessage;

  /// 失败的适配器索引（失败时）
  @override
  int? get failedAdapterIndex;

  /// Create a copy of UpgradeChainResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UpgradeChainResultImplCopyWith<_$UpgradeChainResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UpgradeChainStatistics _$UpgradeChainStatisticsFromJson(
    Map<String, dynamic> json) {
  return _UpgradeChainStatistics.fromJson(json);
}

/// @nodoc
mixin _$UpgradeChainStatistics {
  /// 总开始时间
  DateTime get startTime => throw _privateConstructorUsedError;

  /// 总结束时间
  DateTime get endTime => throw _privateConstructorUsedError;

  /// 总耗时（毫秒）
  int get totalDurationMs => throw _privateConstructorUsedError;

  /// 执行的适配器数量
  int get adapterCount => throw _privateConstructorUsedError;

  /// 总处理记录数
  int get totalRecords => throw _privateConstructorUsedError;

  /// 总处理文件数
  int get totalFiles => throw _privateConstructorUsedError;

  /// 原始数据大小
  int get originalSizeBytes => throw _privateConstructorUsedError;

  /// 最终数据大小
  int get finalSizeBytes => throw _privateConstructorUsedError;

  /// 各适配器耗时分布
  Map<String, int> get adapterDurations => throw _privateConstructorUsedError;

  /// Serializes this UpgradeChainStatistics to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UpgradeChainStatistics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UpgradeChainStatisticsCopyWith<UpgradeChainStatistics> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UpgradeChainStatisticsCopyWith<$Res> {
  factory $UpgradeChainStatisticsCopyWith(UpgradeChainStatistics value,
          $Res Function(UpgradeChainStatistics) then) =
      _$UpgradeChainStatisticsCopyWithImpl<$Res, UpgradeChainStatistics>;
  @useResult
  $Res call(
      {DateTime startTime,
      DateTime endTime,
      int totalDurationMs,
      int adapterCount,
      int totalRecords,
      int totalFiles,
      int originalSizeBytes,
      int finalSizeBytes,
      Map<String, int> adapterDurations});
}

/// @nodoc
class _$UpgradeChainStatisticsCopyWithImpl<$Res,
        $Val extends UpgradeChainStatistics>
    implements $UpgradeChainStatisticsCopyWith<$Res> {
  _$UpgradeChainStatisticsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UpgradeChainStatistics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? startTime = null,
    Object? endTime = null,
    Object? totalDurationMs = null,
    Object? adapterCount = null,
    Object? totalRecords = null,
    Object? totalFiles = null,
    Object? originalSizeBytes = null,
    Object? finalSizeBytes = null,
    Object? adapterDurations = null,
  }) {
    return _then(_value.copyWith(
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endTime: null == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      totalDurationMs: null == totalDurationMs
          ? _value.totalDurationMs
          : totalDurationMs // ignore: cast_nullable_to_non_nullable
              as int,
      adapterCount: null == adapterCount
          ? _value.adapterCount
          : adapterCount // ignore: cast_nullable_to_non_nullable
              as int,
      totalRecords: null == totalRecords
          ? _value.totalRecords
          : totalRecords // ignore: cast_nullable_to_non_nullable
              as int,
      totalFiles: null == totalFiles
          ? _value.totalFiles
          : totalFiles // ignore: cast_nullable_to_non_nullable
              as int,
      originalSizeBytes: null == originalSizeBytes
          ? _value.originalSizeBytes
          : originalSizeBytes // ignore: cast_nullable_to_non_nullable
              as int,
      finalSizeBytes: null == finalSizeBytes
          ? _value.finalSizeBytes
          : finalSizeBytes // ignore: cast_nullable_to_non_nullable
              as int,
      adapterDurations: null == adapterDurations
          ? _value.adapterDurations
          : adapterDurations // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UpgradeChainStatisticsImplCopyWith<$Res>
    implements $UpgradeChainStatisticsCopyWith<$Res> {
  factory _$$UpgradeChainStatisticsImplCopyWith(
          _$UpgradeChainStatisticsImpl value,
          $Res Function(_$UpgradeChainStatisticsImpl) then) =
      __$$UpgradeChainStatisticsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {DateTime startTime,
      DateTime endTime,
      int totalDurationMs,
      int adapterCount,
      int totalRecords,
      int totalFiles,
      int originalSizeBytes,
      int finalSizeBytes,
      Map<String, int> adapterDurations});
}

/// @nodoc
class __$$UpgradeChainStatisticsImplCopyWithImpl<$Res>
    extends _$UpgradeChainStatisticsCopyWithImpl<$Res,
        _$UpgradeChainStatisticsImpl>
    implements _$$UpgradeChainStatisticsImplCopyWith<$Res> {
  __$$UpgradeChainStatisticsImplCopyWithImpl(
      _$UpgradeChainStatisticsImpl _value,
      $Res Function(_$UpgradeChainStatisticsImpl) _then)
      : super(_value, _then);

  /// Create a copy of UpgradeChainStatistics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? startTime = null,
    Object? endTime = null,
    Object? totalDurationMs = null,
    Object? adapterCount = null,
    Object? totalRecords = null,
    Object? totalFiles = null,
    Object? originalSizeBytes = null,
    Object? finalSizeBytes = null,
    Object? adapterDurations = null,
  }) {
    return _then(_$UpgradeChainStatisticsImpl(
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endTime: null == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      totalDurationMs: null == totalDurationMs
          ? _value.totalDurationMs
          : totalDurationMs // ignore: cast_nullable_to_non_nullable
              as int,
      adapterCount: null == adapterCount
          ? _value.adapterCount
          : adapterCount // ignore: cast_nullable_to_non_nullable
              as int,
      totalRecords: null == totalRecords
          ? _value.totalRecords
          : totalRecords // ignore: cast_nullable_to_non_nullable
              as int,
      totalFiles: null == totalFiles
          ? _value.totalFiles
          : totalFiles // ignore: cast_nullable_to_non_nullable
              as int,
      originalSizeBytes: null == originalSizeBytes
          ? _value.originalSizeBytes
          : originalSizeBytes // ignore: cast_nullable_to_non_nullable
              as int,
      finalSizeBytes: null == finalSizeBytes
          ? _value.finalSizeBytes
          : finalSizeBytes // ignore: cast_nullable_to_non_nullable
              as int,
      adapterDurations: null == adapterDurations
          ? _value._adapterDurations
          : adapterDurations // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UpgradeChainStatisticsImpl extends _UpgradeChainStatistics {
  const _$UpgradeChainStatisticsImpl(
      {required this.startTime,
      required this.endTime,
      required this.totalDurationMs,
      required this.adapterCount,
      this.totalRecords = 0,
      this.totalFiles = 0,
      this.originalSizeBytes = 0,
      this.finalSizeBytes = 0,
      final Map<String, int> adapterDurations = const {}})
      : _adapterDurations = adapterDurations,
        super._();

  factory _$UpgradeChainStatisticsImpl.fromJson(Map<String, dynamic> json) =>
      _$$UpgradeChainStatisticsImplFromJson(json);

  /// 总开始时间
  @override
  final DateTime startTime;

  /// 总结束时间
  @override
  final DateTime endTime;

  /// 总耗时（毫秒）
  @override
  final int totalDurationMs;

  /// 执行的适配器数量
  @override
  final int adapterCount;

  /// 总处理记录数
  @override
  @JsonKey()
  final int totalRecords;

  /// 总处理文件数
  @override
  @JsonKey()
  final int totalFiles;

  /// 原始数据大小
  @override
  @JsonKey()
  final int originalSizeBytes;

  /// 最终数据大小
  @override
  @JsonKey()
  final int finalSizeBytes;

  /// 各适配器耗时分布
  final Map<String, int> _adapterDurations;

  /// 各适配器耗时分布
  @override
  @JsonKey()
  Map<String, int> get adapterDurations {
    if (_adapterDurations is EqualUnmodifiableMapView) return _adapterDurations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_adapterDurations);
  }

  @override
  String toString() {
    return 'UpgradeChainStatistics(startTime: $startTime, endTime: $endTime, totalDurationMs: $totalDurationMs, adapterCount: $adapterCount, totalRecords: $totalRecords, totalFiles: $totalFiles, originalSizeBytes: $originalSizeBytes, finalSizeBytes: $finalSizeBytes, adapterDurations: $adapterDurations)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UpgradeChainStatisticsImpl &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.totalDurationMs, totalDurationMs) ||
                other.totalDurationMs == totalDurationMs) &&
            (identical(other.adapterCount, adapterCount) ||
                other.adapterCount == adapterCount) &&
            (identical(other.totalRecords, totalRecords) ||
                other.totalRecords == totalRecords) &&
            (identical(other.totalFiles, totalFiles) ||
                other.totalFiles == totalFiles) &&
            (identical(other.originalSizeBytes, originalSizeBytes) ||
                other.originalSizeBytes == originalSizeBytes) &&
            (identical(other.finalSizeBytes, finalSizeBytes) ||
                other.finalSizeBytes == finalSizeBytes) &&
            const DeepCollectionEquality()
                .equals(other._adapterDurations, _adapterDurations));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      startTime,
      endTime,
      totalDurationMs,
      adapterCount,
      totalRecords,
      totalFiles,
      originalSizeBytes,
      finalSizeBytes,
      const DeepCollectionEquality().hash(_adapterDurations));

  /// Create a copy of UpgradeChainStatistics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UpgradeChainStatisticsImplCopyWith<_$UpgradeChainStatisticsImpl>
      get copyWith => __$$UpgradeChainStatisticsImplCopyWithImpl<
          _$UpgradeChainStatisticsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UpgradeChainStatisticsImplToJson(
      this,
    );
  }
}

abstract class _UpgradeChainStatistics extends UpgradeChainStatistics {
  const factory _UpgradeChainStatistics(
      {required final DateTime startTime,
      required final DateTime endTime,
      required final int totalDurationMs,
      required final int adapterCount,
      final int totalRecords,
      final int totalFiles,
      final int originalSizeBytes,
      final int finalSizeBytes,
      final Map<String, int> adapterDurations}) = _$UpgradeChainStatisticsImpl;
  const _UpgradeChainStatistics._() : super._();

  factory _UpgradeChainStatistics.fromJson(Map<String, dynamic> json) =
      _$UpgradeChainStatisticsImpl.fromJson;

  /// 总开始时间
  @override
  DateTime get startTime;

  /// 总结束时间
  @override
  DateTime get endTime;

  /// 总耗时（毫秒）
  @override
  int get totalDurationMs;

  /// 执行的适配器数量
  @override
  int get adapterCount;

  /// 总处理记录数
  @override
  int get totalRecords;

  /// 总处理文件数
  @override
  int get totalFiles;

  /// 原始数据大小
  @override
  int get originalSizeBytes;

  /// 最终数据大小
  @override
  int get finalSizeBytes;

  /// 各适配器耗时分布
  @override
  Map<String, int> get adapterDurations;

  /// Create a copy of UpgradeChainStatistics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UpgradeChainStatisticsImplCopyWith<_$UpgradeChainStatisticsImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ImportUpgradeResult _$ImportUpgradeResultFromJson(Map<String, dynamic> json) {
  return _ImportUpgradeResult.fromJson(json);
}

/// @nodoc
mixin _$ImportUpgradeResult {
  /// 升级状态
  ImportUpgradeStatus get status => throw _privateConstructorUsedError;

  /// 源数据版本
  String get sourceVersion => throw _privateConstructorUsedError;

  /// 目标数据版本
  String get targetVersion => throw _privateConstructorUsedError;

  /// 结果消息
  String get message => throw _privateConstructorUsedError;

  /// 升级后的文件路径
  String? get upgradedFilePath => throw _privateConstructorUsedError;

  /// 升级链结果
  UpgradeChainResult? get upgradeChainResult =>
      throw _privateConstructorUsedError;

  /// 错误信息
  String? get errorMessage => throw _privateConstructorUsedError;

  /// Serializes this ImportUpgradeResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ImportUpgradeResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ImportUpgradeResultCopyWith<ImportUpgradeResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ImportUpgradeResultCopyWith<$Res> {
  factory $ImportUpgradeResultCopyWith(
          ImportUpgradeResult value, $Res Function(ImportUpgradeResult) then) =
      _$ImportUpgradeResultCopyWithImpl<$Res, ImportUpgradeResult>;
  @useResult
  $Res call(
      {ImportUpgradeStatus status,
      String sourceVersion,
      String targetVersion,
      String message,
      String? upgradedFilePath,
      UpgradeChainResult? upgradeChainResult,
      String? errorMessage});

  $UpgradeChainResultCopyWith<$Res>? get upgradeChainResult;
}

/// @nodoc
class _$ImportUpgradeResultCopyWithImpl<$Res, $Val extends ImportUpgradeResult>
    implements $ImportUpgradeResultCopyWith<$Res> {
  _$ImportUpgradeResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ImportUpgradeResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? sourceVersion = null,
    Object? targetVersion = null,
    Object? message = null,
    Object? upgradedFilePath = freezed,
    Object? upgradeChainResult = freezed,
    Object? errorMessage = freezed,
  }) {
    return _then(_value.copyWith(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as ImportUpgradeStatus,
      sourceVersion: null == sourceVersion
          ? _value.sourceVersion
          : sourceVersion // ignore: cast_nullable_to_non_nullable
              as String,
      targetVersion: null == targetVersion
          ? _value.targetVersion
          : targetVersion // ignore: cast_nullable_to_non_nullable
              as String,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      upgradedFilePath: freezed == upgradedFilePath
          ? _value.upgradedFilePath
          : upgradedFilePath // ignore: cast_nullable_to_non_nullable
              as String?,
      upgradeChainResult: freezed == upgradeChainResult
          ? _value.upgradeChainResult
          : upgradeChainResult // ignore: cast_nullable_to_non_nullable
              as UpgradeChainResult?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of ImportUpgradeResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UpgradeChainResultCopyWith<$Res>? get upgradeChainResult {
    if (_value.upgradeChainResult == null) {
      return null;
    }

    return $UpgradeChainResultCopyWith<$Res>(_value.upgradeChainResult!,
        (value) {
      return _then(_value.copyWith(upgradeChainResult: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ImportUpgradeResultImplCopyWith<$Res>
    implements $ImportUpgradeResultCopyWith<$Res> {
  factory _$$ImportUpgradeResultImplCopyWith(_$ImportUpgradeResultImpl value,
          $Res Function(_$ImportUpgradeResultImpl) then) =
      __$$ImportUpgradeResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {ImportUpgradeStatus status,
      String sourceVersion,
      String targetVersion,
      String message,
      String? upgradedFilePath,
      UpgradeChainResult? upgradeChainResult,
      String? errorMessage});

  @override
  $UpgradeChainResultCopyWith<$Res>? get upgradeChainResult;
}

/// @nodoc
class __$$ImportUpgradeResultImplCopyWithImpl<$Res>
    extends _$ImportUpgradeResultCopyWithImpl<$Res, _$ImportUpgradeResultImpl>
    implements _$$ImportUpgradeResultImplCopyWith<$Res> {
  __$$ImportUpgradeResultImplCopyWithImpl(_$ImportUpgradeResultImpl _value,
      $Res Function(_$ImportUpgradeResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of ImportUpgradeResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? sourceVersion = null,
    Object? targetVersion = null,
    Object? message = null,
    Object? upgradedFilePath = freezed,
    Object? upgradeChainResult = freezed,
    Object? errorMessage = freezed,
  }) {
    return _then(_$ImportUpgradeResultImpl(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as ImportUpgradeStatus,
      sourceVersion: null == sourceVersion
          ? _value.sourceVersion
          : sourceVersion // ignore: cast_nullable_to_non_nullable
              as String,
      targetVersion: null == targetVersion
          ? _value.targetVersion
          : targetVersion // ignore: cast_nullable_to_non_nullable
              as String,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      upgradedFilePath: freezed == upgradedFilePath
          ? _value.upgradedFilePath
          : upgradedFilePath // ignore: cast_nullable_to_non_nullable
              as String?,
      upgradeChainResult: freezed == upgradeChainResult
          ? _value.upgradeChainResult
          : upgradeChainResult // ignore: cast_nullable_to_non_nullable
              as UpgradeChainResult?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ImportUpgradeResultImpl extends _ImportUpgradeResult {
  const _$ImportUpgradeResultImpl(
      {required this.status,
      required this.sourceVersion,
      required this.targetVersion,
      required this.message,
      this.upgradedFilePath,
      this.upgradeChainResult,
      this.errorMessage})
      : super._();

  factory _$ImportUpgradeResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$ImportUpgradeResultImplFromJson(json);

  /// 升级状态
  @override
  final ImportUpgradeStatus status;

  /// 源数据版本
  @override
  final String sourceVersion;

  /// 目标数据版本
  @override
  final String targetVersion;

  /// 结果消息
  @override
  final String message;

  /// 升级后的文件路径
  @override
  final String? upgradedFilePath;

  /// 升级链结果
  @override
  final UpgradeChainResult? upgradeChainResult;

  /// 错误信息
  @override
  final String? errorMessage;

  @override
  String toString() {
    return 'ImportUpgradeResult(status: $status, sourceVersion: $sourceVersion, targetVersion: $targetVersion, message: $message, upgradedFilePath: $upgradedFilePath, upgradeChainResult: $upgradeChainResult, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ImportUpgradeResultImpl &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.sourceVersion, sourceVersion) ||
                other.sourceVersion == sourceVersion) &&
            (identical(other.targetVersion, targetVersion) ||
                other.targetVersion == targetVersion) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.upgradedFilePath, upgradedFilePath) ||
                other.upgradedFilePath == upgradedFilePath) &&
            (identical(other.upgradeChainResult, upgradeChainResult) ||
                other.upgradeChainResult == upgradeChainResult) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      status,
      sourceVersion,
      targetVersion,
      message,
      upgradedFilePath,
      upgradeChainResult,
      errorMessage);

  /// Create a copy of ImportUpgradeResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ImportUpgradeResultImplCopyWith<_$ImportUpgradeResultImpl> get copyWith =>
      __$$ImportUpgradeResultImplCopyWithImpl<_$ImportUpgradeResultImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ImportUpgradeResultImplToJson(
      this,
    );
  }
}

abstract class _ImportUpgradeResult extends ImportUpgradeResult {
  const factory _ImportUpgradeResult(
      {required final ImportUpgradeStatus status,
      required final String sourceVersion,
      required final String targetVersion,
      required final String message,
      final String? upgradedFilePath,
      final UpgradeChainResult? upgradeChainResult,
      final String? errorMessage}) = _$ImportUpgradeResultImpl;
  const _ImportUpgradeResult._() : super._();

  factory _ImportUpgradeResult.fromJson(Map<String, dynamic> json) =
      _$ImportUpgradeResultImpl.fromJson;

  /// 升级状态
  @override
  ImportUpgradeStatus get status;

  /// 源数据版本
  @override
  String get sourceVersion;

  /// 目标数据版本
  @override
  String get targetVersion;

  /// 结果消息
  @override
  String get message;

  /// 升级后的文件路径
  @override
  String? get upgradedFilePath;

  /// 升级链结果
  @override
  UpgradeChainResult? get upgradeChainResult;

  /// 错误信息
  @override
  String? get errorMessage;

  /// Create a copy of ImportUpgradeResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ImportUpgradeResultImplCopyWith<_$ImportUpgradeResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
