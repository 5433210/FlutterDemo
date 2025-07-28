// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_export_data_adapter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ImportExportAdapterResultImpl _$$ImportExportAdapterResultImplFromJson(
        Map<String, dynamic> json) =>
    _$ImportExportAdapterResultImpl(
      success: json['success'] as bool,
      message: json['message'] as String,
      outputPath: json['outputPath'] as String?,
      errorCode: json['errorCode'] as String?,
      errorDetails: json['errorDetails'] as Map<String, dynamic>?,
      statistics: json['statistics'] == null
          ? null
          : ImportExportAdapterStatistics.fromJson(
              json['statistics'] as Map<String, dynamic>),
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$$ImportExportAdapterResultImplToJson(
        _$ImportExportAdapterResultImpl instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'outputPath': instance.outputPath,
      'errorCode': instance.errorCode,
      'errorDetails': instance.errorDetails,
      'statistics': instance.statistics,
      'timestamp': instance.timestamp?.toIso8601String(),
      'metadata': instance.metadata,
    };

_$ImportExportAdapterStatisticsImpl
    _$$ImportExportAdapterStatisticsImplFromJson(Map<String, dynamic> json) =>
        _$ImportExportAdapterStatisticsImpl(
          startTime: DateTime.parse(json['startTime'] as String),
          endTime: DateTime.parse(json['endTime'] as String),
          durationMs: (json['durationMs'] as num).toInt(),
          processedFiles: (json['processedFiles'] as num?)?.toInt() ?? 0,
          convertedRecords: (json['convertedRecords'] as num?)?.toInt() ?? 0,
          originalSizeBytes: (json['originalSizeBytes'] as num?)?.toInt() ?? 0,
          convertedSizeBytes:
              (json['convertedSizeBytes'] as num?)?.toInt() ?? 0,
          skippedRecords: (json['skippedRecords'] as num?)?.toInt() ?? 0,
          errorRecords: (json['errorRecords'] as num?)?.toInt() ?? 0,
          details: json['details'] as Map<String, dynamic>? ?? const {},
        );

Map<String, dynamic> _$$ImportExportAdapterStatisticsImplToJson(
        _$ImportExportAdapterStatisticsImpl instance) =>
    <String, dynamic>{
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime.toIso8601String(),
      'durationMs': instance.durationMs,
      'processedFiles': instance.processedFiles,
      'convertedRecords': instance.convertedRecords,
      'originalSizeBytes': instance.originalSizeBytes,
      'convertedSizeBytes': instance.convertedSizeBytes,
      'skippedRecords': instance.skippedRecords,
      'errorRecords': instance.errorRecords,
      'details': instance.details,
    };

_$UpgradeChainResultImpl _$$UpgradeChainResultImplFromJson(
        Map<String, dynamic> json) =>
    _$UpgradeChainResultImpl(
      success: json['success'] as bool,
      message: json['message'] as String,
      finalOutputPath: json['finalOutputPath'] as String?,
      adapterResults: (json['adapterResults'] as List<dynamic>)
          .map((e) =>
              ImportExportAdapterResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      statistics: json['statistics'] == null
          ? null
          : UpgradeChainStatistics.fromJson(
              json['statistics'] as Map<String, dynamic>),
      errorMessage: json['errorMessage'] as String?,
      failedAdapterIndex: (json['failedAdapterIndex'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$UpgradeChainResultImplToJson(
        _$UpgradeChainResultImpl instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'finalOutputPath': instance.finalOutputPath,
      'adapterResults': instance.adapterResults,
      'statistics': instance.statistics,
      'errorMessage': instance.errorMessage,
      'failedAdapterIndex': instance.failedAdapterIndex,
    };

_$UpgradeChainStatisticsImpl _$$UpgradeChainStatisticsImplFromJson(
        Map<String, dynamic> json) =>
    _$UpgradeChainStatisticsImpl(
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      totalDurationMs: (json['totalDurationMs'] as num).toInt(),
      adapterCount: (json['adapterCount'] as num).toInt(),
      totalRecords: (json['totalRecords'] as num?)?.toInt() ?? 0,
      totalFiles: (json['totalFiles'] as num?)?.toInt() ?? 0,
      originalSizeBytes: (json['originalSizeBytes'] as num?)?.toInt() ?? 0,
      finalSizeBytes: (json['finalSizeBytes'] as num?)?.toInt() ?? 0,
      adapterDurations:
          (json['adapterDurations'] as Map<String, dynamic>?)?.map(
                (k, e) => MapEntry(k, (e as num).toInt()),
              ) ??
              const {},
    );

Map<String, dynamic> _$$UpgradeChainStatisticsImplToJson(
        _$UpgradeChainStatisticsImpl instance) =>
    <String, dynamic>{
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime.toIso8601String(),
      'totalDurationMs': instance.totalDurationMs,
      'adapterCount': instance.adapterCount,
      'totalRecords': instance.totalRecords,
      'totalFiles': instance.totalFiles,
      'originalSizeBytes': instance.originalSizeBytes,
      'finalSizeBytes': instance.finalSizeBytes,
      'adapterDurations': instance.adapterDurations,
    };

_$ImportUpgradeResultImpl _$$ImportUpgradeResultImplFromJson(
        Map<String, dynamic> json) =>
    _$ImportUpgradeResultImpl(
      status: $enumDecode(_$ImportUpgradeStatusEnumMap, json['status']),
      sourceVersion: json['sourceVersion'] as String,
      targetVersion: json['targetVersion'] as String,
      message: json['message'] as String,
      upgradedFilePath: json['upgradedFilePath'] as String?,
      upgradeChainResult: json['upgradeChainResult'] == null
          ? null
          : UpgradeChainResult.fromJson(
              json['upgradeChainResult'] as Map<String, dynamic>),
      errorMessage: json['errorMessage'] as String?,
    );

Map<String, dynamic> _$$ImportUpgradeResultImplToJson(
        _$ImportUpgradeResultImpl instance) =>
    <String, dynamic>{
      'status': _$ImportUpgradeStatusEnumMap[instance.status]!,
      'sourceVersion': instance.sourceVersion,
      'targetVersion': instance.targetVersion,
      'message': instance.message,
      'upgradedFilePath': instance.upgradedFilePath,
      'upgradeChainResult': instance.upgradeChainResult,
      'errorMessage': instance.errorMessage,
    };

const _$ImportUpgradeStatusEnumMap = {
  ImportUpgradeStatus.compatible: 'compatible',
  ImportUpgradeStatus.upgraded: 'upgraded',
  ImportUpgradeStatus.appUpgradeRequired: 'appUpgradeRequired',
  ImportUpgradeStatus.incompatible: 'incompatible',
  ImportUpgradeStatus.error: 'error',
};
