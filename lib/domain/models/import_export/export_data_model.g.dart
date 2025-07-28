// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_data_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ExportDataModelImpl _$$ExportDataModelImplFromJson(
        Map<String, dynamic> json) =>
    _$ExportDataModelImpl(
      metadata:
          ExportMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
      works: (json['works'] as List<dynamic>?)
              ?.map((e) => WorkEntity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      workImages: (json['workImages'] as List<dynamic>?)
              ?.map((e) => WorkImage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      characters: (json['characters'] as List<dynamic>?)
              ?.map((e) => CharacterEntity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      manifest:
          ExportManifest.fromJson(json['manifest'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ExportDataModelImplToJson(
        _$ExportDataModelImpl instance) =>
    <String, dynamic>{
      'metadata': instance.metadata,
      'works': instance.works,
      'workImages': instance.workImages,
      'characters': instance.characters,
      'manifest': instance.manifest,
    };

_$ExportMetadataImpl _$$ExportMetadataImplFromJson(Map<String, dynamic> json) =>
    _$ExportMetadataImpl(
      version: json['version'] as String? ?? '1.0.0',
      exportTime: DateTime.parse(json['exportTime'] as String),
      exportType: $enumDecode(_$ExportTypeEnumMap, json['exportType']),
      options: ExportOptions.fromJson(json['options'] as Map<String, dynamic>),
      appVersion: json['appVersion'] as String,
      platform: json['platform'] as String,
      dataFormatVersion: json['dataFormatVersion'] as String? ?? '1.0.0',
      compatibility: CompatibilityInfo.fromJson(
          json['compatibility'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ExportMetadataImplToJson(
        _$ExportMetadataImpl instance) =>
    <String, dynamic>{
      'version': instance.version,
      'exportTime': instance.exportTime.toIso8601String(),
      'exportType': _$ExportTypeEnumMap[instance.exportType]!,
      'options': instance.options,
      'appVersion': instance.appVersion,
      'platform': instance.platform,
      'dataFormatVersion': instance.dataFormatVersion,
      'compatibility': instance.compatibility,
    };

const _$ExportTypeEnumMap = {
  ExportType.worksOnly: 'worksOnly',
  ExportType.worksWithCharacters: 'worksWithCharacters',
  ExportType.charactersOnly: 'charactersOnly',
  ExportType.charactersWithWorks: 'charactersWithWorks',
  ExportType.fullData: 'fullData',
};

_$ExportManifestImpl _$$ExportManifestImplFromJson(Map<String, dynamic> json) =>
    _$ExportManifestImpl(
      summary: ExportSummary.fromJson(json['summary'] as Map<String, dynamic>),
      files: (json['files'] as List<dynamic>)
          .map((e) => ExportFileInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      statistics:
          ExportStatistics.fromJson(json['statistics'] as Map<String, dynamic>),
      validations: (json['validations'] as List<dynamic>)
          .map((e) => ExportValidation.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$ExportManifestImplToJson(
        _$ExportManifestImpl instance) =>
    <String, dynamic>{
      'summary': instance.summary,
      'files': instance.files,
      'statistics': instance.statistics,
      'validations': instance.validations,
    };

_$ExportSummaryImpl _$$ExportSummaryImplFromJson(Map<String, dynamic> json) =>
    _$ExportSummaryImpl(
      workCount: (json['workCount'] as num?)?.toInt() ?? 0,
      characterCount: (json['characterCount'] as num?)?.toInt() ?? 0,
      imageCount: (json['imageCount'] as num?)?.toInt() ?? 0,
      dataFileCount: (json['dataFileCount'] as num?)?.toInt() ?? 0,
      totalSize: (json['totalSize'] as num?)?.toInt() ?? 0,
      originalSize: (json['originalSize'] as num?)?.toInt() ?? 0,
      compressionRatio: (json['compressionRatio'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$$ExportSummaryImplToJson(_$ExportSummaryImpl instance) =>
    <String, dynamic>{
      'workCount': instance.workCount,
      'characterCount': instance.characterCount,
      'imageCount': instance.imageCount,
      'dataFileCount': instance.dataFileCount,
      'totalSize': instance.totalSize,
      'originalSize': instance.originalSize,
      'compressionRatio': instance.compressionRatio,
    };

_$ExportFileInfoImpl _$$ExportFileInfoImplFromJson(Map<String, dynamic> json) =>
    _$ExportFileInfoImpl(
      fileName: json['fileName'] as String,
      filePath: json['filePath'] as String,
      fileType: $enumDecode(_$ExportFileTypeEnumMap, json['fileType']),
      fileSize: (json['fileSize'] as num).toInt(),
      checksum: json['checksum'] as String,
      checksumAlgorithm: json['checksumAlgorithm'] as String? ?? 'MD5',
      isRequired: json['isRequired'] as bool? ?? true,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$$ExportFileInfoImplToJson(
        _$ExportFileInfoImpl instance) =>
    <String, dynamic>{
      'fileName': instance.fileName,
      'filePath': instance.filePath,
      'fileType': _$ExportFileTypeEnumMap[instance.fileType]!,
      'fileSize': instance.fileSize,
      'checksum': instance.checksum,
      'checksumAlgorithm': instance.checksumAlgorithm,
      'isRequired': instance.isRequired,
      'description': instance.description,
    };

const _$ExportFileTypeEnumMap = {
  ExportFileType.data: 'data',
  ExportFileType.image: 'image',
  ExportFileType.thumbnail: 'thumbnail',
  ExportFileType.metadata: 'metadata',
  ExportFileType.manifest: 'manifest',
  ExportFileType.config: 'config',
};

_$ExportStatisticsImpl _$$ExportStatisticsImplFromJson(
        Map<String, dynamic> json) =>
    _$ExportStatisticsImpl(
      worksByStyle: (json['worksByStyle'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const {},
      worksByTool: (json['worksByTool'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const {},
      worksByDate: (json['worksByDate'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const {},
      charactersByChar:
          (json['charactersByChar'] as Map<String, dynamic>?)?.map(
                (k, e) => MapEntry(k, (e as num).toInt()),
              ) ??
              const {},
      filesByFormat: (json['filesByFormat'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const {},
      customConfigs: CustomConfigStatistics.fromJson(
          json['customConfigs'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ExportStatisticsImplToJson(
        _$ExportStatisticsImpl instance) =>
    <String, dynamic>{
      'worksByStyle': instance.worksByStyle,
      'worksByTool': instance.worksByTool,
      'worksByDate': instance.worksByDate,
      'charactersByChar': instance.charactersByChar,
      'filesByFormat': instance.filesByFormat,
      'customConfigs': instance.customConfigs,
    };

_$CustomConfigStatisticsImpl _$$CustomConfigStatisticsImplFromJson(
        Map<String, dynamic> json) =>
    _$CustomConfigStatisticsImpl(
      customStyles: (json['customStyles'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      customTools: (json['customTools'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      customStyleUsage:
          (json['customStyleUsage'] as Map<String, dynamic>?)?.map(
                (k, e) => MapEntry(k, (e as num).toInt()),
              ) ??
              const {},
      customToolUsage: (json['customToolUsage'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const {},
    );

Map<String, dynamic> _$$CustomConfigStatisticsImplToJson(
        _$CustomConfigStatisticsImpl instance) =>
    <String, dynamic>{
      'customStyles': instance.customStyles,
      'customTools': instance.customTools,
      'customStyleUsage': instance.customStyleUsage,
      'customToolUsage': instance.customToolUsage,
    };

_$ExportValidationImpl _$$ExportValidationImplFromJson(
        Map<String, dynamic> json) =>
    _$ExportValidationImpl(
      type: $enumDecode(_$ExportValidationTypeEnumMap, json['type']),
      status: $enumDecode(_$ValidationStatusEnumMap, json['status']),
      message: json['message'] as String,
      details: json['details'] as Map<String, dynamic>?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$$ExportValidationImplToJson(
        _$ExportValidationImpl instance) =>
    <String, dynamic>{
      'type': _$ExportValidationTypeEnumMap[instance.type]!,
      'status': _$ValidationStatusEnumMap[instance.status]!,
      'message': instance.message,
      'details': instance.details,
      'timestamp': instance.timestamp.toIso8601String(),
    };

const _$ExportValidationTypeEnumMap = {
  ExportValidationType.dataIntegrity: 'dataIntegrity',
  ExportValidationType.fileIntegrity: 'fileIntegrity',
  ExportValidationType.relationships: 'relationships',
  ExportValidationType.format: 'format',
  ExportValidationType.sizeLimit: 'sizeLimit',
  ExportValidationType.incrementalSync: 'incrementalSync',
  ExportValidationType.cloudIntegration: 'cloudIntegration',
  ExportValidationType.performance: 'performance',
};

const _$ValidationStatusEnumMap = {
  ValidationStatus.passed: 'passed',
  ValidationStatus.warning: 'warning',
  ValidationStatus.failed: 'failed',
  ValidationStatus.skipped: 'skipped',
};

_$CompatibilityInfoImpl _$$CompatibilityInfoImplFromJson(
        Map<String, dynamic> json) =>
    _$CompatibilityInfoImpl(
      minSupportedVersion: json['minSupportedVersion'] as String,
      recommendedVersion: json['recommendedVersion'] as String,
      compatibilityFlags: (json['compatibilityFlags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      backwardCompatible: json['backwardCompatible'] as bool? ?? true,
      forwardCompatible: json['forwardCompatible'] as bool? ?? false,
    );

Map<String, dynamic> _$$CompatibilityInfoImplToJson(
        _$CompatibilityInfoImpl instance) =>
    <String, dynamic>{
      'minSupportedVersion': instance.minSupportedVersion,
      'recommendedVersion': instance.recommendedVersion,
      'compatibilityFlags': instance.compatibilityFlags,
      'backwardCompatible': instance.backwardCompatible,
      'forwardCompatible': instance.forwardCompatible,
    };

_$ExportOptionsImpl _$$ExportOptionsImplFromJson(Map<String, dynamic> json) =>
    _$ExportOptionsImpl(
      type: $enumDecode(_$ExportTypeEnumMap, json['type']),
      format: $enumDecode(_$ExportFormatEnumMap, json['format']),
      includeImages: json['includeImages'] as bool? ?? true,
      includeMetadata: json['includeMetadata'] as bool? ?? true,
      compressData: json['compressData'] as bool? ?? true,
      version: json['version'] as String? ?? '1.0',
      includeRelatedData: json['includeRelatedData'] as bool? ?? true,
      compressionLevel: (json['compressionLevel'] as num?)?.toInt() ?? 6,
      generateThumbnails: json['generateThumbnails'] as bool? ?? true,
      fileNamePrefix: json['fileNamePrefix'] as String?,
      customOptions: json['customOptions'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$$ExportOptionsImplToJson(_$ExportOptionsImpl instance) =>
    <String, dynamic>{
      'type': _$ExportTypeEnumMap[instance.type]!,
      'format': _$ExportFormatEnumMap[instance.format]!,
      'includeImages': instance.includeImages,
      'includeMetadata': instance.includeMetadata,
      'compressData': instance.compressData,
      'version': instance.version,
      'includeRelatedData': instance.includeRelatedData,
      'compressionLevel': instance.compressionLevel,
      'generateThumbnails': instance.generateThumbnails,
      'fileNamePrefix': instance.fileNamePrefix,
      'customOptions': instance.customOptions,
    };

const _$ExportFormatEnumMap = {
  ExportFormat.json: 'json',
  ExportFormat.zip: 'zip',
  ExportFormat.backup: 'backup',
};
